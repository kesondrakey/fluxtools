# R/zzz.R

.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion(pkgname)
  packageStartupMessage("Welcome to fluxtools!")
  packageStartupMessage("Version: ", version)

  packageStartupMessage("\nTo start the app, use 'run_flux_qaqc(offset)', where 'offset' is your UTC time offset:")
  packageStartupMessage("run_flux_qaqc(-5) #for Eastern Time (UTC-5)")

  packageStartupMessage("\nApply Physical Range Module filters:")
  packageStartupMessage("apply_prm(df) #Turn data that does not make sense in the physical world to NA (source: Ameriflux Technical Documents)")

  packageStartupMessage("\nTo view vignettes: \nbrowseVignettes('fluxtools')\n")
  packageStartupMessage("To view the citation: \ncitation('fluxtools')")
  #packageStartupMessage("To see the vignette, run vignette('introduction', package = 'fluxtools')")
}
