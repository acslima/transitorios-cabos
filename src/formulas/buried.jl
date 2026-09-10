using QuadGK: quadgk

"""
    earth_return_impedance(s, radius, h1, h2, separation, soil_resistivity;
                           self=false, rtol=1e-8)

Pollaczek earth-return impedance [Ω/m], with μsoil = μ₀ and no displacement
current. `s` is nonzero in the closed right half-plane, depths are positive,
and `separation` is horizontal distance [m]. For self impedance use the cable's
outer insulation radius; the jacket's internal magnetic impedance is added by
`comp_coaxial_cable_impedance`.

Reference: Uribe et al., *Calculating Earth Impedances for Underground
Transmission Cables*, IPST 2001, equations (1a-b):
https://www.ipstconf.org/papers/Proc_IPST2001/01IPST003.pdf

The integration variable is scaled by h1+h2. Breakpoints resolve both the
skin-depth transition and cosine oscillations; exponential decay bounds the
discarded tail. An unconverged quadrature raises an error.
"""
function earth_return_impedance(
    s::Complex, radius::Real, h1::Real, h2::Real, separation::Real,
    soil_resistivity::Real; self::Bool = false, rtol::Real = 1e-8,
)
    isfinite(s) && !iszero(s) && real(s) >= 0 ||
        throw(ArgumentError("Use a nonzero frequency in the closed right half-plane."))
    all(x -> isfinite(x) && x > 0, (radius, h1, h2, soil_resistivity, rtol)) ||
        throw(ArgumentError("Radii, depths, resistivity and tolerance must be positive."))
    rtol < 1 || throw(ArgumentError("rtol must be less than one."))
    isfinite(separation) || throw(ArgumentError("Separation must be finite."))
    m = sqrt(s * μ₀ / soil_resistivity)
    hsum = h1 + h2
    x = self ? radius : abs(separation)
    d = self ? radius : hypot(x, h1 - h2)
    d > 0 || throw(ArgumentError("Distinct cables cannot have coincident axes."))
    D = self ? hsum : hypot(x, hsum)
    a = m * hsum
    ratio = x / hsum
    umax = max(32.0, -log(rtol * 1e-3))
    integrand(u) = begin
        q = sqrt(u^2 + a^2)
        2 * exp(-q) * cos(ratio * u) / (u + q)
    end
    # Both the near-zero transition and the oscillation period must be resolved.
    step = min(2.0, pi / max(ratio, 1.0))
    points = sort!(unique!(vcat(0.0, min(abs(a), umax),
                               collect(step:step:umax), umax)))
    correction, err = quadgk(integrand, points...; rtol, atol=rtol * 1e-3)
    err <= max(rtol * abs(correction), rtol * 1e-3) ||
        error("Pollaczek quadrature did not converge (error estimate $err).")
    return s * μ₀ / (2pi) * (besselk(0, m * d) - besselk(0, m * D) + correction)
end

"""
    zy_cabo(system::BuriedCableSystem, complex_frequencies; earth_rtol=1e-8)

Series Z [Ω/m] and shunt Y [S/m] for buried single-core cables. Includes
frequency-dependent conductor/sheath skin effect and Pollaczek self/mutual
earth return. Shunt capacitance assumes an equipotential soil outside each
outer jacket. Proximity effects, dielectric losses and soil displacement
current are omitted. No fictitious surrounding pipe or seawater is introduced.
"""
function zy_cabo(
    system::BuriedCableSystem,
    complex_frequencies::AbstractVector{<:Complex};
    earth_rtol::Real = 1e-8,
)
    all(s -> isfinite(s) && !iszero(s) && real(s) >= 0, complex_frequencies) ||
        throw(ArgumentError("Use nonzero frequencies in the closed right half-plane."))
    nc = count_conductors_cable(system)
    nf = length(complex_frequencies)
    Z = zeros(ComplexF64, nc, nc, nf)
    Y = similar(Z)
    P = zeros(ComplexF64, nc, nc)
    groups = UnitRange{Int}[]
    next = 1
    for cable in system.cables
        indices = next:(next + count_conductors_cable(cable) - 1)
        push!(groups, indices)
        P[indices, indices] = comp_coaxial_cable_elastance(cable)
        for (index, component) in zip(indices, cable.components)
            component._index = index
        end
        next = last(indices) + 1
    end
    C = inv(P)
    for (k, s) in enumerate(complex_frequencies)
        Y[:, :, k] = s * C
        for (i, cable) in enumerate(system.cables)
            ii = groups[i]
            Z[ii, ii, k] = comp_coaxial_cable_impedance(cable, s)
            for j in 1:i
                other = system.cables[j]
                jj = groups[j]
                zg = earth_return_impedance(
                    s, outer_radius(cable), cable.y, other.y, cable.x - other.x,
                    system.soil_resistivity; self=(i == j), rtol=earth_rtol,
                )
                Z[ii, jj, k] .+= zg
                i == j || (Z[jj, ii, k] .+= zg)
            end
        end
    end
    return Z, Y
end
