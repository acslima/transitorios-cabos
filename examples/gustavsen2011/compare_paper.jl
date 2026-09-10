# From the project root: julia --project=. examples/gustavsen2011/compare_paper.jl
# Uses the saved Julia run and the digitized reference data. Does not fit,
# rescale, shift, or rerun the cable model.
using NPZ: npzread
using Printf: @sprintf
using SHA: sha256
ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")
using Plots

const COMPARISON_SPECS = [
    (id="fig07", number=7, title="Sending end voltage", kind="measurement",
     key="sending_voltage_v", scale=1e3, unit="V", display_unit="kV",
     stop_us=900.0, ylim=(-0.6, 4.6)),
    (id="fig08", number=8, title="Receiving end voltage", kind="measurement",
     key="receiving_voltage_v", scale=1e3, unit="V", display_unit="kV",
     stop_us=900.0, ylim=(-3.2, 4.8)),
    (id="fig09", number=9, title="Sending end current", kind="measurement",
     key="sending_current_a", scale=1.0, unit="A", display_unit="A",
     stop_us=900.0, ylim=(-100.0, 150.0)),
    (id="fig10", number=10, title="Receiving end load current", kind="measurement",
     key="receiving_load_current_a", scale=1.0, unit="A", display_unit="A",
     stop_us=900.0, ylim=(-6.0, 10.0)),
    (id="fig14", number=14, title="Sending current: first 40 μs", kind="paper_simulation",
     key="sending_current_a", scale=1.0, unit="A", display_unit="A",
     stop_us=40.0, ylim=(0.0, 145.0)),
    (id="fig15", number=15, title="Sending current: first 90 μs", kind="paper_simulation",
     key="sending_current_a", scale=1.0, unit="A", display_unit="A",
     stop_us=90.0, ylim=(-100.0, 150.0)),
    (id="fig16", number=16, title="Sending current: full 900 μs", kind="paper_simulation",
     key="sending_current_a", scale=1.0, unit="A", display_unit="A",
     stop_us=900.0, ylim=(-100.0, 150.0)),
]

# Interpolate Julia onto digitized times only, with no extrapolation.
function comparison_interpolate(t, y, query)
    issorted(t) && all(diff(t) .> 0) || error("Julia time samples must increase.")
    return map(query) do q
        first(t) <= q <= last(t) || error("Interpolation outside Julia time range.")
        i = min(searchsortedlast(t, q), length(t) - 1)
        fraction = (q - t[i]) / (t[i+1] - t[i])
        y[i] + fraction * (y[i+1] - y[i])
    end
end

function comparison_panel(spec, julia_data, references)
    ref = references[spec.id]
    t = julia_data["time_s"]
    paper_mask = ref[:, 1] .<= spec.stop_us * 1e-6
    julia_mask = t .<= spec.stop_us * 1e-6
    measured = spec.kind == "measurement"
    paper_label = measured ? "Paper measurement (Fig. $(spec.number), digitized)" :
                             "Paper PSCAD (Fig. $(spec.number), digitized)"
    paper_color = measured ? "#333C49" : "#1766B5"
    p = plot(ref[paper_mask, 1] * 1e6, ref[paper_mask, 2] / spec.scale;
        label=paper_label, color=paper_color, linestyle=measured ? :solid : :dash,
        linewidth=measured ? 1.3 : 1.8, title="Fig. $(spec.number) · $(spec.title)",
        xlabel="Time [μs]", ylabel="$(occursin("voltage", spec.key) ? "Voltage" : "Current") [$(spec.display_unit)]",
        xlims=(0.0, spec.stop_us), ylims=spec.ylim, legend=:topright,
        legendfontsize=8, titlefontsize=11, guidefontsize=10, tickfontsize=9,
        gridalpha=0.16, foreground_color_grid="#526275", background_color=:white,
        framestyle=:box, size=(1250, 520), margin=5Plots.mm)
    # The full sending-current panels can also show the third available source.
    if spec.id == "fig09"
        ps = references["fig16"]
        plot!(p, ps[:, 1] * 1e6, ps[:, 2]; label="Paper PSCAD (Fig. 16, digitized)",
              color="#1766B5", linestyle=:dash, linewidth=1.6)
    elseif spec.id == "fig16"
        meas = references["fig09"]
        plot!(p, meas[:, 1] * 1e6, meas[:, 2]; label="Paper measurement (Fig. 9, digitized)",
              color="#333C49", linewidth=1.2)
    end
    plot!(p, t[julia_mask] * 1e6, julia_data[spec.key][julia_mask, 1] / spec.scale;
          label="Julia: Table I + ideal 1.2/50 μs source", color="#D45D00", linewidth=1.8)
    return p
end

function compare_paper(;
    run_dir=joinpath(@__DIR__, "..", "..", "output", "gustavsen2011"),
    reference_dir=joinpath(@__DIR__, "reference"),
    output_dir=joinpath(run_dir, "comparison"),
)
    waveform_path = joinpath(run_dir, "waveforms.npz")
    reference_path = joinpath(reference_dir, "paper_traces.npz")
    isfile(waveform_path) || error("Run examples/gustavsen2011.jl to generate Julia waveforms first.")
    isfile(reference_path) || error("Digitized reference data missing; run digitize_paper.py with the source PDF.")
    julia_data = npzread(waveform_path)
    references = npzread(reference_path)
    t = julia_data["time_s"]
    all(isfinite, t) && all(diff(t) .> 0) || error("Invalid Julia time data.")
    for key in unique([spec.key for spec in COMPARISON_SPECS])
        size(julia_data[key], 1) == length(t) || error("Waveform/time length mismatch.")
        all(isfinite, julia_data[key]) || error("Nonfinite saved Julia waveform.")
    end
    # The receiving current must use the load direction, not current into cable.
    isapprox(julia_data["receiving_load_current_a"],
             julia_data["receiving_voltage_v"][:, 1:2:5] / 500; atol=1e-8) ||
        error("Saved receiving load currents do not satisfy the 500 Ω load law.")
    mkpath(output_dir)
    output_dir = abspath(output_dir)
    panels = []
    metrics = []
    for spec in COMPARISON_SPECS
        ref = references[spec.id]
        size(ref, 2) == 6 && all(isfinite, ref) && all(diff(ref[:, 1]) .> 0) ||
            error("Invalid reference data for $(spec.id).")
        maxgap = maximum(diff(ref[:, 1]))
        maxgap < (spec.stop_us > 100 ? 6e-6 : 0.5e-6) ||
            error("Reference gap too large; review digitization.")
        p = comparison_panel(spec, julia_data, references)
        push!(panels, p)
        for extension in ("png", "svg")
            savefig(p, joinpath(output_dir, "$(spec.id)_comparison.$extension"))
        end
        keep = (ref[:, 1] .>= first(t)) .& (ref[:, 1] .<= min(last(t), spec.stop_us * 1e-6))
        rt, ry = ref[keep, 1], ref[keep, 2]
        jy = comparison_interpolate(t, julia_data[spec.key][:, 1], rt)
        difference = jy - ry
        rmse = sqrt(sum(abs2, difference) / length(difference))
        push!(metrics, (figure=spec.number, reference=spec.kind, quantity=spec.key,
            unit=spec.unit, samples=length(rt), start_us=1e6first(rt), end_us=1e6last(rt),
            paper_peak=maximum(ry), julia_peak_on_reference_grid=maximum(jy),
            rmse=rmse, nrmse_range_percent=100rmse / (maximum(ry) - minimum(ry))))
    end

    overview = plot(panels[1:4]...; layout=(2, 2), size=(1600, 1050),
        plot_title="Phase 1 terminal waveforms: paper and Julia",
        plot_titlefontsize=16, top_margin=6Plots.mm, bottom_margin=6Plots.mm)
    current = plot(panels[5:7]...; layout=(3, 1), size=(1450, 1300),
        plot_title="Phase 1 sending current: paper simulation and Julia",
        plot_titlefontsize=15, top_margin=5Plots.mm, bottom_margin=5Plots.mm)
    for extension in ("png", "svg")
        savefig(overview, joinpath(output_dir, "terminal_comparison.$extension"))
        savefig(current, joinpath(output_dir, "sending_current_comparison.$extension"))
    end
    open(joinpath(output_dir, "comparison_metrics.csv"), "w") do io
        println(io, join(string.(keys(first(metrics))), ','))
        for metric in metrics
            println(io, join(values(metric), ','))
        end
    end
    settings_path = joinpath(run_dir, "run_info.txt")
    isfile(settings_path) && cp(settings_path, joinpath(output_dir, "julia_run_info.txt"); force=true)
    open(joinpath(output_dir, "comparison_notes.md"), "w") do io
        println(io, "# Paper / Julia comparison\n")
        println(io, "Source: Gudmundsdottir et al., IEEE TPWRD 26(3), 2011, pp. 1403-1410; DOI 10.1109/TPWRD.2010.2084600.\n")
        println(io, "Seven separate comparisons and two overview sheets are provided as PNG and SVG. All plots concern phase 1.\n")
        println(io, "- Figures 7-10: the paper's measured terminal traces, digitized from the original raster images.")
        println(io, "- Figures 14-16: the blue PSCAD simulation traces in the paper, digitized separately.")
        println(io, "- The full sending-current panels also include the measured trace from Figure 9; the dashed measured curve in Figure 16 was not independently digitized.")
        println(io, "- Figure 14 is compared through its last labelled 40 μs tick; its caption refers to 45 μs.")
        println(io, "- Julia uses the existing saved run. No model tuning, amplitude normalization, time shift or waveform fitting was performed.\n")
        println(io, "## Reading the differences\n")
        println(io, "The measured sending voltage in Figure 7 differs from the ideal 1.2/50 μs source used by Julia. Current and receiving-voltage differences therefore combine excitation and cable-model differences. Table I implies a lossless first cross-bond return near 19.30 μs, whereas the paper marks 17.4 μs. The baseline also assumes soil resistivity of 100 Ω·m and omits proximity effects and the adjacent circuit. Consult julia_run_info.txt for the settings of the plotted run.\n")
        println(io, "Raster extraction is approximate. Pixel scales, source-image identities, calibration and stroke extents are stored in examples/gustavsen2011/reference/digitization.json. Missing grid/occluded columns are bridged by short line segments; endpoints are not extrapolated. Selected stroke extents are not measurement confidence intervals.\n")
        println(io, "## Descriptive discrepancies on the original time axes\n")
        println(io, "Julia was linearly interpolated onto the retained reference times. Metrics use only their shared time range. They summarize differences between the plotted curves; they are not acceptance tests or comparisons with original instrument samples. NRMSE is RMSE divided by the digitized reference's peak-to-peak range.\n")
        println(io, "| Figure | Reference | Window [μs] | RMSE | NRMSE / range |")
        println(io, "| --- | --- | --- | --- | --- |")
        for m in metrics
            println(io, @sprintf("| %d | %s | %.2f–%.2f | %.3g %s | %.1f%% |",
                m.figure, replace(m.reference, "_" => " "), m.start_us, m.end_us,
                m.rmse, m.unit, m.nrmse_range_percent))
        end
        println(io, "\n## Reproduce\n\n```sh\njulia --project=. examples/gustavsen2011/compare_paper.jl\n```\n")
        println(io, "Julia waveform SHA-256: `", bytes2hex(sha256(read(waveform_path))), "`\n")
        println(io, "Digitized reference SHA-256: `", bytes2hex(sha256(read(reference_path))), "`\n")
    end
    println("Saved 7 individual comparisons and 2 overview sheets (PNG + SVG) to ", output_dir)
    for m in metrics
        println(@sprintf("Fig. %d (%s): RMSE %.3g %s over %.2f–%.2f μs",
                         m.figure, m.reference, m.rmse, m.unit, m.start_us, m.end_us))
    end
    return metrics
end

if abspath(PROGRAM_FILE) == @__FILE__
    compare_paper()
end
