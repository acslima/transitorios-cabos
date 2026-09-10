# Run from the repository root: julia --project=. examples/gustavsen2011.jl
# Optional first argument: output directory.
include("gustavsen2011/case.jl")
using .Gustavsen2011
using NPZ: npzwrite
ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")
using Plots

function run_gustavsen2011(; output_dir=joinpath(@__DIR__, "..", "output", "gustavsen2011"),
                          soil_resistivity=100.0, peak_v=4080.0,
                          dt=0.05e-6, duration=900e-6)
    case = build_case(; soil_resistivity, peak_v)
    println("Figure 5: 7.625 km, nine segments, four sheath cross bondings.")
    println("Source: ", peak_v, " V, 1.2/50 μs; soil resistivity ASSUMED: ",
            soil_resistivity, " Ω·m.")
    result = simulate(case; dt, duration)
    estimates = coaxial_estimates()
    mkpath(output_dir)
    output_dir = abspath(output_dir)

    arrays = Dict(
        "time_s" => result.time_s,
        "sending_voltage_v" => result.sending_voltage_v,
        "receiving_voltage_v" => result.receiving_voltage_v,
        "sending_current_a" => result.sending_current_a,
        "receiving_current_a" => result.receiving_current_a,
        "receiving_load_current_a" => result.receiving_load_current_a,
        "prescribed_source_v" => result.prescribed_source_v,
    )
    npzwrite(joinpath(output_dir, "waveforms.npz"), arrays)
    labels = ["c1", "s1", "c2", "s2", "c3", "s3"]
    headers = vcat("time_s", "prescribed_source_v",
        ["$(endname)_$(quantity)_$(label)_$(unit)"
         for (endname, quantity, unit) in
             (("sending", "voltage", "v"), ("receiving", "voltage", "v"),
              ("sending", "current", "a"), ("receiving", "current", "a"))
         for label in labels])
    values = hcat(result.time_s, result.prescribed_source_v,
                  result.sending_voltage_v, result.receiving_voltage_v,
                  result.sending_current_a, result.receiving_current_a)
    open(joinpath(output_dir, "waveforms.csv"), "w") do io
        println(io, join(headers, ','))
        for row in eachrow(values)
            println(io, join(row, ','))
        end
    end

    colors = [:royalblue, :darkorange, :seagreen]
    phase_labels = ["Phase 1" "Phase 2" "Phase 3"]
    t_us = result.time_s * 1e6
    common = (; xlabel="Time [μs]", lw=1.5, legend=:topright,
                label=phase_labels, color=reshape(colors, 1, :), gridalpha=0.2,
                xlims=(0, duration * 1e6), left_margin=5Plots.mm)
    p1 = plot(t_us, result.sending_voltage_v[:, 1:2:5] / 1e3;
              common..., title="Sending end core voltages", ylabel="Voltage [kV]")
    p2 = plot(t_us, result.receiving_voltage_v[:, 1:2:5] / 1e3;
              common..., title="Receiving end core voltages", ylabel="Voltage [kV]")
    p3 = plot(t_us, result.sending_current_a[:, 1:2:5];
              common..., title="Sending end core currents", ylabel="Current into cable [A]")
    p4 = plot(t_us, result.receiving_load_current_a;
              common..., title="Receiving end 500 Ω load currents", ylabel="Load current [A]")
    panel = plot(p1, p2, p3, p4; layout=(2, 2), size=(1400, 900),
                 plot_title="Figure 5 reconstruction | ideal 1.2/50 μs source | Table I parameters",
                 plot_titlefontsize=13, bottom_margin=5Plots.mm)
    savefig(panel, joinpath(output_dir, "waveforms.png"))

    early = t_us .<= min(100.0, duration * 1e6)
    zoom = plot(t_us[early], result.sending_current_a[early, 1];
        xlabel="Time [μs]", ylabel="Phase 1 current into cable [A]", lw=2,
        label="Calculated", color=:royalblue, size=(1100, 500),
        title="Initial transient | Table I predicts a later reflection than the paper reports",
        legend=:topright, xlims=(0, min(100.0, duration * 1e6)), margin=5Plots.mm)
    vline!(zoom, [estimates.first_cross_bond_return_s * 1e6];
           label="Table I: first coaxial return (lossless)", color=:darkorange, ls=:dash)
    vline!(zoom, [17.4]; label="Paper: measured first return", color=:gray, ls=:dot)
    savefig(zoom, joinpath(output_dir, "initial_current.png"))

    open(joinpath(output_dir, "run_info.txt"), "w") do io
        println(io, "Source: Gudmundsdottir et al., IEEE TPWRD 26(3), 2011, 1403-1410")
        println(io, "DOI: 10.1109/TPWRD.2010.2084600; Figures 3, 5, 11, 12; Table I")
        println(io, "Julia: ", VERSION)
        println(io, "Soil resistivity [ohm m], ASSUMED: ", soil_resistivity)
        println(io, "Impulse peak [V]: ", peak_v, " (Section III: 4080; Fig. 6: 4280)")
        println(io, "Waveform: calibrated double exponential, nominal 1.2/50 us")
        println(io, "dt [s]: ", result.dt_s, "; duration [s]: ", last(result.time_s))
        println(io, "FFT period [s]: ", result.transform_period_s,
                "; Laplace shift [1/s]: ", result.laplace_shift_per_s)
        println(io, "Terminal sheaths: exact zero volts; five core shunts: 500 ohms each")
        println(io, "Internal ground: six 10 uH legs to common bus, then 1 mOhm to earth")
        println(io, "Both stored end currents are positive INTO the cable.")
        println(io, "Receiving load current is minus receiving core current.")
        println(io, "Array conductor order: core1,sheath1,core2,sheath2,core3,sheath3")
        println(io, "Lossless estimates from Table I: ", estimates)
        println(io, "Paper measured one-way time: 39 us; Table I gives about 43.05 us.")
        println(io, "Assumptions: ideal source, homogeneous conducting soil without displacement current,")
        println(io, "equipotential soil for shunt capacitance, nonmagnetic metals/jacket.")
        println(io, "Omitted: adjacent circuit/OHL, proximity, dielectric losses, arresters.")
        println(io, "No measured samples are supplied; this is not a field-trace validation.")
        println(io, "Extracted parameters (SI units): ", PAPER_DATA)
    end
    println("Lossless coaxial impedance: ", round(estimates.surge_impedance_ohm; digits=3), " Ω")
    println("Table I one-way time: ", round(1e6estimates.one_way_time_s; digits=3),
            " μs; paper reports 39 μs measured.")
    println("Phase 1 sending-current peak: ", round(maximum(result.sending_current_a[:, 1]); digits=3), " A")
    println("Saved waveforms, plots and run settings to ", output_dir)
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_gustavsen2011(; output_dir=isempty(ARGS) ?
        joinpath(@__DIR__, "..", "output", "gustavsen2011") : first(ARGS))
end
