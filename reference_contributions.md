# Contributions of the CIGRE cable references

This review covers the **26 supplied PDFs: 18 Technical Brochures and 8 Session papers**, published between 2001 and 2025. It explains what each document contributes, the evidence supporting that contribution, its relevance to cable engineering and electromagnetic-transient studies, and its principal limitations.

The review uses the supplied editions, with targeted reading of their scope, executive summaries, methods, relevant results, and conclusions. It is an analytical literature summary, not a reproduction or independent verification of every calculation in the 2,414 PDF pages. **Page references below are PDF page numbers, counted from the first page**, which sometimes differ from printed page numbers. Citation keys match [referencias_cigre.bib](</Users/acsl/Library/Mobile Documents/com~apple~CloudDocs/Documents/GitHub/transitorios-cabos/referencias_cigre.bib>).

Statements under **Contribution and evidence** describe the documents. **Use for this project** is this review's assessment, informed by the repository's focus on electromagnetic transients in cables. Reported test values and survey statistics retain their original conditions and dates. References to standards describe the editions used by the authors; this review does not establish compliance with current standards.

## How the collection fits together

| Theme | Main references | Collective contribution |
|---|---|---|
| Insulation coordination, bonding and earthing | TB 189, 283, 347, 797; B1-108 (2016), B1-11468 (2024), C4-321 (2020) | Connect network disturbances to stresses on main insulation, sheaths, sectionalising joints, bonding leads and protective devices. |
| Cable parameters, losses and system response | TB 556; B1-215 (2020), C4-309 (2018), C4-327 (2020) | Explain how model assumptions affect damping, resonance, sheath currents and earth-return currents; provide numerical and experimental comparisons. |
| Installation and network integration | TB 194, 250, 338, 889 | Relate electrical design to route selection, civil works, mechanical constraints, interfaces and project-specific economics. |
| Reliability, maintenance and resilience | TB 358, 379, 398, 815, 959; B1-209 (2016) | Provide failure evidence, replacement and maintenance methods, damage prevention and lessons from major disturbances. |
| Environmental effects and monitoring | TB 559, 689, 899 | Address magnetic-field mitigation, environmental life-cycle assessment, and the design and qualification of optical-fibre infrastructure. |
| Alternative technologies and manufacturing | TB 199; B1-10294 (2022) | Explain superconducting-cable network implications and manufacturing controls for long EHV XLPE submarine cables. |

## Document-by-document contributions

### 01. TB 189 (2001) — Insulation co-ordination for HV AC underground cable systems

**Citation key:** `CIGRE_TB189` · **Source:** [189.pdf][pdf01]

**Contribution and evidence.** Establishes a framework for relating the insulation withstand of an underground cable system to the overvoltages actually imposed by its network. It brings together network configurations, travelling-wave behaviour, protective devices, insulation ageing and design criteria for fluid-impregnated and extruded cables. The central contribution is the argument that insulation coordination should consider the complete circuit and its protection, rather than selecting insulation solely from customary impulse levels. The discussion identifies potential scope for reducing required withstand in particular systems, while recognising that cable insulation is not self-restoring.

**Use for this project.** Provides the conceptual basis for choosing lightning and switching scenarios, observing reflections at cable interfaces, and connecting calculated voltages to insulation requirements. It also identifies a research need directly relevant to cross-bonded models: the influence of sheath bonding on transients across the main insulation.

**Limits.** This is a framework and research agenda, not approval for a general reduction in insulation levels. The report leaves safety factors, ageing effects and acceptable failure rates unresolved and calls for additional simulations of specific configurations.

**Evidence locations:** PDF p. 3, summary; pp. 29–38, coordination and overvoltage principles; p. 45, conclusions.

### 02. TB 194 (2001) — Construction, laying and installation techniques for extruded and self-contained fluid-filled cable systems

**Citation key:** `CIGRE_TB194` · **Source:** [194.pdf][pdf02]

**Contribution and evidence.** Systematises the engineering decisions needed to construct and install an HV land-cable route. Drawing on questionnaires answered by 46 utilities from 22 countries and 27 manufacturers from 16 countries, it describes twelve construction techniques, including direct burial, ducts, tunnels and trenchless approaches. It distinguishes the civil works that create the route from the activities that install the cable. It also brings together accessory compatibility, pulling tension, sidewall pressure, installation in air, fixation and transitions between installation arrangements. A hypothetical case study illustrates how to compare alternatives.

**Use for this project.** Helps turn an ideal electrical circuit into a physically plausible installation: section lengths, joint locations, spacing and route transitions are constrained by cable handling and civil works. It supplies background for a chapter on how installation choices affect the configuration being simulated.

**Limits.** Its comparative costs and technology survey are historical and project-dependent. For the more recent installation guidance in this collection, especially large-conductor thermomechanical behaviour, read TB 889 alongside it.

**Evidence locations:** PDF pp. 10–14, scope and survey method; Chapters 3–4, construction and installation; Section 6.2, comparative case study.

### 03. TB 199 (2002) — Superconducting cables: impact on network structure and control

**Citation key:** `CIGRE_TB199` · **Source:** [199.pdf][pdf03]

**Contribution and evidence.** Examines how high-temperature superconducting cables could change network design and operation. It compares cold-dielectric and room-temperature-dielectric concepts, discusses their electromagnetic characteristics and shielding arrangements, and connects cable properties to transmission capacity, fault currents, protection and reliability. Its most distinctive contribution is the explanation that superconducting-cable ratings cannot simply follow conventional thermal-overload concepts: current density, temperature and magnetic-field limits can trigger a transition out of the superconducting state. Refrigeration and other auxiliary equipment also become part of the reliability assessment.

**Use for this project.** Provides a technically distinct extension of conventional cable modelling. It motivates coupled electrical and thermal models with state-dependent properties, as well as studies of protection coordination and fault-current limitation. It is useful for explaining why a fixed linear impedance model cannot capture all superconducting-cable behaviour.

**Limits.** The report describes technology and expectations at its publication date, with substantial development and operational questions still open. Its predictions about deployment, economics and equipment requirements should be presented as historical assessments.

**Evidence locations:** PDF p. 5, introduction; Chapter 4, electromagnetic properties; pp. 37–44, ratings, faults and conclusions.

### 04. TB 250 (2004) — General guidelines for the integration of a new underground cable system in the network

**Citation key:** `CIGRE_TB250` · **Source:** [250.pdf][pdf04]

**Contribution and evidence.** Provides an integrated project guide spanning system requirements, cable design, installation, overhead-to-underground transitions, commissioning, operation, refurbishment and environmental assessment. It links electrical characteristics, thermal sizing, short-circuit duty, insulation coordination, bonding and reclosing with practical decisions about routes and transition compounds. A project flowchart makes explicit the interaction between operating requirements, environmental constraints, construction techniques and the final cable design.

**Use for this project.** Supplies an organising framework for a cable-engineering text or study specification. It helps identify the network data and interface conditions that must be supplied before transient simulations can support design decisions. Its treatment of transition compounds is particularly useful for mixed overhead-line/cable cases.

**Limits.** The primary scope is land AC transmission, with emphasis on extruded cables. Some guidance transfers to submarine or DC projects, but the document is not a detailed treatment of every technology or a substitute for the specialised bonding and transient references.

**Evidence locations:** PDF pp. 8–12, purpose and project process; Chapters 2–4, requirements and design; Chapters 5–9, commissioning through environmental assessment.

### 05. TB 283 (2005) — Special bonding of high voltage power cables

**Citation key:** `CIGRE_TB283` · **Source:** [283.pdf][pdf05]

**Contribution and evidence.** Develops calculation and design guidance for single-point and cross-bonded cable systems under normal load, power-frequency faults and transient overvoltages. It compares simplified expressions with impedance-matrix methods and EMTP/ATP studies, including worked examples of sectionalising-joint stresses and a 225 kV mixed overhead/cable system. It explains the effects of unequal minor-section lengths, earth-continuity conductors, terminal earthing, SVL arrangements and bonding-lead inductance. Its practical contribution is to specify when simple formulae are adequate and when more complete modelling is needed.

**Use for this project.** A principal source for constructing and checking the sheath network, applying cross-bonding connections, and interpreting sheath-to-sheath and sheath-to-earth voltages. The worked cases can support reproducible comparisons if their full assumptions and parameters are retained.

**Limits.** The report stresses sensitivity to bonding-lead models and uncertain system inputs. Its broad statements about earth-potential rise require the refinements in TB 347. Reduction or omission of SVLs is discussed only for particular assessed configurations, not as a general bonding rule.

**Evidence locations:** PDF pp. 10–12, survey findings; Chapters 3–4, calculations and examples; pp. 101–104, design recommendations.

### 06. TB 338 (2007) — Statistics of AC underground cables in power networks

**Citation key:** `CIGRE_TB338` · **Source:** [338.pdf][pdf06]

**Contribution and evidence.** Updates international statistics on the use of underground AC circuits relative to overhead lines, reviews significant projects from 1996–2006, and examines the factors governing technology selection. The study covers system voltages of 50 kV and above, excluding submarine and DC cables. Its most useful analytical conclusion is that generic underground-to-overhead cost ratios are unreliable decision tools: local construction conditions, design choices and the overhead-line reference cost can change the ratio substantially. It recommends comparing the actual incremental cost and benefits of alternatives for the same project.

**Use for this project.** Provides historical context for the adoption of underground transmission and a sound structure for discussing economic and environmental trade-offs. It can support the motivation for studying cable systems without relying on a universal cost multiplier.

**Limits.** This is a deployment and project-comparison source, not a failure-statistics or transient-model validation source. Its circuit lengths and technology shares describe the survey period and should not be presented as the present global installed base.

**Evidence locations:** PDF pp. 5–15, executive summary; Chapters 2–4, statistics, projects and comparison factors; p. 53, conclusions.

### 07. TB 347 (2008) — Earth potential rises in specially bonded screen systems

**Citation key:** `CIGRE_TB347` · **Source:** [347.pdf][pdf07]

**Contribution and evidence.** Investigates earth-potential rise, or EPR, after field experience raised questions about the simplified conclusions in TB 283. It develops simplified and complex-impedance approaches, worked examples and sensitivity studies for internal and external earth faults. The analysis identifies fault-current magnitude, terminal earth impedances, sheath resistance, earth-continuity-conductor resistance and overhead earth-wire resistance as influential parameters. Interfaces between dissimilar return paths can transfer substantial EPR into cable sheaths. It also shows that low substation earth impedances do not eliminate the need to examine SVL stress during an internal cable fault.

**Use for this project.** Supplies the reasoning for modelling finite earth impedances and connected metallic return paths explicitly. It is especially valuable for mixed overhead/cable circuits and transitions between single-point and cross-bonded sections.

**Limits.** The report concerns the integrity of the sheath bonding system and its SVLs; personnel touch- and step-voltage safety is explicitly outside its scope. Its accuracy depends strongly on earthing data that may be poorly known. Simplified results are suitable for screening, with detailed analysis warranted where stresses may be important.

**Evidence locations:** PDF p. 5, motivation and scope; Sections 5–7, methods and examples; p. 67, conclusions.

### 08. TB 358 (2008) — Remaining life management of existing AC underground lines

**Citation key:** `CIGRE_TB358` · **Source:** [358.pdf][pdf08]

**Contribution and evidence.** Reframes the question of remaining life as a practical asset-management decision: when to intervene or replace a cable, rather than when its insulation will fail with certainty. It reviews degradation mechanisms and diagnostic methods, then combines technical, economic and strategic criteria in a staged scoring methodology. A simplified assessment screens the fleet; a more detailed assessment prioritises actions. Case studies illustrate the method, and a separate discussion considers measures that can extend service life.

**Use for this project.** Connects physical stress and condition information to operational decisions. It can explain how results from electrical studies, inspection or monitoring become inputs to maintenance and replacement planning, alongside consequences of failure and strategic needs.

**Limits.** The scores and action categories are decision aids, not calibrated predictions of an individual cable's failure date. The report itself recognises gaps in ageing knowledge and failure data. A transient simulation alone cannot supply a remaining-life estimate using this methodology.

**Evidence locations:** PDF pp. 4–9, executive summary; Chapters 5–7, methodology and life extension; pp. 100–101, conclusions.

### 09. TB 379 (2009) — Update of service experience of HV underground and submarine cable systems

**Citation key:** `CIGRE_TB379` · **Source:** [379.pdf][pdf09]

**Contribution and evidence.** Provides survey evidence on installed quantities, technology trends, failure causes and repair times for cable systems rated 60 kV and above. Land-cable data cover five years ending in December 2005; submarine data cover a fifteen-year period ending at the same date. The survey identifies more than 33,000 circuit-km of land cable and about 7,000 circuit-km of submarine cable. It documents the shift toward XLPE and premoulded accessories, while drawing attention to accessory failures, jointing quality and third-party mechanical damage.

**Use for this project.** Supports selection of meaningful failure scenarios and explains why accessories, installation quality and external damage must accompany conductor-level electrical modelling in a discussion of reliability. It also establishes a historical comparison point for TB 815.

**Limits.** Coverage is incomplete and some subpopulations are small. The report explicitly warns against directly comparing cable and accessory failure rates with different denominators, and against using its mean rates to calculate circuit MTBF or availability. Its statistics should retain their population, period and failure definitions.

**Evidence locations:** PDF pp. 4–6, executive summary; Sections 7–8, survey analysis; p. 75, interpretive limitations.

### 10. TB 398 (2009) — Third-party damage to underground and submarine cables

**Citation key:** `CIGRE_TB398` · **Source:** [398.pdf][pdf10]

**Contribution and evidence.** Translates failure experience into a structured approach to preventing external cable damage. It combines its own survey with TB 379 data to examine excavation, drilling, anchors, trawling and other threats. The analysis emphasises both physical protection and the exchange of accurate route information between operators and third parties. A distinctive deliverable is the Cable Protection Index, which combines probability, damage severity and network consequences to prioritise sections for intervention. The report also considers detection of damage before it develops into an electrical failure.

**Use for this project.** Provides the connection between external events and the electrical fault conditions simulated in a cable study. It also contributes a practical risk-prioritisation method for route design, inspection and monitoring.

**Limits.** The index is an ordinal prioritisation tool, not a calibrated probability of failure. Survey percentages depend on their specific populations and should not be mixed indiscriminately with TB 379 or TB 815 statistics. The brochure acknowledges insufficient submarine data for some installation-versus-failure comparisons.

**Evidence locations:** PDF pp. 6–8, executive summary; Chapter 11, index method; pp. 88–92, recommendations and conclusions.

### 11. TB 556 (2013) — Power system technical performance issues related to the application of long HVAC cables

**Citation key:** `CIGRE_TB556` · **Source:** [556.pdf][pdf11]

**Contribution and evidence.** Connects the distinctive electrical characteristics of long AC cables to the studies required during planning, system-impact assessment, equipment design and failure investigation. It covers compensation, resonances, temporary overvoltages, energisation, generator self-excitation and delayed current zero crossings. It supplies example systems, parameter-calculation comparisons, model-selection guidance and validation procedures, including discussion of measurements on a 100 km offshore cable. Its contribution is a study framework that links the phenomenon, frequency range, surrounding-network representation and required model detail.

**Use for this project.** The strongest general reference in this collection for organising an electromagnetic-transient modelling programme. It helps distinguish parameter verification from waveform validation and motivates sensitivity studies for geometry, earthing, bonding and frequency-dependent behaviour.

**Limits.** Its recommendation of a suitably tuned Bergeron model for many studies is conditional. The report explicitly recognises limitations in reproducing later waveform behaviour and recommends frequency-dependent models for higher-accuracy or forensic work. A model adequate for the first voltage peak is not necessarily adequate for damping or the subsequent oscillations.

**Evidence locations:** PDF pp. 6–7, purpose; Chapters 2–4, study examples and modelling; pp. 90–92, conclusions and model-selection qualifications.

### 12. TB 559 (2013) — Impact of EMF on current ratings and cable systems

**Citation key:** `CIGRE_TB559` · **Source:** [559.pdf][pdf12]

**Contribution and evidence.** Evaluates the electrical and thermal consequences of magnetic-field mitigation around HV cables. It considers cable arrangement and phase management, passive loops, metallic plates, ferromagnetic raceways and steel pipes, drawing on theoretical work, laboratory studies and practical installations. The key contribution is to connect field reduction to additional losses and changes in heat dissipation, so that shielding effectiveness is assessed together with ampacity, installation cost and operating cost. It also distinguishes reducing the field above the circuit from reducing it at a specified lateral distance.

**Use for this project.** Supports models in which nearby conductive or magnetic structures influence losses and mutual coupling. It provides an engineering basis for discussing the trade-off between external magnetic-field control and the cable's current rating.

**Limits.** The stated scope assumes balanced currents without zero-sequence current. Its results therefore should not be transferred directly to earth-fault or lightning-transient cases. The finding that mitigation can have little rating penalty depends on choosing and designing the mitigation arrangement appropriately.

**Evidence locations:** PDF p. 5, scope; technical chapters and case studies on individual mitigation methods; p. 101, conclusions.

### 13. TB 689 (2017) — Life cycle assessment of underground cables

**Citation key:** `CIGRE_TB689` · **Source:** [689.pdf][pdf13]

**Contribution and evidence.** Adapts environmental life-cycle assessment to underground cable systems. It reviews existing studies and tools, explains the definition of functional units and system boundaries, and develops guidance for inventories, impact assessment and interpretation. The report finds that operating losses account for the largest share of environmental impacts in many of the reviewed assessments, while also examining manufacturing, installation and end-of-life choices. Its value lies in providing a consistent method for identifying where an improvement actually reduces total impacts across the life cycle.

**Use for this project.** Connects calculated cable losses with environmental design decisions. It supports comparison of conductor sizes, materials and installation options, provided the alternatives deliver an equivalent function and use consistent assumptions about loading, service life and electricity supply.

**Limits.** Dominance of operational losses is not universal: it depends on utilisation, lifetime, electricity mix, boundaries and impact category. The brochure explicitly states that LCA does not cover all local environmental effects, such as ecological disturbance or magnetic fields. Its discussion of recycling also cautions against assuming that every recycling route yields a net environmental benefit.

**Evidence locations:** PDF pp. 3–4, executive summary; Chapters 2–4, review and methodology; p. 76, recommendations.

### 14. TB 797 (2020) — Sheath bonding systems of AC transmission cables: design, testing, and maintenance

**Citation key:** `CIGRE_TB797` · **Source:** [797.pdf][pdf14]

**Contribution and evidence.** Consolidates the design, qualification, commissioning and maintenance of sheath bonding systems into one engineering guide. It combines a review of earlier CIGRE work with service-experience surveys and guidance on bonding leads, link boxes, SVLs, earthing connections and component withstand requirements. Unlike a purely computational reference, it follows the bonding system through its operational life. A principal conclusion is that project-specific insulation-coordination studies must establish the required bonding-system voltage withstand ratings.

**Use for this project.** Provides the overall reference structure for a bonding chapter and for specifying what a simulation must report: induced currents and voltages, component duty, and the stresses relevant to protection and testing. It links the detailed methods of TB 283 and TB 347 to practical equipment and maintenance requirements.

**Limits.** It deliberately refers readers to earlier publications instead of reproducing all their calculations. It should therefore be used as a consolidation and design guide, with TB 283 and TB 347 retained as supporting technical sources. The existence of a standard bonding arrangement does not remove the need to assess the actual circuit.

**Evidence locations:** PDF p. 3, executive summary; pp. 12–14, relationship to earlier work; Chapters 2–4; p. 63, deliverables and conclusions.

### 15. TB 815 (2020) — Update of service experience of HV underground and submarine cable systems

**Citation key:** `CIGRE_TB815` · **Source:** [815.pdf][pdf15]

**Contribution and evidence.** Updates the service-experience survey for a ten-year period ending in December 2015. It analyses technologies, failure locations, causes, age distributions and repair outages for land and submarine cable systems rated 60 kV and above. The land survey records 744 service failures, and the submarine survey records 22. The report highlights early-life accessory failures in XLPE systems, changes in internal and external failure rates, and the operational importance of repair duration. It reports an average submarine repair outage of about 105 days in its collected data.

**Use for this project.** Supplies a more recent empirical counterpart to TB 379. It strengthens the justification for including accessories, commissioning quality and repair logistics in reliability discussions, and for treating failure frequency and restoration time as distinct aspects of system performance.

**Limits.** Missing countries, incomplete responses and differences in survey populations constrain comparisons over time. A smaller surveyed cable length is not evidence that the global installed base shrank. Submarine conclusions rest on few failures, and reported correlations with age or construction do not establish independent causal effects.

**Evidence locations:** PDF pp. 3–5, executive summary and data-quality note; Sections 8–9, results; p. 59, conclusions.

### 16. TB 889 (2023) — Installation of underground HV cable systems

**Citation key:** `CIGRE_TB889` · **Source:** [889.pdf][pdf16]

**Contribution and evidence.** Updates TB 194 by incorporating newer construction practices and a much fuller treatment of large-conductor XLPE installations. It expands trenchless techniques, joint-bay and interface design, temporary installations, and pulling calculations for long ducts and multiple cables. It integrates thermomechanical design for rigid, flexible and transition arrangements, including the effect on cleats, supports and accessories. Its distinction from TB 194 is particularly important where thermal expansion and large axial forces or movements can govern installation reliability.

**Use for this project.** The preferred installation overview within this collection for building realistic cable-system configurations and describing the mechanical constraints behind them. It also helps connect operating temperature changes to possible movement or stress at joints and terminations.

**Limits.** The report states that the relevant expansion coefficients and effective axial and bending stiffnesses must come from manufacturers or measurements on full-size samples. Formulae alone cannot remove this need for cable-specific inputs. It remains primarily an installation and mechanical-design reference, rather than a transient-propagation model.

**Evidence locations:** PDF pp. 3 and 14, scope and comparison with TB 194; Parts 3–4, installation and system design; p. 275, conclusions.

### 17. TB 899 (2023) — Recommendations for the use and testing of fibre optic cables used in land cable systems

**Citation key:** `CIGRE_TB899` · **Source:** [899.pdf][pdf17]

**Contribution and evidence.** Brings together design, testing, installation and maintenance guidance for fibre-optic cables used alongside, or embedded within, land power cables. It addresses communication and sensing applications, including temperature, strain and vibration monitoring. A central design distinction is that communication fibres benefit from independence and maintainability, whereas sensing fibres often benefit from close physical coupling to the power cable. The report examines the resulting compromises, as well as optical performance, mechanical stress, metallic components, induced voltages and bonding arrangements.

**Use for this project.** Provides the engineering context for obtaining monitoring data that can inform cable studies and maintenance. It is also relevant when metallic fibre enclosures introduce additional electrical paths, and when interpreting whether a sensor measures the desired cable quantity or an indirect proxy.

**Limits.** It is a guide to the fibre infrastructure and its qualification, not proof that a particular diagnostic algorithm can predict cable failure. It focuses on land systems. Sensor position, calibration, access and repair implications remain specific to the selected cable and monitoring system.

**Evidence locations:** PDF pp. 3–4, executive summary; Chapters 3–5, design through commissioning; pp. 68–69, operation, maintenance and calibration.

### 18. TB 959 (2025) — Behaviour of cable systems under large disturbances

**Citation key:** `CIGRE_TB959` · **Source:** [959.pdf][pdf18]

**Contribution and evidence.** Collects engineering lessons from natural disturbances affecting cable systems across voltage classes. It covers earthquakes and liquefaction, floods, landslides, storms, fire and drought, with attention to damage mechanisms, restoration, spares, installation improvements and testing. Case histories show how mechanical displacement and support-system behaviour can ultimately produce electrical failure. Its discussion of soil settlement, for example, follows a proposed sequence from cable tension and support deformation to termination damage. Seismic assessment and tests before and after major events broaden the perspective beyond routine cable qualification.

**Use for this project.** Supports realistic disturbance and damaged-state scenarios, and connects installation mechanics to the boundary conditions of an electrical fault study. It is most valuable here as a resilience and case-history source.

**Limits and source-quality note.** The cases do not constitute a general probabilistic fragility model. The broader climate discussion also requires independent checking: PDF p. 120 states that mean global temperature had risen 3°C relative to 1990, attributing this to an IPCC 2012 report. This is not a reliable observed-warming statement. For comparison, the IPCC's 2023 synthesis reports approximately 1.1°C of warming in 2011–2020 relative to 1850–1900. The engineering lessons above do not rely on that erroneous temperature assertion. [IPCC AR6 synthesis, statement A.1](https://www.ipcc.ch/report/ar6/syr/resources/spm-headline-statements/).

**Evidence locations:** PDF pp. 10–15, scope; Chapters 4–7, event-specific cases and mitigation; pp. 102–103, settlement case; Chapter 8, tests; p. 120, conclusion and the statement checked above.

### 19. B1-108 (2016) — Location of sheath voltage limiters for accessory protection

**Citation key:** `CIGRE_2016_B1_108` · **Source:** [B1-108-2016.pdf][pdf19]

**Contribution and evidence.** Khamlichi and co-authors extend analytical sheath-overvoltage calculations to practical SVL connections at cross-bonded joints, single-point arrangements, GIS terminations and outdoor terminations. They derive expressions for allowable bonding-lead length and compare them with ATP simulations. The distinctive result is that short single-core connections can materially increase the effective inductance of an otherwise concentric bonding lead. In their examples, assuming the ideal concentric value can substantially understate the voltage appearing across protected insulation. The work also reports application of the approach to a review of 158 circuits at 220 and 400 kV, comprising 392 km of cable.

**Use for this project.** Provides a focused extension to TB 283 and useful analytical checks for explicitly modelled SVL leads. It demonstrates why the residual voltage of the SVL alone does not define the voltage imposed on the accessory.

**Limits.** Formulae depend on the assumed travelling waves, lead geometry, protection margins and arrangement. The reported network application is engineering experience, not a controlled experimental verification of every transient case. Connections from the SVL to the station earth system must also be represented.

**Evidence locations:** PDF pp. 1–2, purpose; Sections 2–4, derivations and comparisons; pp. 10–12, lead configurations and conclusions.

### 20. B1-209 (2016) — Sheath currents monitoring in high voltage isolated cables

**Citation key:** `CIGRE_2016_B1_209` · **Source:** [B1-209-2016.pdf][pdf20]

**Contribution and evidence.** Burgos, Donoso and García examine how sheath-current measurements can reveal defects in bonding, earthing, oversheaths and SVLs. They relate expected current patterns to different bonding arrangements and describe the Spanish TSO's monitoring experience, including sensors installed on five Barcelona circuits in 2008. The paper distinguishes occasional measurements, periodic trend analysis and continuous monitoring. Its main contribution is the use of model-informed relationships, including current dependence on cable load, to move beyond simple alarm thresholds.

**Use for this project.** Offers a practical use for steady-state sheath-current calculations: generating normal and faulty reference cases and studying which defects are observable from particular measurements. It also motivates analysis of mixed single-point and cross-bonded circuits, where earth-continuity conductors can create current asymmetry in neighbouring sections.

**Limits.** Detectability depends on the bonding arrangement and fault type; some oversheath defects do not produce a useful change in the measured currents. Automatic interpretation and laboratory characterisation of defect and SVL behaviour were still proposed development work. The paper should not be cited as a fully validated universal fault classifier.

**Evidence locations:** PDF pp. 1–2, contribution; Section 1, current patterns; pp. 8–9, operating experience and remaining development needs.

### 21. B1-215 (2020) — 3D-FEM modelling of losses in armoured submarine power cables and comparison with measurements

**Citation key:** `CIGRE_2020_B1_215` · **Source:** [B1-215 — 3D-FEM losses paper][pdf21]

**Contribution and evidence.** Sturm and co-authors compare three-dimensional finite-element calculations, analytical calculations and measurements for several submarine cable constructions and bonding/armour configurations. The model resolves helical geometry and separates conductor, sheath and armour losses; complex magnetic permeability is used to represent hysteresis. The study also investigates how much cable length must be represented computationally. It demonstrates that sheath losses include eddy-current contributions beyond the losses inferred from net circulating current alone. In one fully armoured, bonded example, total equivalent resistance is 41.3 mΩ/km from FEM and 42.0 mΩ/km measured, compared with 57.7 mΩ/km using the IEC calculation employed in the paper.

**Use for this project.** Provides experimental support for improving loss and impedance calculations for armoured three-core cables, and for testing the physical assumptions behind equivalent tubular representations.

**Limits.** The permeability is treated as constant despite its nonlinear behaviour, conductors are geometrically simplified, and some measured sheath currents remain unexplained. These power-frequency loss comparisons do not by themselves validate a broadband transient model. The IEC comparison refers to the method and editions used in this study.

**Evidence locations:** PDF pp. 1–4, modelling and model length; pp. 7–9, comparisons, Table 2 and conclusions.

### 22. B1-10294 (2022) — Research on large-length 500 kV XLPE insulation AC submarine cable

**Citation key:** `CIGRE_2022_B1_10294` · **Source:** [B1-10294-2022.pdf][pdf22]

**Contribution and evidence.** Zhao and co-authors report manufacturing-process work for a long 500 kV XLPE AC submarine cable with a 1,800 mm² conductor and 31 mm nominal insulation thickness. The contribution is the combination of extrusion cleanliness and process control with a thermal-convection degassing method for long, thick-insulation cable cores. Thermogravimetric analysis, or TGA, is used to examine residual by-products at different insulation depths and degassing times. The reported 10 km case supports the use of this process and measurement approach to assess degassing completion.

**Use for this project.** Provides a manufacturing and insulation-quality perspective that complements network-level overvoltage studies. It explains why cable quality depends on material processing and residual by-products, even when an electrical design and its nominal insulation thickness are satisfactory.

**Limits.** The work is specific to the materials, geometry and production process studied. Reported degassing times cannot be transferred unchanged to other designs. The paper is not a transient-propagation study, and its process-control and TGA results do not establish long-term service reliability across a fleet.

**Evidence locations:** PDF pp. 1–3, project and extrusion controls; Sections 3–4, degassing method and TGA; pp. 6–8, results and conclusion.

### 23. B1-11468 (2024) — Single sheath bonding method to eliminate earth continuity cable

**Citation key:** `CIGRE_2024_B1_11468` · **Source:** [B1-PS1-11468-2024-.pdf][pdf23]

**Contribution and evidence.** Khan evaluates an alternative bonding arrangement in which the centre-phase sheath is bonded at both ends and serves as the metallic return path, while the other sheaths retain single-point-type protection. The case concerns a 132 kV circuit of about 3.4 km, with attention to two sections of the mixed bonding arrangement. Analytical calculations, ATP simulations and site current-injection tests are compared. The paper reports centre-sheath current of about 5.4–6.4% of the expected full-load current and estimated sheath losses below 1 W/m for the studied sections. It also estimates avoided ECC material and installation costs.

**Use for this project.** Supplies a concrete alternative topology for studying current sharing, earthing sensitivity and the balance between normal-operation losses and fault-return duty. It can be compared with conventional single-point and solid bonding in the same model.

**Limits.** Site tests injected approximately 100 A at 50 Hz and scaled the resulting sheath currents to full load; the severe fault cases were simulated. This is not a field validation at full load or fault current. Adoption elsewhere requires its own assessment of fault withstand, earthing, insulation coordination and thermal rating. The environmental savings are estimates, not a complete comparative LCA. For reproduction, note that Section 5 is described as 694 m in the case text but listed as 623 m in Table II.

**Evidence locations:** PDF pp. 5–7, case and test method; pp. 8–10, simulations and comparison; pp. 11–12, assumptions, savings and conclusions.

### 24. C4-309 (2018) — Impact of cable impedance modelling assumptions on harmonic losses in offshore wind power plants

**Citation key:** `CIGRE_2018_C4_309` · **Source:** [C4-309_2018-gustavsen.pdf][pdf24]

**Contribution and evidence.** Kocewiak and Gustavsen connect cable-model detail to system-level harmonic damping. They compare tubular and stranded-wire armour representations, skin-effect-only models, models including proximity effect, and an IEC-based supplier loss representation. Frequency sweeps and harmonic-propagation calculations use a real offshore wind-plant configuration. The study shows that cable resistance and inductance depend strongly on the modelling assumptions. In the illustrated system calculation, offshore-bus voltage THD changes from 0.405% with resistance held at its fundamental-frequency value to 0.288% using the stranded-armour model with skin and proximity effects.

**Use for this project.** A key reference for explaining why accurate frequency-dependent impedance matters beyond power-frequency losses. It connects parameter calculations to resonance damping, harmonic levels and the interpretation of transient response, and works with a full 7 × 7 cable impedance representation before deriving sequence quantities.

**Limits.** These are simulation comparisons, not measured validation of the reported plant THD. In the system-level comparisons, inductance is deliberately held equal between cases to isolate resistance and damping effects. The paper therefore does not simultaneously demonstrate the full resonance-frequency shifts associated with each model's different inductance. Hysteresis modelling is preliminary.

**Evidence locations:** PDF pp. 1–8, model variants; pp. 9–11, controlled system comparisons and Tables 3–4; p. 12, conclusions.

### 25. C4-321 (2020) — Lightning analysis for ±500 kV HVDC XLPE cable systems combined with overhead transmission lines

**Citation key:** `CIGRE_2020_C4_321` · **Source:** [C4-321 — HVDC lightning paper][pdf25]

**Contribution and evidence.** Jung and co-authors apply EMTP to a proposed mixed overhead-line/cable HVDC system, examining shielding failure and backflashover with lightning superimposed on the DC operating voltage. They compare cable sections of 10–40 km, polarity combinations, and cases with and without surge arresters. The calculations illustrate different stresses at the incoming and remote cable terminations as travelling waves reflect and attenuate. For the studied protected cases, the paper reports maxima of 876.3 kV for shielding failure and 1,050 kV for backflashover.

**Use for this project.** Provides a worked example for extending travelling-wave and insulation-coordination studies to HVDC. It highlights the need to preserve the DC initial condition and to model the overhead-line interface, tower earthing, lightning scenario and arresters together with the cable.

**Limits.** The reported voltages are scenario-specific simulation outputs, not universal insulation levels or demonstrated withstand ratings. The paper describes a planned system and future insulation verification. Its length trends and maximum stresses depend on the stated source, grounding, termination and protection assumptions.

**Evidence locations:** PDF pp. 1–5, system and assumptions; pp. 6–7, Tables 2–3; pp. 7–8, conclusions.

### 26. C4-327 (2020) — Experimental investigation of ground return currents and mutual induction in extruded cables

**Citation key:** `CIGRE_2020_C4_327` · **Source:** [C4-327 — ground-return experiment][pdf26]

**Contribution and evidence.** Nauta and co-authors investigate current division between cable screens and earth using approximately 200 m of parallel MV cables, variable terminal earthing and measurements at 40–100 Hz. They compare measured earth currents with a resistive approximation and EMTP predictions. The valuable result is the discrepancy: measured earth currents are consistently below the simulations in the reported cases. For example, with 60 A injection at 50 Hz and 23 Ω total electrode resistance, the measured earth current is 173 mA versus 214 mA simulated. The paper also introduces finite-length mutual-inductance theory and documents the experimental arrangements.

**Use for this project.** A useful source for testing assumptions about earth-return modelling, terminal electrodes and finite cable length. It illustrates why a successful numerical calculation does not establish agreement with a physical installation.

**Limits.** The induced-voltage measurements used the wrong reference and were explicitly withheld. Consequently, the supplied paper does not validate the mutual-induction voltage predictions. High terminal electrode resistances dominate the short test circuit, and the causes of the current discrepancies remain unresolved. The text also gives 9.9 Ω in Table 1 but 8.9 Ω in subsequent result tables for one arrangement; that case requires clarification before exact reproduction.

**Evidence locations:** PDF pp. 3–7, theory, setup and measurement issue; pp. 8–9, comparisons, Tables 2–5 and conclusions.

## Synthesis for cable and transient studies

### The principal technical sequence

A productive reading sequence within this collection is **TB 556 → TB 189 → TB 283 → TB 347 → TB 797**. TB 556 defines the system studies and modelling choices; TB 189 connects overvoltages to insulation coordination; TB 283 supplies bonding calculations; TB 347 develops the earth-potential-rise analysis; and TB 797 connects these methods to component qualification and maintenance. This is a suggested learning sequence, not a claim that later documents reproduce all earlier material.

For detailed parameter work, add **C4-309 (2018)** and **B1-215 (2020)**. The former demonstrates the importance of impedance assumptions for harmonic damping; the latter provides measurement comparisons for component losses. **C4-327 (2020)** is particularly useful as a case where disagreement with measurements remains and the experimental limitations are openly documented.

### Findings that should not be conflated

- **Power-frequency loss and harmonic damping are different comparisons.** B1-215 finds that the IEC calculation used in its cases often overestimates total losses, particularly armour losses. C4-309 finds that the IEC-based supplier representation underestimates resistance at higher harmonic frequencies. These findings concern different models, constructions and frequency regimes; they do not justify one universal correction factor.
- **A bonding arrangement is not a complete protection design.** TB 283, TB 347, TB 797 and B1-108 collectively show that earth impedances, return-path discontinuities, lead inductance, SVL connections and fault location determine actual insulation stress.
- **First-peak accuracy is not waveform accuracy.** TB 556's qualified use of simpler distributed models should not be read as evidence that frequency dependence is dispensable when matching damping, multiple reflections or measured waveforms.
- **Loss reduction is not a complete environmental assessment.** TB 689 requires consistent function, boundaries and operating assumptions. The material-saving estimate in B1-11468 addresses only part of that comparison.
- **Survey statistics are not interchangeable.** TB 379 and TB 815 differ in periods, coverage and populations. Their failure counts, component rates, repair times and age distributions answer different questions and should retain their denominators and definitions.
- **Instrumentation is not an automatically validated diagnosis.** TB 899 addresses the fibre infrastructure; B1-209 develops the interpretation of sheath currents. Reliable diagnosis additionally requires calibrated measurements, identifiable fault signatures and validation of the interpretation method.

### Candidate uses in this repository

The following are proposed uses of the literature, not claims that the repository already implements or passes these checks:

| Candidate study | Reference support | What it would establish |
|---|---|---|
| Check power-frequency self, mutual and sequence parameters | TB 283, TB 556 | Consistency of calculated cable parameters and their network reduction under stated assumptions. |
| Compare first peaks, travelling-wave timing and later damping | TB 556, C4-309 | Whether model simplifications affect different waveform features differently. |
| Vary cross-bonding section lengths, earthing and metallic return paths | TB 283, TB 347, TB 797 | Sensitivity of sheath currents and insulation stresses to topology and boundary conditions. |
| Include finite SVL leads and their earthing connections | B1-108, TB 283 | The difference between SVL residual voltage and the voltage imposed on the protected accessory. |
| Compare armoured-cable loss representations | B1-215, C4-309 | The effect of skin, proximity, eddy-current and magnetic-loss assumptions in their appropriate frequency ranges. |
| Reproduce a documented experimental discrepancy | C4-327 | Whether the model reproduces the published simulation and what further data are needed to approach the measurements. |
| Explore alternative bonding and diagnostic signatures | B1-11468, B1-209 | How topology and faults change currents, and which measured quantities could distinguish those changes. |

The remaining references supply the practical context needed to interpret such studies: installation feasibility, manufacturing quality, service experience, maintenance priorities and resilience. Together, they support a cable-system treatment that connects electromagnetic calculations to the physical installation and its operational consequences.

[pdf01]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/189.pdf>
[pdf02]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/194.pdf>
[pdf03]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/199.pdf>
[pdf04]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/250.pdf>
[pdf05]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/283.pdf>
[pdf06]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/338.pdf>
[pdf07]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/347.pdf>
[pdf08]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/358.pdf>
[pdf09]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/379.pdf>
[pdf10]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/398.pdf>
[pdf11]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/556.pdf>
[pdf12]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/559.pdf>
[pdf13]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/689.pdf>
[pdf14]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/797.pdf>
[pdf15]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/815.pdf>
[pdf16]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/889.pdf>
[pdf17]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/899.pdf>
[pdf18]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/959.pdf>
[pdf19]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/B1-108-2016.pdf>
[pdf20]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/B1-209-2016.pdf>
[pdf21]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/B1-215--3D-FEM modelling of losses in armoured submarine power cables and comparison with measurements.pdf>
[pdf22]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/B1-10294-2022.pdf>
[pdf23]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/B1-PS1-11468-2024-.pdf>
[pdf24]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/C4-309_2018-gustavsen.pdf>
[pdf25]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/C4-321--Lightning Analysis for ±500kV HVDC XLPE Cable System Combined with Overhead with Overhead Transmission Lines.pdf>
[pdf26]: </Users/acsl/Library/CloudStorage/Dropbox/01_em_andamento/cp_livro_cabos/refs/C4-327--Experimental Investigation of Ground Return Currents and Mutual Induction in Extruded Cables.pdf>
