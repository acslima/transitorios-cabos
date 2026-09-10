# Run from the project root: julia --project=. examples/tripolar.jl
# Geometry and materials match the tripolar cable in test/test-formulas.jl.
using TransitoriosCabos

## Cable geometry (metres) and material properties
core = CableComponent(0.0, 9.6e-3, 17.054e-3, 1.7241e-8, 1.0, 1.0, 3.31, "Core")
sheath = CableComponent(17.054e-3, 18.054e-3, 19.5e-3, 2.2e-7, 1.0, 1.0, 2.3, "Sheath")
distance = (19.5e-3 + 1e-12) / cosd(30.0)
phases = [
    CoaxialCable([core, sheath], distance * cosd(angle), distance * sind(angle), name)
    for (angle, name) in zip((90.0, 210.0, 330.0), ("Phase A", "Phase B", "Phase C"))
]
cable = PipeCable(
    48e-3, 59e-3, 65e-3, 2.86e-8, 300.0, 1.0, 1.0, 2.3, 10.0;
    cables = phases,
    name = "Tripolar cable",
    cable_length = 2500.0,
    sigma_medium = 5.0,
    epsr_medium = 81.0,
)

## Electrical parameters
frequencies_hz = [50.0, 1_000.0, 100_000.0]
s = 2pi * im .* frequencies_hz
# Set a breakpoint here to inspect the cable or step into zy_cabo.
Z, Y = zy_cabo(cable, s, cable.sigma_medium, cable.epsr_medium)
Yn = ynodal_array(Z, Y, cable.cable_length)

println("Julia ", VERSION, " | ", cable.name)
println("Conductors: ", count_conductors_cable(cable))
println("Frequencies [Hz]: ", frequencies_hz)
println("Z [Ω/m]: ", size(Z), " | Y [S/m]: ", size(Y), " | Yn [S]: ", size(Yn))
println("Z[1, 1] at 50 Hz: ", Z[1, 1, 1], " Ω/m")
