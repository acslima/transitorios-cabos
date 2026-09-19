module Gustavsen2011

using TransitoriosCabos
using LinearAlgebra
using FFTW: irfft

include("data.jl")

export PAPER_DATA, GEOMETRY_COMPARISON, build_case, simulate, impulse_voltage,
       solve_frequency, cable_system, coaxial_estimates

# Calibrated double exponential: (t90-t30)/0.6 = 1.2 μs and
# t50,fall - [t30 - 0.5(t90-t30)] = 50 μs, relative to the virtual origin.
const IMPULSE_ALPHA = 14659.108681119082
const IMPULSE_BETA = 2468926.6530552628
const IMPULSE_PEAK_TIME = log(IMPULSE_BETA / IMPULSE_ALPHA) /
                          (IMPULSE_BETA - IMPULSE_ALPHA)
const IMPULSE_NORMALIZER = exp(-IMPULSE_ALPHA * IMPULSE_PEAK_TIME) -
                           exp(-IMPULSE_BETA * IMPULSE_PEAK_TIME)

"""Ideal prescribed 1.2/50 μs lightning impulse [V]; no measured reflections."""
function impulse_voltage(t::Real; peak_v::Real=PAPER_DATA.impulse_peak_v)
    t < 0 && return 0.0
    return peak_v / IMPULSE_NORMALIZER *
           exp(-IMPULSE_ALPHA * t) * (-expm1(-(IMPULSE_BETA - IMPULSE_ALPHA) * t))
end

impulse_transform(s; peak_v=PAPER_DATA.impulse_peak_v) =
    peak_v / IMPULSE_NORMALIZER * (IMPULSE_BETA - IMPULSE_ALPHA) /
    ((s + IMPULSE_ALPHA) * (s + IMPULSE_BETA))

"""Three single-core cables (six conductors), using Table I without retuning."""
function cable_system(; soil_resistivity::Real=100.0)
    p = PAPER_DATA
    r1 = p.core_radius_m
    r2 = r1 + p.inner_semiconductor_thickness_m + p.xlpe_thickness_m +
         p.outer_semiconductor_thickness_m
    r3 = r2 + p.screen_thickness_m
    r4 = r3 + p.jacket_thickness_m
    core = CableComponent(0.0, r1, r2, p.core_resistivity_ohm_m,
                          1.0, p.main_insulation_mur, p.main_insulation_epsr, "Core")
    sheath = CableComponent(r2, r3, r4, p.screen_resistivity_ohm_m,
                            1.0, 1.0, p.jacket_epsr, "Sheath")
    phases = [CoaxialCable([core, sheath], (phase - 1) * p.phase_spacing_m,
                          p.burial_depth_m, "Phase $phase", sum(p.segment_lengths_m))
              for phase in 1:3]
    return BuriedCableSystem(phases; soil_resistivity,
                              name="Gudmundsdottir et al. 2011, Figure 5")
end

"""Lossless high-frequency coaxial estimates derived from Table I, in SI units."""
function coaxial_estimates()
    c = cable_system().cables[1].components[1]
    mu0, eps0 = 4pi * 1e-7, 8.854187817e-12
    L = mu0 * c.mur_d / (2pi) * log(c.radius_ext_insulator / c.radius_ext)
    C = 2pi * eps0 * c.epsr / log(c.radius_ext_insulator / c.radius_ext)
    velocity = inv(sqrt(L * C))
    return (; inductance_h_per_m=L, capacitance_f_per_m=C,
              surge_impedance_ohm=sqrt(L / C), velocity_m_per_s=velocity,
              one_way_time_s=sum(PAPER_DATA.segment_lengths_m) / velocity,
              first_cross_bond_return_s=2sum(PAPER_DATA.segment_lengths_m[1:2]) / velocity)
end

struct ImpulseCase
    system::BuriedCableSystem
    lengths_m::Vector{Float64}
    segment_nodes::Vector{Vector{Int}} # [sending C1,S1,C2,S2,C3,S3; receiving ...]
    inductors::Vector{Tuple{Int,Int,Float64}}
    ground_bus::Int
    node_count::Int
    source_node::Int
    grounded_nodes::Vector{Int}
    load_nodes::Vector{Int}
    free_nodes::Vector{Int}
    peak_v::Float64
end

"""
    build_case(; soil_resistivity=100.0, peak_v=4080.0)

Figure 5 terminations and Figures 3/11/12 internal sheath network. The soil
resistivity is an explicit assumption, absent from the paper. The energized
outer phase is phase 1. Its sending voltage is prescribed; sending phases 2/3
and receiving phases 1/2/3 each have their own 500 Ω shunt to ground. All six
terminal sheaths are ideal grounds. The intermediate earth uses the 1 mΩ
resistance and six 10 μH leads drawn in Fig. 12.
"""
function build_case(; soil_resistivity::Real=100.0, peak_v::Real=PAPER_DATA.impulse_peak_v)
    isfinite(peak_v) && peak_v > 0 || throw(ArgumentError("Impulse peak must be positive."))
    system = cable_system(; soil_resistivity)
    p = PAPER_DATA
    nodes = Vector{Int}[]
    inductors = Tuple{Int,Int,Float64}[]
    count = 6
    left = collect(1:6)
    ground_bus = 0
    for segment in eachindex(p.segment_lengths_m)
        if segment > 1
            previous = nodes[end][7:12]
            left = copy(previous)
            junction = segment - 1
            if junction in p.cross_bond_after || junction == p.ground_after
                for phase in 1:3
                    left[2phase] = (count += 1)
                end
                if junction in p.cross_bond_after
                    for phase in 1:3
                        target = p.cross_bond_permutation[phase]
                        push!(inductors, (previous[2phase], left[2target],
                                         2p.cross_bond_lead_inductance_h))
                    end
                else
                    ground_bus = (count += 1)
                    for node in vcat(previous[2:2:6], left[2:2:6])
                        push!(inductors, (node, ground_bus, p.ground_lead_inductance_h))
                    end
                end
            end
        end
        right = collect(count+1:count+6)
        count += 6
        push!(nodes, vcat(left, right))
    end
    send, receive = first(nodes)[1:6], last(nodes)[7:12]
    grounded = vcat(send[2:2:6], receive[2:2:6])
    loads = vcat(send[[3, 5]], receive[1:2:5])
    source = send[1]
    free = setdiff(1:count, vcat(grounded, source))
    return ImpulseCase(system, collect(p.segment_lengths_m), nodes, inductors,
                       ground_bus, count, source, grounded, loads, free, Float64(peak_v))
end

function network_admittance(case::ImpulseCase, s::Complex, Z::Matrix, Y::Matrix)
    A = zeros(ComplexF64, case.node_count, case.node_count)
    # Repeated segment lengths share a nodal matrix at each frequency.
    segment_yn = Dict(len => ynodal(Z, Y, len) for len in unique(case.lengths_m))
    for (nodes, len) in zip(case.segment_nodes, case.lengths_m)
        A[nodes, nodes] .+= segment_yn[len]
    end
    for (a, b, L) in case.inductors
        admittance = inv(s * L)
        A[a, a] += admittance
        A[b, b] += admittance
        A[a, b] -= admittance
        A[b, a] -= admittance
    end
    A[case.ground_bus, case.ground_bus] += inv(PAPER_DATA.middle_ground_resistance_ohm)
    for node in case.load_nodes
        A[node, node] += inv(PAPER_DATA.terminal_load_ohm)
    end
    return A, segment_yn
end

"""Unit-source frequency solution. Both end currents are positive INTO the cable."""
function solve_frequency(case::ImpulseCase, s::Complex; earth_rtol::Real=1e-8)
    Zs, Ys = zy_cabo(case.system, [s]; earth_rtol)
    A, segment_yn = network_admittance(case, s, Zs[:, :, 1], Ys[:, :, 1])
    v = zeros(ComplexF64, case.node_count)
    v[case.source_node] = 1
    free = case.free_nodes
    v[free] = -(A[free, free] \ A[free, case.source_node])
    first_nodes, last_nodes = first(case.segment_nodes), last(case.segment_nodes)
    i_send = (segment_yn[first(case.lengths_m)] * v[first_nodes])[1:6]
    i_receive = (segment_yn[last(case.lengths_m)] * v[last_nodes])[7:12]
    residual = A * v
    return (; voltage=v, sending_voltage=v[first_nodes[1:6]],
              receiving_voltage=v[last_nodes[7:12]], sending_current=i_send,
              receiving_current=i_receive,
              free_kcl_residual=norm(residual[free], Inf))
end

"""
    simulate(case=build_case(); dt=0.05e-6, duration=900e-6, period=nothing,
             damping=10.0, earth_rtol=1e-8)

Invert frequency-domain solutions on s = damping/T + j2πk/T, using the analytic
Laplace transform of the prescribed impulse and a real inverse FFT. `T` is at
least twice `duration`; its sample count is rounded up to a power of two.
This padding and exponential damping suppress periodic wraparound. A finite
bandwidth can produce small ringing before arrivals; no samples are clipped.

Output includes six conductor voltages/currents at each end. Core columns are
1,3,5; sheath columns are 2,4,6. Receiving load currents are separately returned
positive OUT of the cable, so Iload = Vreceive/500. Increase bandwidth (halve dt)
and extend T to check numerical convergence. This does not use measured traces
or a fitted PSCAD model and is not a validation against the field measurements.
"""
function simulate(
    case::ImpulseCase=build_case(); dt::Real=0.05e-6, duration::Real=900e-6,
    period::Union{Nothing,Real}=nothing, damping::Real=10.0, earth_rtol::Real=1e-8,
)
    all(x -> isfinite(x) && x > 0, (dt, duration, damping)) ||
        throw(ArgumentError("dt, duration and damping must be finite and positive."))
    requested_period = isnothing(period) ? 2duration : period
    isfinite(requested_period) && requested_period >= 2duration ||
        throw(ArgumentError("Transform period must be at least twice the output duration."))
    n = nextpow(2, max(16, ceil(Int, requested_period / dt)))
    T = n * dt
    shift = damping / T
    spectrum = zeros(ComplexF64, n ÷ 2 + 1, 24)
    for k in 0:n÷2
        s = complex(shift, 2pi * k / T)
        solution = solve_frequency(case, s; earth_rtol)
        input = impulse_transform(s; peak_v=case.peak_v)
        spectrum[k+1, :] = input .* vcat(solution.sending_voltage,
            solution.receiving_voltage, solution.sending_current, solution.receiving_current)
    end
    # A real sampled signal has real DC/Nyquist bins; irfft otherwise ignores
    # their imaginary parts implicitly. Make this finite-bandwidth choice explicit.
    spectrum[1, :] = real.(spectrum[1, :])
    spectrum[end, :] = real.(spectrum[end, :])
    nsaved = min(n, floor(Int, duration / dt + 1e-9) + 1)
    time = collect(0:nsaved-1) .* dt
    values = irfft(spectrum, n, 1)[1:nsaved, :] .* (exp.(shift .* time) ./ dt)
    all(isfinite, values) || error("Nonfinite transient result; check parameters and sampling.")
    return (; time_s=time,
              sending_voltage_v=values[:, 1:6], receiving_voltage_v=values[:, 7:12],
              sending_current_a=values[:, 13:18], receiving_current_a=values[:, 19:24],
              receiving_load_current_a=values[:, [7, 9, 11]] ./ PAPER_DATA.terminal_load_ohm,
              prescribed_source_v=impulse_voltage.(time; peak_v=case.peak_v),
              dt_s=Float64(dt), transform_period_s=T, laplace_shift_per_s=shift,
              soil_resistivity_ohm_m=case.system.soil_resistivity, peak_v=case.peak_v)
end

include("svl.jl")

end # module Gustavsen2011
