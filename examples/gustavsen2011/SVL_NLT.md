# Cross-bonded underground cable with SVLs and NLT

Run the configurable illustrative protection case from the repository root:

```sh
julia --project=. examples/gustavsen2011_svl.jl
julia --project=. test/runtests.jl
```

The runner compares **12 connected SVLs with the same 12 branches open**, using
one cached frequency sweep. Results go to `output/gustavsen2011_svl/`:

- `svl_comparison.png` and `.svg`: SVL voltage, sectionalising-joint voltage,
  SVL current and energy for the SVL absorbing the most energy.
- `with_svl.csv`, `without_svl.csv`: all SVL and joint waveforms.
- `svl_summary.csv`: per-device voltage/current peaks and interval energy,
  including the unprotected comparison.
- `waveforms.npz`: all terminal, SVL, bonding-midpoint, lead, local-earth and
  joint arrays for both runs; keys begin with `with_svl_` or `without_svl_`.
- `run_info.txt`: the actual curves, connections, source, numerical settings,
  convergence residuals and modelling assumptions.

The cable retains the Table I properties, nine section lengths, cross-bond
permutation, original intermediate grounding, five 500 Ω core terminations and
six ideal terminal sheath grounds. The original `examples/gustavsen2011.jl`
remains the **4080 V linear benchmark**. The new runner uses an assumed
**100 kV, 1.2/50 μs prescribed core-voltage impulse**, chosen to exercise the
illustrative SVLs; it is not a source condition from the paper. Its default
step is 0.05 μs and its displayed duration is 200 μs.

## Assumed SVL connections

At junctions after sections **2, 4, 7 and 8**, split each original 2 μH cross-bond
link into its two 1 μH leads and attach an SVL branch to their midpoint:

```text
left S1 ---- 1 μH ---- M1 ---- 1 μH ---- right S3
left S2 ---- 1 μH ---- M2 ---- 1 μH ---- right S1
left S3 ---- 1 μH ---- M3 ---- 1 μH ---- right S2

M1 ---- Rlead ---- Llead ---- SVL1 ----+
M2 ---- Rlead ---- Llead ---- SVL2 ----+---- E ---- Rearth ---- earth
M3 ---- Rlead ---- Llead ---- SVL3 ----+
```

Defaults are `Rlead = 0.1 Ω`, `Llead = 1 μH` for each additional SVL connection,
and `Rearth = 1 Ω` shared by the three SVLs in each box. The four local earth
electrodes are independent. A zero `Rearth` means ideal local earth. These are
configurable assumptions, separate from the paper's existing 1 mΩ intermediate
ground. No mutual ground impedance or earth-continuity conductor is added.

The SVL curve is memoryless, symmetric about the origin and interpolated
**linearly in V and I** between these illustrative points:

| Voltage [V] | Current [A] |
| ---: | ---: |
| 0 | 0 |
| 3000 | 0.000001 |
| 6000 | 1 |
| 8000 | 100 |
| 10000 | 1000 |
| 12000 | 10000 |

These are not manufacturer data. The last segment is extrapolated above
12 kV. Replace the points with the intended device characteristic; add points
to resolve its knee. The model does not represent capacitance, dynamic
residual-voltage effects, thermal state, ageing or an energy-failure threshold.

## Configure and reuse the case

```julia
include("examples/gustavsen2011/case.jl")
using .Gustavsen2011

# Replace these illustrative points and physical assumptions with project data.
curve = illustrative_svl()
base = build_case(peak_v=100e3, soil_resistivity=100.0)
case = build_svl_case(base;
    curve,
    junctions=[2, 4, 7, 8],
    lead_resistance_ohm=0.1,
    lead_inductance_h=1e-6,
    earth_resistance_ohm=1.0,
)
prepared = prepare_svl(case; dt=0.05e-6, duration=200e-6)
protected = simulate_svl(prepared)
unprotected = simulate_svl(prepared; enabled=false)

# Supply a separate SVLCurve for every port when devices differ:
curves = [SVLCurve(curve.voltage_v, curve.current_a) for _ in 1:12]
other_case = build_svl_case(base; curve=curves)

# Inspect one SVL. Port ordering follows the supplied junction list, then S1,S2,S3.
p = 1
peak_current_a = maximum(abs, protected.svl_current_a[:, p])
energy_j = protected.svl_energy_j[end, p]
joint_peak_v = maximum(abs, protected.joint_voltage_v[:, p])

# Check bandwidth and transform-period sensitivity independently.
finer = simulate_svl(case; dt=0.025e-6, duration=200e-6)
longer = simulate_svl(case; dt=0.05e-6, duration=200e-6,
                      period=2protected.transform_period_s)
```

`prepare_svl` snapshots the case. Rebuild the cache when changing the source,
curves, physical parameters or sampling. Its standalone default step is 0.1 μs;
the plotting runner deliberately requests 0.05 μs. `reference_resistance_ohm`
is a positive **numerical wave scale**, default 10 Ω; it adds no circuit resistor.
An empty `junctions=[]` gives the original cable without additional ports.

## How the nonlinear NLT coupling works

The original solver already evaluates the distributed network on
`sₖ = c + j2πk/T`, where `c = damping/T`, and uses an inverse FFT. The added
solver uses the reciprocal discrete pair

```text
NLT{x}  = dt · rfft(exp(-c·t) · x)
INLT{X} = exp(c·t) · irfft(X) / dt
```

The linear network is reduced to its coupled SVL ports. Let `u₀` be the
open-circuit midpoint voltages and `i` the currents leaving the midpoints
towards the SVLs. The frequency-domain element-voltage equation is

```text
U = U₀ - Zp I
Zp = Bᵀ Aff⁻¹ B + diag(Rlead + s·Llead) + Zearth
```

`B` selects the midpoint nodes among the free nodes, and `Aff` contains the
distributed cable, bonding leads and original loads/grounds. Each three-port
diagonal block of `Zearth` equals `Rearth · ones(3,3)`, accounting for the shared
earth voltage `Rearth · (i₁+i₂+i₃)`.

For numerical conditioning, define `a = u + R i` and `b = u - R i`, with the
numerical reference resistance `R`. Then

```text
S  = I - 2R · (Zp + R·I)⁻¹
A₀ = 2R · (Zp + R·I)⁻¹ U₀
a  = INLT{A₀} + INLT{S · NLT{b(a)}}
```

For each time sample, invert the monotone piecewise-linear relation
`a = u + R f(u)` exactly. A damped Newton iteration solves the coupled waveform
residual; restarted GMRES applies its Jacobian through FFT operations. All
nonlinear currents are recomputed in time, transformed back, and injected into
the cable network. The algorithm does **not** evaluate `f(U(s))` or superpose
separately solved nonlinear responses. It operates on damped waveforms over the
whole transform period, and returns only the requested interval.

Separating a linear NLT network from instantaneous nonlinear loads is discussed
by [Villanueva et al., IPST 2013](https://www.ipstconf.org/papers/Proc_IPST2013/13IPST084.pdf).
That paper compares sequential piecewise-linear switching and a Newton method
with a polynomial characteristic. This implementation uses a piecewise-linear
characteristic with a wave-variable Newton/GMRES solve; it does not reproduce
either paper algorithm verbatim. A broader discussion is given by
[Gómez and Uribe, 2009](https://doi.org/10.1016/j.ijepes.2008.10.006).

DC and Nyquist bins use real endpoint values. For consistent nonlinear port
equations, the Nyquist port impedance is projected to real values before
conversion to wave variables. This finite-bandwidth choice differs from first
solving a complex circuit at Nyquist and then discarding its imaginary result.
Bandwidth ringing and exponentially suppressed periodic wraparound remain;
no pre-arrival samples are clipped. Numerical residual convergence does not
replace step/period convergence checks.

## Interpreting and verifying the result

SVL voltage is measured across the nonlinear element only. `lead_voltage_v`
includes the additional series R-L drop; `local_earth_voltage_v` is the shared
earth-bus rise. Their sum equals `bond_midpoint_voltage_v` within the reported
`port_kvl_residual_v`. `nonlinear_residual_v` is the Newton wave-equation
residual in the saved interval, which is a different diagnostic.

`joint_voltage_v` is the left-minus-right sheath voltage on the **same physical
phase** at the sectionalising joint. Because the sheaths are cross-bonded,
this is different from both the SVL voltage and the drop along a cross-bond
link. Limiting one SVL's voltage does not imply the same bound for every joint.

SVL current is positive towards local earth. Energy is the trapezoidal integral
of `u_SVL · i_SVL` over the displayed interval, excluding lead/earth losses.
Extend `duration` to establish the total event energy. Terminal conductor order
and current signs match the original benchmark.

`test/test-svl.jl` checks polarity/passivity, invalid curves, bond topology,
an exact nonlinear resistive circuit, agreement with an independently stamped
linear-SVL circuit, recovery of the original benchmark when SVLs are open,
terminal KCL, the nonlinear V-I law, physical port KVL, nonnegative absorbed
energy, step/period convergence, and explicit failure on nonconvergence.
These are numerical and circuit-consistency checks, not field or manufacturer
validation. The original cable model's limitations remain in effect.

For the default 100 kV, 200 μs example, the largest interval energy is about
761.724 J (junction 2, incoming sheath 2). Its open-branch peak is 22.805 kV;
the connected SVL peak is 10.127 kV. The largest connected SVL voltage across
all 12 devices is 10.134 kV. The baseline physical port KVL residual is below
0.1 μV. All 250 tests in the complete suite pass.

Independent sampling checks on that 200 μs run gave these maximum differences
over all devices, relative to the default 0.05 μs step / 409.6 μs period:

| Change | SVL voltage waveform [V] | SVL current waveform [A] | Final interval energy [J] |
| --- | ---: | ---: | ---: |
| Halve step to 0.025 μs, retain period | 110.51 | 1.286 | 0.00219 |
| Double period to 819.2 μs, retain step | 7.87 | 0.148 | 0.00586 |

The peak and energy estimates settle faster than the local voltage ringing.
These differences quantify numerical sensitivity for this illustrative case;
they are not physical model-error bounds. More samples increase both transform
storage and nonlinear iteration work. The finer run required 48 Newton
iterations; the default run required 26. `verbose=true` on `simulate_svl`
prints convergence progress, and unconverged solves raise an error.
