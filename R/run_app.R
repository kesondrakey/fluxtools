#' Launch the interactive 'shiny' QA/QC app for flux data
#'
#' @param offset Integer. The site's UTC offset in hours (e.g. -5 for 'UTC-5', +2 for 'UTC+2').
#'               Must be a single integer between -12 and +14;
#'               supplying a value outside this range throws an error.
#'
#' @return
#' No return value, called for side effects (it launches the Shiny app).
#'
#' @examples
#' # — Quick automated checks —
#' # These run during R CMD check, but users don’t see them:
#' try(run_flux_qaqc(-13))  # should print error message
#' try(run_flux_qaqc(15))   # should print error message
#'
#' # — Interactive demo (only in an interactive R session) —
#' if (interactive()) {
#'   run_flux_qaqc(-5)     # US Eastern Standard Time ('UTC-5')
#' }
#'
#'
#' @importFrom shiny runApp
#' @importFrom plotly plot_ly add_trace add_lines layout event_register
#' @importFrom dplyr filter mutate pull
#' @export
run_flux_qaqc <- function(offset) {
  # 1) Validate offset
  if (missing(offset) ||
      !is.numeric(offset) ||
      length(offset) != 1 ||
      offset < -12 ||
      offset > 14 ||
      offset != as.integer(offset)) {
    stop("`offset` must be a single integer between -12 and +14.", call. = FALSE)
  }

  # 2) Store it as an R option so the Shiny server can read it
  old_opts <- options(shiny.initialOffset = as.integer(offset))
  on.exit(options(old_opts), add = TRUE)

  # 3) Run the app. In a released package, we use system.file("app", ...).
  #    But for local testing, point directly at "inst/app".
  app_dir <- system.file("app", package = "fluxtools")
  if (app_dir == "") {
    # We're likely in development mode (not yet installed). Use the local path:
    app_dir <- "inst/app"
  }

  shiny::runApp(
    appDir        = app_dir,
    launch.browser = TRUE
  )
}
