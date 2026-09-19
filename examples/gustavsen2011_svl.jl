# julia --project=. examples/gustavsen2011_svl.jl [output_directory]
include("gustavsen2011/case.jl")
using .Gustavsen2011
using NPZ: npzwrite
ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")
using Plots

function run_gustavsen2011_svl(;
    output_dir=joinpath(@__DIR__, "..", "output", "gustavsen2011_svl"),
    peak_v=100e3, soil_resistivity=100.0, curve=illustrative_svl(),
    junctions=PAPER_DATA.cross_bond_after, lead_resistance_ohm=0.1,
    lead_inductance_h=1e-6, earth_resistance_ohm=1.0,
    dt=0.05e-6, duration=200e-6, period=nothing, damping=10.0,
    reference_resistance_ohm=10.0)
    base = build_case(; peak_v, soil_resistivity)
    case = build_svl_case(base; curve, junctions, lead_resistance_ohm,
                          lead_inductance_h, earth_resistance_ohm)
    isempty(case.port_nodes) && throw(ArgumentError("Select at least one cross-bond box for this plotting example."))
    println("NLT with ", length(case.port_nodes), " SVLs; prescribed impulse = ", peak_v, " V.")
    println("Illustrative protection study: new source level, SVL curve and link-box earth/lead data are assumptions.")
    prepared = prepare_svl(case; dt, duration, period, damping, reference_resistance_ohm)
    protected = simulate_svl(prepared)
    unprotected = simulate_svl(prepared; enabled=false)
    output_dir = abspath(output_dir)
    mkpath(output_dir)
    arrays = Dict{String,Any}()
    for (prefix, result) in (("with_svl", protected), ("without_svl", unprotected))
        for (key, value) in pairs(result)
            value isa AbstractArray && (arrays["$(prefix)_$(key)"] = value)
        end
    end
    npzwrite(joinpath(output_dir, "waveforms.npz"), arrays)
    for (filename, result) in (("with_svl.csv", protected), ("without_svl.csv", unprotected))
        fields = (:svl_voltage_v, :svl_current_a, :svl_energy_j, :bond_midpoint_voltage_v,
                  :lead_voltage_v, :joint_voltage_v)
        headers = vcat("time_s", ["$(field)_j$(j)_s$(p)" for field in fields
            for (j,p) in zip(result.port_junctions, result.port_phases)])
        values = hcat(result.time_s, (getproperty(result, f) for f in fields)...)
        open(joinpath(output_dir, filename), "w") do io
            println(io, join(headers, ','))
            for row in eachrow(values)
                println(io, join(row, ','))
            end
        end
    end
    open(joinpath(output_dir, "svl_summary.csv"), "w") do io
        println(io, "junction,phase,open_port_peak_v,svl_peak_v,svl_peak_a,svl_energy_j,open_joint_peak_v,protected_joint_peak_v")
        for p in eachindex(case.port_nodes)
            println(io, join((protected.port_junctions[p], protected.port_phases[p],
                maximum(abs, unprotected.svl_voltage_v[:,p]), maximum(abs, protected.svl_voltage_v[:,p]),
                maximum(abs, protected.svl_current_a[:,p]), protected.svl_energy_j[end,p],
                maximum(abs, unprotected.joint_voltage_v[:,p]), maximum(abs, protected.joint_voltage_v[:,p])), ','))
        end
    end

    p = argmax(protected.svl_energy_j[end,:])
    j, phase = protected.port_junctions[p], protected.port_phases[p]
    t = protected.time_s .* 1e6
    common = (; xlabel="Time [μs]", lw=1.5, xlims=(0, last(t)), legend=:topright,
                gridalpha=0.2, margin=5Plots.mm)
    vplot = plot(t, unprotected.svl_voltage_v[:,p] ./ 1e3; common...,
        label="SVL open", ylabel="Voltage [kV]", title="SVL element voltage")
    plot!(vplot, t, protected.svl_voltage_v[:,p] ./ 1e3; label="SVL connected", lw=1.5)
    jplot = plot(t, unprotected.joint_voltage_v[:,p] ./ 1e3; common...,
        label="SVLs open", ylabel="Voltage [kV]", title="Same-phase sectionalising joint stress")
    plot!(jplot, t, protected.joint_voltage_v[:,p] ./ 1e3; label="SVLs connected", lw=1.5)
    iplot = plot(t, protected.svl_current_a[:,p]; common..., label="SVL current",
        ylabel="Current [A]", title="Positive from bond midpoint toward local earth")
    eplot = plot(t, protected.svl_energy_j[:,p]; common..., label="SVL only",
        ylabel="Energy [J]", title="Absorbed energy over the displayed interval")
    panel = plot(vplot, jplot, iplot, eplot; layout=(2,2), size=(1400,900),
        plot_title="Illustrative NLT study | $(peak_v/1000) kV impulse | junction $j, incoming sheath $phase",
        plot_titlefontsize=12)
    savefig(panel, joinpath(output_dir, "svl_comparison.png"))
    savefig(panel, joinpath(output_dir, "svl_comparison.svg"))
    open(joinpath(output_dir, "run_info.txt"), "w") do io
        println(io, "ILLUSTRATIVE SVL EXTENSION OF GUDMUNDSDOTTIR ET AL. 2011; not a paper reproduction or SVL rating study.")
        println(io, "Julia: ", VERSION)
        println(io, "Source peak [V]: ", peak_v, "; original paper benchmark: 4080 V. Waveform: ideal 1.2/50 us.")
        println(io, "Cable geometry, frequency-dependent parameters and five 500 ohm core loads retained.")
        println(io, "Terminal sheaths remain exactly grounded. Intermediate original ground remains unchanged.")
        println(io, "Soil resistivity [ohm m], assumed: ", soil_resistivity)
        println(io, "SVL junctions: ", case.junctions, "; port order: junction, incoming phases 1,2,3.")
        println(io, "Each 2 uH cross bond is split into two 1 uH leads; SVL branch attaches to their midpoint.")
        println(io, "Each branch: series R [ohm] = ", lead_resistance_ohm, ", L [H] = ", lead_inductance_h, ", then SVL.")
        println(io, "Three SVLs share one local earth resistor per box [ohm]: ", earth_resistance_ohm)
        println(io, "Electrodes have no mutual ground impedance. All new topology and numerical values are assumptions.")
        for (p, characteristic) in enumerate(case.curves)
            println(io, "Port $p curve V [V]: ", characteristic.voltage_v, "; I [A]: ", characteristic.current_a)
        end
        println(io, "Curve: odd-symmetric, memoryless, piecewise linear, final segment extrapolated.")
        println(io, "No arrester capacitance, dynamic residual-voltage model, thermal state or energy limit is included.")
        println(io, "NLT dt [s]: ", protected.dt_s, "; output duration [s]: ", last(protected.time_s))
        println(io, "Transform period [s]: ", protected.transform_period_s, "; shift [1/s]: ", protected.laplace_shift_per_s)
        println(io, "Numerical wave reference resistance [ohm] (not a physical component): ", reference_resistance_ohm)
        println(io, "Newton iterations: ", protected.nonlinear_iterations,
            "; saved-window wave residual [V]: ", protected.nonlinear_residual_v,
            "; saved-window physical port KVL residual [V]: ", protected.port_kvl_residual_v)
        println(io, "Energy uses trapezoidal integral of SVL voltage times current over saved interval; excludes lead and earth losses.")
        println(io, "Joint voltage is left-minus-right sheath voltage on the same physical phase.")
        println(io, "The nonlinear relation is solved over the full damped FFT period. Refine dt and extend period to assess ringing/wraparound.")
        println(io, "Plot selects the largest-energy SVL: junction $j, incoming sheath $phase.")
    end
    println("Converged in ", protected.nonlinear_iterations, " Newton iterations; port KVL residual ", protected.port_kvl_residual_v, " V.")
    println("Largest SVL energy over ", last(t), " us: ", maximum(protected.svl_energy_j[end,:]), " J.")
    println("Saved comparison, CSV/NPZ waveforms and assumptions to ", output_dir)
    return (; protected, unprotected, case, output_dir)
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_gustavsen2011_svl(; output_dir=isempty(ARGS) ?
        joinpath(@__DIR__, "..", "output", "gustavsen2011_svl") : first(ARGS))
end
