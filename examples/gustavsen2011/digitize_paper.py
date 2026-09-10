#!/usr/bin/env python3
"""Digitize seven figure traces from the supplied PDF; no Julia results are read.

Requires pypdf, numpy and Pillow. Run with the source PDF as the first argument.
The axis calibrations below are in ORIGINAL embedded-image pixels (x right,
y down), not screenshots or resized previews. See reference/README.md.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from pypdf import PdfReader

HERE = Path(__file__).resolve().parent
SPECS = [
    dict(id="fig07", page=3, image="Im40.tiff", kind="measurement", unit="V",
         quantity="sending_voltage", box=[264, 1896, 20, 1324],
         x_cal=[[264, 0], [1896, 900e-6]], y_cal=[[20, 5000], [1324, -500]],
         grid_times_s=[200e-6, 400e-6, 600e-6, 800e-6]),
    dict(id="fig08", page=3, image="Im41.tiff", kind="measurement", unit="V",
         quantity="receiving_voltage", box=[275, 1887, 21, 1325],
         x_cal=[[275, 0], [1887, 900e-6]], y_cal=[[21, 6000], [1325, -5000]],
         grid_times_s=[200e-6, 400e-6, 600e-6, 800e-6]),
    dict(id="fig09", page=3, image="Im42.tiff", kind="measurement", unit="A",
         quantity="sending_current", box=[226, 1866, 20, 1325],
         x_cal=[[226, 0], [1866, 900e-6]], y_cal=[[20, 200], [1325, -200]],
         grid_times_s=[200e-6, 400e-6, 600e-6, 800e-6]),
    dict(id="fig10", page=4, image="Im52.tiff", kind="measurement", unit="A",
         quantity="receiving_load_current", box=[181, 1886, 21, 1380],
         x_cal=[[181, 0], [1886, 900e-6]], y_cal=[[21, 12], [1380, -8]],
         grid_times_s=[200e-6, 400e-6, 600e-6, 800e-6]),
    # Fig. 14's last labelled x tick is 40 us; the frame extends beyond it.
    # Calibrating the right frame as 40 us would incorrectly compress time.
    dict(id="fig14", page=5, image="Im85.jpg", kind="paper_simulation", unit="A",
         quantity="sending_current", box=[104, 988, 10, 564],
         x_cal=[[104, 0], [966, 40e-6]], y_cal=[[10, 140], [564, 0]],
         legend=[631, 19, 984, 101]),
    dict(id="fig15", page=6, image="Im87.jpg", kind="paper_simulation", unit="A",
         quantity="sending_current", box=[103, 969, 2, 547],
         x_cal=[[103, 0], [969, 90e-6]], y_cal=[[319, 0], [547, -100]],
         legend=[610, 14, 958, 93]),
    dict(id="fig16", page=6, image="Im88.jpg", kind="paper_simulation", unit="A",
         quantity="sending_current", box=[109, 972, 2, 544],
         x_cal=[[109, 0], [972, 900e-6]], y_cal=[[318, 0], [544, -100]],
         legend=[618, 11, 962, 91]),
]


def linear_map(values, calibration):
    (p0, v0), (p1, v1) = calibration
    return v0 + (np.asarray(values) - p0) * (v1 - v0) / (p1 - p0)


def extract_trace(image, spec):
    rgb = np.asarray(image.convert("RGB"), dtype=float)
    if spec["kind"] == "measurement":
        mask = rgb[:, :, 0] < 128
        # Remove isolated fine grid dots; no smoothing of the numerical trace.
        opened = Image.fromarray((255 * mask).astype(np.uint8))
        opened = opened.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
        mask = np.asarray(opened) > 0
        margin = 6
    else:
        r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
        mask = (b > 80) & (b - r > 60) & (b - g > 50)
        lx0, ly0, lx1, ly1 = spec["legend"]
        mask[ly0:ly1, lx0:lx1] = False
        margin = 2
    x0, x1, y0, y1 = spec["box"]
    mask[:y0 + margin] = False
    mask[y1 - margin:] = False
    mask[:, :x0 + margin] = False
    mask[:, x1 - margin:] = False
    rows = []
    skipped = 0
    for x in range(x0 + margin, x1 - margin):
        t = float(linear_map(x, spec["x_cal"]))
        seconds_per_pixel = abs(float(linear_map(x + 1, spec["x_cal"])) - t)
        if any(abs(t - grid_t) < 4 * seconds_per_pixel
               for grid_t in spec.get("grid_times_s", [])):
            skipped += 1
            continue
        ys = np.flatnonzero(mask[:, x])
        if len(ys) == 0:
            skipped += 1
            continue
        # Choose the thick trace run, not scattered grid dots elsewhere in the
        # same column. Overlapping/jagged strokes remain an approximation.
        groups = np.split(ys, np.where(np.diff(ys) > 1)[0] + 1)
        stroke = max(groups, key=len)
        centre = float(np.median(stroke))
        value = float(linear_map(centre, spec["y_cal"]))
        bounds = sorted(linear_map([stroke[0] - 0.5, stroke[-1] + 0.5], spec["y_cal"]))
        rows.append([t, value, *bounds, x, centre])
    result = np.asarray(rows, dtype=float)
    assert len(result) > 500, f"Insufficient trace samples: {spec['id']}"
    assert np.all(np.diff(result[:, 0]) > 0), "Times must be strictly increasing"
    assert np.isfinite(result).all(), "Nonfinite extracted point"
    assert np.max(np.diff(result[:, 4])) <= 12, "Unexpected gap needs manual review"
    return result, skipped


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--output", type=Path, default=HERE / "reference")
    parser.add_argument("--qa-output", type=Path,
                        default=HERE.parent.parent / "output/gustavsen2011/comparison/digitization_qa")
    args = parser.parse_args()
    reader = PdfReader(args.pdf)
    args.output.mkdir(parents=True, exist_ok=True)
    args.qa_output.mkdir(parents=True, exist_ok=True)
    datasets = {}
    records = []
    metadata = dict(
        source_filename=args.pdf.name,
        source_sha256=hashlib.sha256(args.pdf.read_bytes()).hexdigest(),
        citation="Gudmundsdottir et al., IEEE TPWRD 26(3), 2011, 1403-1410",
        doi="10.1109/TPWRD.2010.2084600",
        method="Native raster pixel trace extraction; original axes; no fit or time shift",
        columns=["time_s", "value", "stroke_lower", "stroke_upper", "pixel_x", "pixel_y"],
        bounds_note="Selected stroke extent, not a statistical confidence interval or instrument accuracy",
        traces=[],
    )
    for spec in SPECS:
        pdf_image = next(i for i in reader.pages[spec["page"] - 1].images if i.name == spec["image"])
        image = pdf_image.image.convert("RGB")
        data, skipped = extract_trace(image, spec)
        datasets[spec["id"]] = data
        records.extend([spec["id"], spec["kind"], spec["unit"], *row] for row in data)
        seconds_per_pixel = abs(np.diff(np.array(spec["x_cal"]), axis=0)[0, 1] /
                                np.diff(np.array(spec["x_cal"]), axis=0)[0, 0])
        units_per_pixel = abs(np.diff(np.array(spec["y_cal"]), axis=0)[0, 1] /
                              np.diff(np.array(spec["y_cal"]), axis=0)[0, 0])
        metadata["traces"].append(dict(
            **spec, image_size=list(image.size), sample_count=len(data),
            skipped_columns=skipped, seconds_per_pixel=seconds_per_pixel,
            value_units_per_pixel=units_per_pixel,
            max_gap_s=float(np.max(np.diff(data[:, 0]))),
        ))
        # This diagnostic overlay is for checking calibration/curve selection,
        # not a replacement for the source image or a data-validation benchmark.
        overlay = image.copy()
        draw = ImageDraw.Draw(overlay)
        points = [tuple(row[4:6]) for row in data]
        draw.line(points, fill=(230, 90, 0) if spec["kind"] == "measurement" else (0, 160, 70), width=2)
        overlay.save(args.qa_output / f"{spec['id']}_trace_overlay.png")
        print(f"{spec['id']}: {len(data)} samples, {seconds_per_pixel*1e6:.3f} us/pixel, "
              f"{units_per_pixel:.3f} {spec['unit']}/pixel")
    np.savez(args.output / "paper_traces.npz", **datasets)
    with (args.output / "paper_traces.csv").open("w", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(["figure", "kind", "unit", *metadata["columns"]])
        writer.writerows(records)
    (args.output / "digitization.json").write_text(json.dumps(metadata, indent=2) + "\n")


if __name__ == "__main__":
    main()
