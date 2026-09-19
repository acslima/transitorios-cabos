using FFTW: rfft

export SVLCurve, SVLCase, illustrative_svl, svl_current, build_svl_case,
       prepare_svl, simulate_svl

"""
    SVLCurve(voltage_v, current_a)

Memoryless, odd-symmetric piecewise-linear SVL characteristic. Supply at least
two nonnegative V-I points, starting at (0,0), with strictly increasing voltage
and nondecreasing current. The last segment is extrapolated; no clipping or
ideal voltage clamp is used. This model has no thermal or dynamic arrester state.
"""
struct SVLCurve
    voltage_v::Vector{Float64}
    current_a::Vector{Float64}
    function SVLCurve(voltage_v, current_a)
        v, i = Float64.(collect(voltage_v)), Float64.(collect(current_a))
        length(v) == length(i) >= 2 || throw(ArgumentError("Supply matching V-I arrays with at least two points."))
        all(isfinite, v) && all(isfinite, i) && v[1] == i[1] == 0 &&
            all(>(0), diff(v)) && all(>=(0), diff(i)) ||
            throw(ArgumentError("V-I points must be finite, start at (0,0), and have increasing V and nondecreasing I."))
        new(v, i)
    end
end

"""ILLUSTRATIVE only: not a manufacturer curve or data from the 2011 paper."""
illustrative_svl() = SVLCurve([0, 3000, 6000, 8000, 10000, 12000],
                              [0, 1e-6, 1, 100, 1000, 10000])

function svl_current(curve::SVLCurve, voltage::Real)
    isfinite(voltage) || throw(ArgumentError("SVL voltage must be finite."))
    v = abs(voltage)
    k = clamp(searchsortedlast(curve.voltage_v, v), 1, length(curve.voltage_v) - 1)
    slope = (curve.current_a[k+1] - curve.current_a[k]) /
            (curve.voltage_v[k+1] - curve.voltage_v[k])
    return sign(voltage) * (curve.current_a[k] + slope * (v - curve.voltage_v[k]))
end

struct SVLCase
    linear::ImpulseCase
    port_nodes::Vector{Int}
    junctions::Vector{Int}
    curves::Vector{SVLCurve}
    lead_resistance_ohm::Float64
    lead_inductance_h::Float64
    earth_resistance_ohm::Float64
end

"""
    build_svl_case(case=build_case(); curve=illustrative_svl(),
                   junctions=PAPER_DATA.cross_bond_after,
                   lead_resistance_ohm=0.1, lead_inductance_h=1e-6,
                   earth_resistance_ohm=1.0)

Add three SVLs at each selected cross-bonding junction. Each existing 2 μH
bond is split into its two 1 μH leads. Its midpoint feeds a series R-L and an
SVL to a common local earth bus; the three SVLs share one earth resistor per
box. Boxes have independent earth electrodes (no mutual ground impedance).
The port order is junction order, then incoming sheath phases 1,2,3. `curve`
may be one SVLCurve or a vector of one curve per port. Empty junctions disable
the extension. All new values and this protection arrangement are assumptions.
"""
function build_svl_case(case::ImpulseCase=build_case(); curve=illustrative_svl(),
    junctions=PAPER_DATA.cross_bond_after, lead_resistance_ohm::Real=0.1,
    lead_inductance_h::Real=1e-6, earth_resistance_ohm::Real=1.0)
    all(x -> isfinite(x) && x >= 0,
        (lead_resistance_ohm, lead_inductance_h, earth_resistance_ohm)) ||
        throw(ArgumentError("SVL lead R/L and earth resistance must be finite and nonnegative."))
    joints = Int.(collect(junctions))
    all(j -> j in PAPER_DATA.cross_bond_after, joints) && allunique(joints) ||
        throw(ArgumentError("Select distinct cross-bonding junctions from $(PAPER_DATA.cross_bond_after)."))
    curves = curve isa SVLCurve ? fill(curve, 3length(joints)) : collect(curve)
    length(curves) == 3length(joints) && all(c -> c isa SVLCurve, curves) ||
        throw(ArgumentError("Supply one SVLCurve or one curve per SVL port."))
    inductors, ports = copy(case.inductors), Int[]
    count = case.node_count
    for j in joints, phase in 1:3
        a = case.segment_nodes[j][6 + 2phase]
        b = case.segment_nodes[j+1][2PAPER_DATA.cross_bond_permutation[phase]]
        index = findfirst(link -> link[1:2] == (a, b), inductors)
        isnothing(index) && throw(ArgumentError("Missing cross-bond link at junction $j, phase $phase."))
        _, _, L = popat!(inductors, index)
        mid = (count += 1)
        push!(ports, mid)
        push!(inductors, (a, mid, L/2), (mid, b, L/2))
    end
    linear = ImpulseCase(case.system, copy(case.lengths_m), deepcopy(case.segment_nodes),
        inductors, case.ground_bus, count, case.source_node, copy(case.grounded_nodes),
        copy(case.load_nodes), vcat(case.free_nodes, collect(case.node_count+1:count)), case.peak_v)
    return SVLCase(linear, ports, joints, SVLCurve[curves...], Float64(lead_resistance_ohm),
                   Float64(lead_inductance_h), Float64(earth_resistance_ohm))
end

function svl_grid(; dt, duration, period, damping)
    all(x -> isfinite(x) && x > 0, (dt, duration, damping)) && damping <= 30 ||
        throw(ArgumentError("dt and duration must be positive; damping must lie in (0,30]."))
    requested = isnothing(period) ? 2duration : period
    isfinite(requested) && requested >= 2duration ||
        throw(ArgumentError("Transform period must be at least twice the output duration."))
    n = nextpow(2, max(16, ceil(Int, requested / dt)))
    T, shift = n * dt, damping / (n * dt)
    time = collect(0:n-1) .* dt
    saved = floor(Int, duration / dt + 1e-9) + 1
    return (; n, T, shift, time, saved, dt=Float64(dt), weight=exp.(-shift .* time))
end

# Operate on exponentially damped waveforms. Transform factors dt and 1/dt
# cancel for transfer operators, but are retained for physical source spectra.
function spectral_apply(operator, waveform)
    spectrum = rfft(waveform, 1)
    result = zeros(ComplexF64, size(spectrum, 1), size(operator, 1))
    for k in axes(spectrum, 1)
        @views mul!(result[k, :], operator[:, :, k], spectrum[k, :])
    end
    return irfft(result, size(waveform, 1), 1)
end

function observation_matrix(case::SVLCase, segment_yn)
    c, m = case.linear, length(case.port_nodes)
    # 24 terminal quantities, m bond-midpoint voltages, m same-phase joint stresses.
    O = zeros(ComplexF64, 24 + 2m, c.node_count)
    first_nodes, last_nodes = first(c.segment_nodes), last(c.segment_nodes)
    for (row, node) in enumerate(vcat(first_nodes[1:6], last_nodes[7:12]))
        O[row, node] = 1
    end
    O[13:18, first_nodes] = segment_yn[first(c.lengths_m)][1:6, :]
    O[19:24, last_nodes] = segment_yn[last(c.lengths_m)][7:12, :]
    for (p, node) in enumerate(case.port_nodes)
        O[24+p, node] = 1
    end
    for (box, j) in enumerate(case.junctions), phase in 1:3
        row = 24 + m + 3(box-1) + phase
        O[row, c.segment_nodes[j][6+2phase]] = 1
        O[row, c.segment_nodes[j+1][2phase]] = -1
    end
    return O
end

"""
    prepare_svl(case=build_svl_case(); dt=0.1e-6, duration=200e-6,
                period=nothing, damping=10.0, earth_rtol=1e-8,
                reference_resistance_ohm=10.0)

Reduce the distributed cable to coupled SVL ports on s = damping/T + j2πk/T.
Cache source and current-injection transfers for repeated protected/unprotected
solutions on this grid. The reference resistance is a numerical wave-variable
scale, not a resistor added to the circuit. Preparation snapshots the case.
"""
function prepare_svl(case::SVLCase=build_svl_case(); dt::Real=0.1e-6,
    duration::Real=200e-6, period::Union{Nothing,Real}=nothing, damping::Real=10.0,
    earth_rtol::Real=1e-8, reference_resistance_ohm::Real=10.0)
    isfinite(reference_resistance_ohm) && reference_resistance_ohm > 0 ||
        throw(ArgumentError("The numerical reference resistance must be positive."))
    case = deepcopy(case)
    grid = svl_grid(; dt, duration, period, damping)
    c, m, R = case.linear, length(case.port_nodes), Float64(reference_resistance_ohm)
    nf = grid.n ÷ 2 + 1
    source = zeros(ComplexF64, nf, 24 + 2m)
    response = zeros(ComplexF64, 24 + 2m, m, nf)
    scattering = zeros(ComplexF64, m, m, nf)
    incident_source = zeros(ComplexF64, nf, m)
    B = zeros(c.node_count, m)
    for (p, node) in enumerate(case.port_nodes)
        B[node, p] = 1
    end
    free = c.free_nodes
    for k in 1:nf
        s = complex(grid.shift, 2pi * (k-1) / grid.T)
        Z, Y = zy_cabo(c.system, [s]; earth_rtol)
        A, segment_yn = network_admittance(c, s, Z[:, :, 1], Y[:, :, 1])
        solved = A[free, free] \ hcat(-A[free, c.source_node], B[free, :])
        v = zeros(ComplexF64, c.node_count, m+1)
        v[c.source_node, 1] = 1
        v[free, :] = solved
        O = observation_matrix(case, segment_yn)
        source[k, :] = (O * v[:, 1]) .* impulse_transform(s; peak_v=c.peak_v)
        response[:, :, k] = O * v[:, 2:end]
        m == 0 && continue
        Zport = transpose(B) * v[:, 2:end]
        for p in 1:m
            Zport[p, p] += case.lead_resistance_ohm + s * case.lead_inductance_h
        end
        for box in eachindex(case.junctions)
            ports = 3box-2:3box
            Zport[ports, ports] .+= case.earth_resistance_ohm
        end
        u0 = copy(source[k, 25:24+m])
        # Project the finite-bandwidth endpoints BEFORE the port conversion,
        # so all terminal reconstruction and nonlinear equations share the same
        # real DC/Nyquist convention. Projection and matrix inversion do not commute.
        if k == 1 || k == nf
            Zport .= real.(Zport)
            u0 .= real.(u0)
        end
        factor = lu(Zport + R * I)
        scattering[:, :, k] = Matrix{ComplexF64}(I, m, m) - 2R * (factor \ Matrix{ComplexF64}(I, m, m))
        incident_source[k, :] = 2R .* (factor \ u0)
    end
    source[[1, nf], :] .= real.(source[[1, nf], :])
    response[:, :, [1, nf]] .= real.(response[:, :, [1, nf]])
    return (; case, grid, source, response, scattering, R,
              incident_source=irfft(incident_source, grid.n, 1) ./ grid.dt)
end

# The load relation a = u + R*f(u) is monotone on every PWL segment.
# Invert it exactly at each sample; b = u - R*f(u), db/da = (1-R*g)/(1+R*g).
function reflected_wave(a, curves, R, weight)
    b, derivative = similar(a), similar(a)
    for p in axes(a, 2)
        curve = curves[p]
        knots = curve.voltage_v + R .* curve.current_a
        for t in axes(a, 1)
            incoming = a[t, p] / weight[t]
            k = clamp(searchsortedlast(knots, abs(incoming)), 1, length(knots)-1)
            g = (curve.current_a[k+1] - curve.current_a[k]) /
                (curve.voltage_v[k+1] - curve.voltage_v[k])
            u = curve.voltage_v[k] + (abs(incoming) - knots[k]) / (1 + R*g)
            b[t, p] = 2sign(incoming) * u * weight[t] - a[t, p]
            derivative[t, p] = (1 - R*g) / (1 + R*g)
        end
    end
    return b, derivative
end

# Restarted matrix-free GMRES for the Newton corrections. No dense Jacobian
# over all time samples is assembled. Reorthogonalization limits loss of basis
# orthogonality; convergence is checked using the actual residual at restart.
function svl_gmres(apply, rhs; rtol=1e-5, restart=40, maxiter=400)
    shape = size(rhs)
    b = vec(rhs)
    x = zeros(length(b))
    target = rtol * norm(b)
    residual = copy(b)
    count = 0
    norm(residual) == 0 && return reshape(x, shape)
    width = min(restart, length(b))
    while count < maxiter
        beta = norm(residual)
        beta <= target && return reshape(x, shape)
        Q = zeros(length(b), width+1)
        H = zeros(width+1, width)
        Q[:, 1] = residual ./ beta
        used = 0
        for j in 1:min(width, maxiter-count)
            w = vec(apply(reshape(@view(Q[:, j]), shape)))
            for _ in 1:2, i in 1:j
                h = dot(@view(Q[:, i]), w)
                H[i, j] += h
                @views w .-= h .* Q[:, i]
            end
            H[j+1, j] = norm(w)
            count += 1
            used = j
            projected_rhs = vcat(beta, zeros(j))
            @views coefficients = H[1:j+1, 1:j] \ projected_rhs
            projected_error = norm(H[1:j+1, 1:j] * coefficients - projected_rhs)
            if projected_error <= target || H[j+1, j] <= eps(Float64)
                break
            end
            Q[:, j+1] = w ./ H[j+1, j]
        end
        @views x .+= Q[:, 1:used] * (H[1:used+1, 1:used] \ vcat(beta, zeros(used)))
        residual = b - vec(apply(reshape(x, shape)))
    end
    norm(residual) <= target || error("SVL Newton linear solve did not converge in $maxiter GMRES iterations.")
    return reshape(x, shape)
end

function solve_svl_waves(prepared; enabled=true, rtol=1e-8, atol_v=1e-4,
                         maxiter=80, gmres_maxiter=400, verbose::Bool=false)
    all(x -> isfinite(x) && x > 0, (rtol, atol_v)) && rtol < 1 ||
        throw(ArgumentError("Use positive tolerances and rtol < 1."))
    maxiter >= 1 && gmres_maxiter >= 1 || throw(ArgumentError("Iteration limits must be positive."))
    (; case, grid, scattering, incident_source, R) = prepared
    m = length(case.port_nodes)
    u0 = irfft(prepared.source[:, 25:24+m], grid.n, 1) ./ grid.dt
    if !enabled || m == 0
        return (; voltage=u0 ./ grid.weight, current=zeros(grid.n, m), iterations=0,
                  residual_v=0.0, damped_residual_v=0.0)
    end
    a = copy(u0)
    b, q = reflected_wave(a, case.curves, R, grid.weight)
    residual = a - incident_source - spectral_apply(scattering, b)
    tolerance = atol_v + rtol * maximum(abs, u0[1:grid.saved, :] ./ grid.weight[1:grid.saved])
    damped_tolerance = atol_v + rtol * maximum(abs, u0)
    for iteration in 0:maxiter
        physical_residual = maximum(abs, residual[1:grid.saved, :] ./ grid.weight[1:grid.saved])
        damped_residual = maximum(abs, residual)
        verbose && println("SVL Newton $iteration: wave residual = $physical_residual V, damped full-period residual = $damped_residual V")
        if physical_residual <= tolerance && damped_residual <= damped_tolerance
            return (; voltage=(a+b) ./ (2 .* grid.weight),
                      current=(a-b) ./ (2R .* grid.weight), iterations=iteration,
                      residual_v=physical_residual, damped_residual_v=damped_residual)
        end
        iteration == maxiter && break
        apply(delta) = delta - spectral_apply(scattering, q .* delta)
        step = svl_gmres(apply, -residual; maxiter=gmres_maxiter)
        old_norm = norm(residual)
        accepted = false
        for backtrack in 0:16
            trial = a + (0.5^backtrack) .* step
            trial_b, trial_q = reflected_wave(trial, case.curves, R, grid.weight)
            trial_residual = trial - incident_source - spectral_apply(scattering, trial_b)
            if all(isfinite, trial_residual) && norm(trial_residual) < old_norm
                a, b, q, residual = trial, trial_b, trial_q, trial_residual
                accepted = true
                break
            end
        end
        accepted || error("SVL Newton line search failed; refine the grid or change the numerical reference resistance.")
    end
    error("SVL nonlinear NLT solve did not converge in $maxiter iterations; no unconverged waveforms returned.")
end

"""
    simulate_svl(prepared; enabled=true, rtol=1e-8, atol_v=1e-4,
                 maxiter=80, gmres_maxiter=400, verbose=false)
    simulate_svl(case::SVLCase=build_svl_case(); dt=0.1e-6, duration=200e-6, ...)

Couple the linear NLT network to instantaneous nonlinear SVLs with a damped
Newton/GMRES waveform solve. `enabled=false` opens every SVL for an otherwise
identical comparison. Energy is integral(u_SVL*i_SVL dt), excluding the leads
and earth resistors, over the saved interval only. Both end currents point INTO
the cable. Joint stress is left minus right sheath voltage of the SAME physical
phase, not voltage across the cross-bond connection or the SVL alone.
"""
function simulate_svl(prepared::NamedTuple; enabled::Bool=true, kwargs...)
    solved = solve_svl_waves(prepared; enabled, kwargs...)
    (; case, grid) = prepared
    m = length(case.port_nodes)
    spectrum = copy(prepared.source)
    currents = grid.dt .* rfft(solved.current .* grid.weight, 1)
    for k in axes(spectrum, 1)
        @views spectrum[k, :] .-= prepared.response[:, :, k] * currents[k, :]
    end
    keep = 1:grid.saved
    values = irfft(spectrum, grid.n, 1)[keep, :] ./ (grid.dt .* grid.weight[keep])
    all(isfinite, values) || error("Nonfinite SVL transient output.")
    voltage, current = solved.voltage[keep, :], solved.current[keep, :]
    power = voltage .* current
    energy = zeros(size(power))
    energy[2:end, :] = cumsum((power[1:end-1, :] + power[2:end, :]) .* (grid.dt/2); dims=1)
    earth = zeros(grid.saved, length(case.junctions))
    for box in eachindex(case.junctions)
        earth[:, box] = vec(sum(current[:, 3box-2:3box]; dims=2)) .* case.earth_resistance_ohm
    end
    lead_spectrum = copy(currents)
    for k in axes(lead_spectrum, 1)
        s = complex(grid.shift, 2pi * (k-1) / grid.T)
        lead_spectrum[k, :] .*= case.lead_resistance_ohm + s * case.lead_inductance_h
    end
    lead = irfft(lead_spectrum, grid.n, 1)[keep, :] ./ (grid.dt .* grid.weight[keep])
    port_residual = values[:, 25:24+m] - repeat(earth; inner=(1,3)) - lead - voltage
    return (; time_s=grid.time[keep], sending_voltage_v=values[:, 1:6],
        receiving_voltage_v=values[:, 7:12], sending_current_a=values[:, 13:18],
        receiving_current_a=values[:, 19:24],
        receiving_load_current_a=values[:, [7,9,11]] ./ PAPER_DATA.terminal_load_ohm,
        prescribed_source_v=impulse_voltage.(grid.time[keep]; peak_v=case.linear.peak_v),
        bond_midpoint_voltage_v=values[:, 25:24+m],
        joint_voltage_v=values[:, 25+m:24+2m], svl_voltage_v=voltage,
        svl_current_a=current, svl_power_w=power, svl_energy_j=energy,
        lead_voltage_v=lead, local_earth_voltage_v=earth, svl_enabled=enabled,
        port_kvl_residual_v=isempty(port_residual) ? 0.0 : maximum(abs, port_residual),
        port_junctions=repeat(case.junctions; inner=3),
        port_phases=repeat(collect(1:3), length(case.junctions)),
        nonlinear_iterations=solved.iterations, nonlinear_residual_v=solved.residual_v,
        damped_nonlinear_residual_v=solved.damped_residual_v,
        dt_s=grid.dt, transform_period_s=grid.T, laplace_shift_per_s=grid.shift,
        peak_v=case.linear.peak_v, soil_resistivity_ohm_m=case.linear.system.soil_resistivity)
end

function simulate_svl(case::SVLCase=build_svl_case(); dt=0.1e-6, duration=200e-6,
    period=nothing, damping=10.0, earth_rtol=1e-8, reference_resistance_ohm=10.0,
    kwargs...)
    prepared = prepare_svl(case; dt, duration, period, damping, earth_rtol, reference_resistance_ohm)
    return simulate_svl(prepared; kwargs...)
end
