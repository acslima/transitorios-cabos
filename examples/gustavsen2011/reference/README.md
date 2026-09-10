# Digitized reference curves

These are **approximate traces extracted from printed figures**, not original
measurement samples, PSCAD output files, or regression-test truth.

Source: U. S. Gudmundsdottir, B. Gustavsen, C. L. Bak and W. Wiechowski,
*Field Test and Simulation of a 400-kV Cross-Bonded Cable System*, IEEE
Transactions on Power Delivery 26(3), 2011, pp. 1403-1410,
[doi:10.1109/TPWRD.2010.2084600](https://doi.org/10.1109/TPWRD.2010.2084600).
Extracted from the user-supplied `26pwrd03gustavsen.pdf`. The exact PDF SHA-256,
embedded image names, image sizes and pixel calibrations are in
`digitization.json`.

| Figure | PDF page | Curve extracted | Horizontal scale | Vertical scale |
| --- | ---: | --- | ---: | ---: |
| 7 | 3 | Measured phase 1 sending voltage | 0.551 μs/pixel | 4.218 V/pixel |
| 8 | 3 | Measured phase 1 receiving voltage | 0.558 μs/pixel | 8.436 V/pixel |
| 9 | 3 | Measured phase 1 sending current | 0.549 μs/pixel | 0.307 A/pixel |
| 10 | 4 | Measured phase 1 receiving load current | 0.528 μs/pixel | 0.0147 A/pixel |
| 14 | 5 | Blue PSCAD sending-current simulation | 0.0464 μs/pixel | 0.253 A/pixel |
| 15 | 6 | Blue PSCAD sending-current simulation | 0.104 μs/pixel | 0.439 A/pixel |
| 16 | 6 | Blue PSCAD sending-current simulation | 1.043 μs/pixel | 0.442 A/pixel |

Pixel scale alone is not the total extraction uncertainty. Stroke width, raster
noise, JPEG artifacts, axis calibration and overlapping annotations also matter.

## Method

`../digitize_paper.py` extracts the **native embedded images** using pypdf.
It does not use Julia results, rendered screenshots, curve fitting or time
alignment. Coordinates are zero-based original image pixels: x increases right,
y increases down.

For monochrome Figures 7-10, the script thresholds the dark pixels and applies
a 3-pixel morphological opening to remove fine grid dots. It skips the vertical
grid columns and selects the longest contiguous dark run in each retained
column. The run's median is the trace estimate. This follows the thick measured
curve while rejecting isolated grid dots; it does not recover every noisy
excursion within the stroke.

For Figures 14-16, it selects blue pixels by their RGB contrast, masks the legend,
and takes the median of the longest blue run in each retained column. The black
dashed measured curves in those figures are **not independently extracted**.
The full sending-current comparison also shows the separately extracted
measurement from Figure 9, with that source identified in the legend.

Axes are mapped linearly using visible labelled ticks. Figure 14 is calibrated
with its 0 and 40 μs ticks; the right border lies beyond 40 μs. The comparison
stops at 40 μs, although its caption refers to 45 μs. All other time-domain
figures are mapped to the visible 0-900 μs or 0-90 μs range.

Plot borders and ticks are excluded. Consequently, the first retained samples
are slightly after zero and the last samples slightly before the right border;
they are not extrapolated. Small missing column intervals (grid lines or
annotations) are joined by straight plot segments. The largest gap and retained
sample count for each curve are recorded in the metadata.

Measured voltage and receiving current were extracted **independently** from
Figures 8 and 10; their values were not forced to satisfy a 500 Ω relation.
The Julia receiving current is plotted positive into the 500 Ω load, as in
the paper, rather than positive into the cable at the receiving port.

## Files and checks

- `paper_traces.npz`: one N×6 array for each figure (`fig07`, ..., `fig16`).
- `paper_traces.csv`: the same data in a long table with figure, kind and unit.
- `digitization.json`: provenance, calibrations, masks and extraction metadata.

The six numeric columns are `time_s`, `value`, `stroke_lower`, `stroke_upper`,
`pixel_x`, `pixel_y`. Values use volts or amperes as listed above. Stroke bounds
describe the selected pixel run, **not confidence intervals** or measurement
instrument accuracy.

The extraction checks finite values, increasing time, sample coverage and gap
size. Diagnostic overlays are generated in
`output/gustavsen2011/comparison/digitization_qa/`; the extracted paths were
visually checked against the source images. The plotting script also checks
array dimensions, reference gaps, finite values and Julia's receiving load law.
No digitized result is used to modify the cable model or to assert that the
field experiment has been reproduced exactly.

## Regenerate

With Python packages `pypdf`, `numpy` and `Pillow` available:

```sh
python3 examples/gustavsen2011/digitize_paper.py /path/to/26pwrd03gustavsen.pdf
julia --project=. examples/gustavsen2011/compare_paper.jl
```

The Julia plotting command needs only the bundled reference arrays and the
saved Julia run. It does not need Python or access to the original PDF.

The output directory contains seven individual PNG/SVG comparisons, two overview
sheets, `comparison_metrics.csv`, `comparison_notes.md`, and a copy of the Julia
run settings. RMSE is calculated on the shared time range, interpolating Julia
onto retained paper sample times without fitting, scaling or shifting either
curve. These metrics describe both excitation/model differences and digitization
limitations; they are not solver error estimates.
