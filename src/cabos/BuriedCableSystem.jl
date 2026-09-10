"""
    BuriedCableSystem(cables; soil_resistivity, name="Buried cable system")

Parallel single-core cables in homogeneous, nonmagnetic soil below a flat
soil/air interface. Coordinates are metres; `y` is the **positive burial depth**.
All cables must have the same length. Soil resistivity [Ω·m] is required because
it is site dependent. Conductors are ordered cable by cable, inside to outside.
"""
struct BuriedCableSystem
    cables::Vector{CoaxialCable}
    soil_resistivity::Float64
    cable_length::Float64
    name::String

    function BuriedCableSystem(
        cables::AbstractVector{<:CoaxialCable};
        soil_resistivity::Real,
        name::AbstractString = "Buried cable system",
    )
        isempty(cables) && throw(ArgumentError("At least one cable is required."))
        isfinite(soil_resistivity) && soil_resistivity > 0 ||
            throw(ArgumentError("Soil resistivity must be finite and positive."))
        len = first(cables).cable_length
        isfinite(len) && len > 0 || throw(ArgumentError("Cable length must be positive."))
        for (i, cable) in enumerate(cables)
            isempty(cable.components) && throw(ArgumentError("Cable components are required."))
            isfinite(cable.x) && isfinite(cable.y) && cable.y > outer_radius(cable) ||
                throw(ArgumentError("Each cable must be entirely below the soil surface."))
            isapprox(cable.cable_length, len) ||
                throw(ArgumentError("All cables must have the same length."))
            for other in cables[1:i-1]
                hypot(cable.x - other.x, cable.y - other.y) >
                    outer_radius(cable) + outer_radius(other) ||
                    throw(ArgumentError("Cable cross sections must not overlap."))
            end
        end
        new(deepcopy(collect(cables)), Float64(soil_resistivity), len, String(name))
    end
end

count_conductors_cable(system::BuriedCableSystem) =
    sum(count_conductors_cable, system.cables)
