if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("n_non_na_before", "n_replaced"))
}

# --- INTERNAL: PRM rules (single source of truth) -----------------------------
.prm_rules <- function() {
  list(
    "^COND_WATER($|_)" = c(0, 10000),           # uS cm^-1
    "^DO($|_)"         = c(0, NA_real_),        # umol L^-1
    "^PCH4($|_)"       = c(0, NA_real_),        # nmolCH4 mol^-1
    "^PCO2($|_)"       = c(0, 10000),           # umolCO2 mol^-1
    "^PN2O($|_)"       = c(0, NA_real_),        # nmolN2O mol^-1
    "^PPFD_UW_IN($|_)" = c(0, 2400),            # umolPhotons m^-2 s^-1
    "^TW($|_)"         = c(-20, 50),            # deg C
    "^DBH($|_)"        = c(0, 500),             # cm
    "^LEAF_WET($|_)"   = c(0, 100),             # %
    "^SAP_DT($|_)"     = c(-10, 10),            # deg C
    "^T_BOLE($|_)"     = c(-50, 70),            # deg C
    "^T_CANOPY($|_)"   = c(-50, 70),            # deg C
    "^CH4($|_)"              = c(0, 15000),     # nmolCH4 mol^-1
    "^CH4_MIXING_RATIO($|_)" = c(0, 15000),     # nmolCH4 mol^-1
    "^CO($|_)"               = c(0, NA_real_),  # nmolCO mol^-1
    "^CO2($|_)"              = c(150, 1200),    # umolCO2 mol^-1
    "^CO2_MIXING_RATIO($|_)" = c(150, 1200),    # umolCO2 mol^-1
    "^CO2_SIGMA($|_)"        = c(0, 150),       # umolCO2 mol^-1
    "^CO2C13($|_)"           = c(NA_real_, -6), # permil
    "^FC($|_)"   = c(-100, 100),                # umolCO2 m^-2 s^-1
    "^FCH4($|_)" = c(-500, 4000),               # nmolCH4 m^-2 s^-1
    "^H2O($|_)"              = c(0, 100),       # mmolH2O mol^-1
    "^H2O_MIXING_RATIO($|_)" = c(0, 100),       # mmolH2O mol^-1
    "^H2O_SIGMA($|_)"        = c(0, 15),        # mmolH2O mol^-1
    "^N2O($|_)"              = c(0, NA_real_),  # nmolN2O mol^-1
    "^N2O_MIXING_RATIO($|_)" = c(0, NA_real_),  # nmolN2O mol^-1
    "^NO($|_)"               = c(0, NA_real_),  # nmolNO mol^-1
    "^NO2($|_)"              = c(0, NA_real_),  # nmolNO2 mol^-1
    "^O3($|_)"               = c(0, NA_real_),  # nmolO3 mol^-1
    "^SC($|_)"   = c(-100, 100),                # umolCO2 m^-2 s^-1
    "^SO2($|_)"  = c(0, NA_real_),              # nmolSO2 mol^-1
    "^FH2O($|_)" = c(-10, 20),                  # mmolH2O m^-2 s^-1
    "^G($|_)"    = c(-250, 400),                # W m^-2
    "^H($|_)"    = c(-450, 900),                # W m^-2
    "^LE($|_)"   = c(-450, 900),                # W m^-2
    "^SG($|_)"   = c(-100, 250),                # W m^-2
    "^SH($|_)"   = c(-150, 150),                # W m^-2
    "^SLE($|_)"  = c(-150, 150),                # W m^-2
    "^PA($|_)"            = c(60, 105),         # kPa
    "^PBLH($|_)"          = c(0, 3000),         # m
    "^RH($|_)"            = c(0, 100),          # %
    "^T_SONIC($|_)"       = c(-50, 50),         # deg C
    "^T_SONIC_SIGMA($|_)" = c(0, 5),            # deg C
    "^TA($|_)"            = c(-50, 50),         # deg C
    "^VPD($|_)"           = c(0, 80),           # hPa
    "^D_SNOW($|_)"        = c(0, 500),          # cm
    "^P($|_)"        = c(0, 50),                # mm
    "^P_RAIN($|_)"   = c(0, 50),                # mm
    "^P_SNOW($|_)"   = c(0, 50),                # mm
    "^RUNOFF($|_)"   = c(0, 200),               # mm
    "^STEMFLOW($|_)" = c(0, 200),               # mm
    "^THROUGHFALL($|_)" = c(0, 20),             # mm
    "^ALB($|_)"  = c(0, 100),                   # %
    "^APAR($|_)" = c(0, 2300),                  # umolPhoton m^-2 s^-1
    "^EVI($|_)"  = c(-1, 1),                    # nondimensional
    "^FAPAR($|_)"= c(0, 100),                   # %
    "^FIPAR($|_)"= c(0, 100),                   # %
    "^LW_BC_IN($|_)"  = c(50, 600),             # W m^-2
    "^LW_BC_OUT($|_)" = c(100, 750),            # W m^-2
    "^LW_IN($|_)"     = c(50, 600),             # W m^-2
    "^LW_OUT($|_)"    = c(100, 750),            # W m^-2
    "^MCRI($|_)"  = c(0, 10),                   # nondimensional
    "^MTCI($|_)"  = c(0, 10),                   # nondimensional
    "^NDVI($|_)"  = c(-1, 1),                   # nondimensional
    "^NETRAD($|_)"= c(-200, 1100),              # W m^-2
    "^NIRV($|_)"  = c(0, 2),                    # W m^-2 sr^-1 nm^-1
    "^PPFD_BC_IN($|_)"  = c(0, 2400),           # umolPhoton m^-2 s^-1
    "^PPFD_BC_OUT($|_)" = c(0, 2000),           # umolPhoton m^-2 s^-1
    "^PPFD_DIF($|_)"    = c(0, 1400),           # umolPhoton m^-2 s^-1
    "^PPFD_DIR($|_)"    = c(0, 2400),           # umolPhoton m^-2 s^-1
    "^PPFD_IN($|_)"     = c(0, 2400),           # umolPhoton m^-2 s^-1
    "^PPFD_OUT($|_)"    = c(0, 2000),           # umolPhoton m^-2 s^-1
    "^PRI($|_)"   = c(-1, 1),                   # nondimensional
    "^R_UVA($|_)" = c(0, 85),                   # W m^-2
    "^R_UVB($|_)" = c(0, 20),                   # W m^-2
    "^REDCI($|_)" = c(0, 10),                   # nondimensional
    "^REP($|_)"   = c(400, 800),                 # nm
    "^SPEC_NIR_IN($|_)"       = c(0, 2),        # W m^-2 nm^-1
    "^SPEC_NIR_OUT($|_)"      = c(0, 2),        # W m^-2 sr^-1 nm^-1
    "^SPEC_NIR_REFL($|_)"     = c(0, 1),        # nondimensional
    "^SPEC_PRI_REF_IN($|_)"   = c(0, 2),        # W m^-2 nm^-1
    "^SPEC_PRI_REF_OUT($|_)"  = c(0, 2),        # W m^-2 sr^-1 nm^-1
    "^SPEC_PRI_REF_REFL($|_)" = c(0, 1),        # nondimensional
    "^SPEC_PRI_TGT_IN($|_)"   = c(0, 2),        # W m^-2 nm^-1
    "^SPEC_PRI_TGT_OUT($|_)"  = c(0, 2),        # W m^-2 sr^-1 nm^-1
    "^SPEC_PRI_TGT_REFL($|_)" = c(0, 1),        # nondimensional
    "^SPEC_RED_IN($|_)"       = c(0, 2),        # W m^-2 nm^-1
    "^SPEC_RED_OUT($|_)"      = c(0, 2),        # W m^-2 sr^-1 nm^-1
    "^SPEC_RED_REFL($|_)"     = c(0, 1),        # nondimensional
    "^SR($|_)" = c(0, 10),                      # nondimensional
    "^SW_BC_IN($|_)" = c(0, 1300),              # W m^-2
    "^SW_BC_OUT($|_)"= c(0, 800),               # W m^-2
    "^SW_DIF($|_)"   = c(0, 750),               # W m^-2
    "^SW_DIR($|_)"   = c(0, 1300),              # W m^-2
    "^SW_IN($|_)"    = c(0, 1300),              # W m^-2
    "^SW_OUT($|_)"   = c(0, 800),               # W m^-2
    "^TCARI($|_)" = c(0, 10),                   # nondimensional
    "^SWC($|_)" = c(0, 100),                    # %
    "^SWP($|_)" = c(-750, 0),                   # kPa
    "^TS($|_)"  = c(-40, 65),                   # deg C
    "^TSN($|_)" = c(-40, 4),                    # deg C
    "^WTD($|_)" = c(-10, 10),                   # m
    "^TAU($|_)"       = c(-10, 2),              # kg m^-1 s^-2
    "^U_SIGMA($|_)"   = c(0, 12),               # m s^-1
    "^USTAR($|_)"     = c(0, 8),                # m s^-1
    "^V_SIGMA($|_)"   = c(0, 10),               # m s^-1
    "^W_SIGMA($|_)"   = c(0, 5),                # m s^-1
    "^WD($|_)"        = c(0, 360),              # degree
    "^WD_SIGMA($|_)"  = c(0, 180),              # degree
    "^WS($|_)"        = c(0, 40),               # m s^-1
    "^WS_MAX($|_)"    = c(0, 50),               # m s^-1
    "^GPP($|_)"  = c(-30, 100),                 # umolCO2 m^-2 s^-1
    "^NEE($|_)"  = c(-100, 100),                # umolCO2 m^-2 s^-1
    "^RECO($|_)" = c(-20, 50)                   # umolCO2 m^-2 s^-1
  )
}

# --- INTERNAL: PRM units (ASCII) ---------------------------------------------
.prm_units <- function() {
  c(
    "^COND_WATER($|_)" = "uS cm^-1",
    "^DO($|_)"         = "umol L^-1",
    "^PCH4($|_)"       = "nmolCH4 mol^-1",
    "^PCO2($|_)"       = "umolCO2 mol^-1",
    "^PN2O($|_)"       = "nmolN2O mol^-1",
    "^PPFD_UW_IN($|_)" = "umolPhotons m^-2 s^-1",
    "^TW($|_)"         = "deg C",
    "^DBH($|_)"        = "cm",
    "^LEAF_WET($|_)"   = "%",
    "^SAP_DT($|_)"     = "deg C",
    "^SAP_FLOW($|_)"   = "mmolH2O m^-2 s^-1",
    "^T_BOLE($|_)"     = "deg C",
    "^T_CANOPY($|_)"   = "deg C",
    "^CH4($|_)"              = "nmolCH4 mol^-1",
    "^CH4_MIXING_RATIO($|_)" = "nmolCH4 mol^-1",
    "^CO($|_)"               = "nmolCO mol^-1",
    "^CO2($|_)"              = "umolCO2 mol^-1",
    "^CO2_MIXING_RATIO($|_)" = "umolCO2 mol^-1",
    "^CO2_SIGMA($|_)"        = "umolCO2 mol^-1",
    "^CO2C13($|_)"           = "permil",
    "^FC($|_)"   = "umolCO2 m^-2 s^-1",
    "^FCH4($|_)" = "nmolCH4 m^-2 s^-1",
    "^FN2O($|_)" = "nmolN2O m^-2 s^-1",
    "^FNO($|_)"  = "nmolNO m^-2 s^-1",
    "^FNO2($|_)" = "nmolNO2 m^-2 s^-1",
    "^FO3($|_)"  = "nmolO3 m^-2 s^-1",
    "^H2O($|_)"              = "mmolH2O mol^-1",
    "^H2O_MIXING_RATIO($|_)" = "mmolH2O mol^-1",
    "^H2O_SIGMA($|_)"        = "mmolH2O mol^-1",
    "^N2O($|_)"              = "nmolN2O mol^-1",
    "^N2O_MIXING_RATIO($|_)" = "nmolN2O mol^-1",
    "^NO($|_)"               = "nmolNO mol^-1",
    "^NO2($|_)"              = "nmolNO2 mol^-1",
    "^O3($|_)"               = "nmolO3 mol^-1",
    "^SC($|_)"   = "umolCO2 m^-2 s^-1",
    "^SCH4($|_)" = "nmolCH4 m^-2 s^-1",
    "^SN2O($|_)" = "nmolN2O m^-2 s^-1",
    "^SNO($|_)"  = "nmolNO m^-2 s^-1",
    "^SNO2($|_)" = "nmolNO2 m^-2 s^-1",
    "^SO2($|_)"  = "nmolSO2 mol^-1",
    "^SO3($|_)"  = "nmolO3 m^-2 s^-1",
    "^FH2O($|_)" = "mmolH2O m^-2 s^-1",
    "^G($|_)"    = "W m^-2",
    "^H($|_)"    = "W m^-2",
    "^LE($|_)"   = "W m^-2",
    "^SB($|_)"   = "W m^-2",
    "^SG($|_)"   = "W m^-2",
    "^SH($|_)"   = "W m^-2",
    "^SLE($|_)"  = "W m^-2",
    "^PA($|_)"            = "kPa",
    "^PBLH($|_)"          = "m",
    "^RH($|_)"            = "%",
    "^T_SONIC($|_)"       = "deg C",
    "^T_SONIC_SIGMA($|_)" = "deg C",
    "^TA($|_)"            = "deg C",
    "^VPD($|_)"           = "hPa",
    "^D_SNOW($|_)"        = "cm",
    "^P($|_)"        = "mm",
    "^P_RAIN($|_)"   = "mm",
    "^P_SNOW($|_)"   = "mm",
    "^RUNOFF($|_)"   = "mm",
    "^STEMFLOW($|_)" = "mm",
    "^THROUGHFALL($|_)" = "mm",
    "^ALB($|_)"  = "%",
    "^APAR($|_)" = "umolPhoton m^-2 s^-1",
    "^EVI($|_)"  = "nondimensional",
    "^FAPAR($|_)"= "%",
    "^FIPAR($|_)"= "%",
    "^LW_BC_IN($|_)"  = "W m^-2",
    "^LW_BC_OUT($|_)" = "W m^-2",
    "^LW_IN($|_)"     = "W m^-2",
    "^LW_OUT($|_)"    = "W m^-2",
    "^MCRI($|_)"  = "nondimensional",
    "^MTCI($|_)"  = "nondimensional",
    "^NDVI($|_)"  = "nondimensional",
    "^NETRAD($|_)"= "W m^-2",
    "^NIRV($|_)"  = "W m^-2 sr^-1 nm^-1",
    "^PPFD_BC_IN($|_)"  = "umolPhoton m^-2 s^-1",
    "^PPFD_BC_OUT($|_)" = "umolPhoton m^-2 s^-1",
    "^PPFD_DIF($|_)"    = "umolPhoton m^-2 s^-1",
    "^PPFD_DIR($|_)"    = "umolPhoton m^-2 s^-1",
    "^PPFD_IN($|_)"     = "umolPhoton m^-2 s^-1",
    "^PPFD_OUT($|_)"    = "umolPhoton m^-2 s^-1",
    "^PRI($|_)"   = "nondimensional",
    "^R_UVA($|_)" = "W m^-2",
    "^R_UVB($|_)" = "W m^-2",
    "^REDCI($|_)" = "nondimensional",
    "^REP($|_)"   = "nm",
    "^SPEC_NIR_IN($|_)"       = "W m^-2 nm^-1",
    "^SPEC_NIR_OUT($|_)"      = "W m^-2 sr^-1 nm^-1",
    "^SPEC_NIR_REFL($|_)"     = "nondimensional",
    "^SPEC_PRI_REF_IN($|_)"   = "W m^-2 nm^-1",
    "^SPEC_PRI_REF_OUT($|_)"  = "W m^-2 sr^-1 nm^-1",
    "^SPEC_PRI_REF_REFL($|_)" = "nondimensional",
    "^SPEC_PRI_TGT_IN($|_)"   = "W m^-2 nm^-1",
    "^SPEC_PRI_TGT_OUT($|_)"  = "W m^-2 sr^-1 nm^-1",
    "^SPEC_PRI_TGT_REFL($|_)" = "nondimensional",
    "^SPEC_RED_IN($|_)"       = "W m^-2 nm^-1",
    "^SPEC_RED_OUT($|_)"      = "W m^-2 sr^-1 nm^-1",
    "^SPEC_RED_REFL($|_)"     = "nondimensional",
    "^SR($|_)" = "nondimensional",
    "^SW_BC_IN($|_)" = "W m^-2",
    "^SW_BC_OUT($|_)"= "W m^-2",
    "^SW_DIF($|_)"   = "W m^-2",
    "^SW_DIR($|_)"   = "W m^-2",
    "^SW_IN($|_)"    = "W m^-2",
    "^SW_OUT($|_)"   = "W m^-2",
    "^TCARI($|_)" = "nondimensional",
    "^SWC($|_)" = "%",
    "^SWP($|_)" = "kPa",
    "^TS($|_)"  = "deg C",
    "^TSN($|_)" = "deg C",
    "^WTD($|_)" = "m",
    "^TAU($|_)"       = "kg m^-1 s^-2",
    "^U_SIGMA($|_)"   = "m s^-1",
    "^USTAR($|_)"     = "m s^-1",
    "^V_SIGMA($|_)"   = "m s^-1",
    "^W_SIGMA($|_)"   = "m s^-1",
    "^WD($|_)"        = "degree",
    "^WD_SIGMA($|_)"  = "degree",
    "^WS($|_)"        = "m s^-1",
    "^WS_MAX($|_)"    = "m s^-1",
    "^GPP($|_)"  = "umolCO2 m^-2 s^-1",
    "^NEE($|_)"  = "umolCO2 m^-2 s^-1",
    "^RECO($|_)" = "umolCO2 m^-2 s^-1"
  )
}


# --- INTERNAL: PRM descriptions (from AmeriFlux Tech Note, Table A1) ----------
.prm_desc <- function() {
  c(
    "^COND_WATER($|_)" = "Conductivity of water",
    "^DO($|_)"         = "Dissolved oxygen in water",
    "^PCH4($|_)"       = "Dissolved methane (CH4) in water",
    "^PCO2($|_)"       = "Dissolved carbon dioxide (CO2) in water",
    "^PN2O($|_)"       = "Dissolved nitrous oxide (N2O) in water",
    "^PPFD_UW_IN($|_)" = "Photosynthetic photon flux density, underwater, incoming",
    "^TW($|_)"         = "Water temperature",
    "^DBH($|_)"        = "Tree diameter at breast height",
    "^LEAF_WET($|_)"   = "Leaf wetness (0-100)",
    "^SAP_DT($|_)"     = "Sapflow probe temperature difference",
    "^T_BOLE($|_)"     = "Bole temperature",
    "^T_CANOPY($|_)"   = "Canopy/surface temperature",
    "^CH4($|_)"              = "Methane (CH4) mole fraction (wet air)",
    "^CH4_MIXING_RATIO($|_)" = "Methane (CH4) mole fraction (dry air)",
    "^CO($|_)"               = "Carbon monoxide (CO) mole fraction (wet air)",
    "^CO2($|_)"              = "Carbon dioxide (CO2) mole fraction (wet air)",
    "^CO2_MIXING_RATIO($|_)" = "Carbon dioxide (CO2) mole fraction (dry air)",
    "^CO2_SIGMA($|_)"        = "Std. dev. of CO2 mole fraction (wet air)",
    "^CO2C13($|_)"           = "Stable isotope delta13C of CO2 (permil)",
    "^FC($|_)"   = "CO2 turbulent flux (no storage correction)",
    "^FCH4($|_)" = "CH4 turbulent flux (no storage correction)",
    "^H2O($|_)"              = "Water vapor in mole fraction (wet air)",
    "^H2O_MIXING_RATIO($|_)" = "Water vapor in mole fraction (dry air)",
    "^H2O_SIGMA($|_)"        = "Std. dev. of water vapor mole fraction",
    "^N2O($|_)"              = "N2O mole fraction (wet air)",
    "^N2O_MIXING_RATIO($|_)" = "N2O mole fraction (dry air)",
    "^NO($|_)"               = "NO mole fraction (wet air)",
    "^NO2($|_)"              = "NO2 mole fraction (wet air)",
    "^O3($|_)"               = "O3 mole fraction (wet air)",
    "^SC($|_)"   = "CO2 storage flux",
    "^SO2($|_)"  = "SO2 mole fraction (wet air)",
    "^FH2O($|_)" = "Water vapor (H2O) turbulent flux (no storage correction)",
    "^G($|_)"    = "Soil heat flux",
    "^H($|_)"    = "Sensible heat flux (no storage correction)",
    "^LE($|_)"   = "Latent heat flux (no storage correction)",
    "^SG($|_)"   = "Soil heat storage flux above plates",
    "^SH($|_)"   = "Sensible heat storage flux",
    "^SLE($|_)"  = "Latent heat storage flux",
    "^PA($|_)"            = "Atmospheric pressure",
    "^PBLH($|_)"          = "Planetary boundary layer height",
    "^RH($|_)"            = "Relative humidity (0-100)",
    "^T_SONIC($|_)"       = "Sonic temperature",
    "^T_SONIC_SIGMA($|_)" = "Std. dev. of sonic temperature",
    "^TA($|_)"            = "Air temperature",
    "^VPD($|_)"           = "Vapor pressure deficit",
    "^D_SNOW($|_)"        = "Snow depth",
    "^P($|_)"        = "Precipitation",
    "^P_RAIN($|_)"   = "Rainfall",
    "^P_SNOW($|_)"   = "Snowfall",
    "^RUNOFF($|_)"   = "Runoff",
    "^STEMFLOW($|_)" = "Stemflow",
    "^THROUGHFALL($|_)" = "Throughfall",
    "^ALB($|_)"  = "Albedo (0-100)",
    "^APAR($|_)" = "Absorbed PAR",
    "^EVI($|_)"  = "Enhanced Vegetation Index",
    "^FAPAR($|_)"= "Fraction of absorbed PAR (0-100)",
    "^FIPAR($|_)"= "Fraction of intercepted PAR (0-100)",
    "^LW_BC_IN($|_)"  = "Longwave radiation, below canopy incoming",
    "^LW_BC_OUT($|_)" = "Longwave radiation, below canopy outgoing",
    "^LW_IN($|_)"     = "Longwave radiation, incoming",
    "^LW_OUT($|_)"    = "Longwave radiation, outgoing",
    "^MCRI($|_)"  = "Carotenoid Reflectance Index",
    "^MTCI($|_)"  = "MERIS Terrestrial Chlorophyll Index",
    "^NDVI($|_)"  = "Normalized Difference Vegetation Index",
    "^NETRAD($|_)"= "Net radiation",
    "^NIRV($|_)"  = "Near Infrared Vegetation Index",
    "^PPFD_BC_IN($|_)"  = "PPFD, below canopy incoming",
    "^PPFD_BC_OUT($|_)" = "PPFD, below canopy outgoing",
    "^PPFD_DIF($|_)"    = "PPFD, diffuse incoming",
    "^PPFD_DIR($|_)"    = "PPFD, direct incoming",
    "^PPFD_IN($|_)"     = "PPFD, incoming",
    "^PPFD_OUT($|_)"    = "PPFD, outgoing",
    "^PRI($|_)"   = "Photochemical Reflectance Index",
    "^R_UVA($|_)" = "UVA radiation, incoming",
    "^R_UVB($|_)" = "UVB radiation, incoming",
    "^REDCI($|_)" = "Red-Edge Chlorophyll Index",
    "^REP($|_)"   = "Red-Edge Position",
    "^SPEC_NIR_IN($|_)"       = "NIR band radiation, incoming (hemispherical)",
    "^SPEC_NIR_OUT($|_)"      = "NIR band radiation, outgoing",
    "^SPEC_NIR_REFL($|_)"     = "NIR band reflectance",
    "^SPEC_PRI_REF_IN($|_)"   = "PRI reference band radiation, incoming",
    "^SPEC_PRI_REF_OUT($|_)"  = "PRI reference band radiation, outgoing",
    "^SPEC_PRI_REF_REFL($|_)" = "PRI reference band reflectance",
    "^SPEC_PRI_TGT_IN($|_)"   = "PRI target band radiation, incoming",
    "^SPEC_PRI_TGT_OUT($|_)"  = "PRI target band radiation, outgoing",
    "^SPEC_PRI_TGT_REFL($|_)" = "PRI target band reflectance",
    "^SPEC_RED_IN($|_)"       = "Red band radiation, incoming (hemispherical)",
    "^SPEC_RED_OUT($|_)"      = "Red band radiation, outgoing",
    "^SPEC_RED_REFL($|_)"     = "Red band reflectance",
    "^SR($|_)" = "Simple Ratio",
    "^SW_BC_IN($|_)" = "Shortwave radiation, below canopy incoming",
    "^SW_BC_OUT($|_)"= "Shortwave radiation, below canopy outgoing",
    "^SW_DIF($|_)"   = "Shortwave radiation, diffuse incoming",
    "^SW_DIR($|_)"   = "Shortwave radiation, direct incoming",
    "^SW_IN($|_)"    = "Shortwave radiation, incoming",
    "^SW_OUT($|_)"   = "Shortwave radiation, outgoing",
    "^TCARI($|_)" = "Transformed Chlorophyll Absorption in Reflectance Index",
    "^SWC($|_)" = "Soil water content (volumetric, 0-100)",
    "^SWP($|_)" = "Soil water potential",
    "^TS($|_)"  = "Soil temperature",
    "^TSN($|_)" = "Snow temperature",
    "^WTD($|_)" = "Water table depth",
    "^TAU($|_)"       = "Momentum flux",
    "^U_SIGMA($|_)"   = "Std. dev. of along-wind velocity",
    "^USTAR($|_)"     = "Friction velocity",
    "^V_SIGMA($|_)"   = "Std. dev. of cross-wind velocity",
    "^W_SIGMA($|_)"   = "Std. dev. of vertical velocity",
    "^WD($|_)"        = "Wind direction",
    "^WD_SIGMA($|_)"  = "Std. dev. of wind direction",
    "^WS($|_)"        = "Wind speed",
    "^WS_MAX($|_)"    = "Max wind speed in averaging period",
    "^GPP($|_)"  = "Gross primary productivity",
    "^NEE($|_)"  = "Net ecosystem exchange",
    "^RECO($|_)" = "Ecosystem respiration"
  )
}


# --- EXPORTED: rules tibble for vignettes/docs --------------------------------
#' Get the PRM rules as a tibble (for vignettes & checks)
#' @return A tibble with columns: family (regex), variable (base), min, max, units, description
#' @export
get_prm_rules <- function() {
  rl <- .prm_rules()
  un <- .prm_units()
  de <- .prm_desc()

  fam  <- names(rl)                                   # regex, e.g. ^SWC($|_)
  base <- sub("^\\^(.+)\\(\\$\\|_\\)$", "\\1", fam)   # SWC

  tibble::tibble(
    family      = fam,  # keep for compatibility
    variable    = base,
    min         = unname(vapply(rl, function(x) as.numeric(x[1]), numeric(1))),
    max         = unname(vapply(rl, function(x) as.numeric(x[2]), numeric(1))),
    description = unname(de[fam]),
    units       = unname(un[fam])
  )
}


# --- EXPORTED: main function ---------------------------------------------------

#' Apply Physical Range Module (PRM) bounds to AmeriFlux-style data
#'
#' Clamps values to PRM ranges by variable *family* (e.g., `^SWC($|_)`, `^P($|_)`).
#' Columns with "QC" in their names are skipped by default. Out-of-range values
#' are set to `NA`. No columns are removed.
#'
#' @param .data A data.frame or tibble.
#' @param include Optional character vector of base family names to apply (e.g., "SWC", "P").
#'   If `NULL`, all families are applied.
#' @param skip_qc Logical; when TRUE, skip columns that look like flags:
#'   names ending/containing `_QC` or `_SSITC_TEST` (case-insensitive).
#'   Default: TRUE.
#' @param note Logical; print a per-column summary with expected units, PRM range, and counts.
#' @param summarize Logical; if `TRUE`, return a list with `data` and `summary`; otherwise return only the clamped data frame.
#'
#' @return If `summarize = TRUE`, a list with `data` and `summary`; else a data.frame.
#' @export
apply_prm <- function(.data,
                      include   = NULL,
                      skip_qc   = TRUE,
                      note      = TRUE,
                      summarize = TRUE) {

  stopifnot(is.data.frame(.data))
  rules <- .prm_rules()

  if (!is.null(include)) {
    stopifnot(is.character(include))
    base <- sub("^\\^(.+)\\(\\$\\|_\\)$", "\\1", names(rules))
    keep <- base %in% unique(include)
    rules <- rules[keep]
  }

  before  <- .data
  applied <- list()

  for (pat in names(rules)) {
    lim   <- rules[[pat]]
    min_v <- lim[1]; max_v <- lim[2]
    cols  <- grep(pat, names(.data), value = TRUE)

    if (skip_qc) {
      cols <- cols[!grepl("(^|_)QC($|_)",    cols, ignore.case = TRUE)]
      cols <- cols[!grepl("SSITC_TEST($|_)", cols, ignore.case = TRUE)]
    }
    if (!length(cols)) next

    family_name <- sub("^\\^(.+)\\(\\$\\|_\\)$", "\\1", pat)

    for (col in cols) {
      x <- suppressWarnings(as.numeric(.data[[col]]))

      keep <- !is.na(x)
      if (!is.na(min_v)) keep <- keep & x >= min_v
      if (!is.na(max_v)) keep <- keep & x <= max_v
      x[!keep] <- NA_real_
      .data[[col]] <- x

      b <- suppressWarnings(as.numeric(before[[col]]))
      applied[[length(applied) + 1L]] <- data.frame(
        column           = col,
        family           = family_name,
        min              = min_v,
        max              = max_v,
        n_non_na_before  = sum(!is.na(b)),
        n_replaced       = sum(is.na(x) & !is.na(b)),
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(applied)) {
    summ <- dplyr::bind_rows(applied) |>
      dplyr::mutate(
        pct_replaced = ifelse(n_non_na_before > 0, 100 * n_replaced / n_non_na_before, 0)
      ) |>
      dplyr::arrange(dplyr::desc(n_replaced))

    # ▶ If nothing was replaced anywhere, print the “no replacements” message
    #   and return an EMPTY summary tibble.
    if (all(summ$n_replaced == 0L)) {
      if (note) message("PRM: no replacements made.")
      summ <- tibble::tibble(
        column = character(), family = character(),
        min = numeric(), max = numeric(),
        n_non_na_before = integer(), n_replaced = integer(), pct_replaced = numeric()
      )

    } else if (note) {
      # ▶ Only print the per-column notes when there WAS at least one replacement.
      u_vec  <- .prm_units()
      base_u <- u_vec
      names(base_u) <- sub("^\\^(.+)\\(\\$\\|_\\)$", "\\1", names(u_vec))

      fmt <- function(z) ifelse(is.na(z), "NA", as.character(z))
      lines <- mapply(function(col, fam, lo, hi, nrep, pct) {
        paste0(
          "* ", col, "\n",
          "  expected units: ", base_u[[fam]], ", PRM range: ", fmt(lo), " to ", fmt(hi), "\n",
          "  ", nrep, " values set to NA (", sprintf("%.1f", pct), "% of data)"
        )
      },
      summ$column, summ$family, summ$min, summ$max, summ$n_replaced, summ$pct_replaced,
      SIMPLIFY = TRUE)

      message("PRM summary:\n", paste(lines, collapse = "\n"))
    }

  } else {
    # ▶ No matching columns at all
    summ <- tibble::tibble(
      column = character(), family = character(),
      min = numeric(), max = numeric(),
      n_non_na_before = integer(), n_replaced = integer(), pct_replaced = numeric()
    )
    if (note) message("PRM: no replacements made.")
  }

  # ▶ Make the returns explicit and LAST. Nothing after this.
  if (!summarize) return(.data)
  return(list(data = .data, summary = summ))
}
