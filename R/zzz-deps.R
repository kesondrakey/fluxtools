#' @keywords internal
#' @noRd
.use_readr <- function() {
  # Make CRAN see the readr usage from R/ (not just inst/app)
  readr::write_csv(data.frame(x = 1), tempfile())
  invisible(TRUE)
}
