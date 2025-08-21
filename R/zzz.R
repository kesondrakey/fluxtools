# R/zzz.R

.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion(pkgname)
  packageStartupMessage("Welcome to fluxtools V", version)
  packageStartupMessage("\nTo start the app: run_fluxtools()")
  packageStartupMessage("To apply Physical Range Module (PRM) filters: use apply_prm()")
  packageStartupMessage("\nFor additional help: see ?run_fluxtools, ?apply_prm, browseVignettes('fluxtools')")
  packageStartupMessage("To view citation: citation('fluxtools')")
}
