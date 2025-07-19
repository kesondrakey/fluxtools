# R/zzz.R

.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion(pkgname)
  packageStartupMessage("Welcome to fluxtools!")
  packageStartupMessage("Version: ", version)

  packageStartupMessage("\nTo start the app, use: run_flux_qaqc(offset), where `offset` is your UTC time offset")
  packageStartupMessage("Example: \nrun_flux_qaqc(-5) #for Eastern Time (UTC-5)\n")

  packageStartupMessage("To view all vignettes: \nbrowseVignettes('fluxtools')\n")
  packageStartupMessage("To view the citation: \ncitation('fluxtools')")
  #packageStartupMessage("To see the vignette, run vignette('introduction', package = 'fluxtools')")
}
