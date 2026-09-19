using FFTW: rfft, irfft

@testset "SVLs coupled through NLT" begin
    @testset "V-I data, polarity and passive dissipation" begin
        curve = SVLCurve([0, 1000, 2000], [0, 1, 101])
        @test svl_current(curve, 1500) ≈ 51
        @test svl_current(curve, 2500) ≈ 151 # last-segment extrapolation
        for v in [-3000, -1500, -1, 0, 1, 1500, 3000]
            @test svl_current(curve, -v) == -svl_current(curve, v)
            @test v * svl_current(curve, v) >= 0
        end
        for (v, i) in [([0], [0]), ([0, 1], [0]), ([1, 2], [0, 1]),
                       ([0, 0], [0, 1]), ([0, 1, 2], [0, 1, 0]),
                       ([0, Inf], [0, 1]), ([0, 1], [0, NaN])]
            @test_throws ArgumentError SVLCurve(v, i)
        end
        @test_throws ArgumentError svl_current(curve, NaN)
    end

    @testset "Nonlinear resistive circuit with exact algebraic solution" begin
        grid = Gustavsen2011.svl_grid(dt=0.01, duration=1.0, period=nothing, damping=10.0)
        curve = SVLCurve([0, 1, 2], [0, 0, 10]) # dead band, then 10 S
        source = 5sin.(2pi .* grid.time) .* exp.(-grid.time)
        Rth = 2.0
        exact = sign.(source) .* ifelse.(abs.(source) .<= 1, abs.(source),
                                      (abs.(source) .+ 20) ./ 21)
        for R in [0.5, 10.0]
            S = (Rth - R) / (Rth + R)
            source_spectrum = zeros(ComplexF64, grid.n ÷ 2 + 1, 26)
            source_spectrum[:, 25] = grid.dt .* rfft(source .* grid.weight)
            prepared = (; case=(; port_nodes=[1], curves=[curve]), grid, R,
                source=source_spectrum, scattering=fill(complex(S), 1, 1, grid.n ÷ 2 + 1),
                incident_source=reshape((1-S) .* source .* grid.weight, :, 1))
            solved = Gustavsen2011.solve_svl_waves(prepared; atol_v=1e-9, rtol=1e-10)
            @test vec(solved.voltage) ≈ exact atol=1e-8
            @test vec(solved.current) ≈ (source - exact) ./ Rth atol=1e-8
            @test all(solved.voltage .* solved.current .>= -1e-12)
        end
    end

    base = build_case(peak_v=100e3)
    svl = build_svl_case(base)
    @test svl.port_nodes == collect(base.node_count+1:base.node_count+12)
    @test length(svl.linear.inductors) == length(base.inductors) + 12
    @test count(link -> link[3] == 1e-6, svl.linear.inductors) == 24
    @test count(link -> link[3] == 10e-6, svl.linear.inductors) == 6
    @test svl.linear.grounded_nodes == base.grounded_nodes
    @test svl.linear.load_nodes == base.load_nodes
    for (box, j) in enumerate(svl.junctions), phase in 1:3
        mid = svl.port_nodes[3(box-1)+phase]
        a = base.segment_nodes[j][6+2phase]
        b = base.segment_nodes[j+1][2PAPER_DATA.cross_bond_permutation[phase]]
        @test (a, mid, 1e-6) in svl.linear.inductors
        @test (mid, b, 1e-6) in svl.linear.inductors
    end
    @test_throws ArgumentError build_svl_case(base; junctions=[1])
    @test_throws ArgumentError build_svl_case(base; junctions=[2,2])
    @test_throws ArgumentError build_svl_case(base; curve=[illustrative_svl()])
    @test_throws ArgumentError build_svl_case(base; lead_inductance_h=-1)
    @test_throws ArgumentError prepare_svl(svl; period=1e-6)
    @test_throws ArgumentError prepare_svl(svl; reference_resistance_ohm=0)
    @test_throws ArgumentError prepare_svl(svl; damping=1000)

    @testset "Open ports reproduce original benchmark" begin
        original = simulate(base; dt=0.2e-6, duration=100e-6)
        prepared = prepare_svl(svl; dt=0.2e-6, duration=100e-6)
        opened = simulate_svl(prepared; enabled=false)
        @test opened.sending_current_a ≈ original.sending_current_a rtol=1e-8 atol=1e-7
        @test opened.receiving_voltage_v ≈ original.receiving_voltage_v rtol=1e-8 atol=1e-6
        @test all(iszero, opened.svl_current_a)
        @test all(iszero, opened.svl_energy_j)
        @test opened.port_kvl_residual_v < 1e-8
        empty_case = simulate_svl(build_svl_case(base; junctions=[]); dt=0.2e-6, duration=100e-6)
        @test size(empty_case.svl_current_a) == (length(original.time_s), 0)
        @test empty_case.sending_current_a ≈ original.sending_current_a
        low_cache = prepare_svl(build_svl_case(build_case()); dt=0.2e-6, duration=100e-6)
        low = simulate_svl(low_cache)
        low_open = simulate_svl(low_cache; enabled=false)
        @test maximum(abs, low.svl_current_a) < 1e-5
        @test maximum(abs, low.sending_current_a - low_open.sending_current_a) < 1e-5
    end

    @testset "Linear SVLs match independently stamped frequency circuit" begin
        g = 0.02
        linear = build_svl_case(base; junctions=[2], curve=SVLCurve([0, 1], [0, g]))
        prepared = prepare_svl(linear; dt=0.2e-6, duration=100e-6)
        result = simulate_svl(prepared; atol_v=1e-6, rtol=1e-10)
        # Explicit local bus and SVL top nodes, including each R-L lead.
        c, grid = linear.linear, prepared.grid
        expected = zeros(ComplexF64, grid.n ÷ 2 + 1, 12)
        for k in axes(expected, 1)
            s = complex(grid.shift, 2pi * (k-1) / grid.T)
            Z, Y = zy_cabo(c.system, [s])
            A, segments = Gustavsen2011.network_admittance(c, s, Z[:, :, 1], Y[:, :, 1])
            extra = zeros(ComplexF64, c.node_count+4, c.node_count+4)
            extra[1:c.node_count, 1:c.node_count] = A
            bus = c.node_count + 4
            extra[bus,bus] = inv(linear.earth_resistance_ohm)
            for (p, node) in enumerate(linear.port_nodes)
                top = c.node_count + p
                for (a,b,y) in [(node, top, inv(linear.lead_resistance_ohm + s*linear.lead_inductance_h)),
                                (top, bus, complex(g))]
                    extra[a,a] += y; extra[b,b] += y
                    extra[a,b] -= y; extra[b,a] -= y
                end
            end
            free = vcat(c.free_nodes, collect(c.node_count+1:c.node_count+4))
            v = zeros(ComplexF64, c.node_count+4)
            input = Gustavsen2011.impulse_transform(s; peak_v=c.peak_v)
            v[c.source_node] = input
            v[free] = -(extra[free,free] \ extra[free,c.source_node]) .* input
            expected[k,:] = vcat(v[first(c.segment_nodes)[1:6]], v[last(c.segment_nodes)[7:12]])
        end
        waves = Gustavsen2011.solve_svl_waves(prepared; atol_v=1e-6, rtol=1e-10)
        current_spectrum = grid.dt .* rfft(waves.current .* grid.weight, 1)
        actual = copy(prepared.source[:,1:12])
        for k in axes(actual, 1)
            actual[k,:] -= prepared.response[1:12,:,k] * current_spectrum[k,:]
        end
        # A complex Nyquist solve and real endpoint port projection are different
        # discretizations. Compare every other frequency, then their inverse NLT.
        @test actual[1:end-1,:] ≈ expected[1:end-1,:] rtol=1e-8 atol=1e-10
        actual[end,:] .= 0
        expected[end,:] .= 0
        exact = irfft(expected, grid.n, 1)[1:grid.saved,:] ./ (grid.dt .* grid.weight[1:grid.saved])
        observed = irfft(actual, grid.n, 1)[1:grid.saved,:] ./ (grid.dt .* grid.weight[1:grid.saved])
        @test maximum(abs, observed - exact) < 1e-3
        @test result.svl_current_a ≈ g .* result.svl_voltage_v atol=1e-8
        @test result.port_kvl_residual_v < 1e-3
    end

    @testset "Nonlinear cable response, KCL, energy and sampling convergence" begin
        coarse_cache = prepare_svl(svl; dt=0.1e-6, duration=100e-6)
        coarse = simulate_svl(coarse_cache)
        opened = simulate_svl(coarse_cache; enabled=false)
        fine = simulate_svl(svl; dt=0.05e-6, duration=100e-6)
        @test coarse.nonlinear_iterations > 0
        @test coarse.port_kvl_residual_v < 1e-3
        @test maximum(abs, coarse.svl_current_a) > 100
        @test maximum(abs, coarse.svl_voltage_v) < maximum(abs, opened.svl_voltage_v)
        @test all(iszero, fine.sending_voltage_v[:, 2:2:6])
        @test all(iszero, fine.receiving_voltage_v[:, 2:2:6])
        @test fine.receiving_load_current_a ≈ -fine.receiving_current_a[:, 1:2:5] atol=1e-7
        @test fine.sending_current_a[:, [3,5]] ≈ -fine.sending_voltage_v[:, [3,5]] ./ 500 atol=1e-7
        for p in axes(fine.svl_voltage_v, 2)
            @test fine.svl_current_a[:, p] ≈ svl_current.(Ref(svl.curves[p]), fine.svl_voltage_v[:, p]) atol=1e-8
        end
        @test minimum(fine.svl_power_w) >= -1e-8
        @test minimum(diff(fine.svl_energy_j; dims=1)) >= -1e-10
        @test maximum(fine.svl_energy_j[end,:]) > 1
        # PWL slope changes introduce finite-bandwidth ringing. Bound the full
        # waveform discrepancy relative to the device peak, and separately
        # check peak voltage and integrated energy, which converge faster.
        @test maximum(abs, coarse.svl_voltage_v - fine.svl_voltage_v[1:2:end,:]) < 0.02maximum(abs, fine.svl_voltage_v)
        @test maximum(abs, coarse.svl_voltage_v) ≈ maximum(abs, fine.svl_voltage_v) rtol=1e-4
        @test maximum(abs, coarse.svl_current_a - fine.svl_current_a[1:2:end,:]) < 25
        @test coarse.svl_energy_j[end,:] ≈ fine.svl_energy_j[end,:] rtol=0.01 atol=1e-3
        extended = simulate_svl(svl; dt=0.1e-6, duration=100e-6, period=2coarse.transform_period_s)
        @test maximum(abs, coarse.svl_voltage_v - extended.svl_voltage_v) < 0.002maximum(abs, extended.svl_voltage_v)
        @test maximum(abs, coarse.svl_current_a - extended.svl_current_a) < 2
        @test_throws ArgumentError simulate_svl(coarse_cache; rtol=0)
        @test_throws ArgumentError simulate_svl(coarse_cache; maxiter=0)
        @test_throws ErrorException simulate_svl(coarse_cache; maxiter=1)
    end
end
