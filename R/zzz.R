# R/zzz.R

.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion(pkgname)
  packageStartupMessage("Welcome to fluxtools!")
  packageStartupMessage("Version: ", version)

  packageStartupMessage("\nTo start the app:")
  packageStartupMessage("run_fluxtools()")

  packageStartupMessage("\nApply Physical Range Module filters:")
  packageStartupMessage("apply_prm(df) #Turn data that does not make sense in the physical world to NA (source: Ameriflux Technical Documents)")

  packageStartupMessage("\nTo view vignettes: \nbrowseVignettes('fluxtools')\n")
  packageStartupMessage("To view the citation: \ncitation('fluxtools')")
  #packageStartupMessage("To see the vignette, run vignette('introduction', package = 'fluxtools')")
}
