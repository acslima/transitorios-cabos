# Transcribed from Gudmundsdottir et al. (2011), DOI 10.1109/TPWRD.2010.2084600.
# SI units throughout. See README.md for page/figure provenance and assumptions.
const PAPER_DATA = (
    nominal_voltage_v = 400e3,
    nominal_core_area_m2 = 1200e-6,
    core_wire_count = 127,
    core_radius_m = 21.6e-3,
    core_resistivity_ohm_m = 3.46e-8,
    inner_semiconductor_thickness_m = 1.3e-3,
    xlpe_thickness_m = 27e-3,
    outer_semiconductor_thickness_m = 1.12e-3,
    main_insulation_epsr = 2.7588,
    main_insulation_mur = 1.0385,
    screen_thickness_m = 2.39e-3,
    screen_resistivity_ohm_m = 5.66e-8,
    jacket_thickness_m = 4.3e-3,
    jacket_epsr = 2.3,
    burial_depth_m = 1.3,
    phase_spacing_m = 0.3,
    adjacent_circuit_gap_m = 6.0,
    segment_lengths_m = (860.0, 849.0, 849.0, 849.0, 850.0, 862.0, 849.0, 852.0, 805.0),
    cross_bond_after = (2, 4, 7, 8),
    # Fig. 11: left S1 -> right S3, left S2 -> right S1, left S3 -> right S2.
    cross_bond_permutation = (3, 1, 2),
    cross_bond_lead_inductance_h = 1e-6, # each side; 2 μH per complete link
    ground_after = 6,
    ground_lead_inductance_h = 10e-6,    # each of the six legs in Fig. 12
    middle_ground_resistance_ohm = 1e-3, # Fig. 12 label: 1 mOhm
    bonding_wire_area_m2 = 300e-6,
    terminal_load_ohm = 500.0,
    impulse_peak_v = 4080.0,            # Section III; Fig. 6 instead says 4280 V
    impulse_front_s = 1.2e-6,
    impulse_half_value_s = 50e-6,
    measured_one_way_time_s = 39e-6,
    measured_coaxial_velocity_m_per_s = 195.5e6,
)

# Table II. Thicknesses except the first entry, which is a diameter.
const GEOMETRY_COMPARISON = (
    datasheet = (core_diameter_m=42.9e-3, inner_semiconductor_m=1.6e-3,
        insulation_m=28e-3, outer_semiconductor_m=1.5e-3,
        screen_m=2.39e-3, jacket_m=5e-3),
    measured_sample = (core_diameter_m=43e-3, inner_semiconductor_m=1.5e-3,
        insulation_m=31e-3, outer_semiconductor_m=3e-3,
        screen_m=2.1e-3, jacket_m=4e-3),
    supplier_test_report = (core_diameter_m=43.2e-3, inner_semiconductor_m=1.3e-3,
        insulation_m=27e-3, outer_semiconductor_m=1.12e-3,
        screen_m=2.39e-3, jacket_m=4.3e-3),
)
