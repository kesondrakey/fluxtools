#' Launch the interactive 'shiny' QA/QC app for flux data
#'
#' @return
#' No return value, called for side effects (it launches the Shiny app).
#'
#' @examples
#' if (interactive()) {
#'   run_fluxtools()
#' }

#'
#' @importFrom shiny runApp
#' @importFrom plotly plot_ly add_trace add_lines layout event_register
#' @importFrom dplyr filter mutate pull
#'
#'
#' @export
run_fluxtools <- function() {
  # Run the app. In a released package, we use system.file("app", ...).
  #    But for local testing, point directly at "inst/app".
  app_dir <- system.file("app", package = "fluxtools")
  if (identical(app_dir, "")) app_dir <- "inst/app"

  if (!dir.exists(app_dir)) {
    stop("Could not find the Shiny app directory. Is the package installed with inst/app?",
         call. = FALSE)
  }

  shiny::runApp(
    appDir        = app_dir,
    launch.browser = TRUE
  )
}


