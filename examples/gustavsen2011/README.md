# Figure 5 impulse test: 400 kV cross-bonded cable

This runnable case reconstructs the **electrical connections** in Figure 5 of
U. S. Gudmundsdottir, B. Gustavsen, C. L. Bak and W. Wiechowski,
*Field Test and Simulation of a 400-kV Cross-Bonded Cable System*,
IEEE Transactions on Power Delivery, 26(3), July 2011, pp. 1403-1410,
[doi:10.1109/TPWRD.2010.2084600](https://doi.org/10.1109/TPWRD.2010.2084600).
The supplied source file is `26pwrd03gustavsen.pdf`.

It uses the cable properties in Table I, the nine lengths and bonding sequence
in Figure 3, and the bonding/grounding leads in Figures 11 and 12. It calculates
terminal waveforms with a distributed, frequency-dependent cable model. The PDF
does not supply measured waveform samples or all simulation settings, so this
is a reproducible reconstruction with declared assumptions, not a numerical
replication of the measured curves or the original PSCAD implementation.

## Run

From the repository root:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. examples/gustavsen2011.jl
julia --project=. test/runtests.jl
```

The example creates `output/gustavsen2011/` containing:

- `waveforms.png`: sending/receiving core voltages and currents for all phases,
  through 900 microseconds.
- `initial_current.png`: phase 1 sending current for the first 100 microseconds.
- `waveforms.csv`: time, prescribed source, and all six conductor voltages and
  currents at both ends, with units in the column headers.
- `waveforms.npz`: named arrays, also including receiving load currents.
- `run_info.txt`: parameters, numerical settings, conventions and assumptions.

Generated outputs are ignored by Git. No source PDF is copied into the repository.
The first command-line argument can select a different output directory.

### Compare with the paper

After generating the Julia waveforms, run:

```sh
julia --project=. examples/gustavsen2011/compare_paper.jl
```

This creates `output/gustavsen2011/comparison/` with seven individual comparisons
and two overview sheets, each in PNG and SVG. Figures 7-10 provide measured
terminal curves; Figures 14-16 provide the paper's PSCAD sending-current curves.
Reference curves are digitized approximations from the PDF's native raster
images. No time shifting, amplitude fitting or changes to the cable model are
applied. The output also includes descriptive RMSE metrics and run provenance.
See [the reference-data documentation](reference/README.md) for calibration,
resolution, limitations and instructions to repeat the digitization.

For a different soil resistivity or the alternative 4.28 kV figure-caption value:

```julia
include("examples/gustavsen2011.jl")
result = run_gustavsen2011(soil_resistivity=100.0, peak_v=4280.0)
```

For a calculation without plots/files:

```julia
include("examples/gustavsen2011/case.jl")
using .Gustavsen2011
case = build_case(soil_resistivity=100.0, peak_v=4080.0)
result = simulate(case; dt=0.05e-6, duration=900e-6)
```

The extracted SI data are in `data.jl` as `PAPER_DATA` and
`GEOMETRY_COMPARISON`. Changing the constructor keywords does not modify them.

## Extracted cable data

The cable is a single-core, 400 kV, 1200 mm² aluminium XLPE cable; its core has
127 strands (Sections II and IV-A, printed pp. 1403-1404 / PDF pp. 1-2).
Table I on printed p. 1406 / PDF p. 4 gives the following model inputs.

| Layer or property | Paper value | Representation in this case |
| --- | --- | --- |
| Core radius | 21.6 mm | Solid equivalent aluminium conductor |
| Corrected core resistivity | 3.46 × 10⁻⁸ Ω·m | Already accounts for stranding |
| Inner semiconductor thickness | 1.3 mm | Included in the main dielectric region |
| XLPE insulation thickness | 27 mm | Included in the main dielectric region |
| Outer semiconductor thickness | 1.12 mm | Included in the main dielectric region |
| Corrected main dielectric relative permittivity | 2.7588 | Applied to the expanded dielectric region |
| Corrected main dielectric relative permeability | 1.0385 | Includes the stated screen solenoid correction |
| Metallic screen thickness | 2.39 mm | Equivalent tubular sheath |
| Effective screen resistivity | 5.66 × 10⁻⁸ Ω·m | Aluminium wires and foil represented together |
| Outer insulation thickness | 4.3 mm | Outer jacket |
| Outer insulation relative permittivity | 2.3 | Outer jacket |

The resulting radii, measured from the cable centre, are:

| Boundary | Radius [mm] |
| --- | ---: |
| Core exterior | 21.60 |
| Inner semiconductor exterior | 22.90 |
| XLPE exterior | 49.90 |
| Outer semiconductor exterior / sheath interior | 51.02 |
| Sheath exterior | 53.41 |
| Jacket exterior | 57.71 |

The `CableComponent` radii are therefore `(0, 21.60, 51.02)` mm for the core
and `(51.02, 53.41, 57.71)` mm for the sheath. The semiconductors are absorbed
into the dielectric once; the corrected permittivity is not corrected again.
Metal and jacket relative permeabilities are taken as 1.

For completeness, Table II (printed p. 1407 / PDF p. 5) compares three geometries:

| Dimension [mm] | Manufacturer datasheet | Measured sample | Supplier test report |
| --- | ---: | ---: | ---: |
| Core **diameter** | 42.9 | 43.0 | 43.2 |
| Inner semiconductor thickness | 1.6 | 1.5 | 1.3 |
| Insulation thickness | 28 | 31 | 27 |
| Outer semiconductor thickness | 1.5 | 3.0 | 1.12 |
| Screen thickness | 2.39 | 2.1 | 2.39 |
| Outer insulation thickness | 5 | 4 | 4.3 |

Table I agrees with the supplier test-report geometry, which is the default
here. The other geometries are preserved as data; they are not silently
substituted or combined with the default geometry.

## Layout, lengths and sheath connections

Figure 2 (PDF p. 1) places the cables in flat formation, with 0.3 m centre
spacing and 1.3 m burial depth. This case uses `(x, depth)` positions
`(0, 1.3)`, `(0.3, 1.3)`, `(0.6, 1.3)` metres. Phase 1 is an outer phase.

Figure 3 (PDF p. 2) specifies:

| Segment | Length [m] | Cumulative length [m] | Connection after segment |
| --- | ---: | ---: | --- |
| 1 | 860 | 860 | Straight joint |
| 2 | 849 | 1709 | Sheath cross bonding |
| 3 | 849 | 2558 | Straight joint |
| 4 | 849 | 3407 | Sheath cross bonding |
| 5 | 850 | 4257 | Straight joint |
| 6 | 862 | 5119 | Intermediate sheath grounding |
| 7 | 849 | 5968 | Sheath cross bonding |
| 8 | 852 | 6820 | Sheath cross bonding |
| 9 | 805 | 7625 | Receiving end |

Main conductors remain connected phase-to-phase throughout. At every cross
bonding, Figure 11 maps the left sheath terminals to the right terminals as
`S1 -> S3`, `S2 -> S1`, `S3 -> S2`. Each path contains two 1 μH leads, equivalent
to **2 μH per complete cross-bond link**. The 300 mm² copper bonding wires and
1 μH/m estimate are described in Section IV-F.

Figure 12 has **six separate 10 μH legs**, one from each incoming/outgoing
sheath terminal to a common ground bus. That bus connects to earth through the
**1 mΩ** resistor drawn in the figure. There is no direct sheath connection
bypassing those legs. The internal ground therefore differs from the ideal
terminal sheath grounds specified in Figure 5.

## Figure 5 excitation and terminations

| Terminal | Connection to earth |
| --- | --- |
| Sending phase 1 core | Prescribed impulse voltage source |
| Sending phase 2 core | Individual 500 Ω resistor |
| Sending phase 3 core | Individual 500 Ω resistor |
| Receiving phase 1 core | Individual 500 Ω resistor |
| Receiving phase 2 core | Individual 500 Ω resistor |
| Receiving phase 3 core | Individual 500 Ω resistor |
| All three sheaths, both ends | Ideal ground, exactly zero terminal voltage |

There are **five 500 Ω resistors**. The phase 1 source has no additional
500 Ω sending resistor. An ideal prescribed voltage is used because no
generator equivalent circuit or source impedance is supplied.

Section III (PDF p. 2) specifies **4.08 kV, 1.2/50 μs**; the Figure 6 caption
(PDF p. 3) instead states **4.28 kV**. The default is the main-text value,
4080 V, and `peak_v` allows the caption value. The 400 kV cable rating is not
the applied test voltage.

The source is the normalized double exponential

```text
v(t) = Vpeak * [exp(-alpha*t) - exp(-beta*t)] / peak_normalizer, t >= 0
alpha = 14659.108681119082 s^-1
beta  = 2468926.6530552628 s^-1
```

The rates give a 1.2 μs virtual front `(t90 - t30)/0.6` and a 50 μs half-value
time measured from `t30 - 0.5*(t90 - t30)`. The peak occurs about 2.089 μs after
the mathematical start. This analytic waveform does not contain the returning
wave features visible in the measured sending voltage in Figure 7.

Arrays use conductor order `[core1, sheath1, core2, sheath2, core3, sheath3]`.
Both stored cable-end currents are positive **into** the cable. Thus the
receiving resistor current is `-receiving_current_a[:, [1,3,5]]`, and also
`receiving_voltage_v[:, [1,3,5]] / 500`. It is separately provided as
`receiving_load_current_a`. The receiving-current plots use this load direction,
consistent with the measurement described in Section III.

## Calculation and limits of reproduction

`BuriedCableSystem` adds the missing underground single-core-system geometry
to the package. `zy_cabo` combines the existing coaxial conductor/sheath skin
effect with the self/mutual Pollaczek earth-return impedance. The latter uses
the integral in equations (1a-b) of
[Uribe et al., IPST 2001](https://www.ipstconf.org/papers/Proc_IPST2001/01IPST003.pdf).
It assumes homogeneous, nonmagnetic, conducting soil with a flat air interface
and neglects displacement current. The shunt matrix includes the main dielectric
and outer jacket, taking the soil outside the jackets as equipotential.
Proximity effects and dielectric losses are not included.

Each distributed segment is converted to a 12-terminal nodal admittance.
The complete system connects these segments, bonding inductors and terminal
loads. Ideal terminal grounds and the prescribed source voltage are eliminated
exactly before solving the free-node voltages. The time response is obtained
by inverse FFT along a shifted Laplace contour, with the analytic source
transform, padding and exponential damping. At the default 0.05 μs step and
900 μs output duration, the transform period is 3.2768 ms, the bandwidth is
10 MHz and the shift is approximately 3051.76 s⁻¹. Small finite-bandwidth
ringing at time zero or before arrivals is retained rather than clipped.

The following distinctions matter when comparing the plots to the paper:

1. **Soil resistivity is missing from the PDF.** The case explicitly assumes
   100 Ω·m; change `soil_resistivity` when a site value is available. Earth-mode
   behaviour and later coupled responses depend on it.
2. **The measured source samples are missing.** The paper says its measured
   data can be requested from the first author. The `reference/` directory now
   contains approximate digitized figure traces for comparison, clearly
   distinguished from original measurement samples. They are not used to drive
   or tune the simulation.
3. **Published timing and material values are not mutually reproduced by
   the simple coaxial limit.** Table I gives approximately 178.523 nH/m,
   178.563 pF/m, 31.619 Ω, and 177.116 m/μs. These imply a 43.051 μs one-way
   time over 7625 m and a 19.298 μs first cross-bond return. Section V instead
   quotes measured values of 39 μs and 17.4 μs (195.5 m/μs). Finite conductor
   impedance adds dispersion. The case preserves Table I; it does not tune
   permittivity or length to force agreement with the reported timing.
4. **The adjacent circuit is omitted.** Figures 2 and 4 show a second circuit
   6 m away, connected to a grounded overhead line. The present case models the
   measured six-conductor circuit in Figure 5, matching the six-mode analysis
   discussed in the paper. The adjacent circuit/OHL coupling and unspecified
   overhead-line geometry are not represented.
5. **No arrester characteristic is supplied.** Arresters are omitted for this
   low-voltage linear benchmark. A separate [configurable SVL/NLT extension](SVL_NLT.md)
   adds illustrative nonlinear SVLs, connection leads and local earth resistors.
   Its assumed higher impulse and V-I curve are not data from this paper.
6. **This is a direct frequency-domain calculation.** It does not recreate
   PSCAD rational fits, the physical surge tester, or measurement probes. The
   paper itself reports disagreement with measured later transients associated
   with proximity effects in intersheath modes.

With the defaults, the calculated phase 1 sending-current peak is about
**127.8 A**. Treat that as a model output, not an independently measured
validation target.

## Verification

`test/test-gustavsen2011.jl` checks the extracted geometry, cumulative lengths,
every cross-bond permutation, six intermediate grounding legs, five resistive
terminations and all six exact terminal grounds. It also checks frequency-domain
KCL, the receiving load law, reciprocity, conjugate symmetry, positive series
losses/capacitance, the infinite-depth earth-return limit, quadrature convergence,
impulse timing, approximate causality and time-step convergence.

The case exposed and fixes a pre-existing error in
`comp_coaxial_cable_impedance`: dielectric inductance used the metal permeability
`mur_c` instead of the dielectric value `mur_d`. A regression test verifies
the expected analytical inductance increment for the paper's 1.0385 correction.
The existing cable fixture tests remain part of the full suite.
