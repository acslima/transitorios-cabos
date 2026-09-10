using Test
using LinearAlgebra
using TransitoriosCabos
using SpecialFunctions: besselk
using TransitoriosCabos.Formulas: comp_coaxial_cable_impedance, earth_return_impedance

include(joinpath(@__DIR__, "..", "examples", "gustavsen2011", "case.jl"))
using .Gustavsen2011

@testset "Gustavsen 2011 Figure 5" begin
    p = PAPER_DATA
    case = build_case()
    system = case.system
    @test sum(case.lengths_m) == 7625.0
    @test cumsum(case.lengths_m)[[2, 4, 6, 7, 8]] == [1709, 3407, 5119, 5968, 6820]
    @test count_conductors_cable(system) == 6
    @test [c.x for c in system.cables] ≈ [0, 0.3, 0.6]
    @test all(c -> c.y == 1.3, system.cables)
    core, sheath = system.cables[1].components
    @test [core.radius_ext, sheath.radius_in, sheath.radius_ext,
           sheath.radius_ext_insulator] ≈ 1e-3 .* [21.6, 51.02, 53.41, 57.71]
    @test_throws ArgumentError build_case(; soil_resistivity=0)
    @test_throws ArgumentError BuriedCableSystem([system.cables[1], system.cables[1]];
                                                 soil_resistivity=100)

    @testset "Insulation permeability correction" begin
        s = 1e4 + 2pi * 1e5im
        uncorrected = deepcopy(system.cables[1])
        uncorrected.components[1].mur_d = 1.0
        delta = comp_coaxial_cable_impedance(system.cables[1], s) -
                comp_coaxial_cable_impedance(uncorrected, s)
        expected = zeros(ComplexF64, 2, 2)
        expected[1, 1] = s * 4pi * 1e-7 / (2pi) * (p.main_insulation_mur - 1) *
                         log(sheath.radius_in / core.radius_ext)
        @test delta ≈ expected rtol=1e-11
    end

    @testset "Buried cable physics" begin
        freq = 2pi * im .* [1.0, 50.0, 1e3, 1e5, 1e6]
        Z, Y = zy_cabo(system, freq)
        Zn, Yn = zy_cabo(system, conj.(freq))
        @test Zn ≈ conj.(Z)
        @test Yn ≈ conj.(Y)
        for k in eachindex(freq)
            @test Z[:, :, k] ≈ transpose(Z[:, :, k])
            @test Y[:, :, k] ≈ transpose(Y[:, :, k])
            @test minimum(eigvals(Symmetric(real.(Z[:, :, k])))) > 0
            @test minimum(eigvals(Symmetric(real.(Y[:, :, k] / freq[k])))) > 0
        end
        # At very large burial depth the air-interface terms disappear.
        s = 2pi * 1e3im
        radius = sheath.radius_ext_insulator
        m = sqrt(s * 4pi * 1e-7 / 100)
        infinite_soil = s * 4pi * 1e-7 / (2pi) * besselk(0, m * radius)
        @test earth_return_impedance(s, radius, 1e5, 1e5, 0.0, 100; self=true) ≈ infinite_soil
        Ztight, _ = zy_cabo(system, freq; earth_rtol=1e-11)
        @test Ztight ≈ Z rtol=1e-9
        @test_throws ArgumentError zy_cabo(system, [0.0 + 0.0im])
    end

    @testset "Bonding and terminal boundary conditions" begin
        @test length(case.grounded_nodes) == 6
        @test length(case.load_nodes) == 5
        @test !(case.source_node in case.load_nodes)
        @test count(link -> link[3] == 2e-6, case.inductors) == 12
        @test count(link -> link[3] == 10e-6, case.inductors) == 6
        for junction in 1:8
            right = case.segment_nodes[junction][7:12]
            left = case.segment_nodes[junction+1][1:6]
            @test right[1:2:5] == left[1:2:5] # no core transposition
            if junction in p.cross_bond_after
                for (phase, target) in enumerate((3, 1, 2))
                    @test (right[2phase], left[2target], 2e-6) in case.inductors
                end
            elseif junction == p.ground_after
                for node in vcat(right[2:2:6], left[2:2:6])
                    @test (node, case.ground_bus, 10e-6) in case.inductors
                end
            else
                @test right == left
            end
        end
        for s in [1e4 + 0im, 1e4 + 1e5im, 1e4 + 1e7im]
            result = solve_frequency(case, s)
            @test result.voltage[case.source_node] == 1
            @test all(iszero, result.voltage[case.grounded_nodes])
            @test result.free_kcl_residual < 1e-10
            @test result.sending_current[[3, 5]] ≈
                  -result.sending_voltage[[3, 5]] / 500 rtol=1e-9 atol=1e-12
            @test result.receiving_current[1:2:5] ≈
                  -result.receiving_voltage[1:2:5] / 500 rtol=1e-9 atol=1e-12
        end
    end

    @testset "1.2/50 impulse and transient" begin
        # Independently locate nominal front and half-value crossings.
        bisect(f, lo, hi) = begin
            for _ in 1:70
                mid = (lo + hi) / 2
                if sign(f(mid)) == sign(f(lo))
                    lo = mid
                else
                    hi = mid
                end
            end
            (lo + hi) / 2
        end
        tp = Gustavsen2011.IMPULSE_PEAK_TIME
        @test impulse_voltage(-1e-6) == impulse_voltage(0.0) == 0
        @test impulse_voltage(tp) ≈ 4080
        t30 = bisect(t -> impulse_voltage(t) / 4080 - 0.3, 0.0, tp)
        t90 = bisect(t -> impulse_voltage(t) / 4080 - 0.9, 0.0, tp)
        t50 = bisect(t -> impulse_voltage(t) / 4080 - 0.5, tp, 1e-3)
        virtual_origin = t30 - (t90 - t30) / 2
        @test (t90 - t30) / 0.6 ≈ 1.2e-6 rtol=1e-9
        @test t50 - virtual_origin ≈ 50e-6 rtol=1e-9
        coarse = simulate(case; dt=0.05e-6, duration=100e-6)
        fine = simulate(case; dt=0.025e-6, duration=100e-6)
        @test maximum(abs, fine.sending_voltage_v[:, 2:2:6]) == 0
        @test maximum(abs, fine.receiving_voltage_v[:, 2:2:6]) == 0
        @test fine.receiving_load_current_a ≈ -fine.receiving_current_a[:, 1:2:5] atol=1e-8
        @test fine.sending_current_a[:, [3, 5]] ≈
              -fine.sending_voltage_v[:, [3, 5]] / 500 atol=1e-8
        # Physical checks use analytic scales, not synthetic field measurements.
        estimates = coaxial_estimates()
        @test estimates.surge_impedance_ohm ≈ 31.6193 rtol=1e-5
        @test estimates.one_way_time_s ≈ 43.0509e-6 rtol=1e-5
        @test 120 < maximum(fine.sending_current_a[:, 1]) < 135
        prearrival = fine.time_s .< 40e-6
        @test maximum(abs, fine.receiving_voltage_v[prearrival, 1]) < 0.01case.peak_v
        # Halving dt must preserve the resolved response (exclude the bandwidth
        # error right at the source's derivative discontinuity at time zero).
        keep = coarse.time_s .>= 1e-6
        reference = fine.sending_current_a[1:2:end, :]
        @test maximum(abs, coarse.sending_current_a[keep, :] - reference[keep, :]) < 0.5
        reference_v = fine.receiving_voltage_v[1:2:end, :]
        @test maximum(abs, coarse.receiving_voltage_v - reference_v) < 20
        extended = simulate(case; dt=coarse.dt_s, duration=100e-6,
                             period=2coarse.transform_period_s)
        @test maximum(abs, coarse.sending_current_a - extended.sending_current_a) < 0.05
        @test maximum(abs, coarse.receiving_voltage_v - extended.receiving_voltage_v) < 0.5
        @test maximum(abs, coarse.sending_voltage_v[keep, 1] -
                           coarse.prescribed_source_v[keep]) < 0.25
        @test_throws ArgumentError simulate(case; duration=100e-6, period=100e-6)
    end
end
