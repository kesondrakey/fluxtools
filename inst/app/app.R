library(shiny)
library(plotly)
library(dplyr)
library(shinyBS)   # for bsTooltip()
library(bslib)     # for theming

# Allow larger uploads (here: up to 1gb)
options(shiny.maxRequestSize = 1024 * 1024 * 1024) #1gb


## ── 1) Theme ───────────────────────────────────────────────────────
light_theme <- bs_theme(
  bootswatch = "cerulean",
  base_font_size  = "18px",    # ← bump this up (default is 14px)
  font_scale      = 1.2        # ← or scale everything to 120%
)


dark_theme <- bs_theme(
  version        = 5,
  #bootswatch     = "darkly",
  bootswatch     = "slate",
  base_font_size  = "18px",    # ← bump this up (default is 14px)
  font_scale      = 1.2,        # ← or scale everything to 120%
  fg             = "#EEE",
  bg             = "#222",
  input_bg       = "#333",
  input_fg       = "#EEE"#,
  #
  #   # override the form‐select CSS vars:
  #   "form-select-color"         = "#EEE",
  #   "form-select-bg"            = "#333",
  #   "form-select-border-color"  = "#555",
  #
  #   # override form‐control CSS vars:
  #   "form-control-color"        = "#EEE",
  #   "form-control-bg"           = "#333",
  #   "form-control-border-color" = "#555"
)


ui <- fluidPage(
  # lock the page to the height of the browser window,
  # and stop it from ever scrolling
  style = "height:100vh; overflow:hidden;",
  #default theme
  theme = light_theme,   # ← important!

  # client‐side handler for copying text
  tags$head(
    tags$style(HTML('
        html[data-bs-theme="slate"] {
          /* form controls (text inputs, selects, textareas) */
          --bs-form-control-bg:           #333 !important;
          --bs-form-control-color:        #EEE !important;
          --bs-form-control-border-color: #555 !important;
          /* <select> dropdowns */
          --bs-form-select-bg:            #333 !important;
          --bs-form-select-color:         #EEE !important;
          --bs-form-select-border-color:  #555 !important;
        }
       /* x) Put the copy button back in place */
      .copy-button-col {
        display: flex !important;
        justify-content: flex-end !important;
        align-items: center !important;
        padding-left: 0 !important;
        padding-right: 1rem !important;
      }
  ')),
    tags$script(HTML("
    function copyVisibleCode(){
      var which = document.querySelector('input[name=code_choice]:checked').value;
      var srcId = which==='current' ? 'code_current' : 'code_all';
      var ta    = document.createElement('textarea');
      ta.value  = document.getElementById(srcId).innerText;
      ta.readOnly = true;
      ta.style.position = 'absolute'; ta.style.left = '-9999px';
      document.body.appendChild(ta);
      ta.select(); document.execCommand('copy');
      document.body.removeChild(ta);
      Shiny.setInputValue('did_copy_code', Math.random());
    }
    document.addEventListener('shiny:connected', function(){
      var btn = document.getElementById('copy_code_btn');
      if(btn) btn.onclick = copyVisibleCode;
    });
  "))
  ),

  ## ── 2) Title + help link ───────────────────────────────────────────
  titlePanel(
    div(
      "fluxtools: Interactive QA/QC with Code Generator",
      actionLink("help", label = icon("question-circle"), style = "margin-left:10px;")
    )
  ),

  ## ── 3) Subtitle ─────────────────────────────────────────────────────
  uiOutput("subtitle"),

  ## ── 4) Main layout ─────────────────────────────────────────────────
  sidebarLayout(

    ### Sidebar with all your controls
    sidebarPanel(
      style = "max-height: calc(100vh - 80px); overflow-y: auto;",
      width = 4,

      # Upload
      fileInput("csv_file", "Upload Ameriflux‐style .csv:", accept = ".csv"),

      # Year filter
      tagAppendAttributes(
        selectizeInput("year_sel", "Select Year(s):", choices  = NULL, multiple = TRUE,
                       options  = list(placeholder = "– upload to load year(s) –",
                                       plugins     = list("remove_button")),
                       width = "100%"),
        'data-bs-toggle' = "tooltip",
        title            = "Filter to one or more years"
      ),
      hr(),

      # new inline axes row:
      fluidRow(
        column(
          6,
          tags$label(
            `for`  = "yvar",
            "Y-axis:",
            style  = "width:100%; font-weight:500;"
          ),
          tagAppendAttributes(
            selectInput(
              "yvar", NULL, choices = NULL, width = "100%"
            ),
            'data-bs-toggle' = "tooltip",
            title            = "Select your Y-axis variable — the column whose values will be set to NA"
          )
        ),

        column(
          6,
          tags$label(
            `for`  = "xvar",
            "X-axis:",
            style  = "width:100%; font-weight:500;"
          ),
          tagAppendAttributes(
            selectInput(
              "xvar", NULL, choices = NULL, width = "100%"
            ),
            'data-bs-toggle' = "tooltip",
            title            = "Select your X-axis variable"
          )
        )
      ),
      hr()
      ,

      #correct ()
      # Manual selection row
      fluidRow(
        column(6,actionButton("add_sel", "Flag Data",
                              width="100%",
                              icon = icon("check"),
                              'data-bs-toggle'="tooltip",
                              title="Add the selected points to the accumulated removal code")
        ),
        column(6,
               actionButton("clear_sel","Clear Selection",
                            width = "100%",
                            icon = icon("broom"),
                            'data-bs-toggle'="tooltip",
                            title="Clear all flagged points from the current y-variable from the accumulated removal code")
        )
      ),

      # Accumulated‐selection row
      fluidRow(
        column(6,
               actionButton("remove_acc","Unflag Data",
                            width = "100%",
                            icon = icon("ban"),
                            'data-bs-toggle'="tooltip",
                            title="Remove current selection from the accumulated removal code")
        ),
        column(6,
               actionButton("remove","Apply removals",
                            width = "100%",
                            icon = icon("trash"),
                            'data-bs-toggle'="tooltip",
                            title="Turn the currently selected Y‐values into NA's and remove from view. These will be reflected in the exported .csv using the 'export cleaned data' button")
        )
      ),

      tags$br(),
      hr(),

      # Outlier controls
      sliderInput("sd_thresh", "Highlight points beyond (σ):", min = 0, max = 3, value = 0, step = 1),
      checkboxInput("show_reg", "Show regression line & R²", value = TRUE),

      #outliers
      fluidRow(
        column(6,
               tagAppendAttributes(
                 actionButton("add_outliers", "Select all ±σ outliers", width="100%"),
                 'data-bs-toggle' = "tooltip",
                 title            = "Select every point whose residual is beyond ± n standard deviations (σ) from the regression line and add to the accumulated code"
               ),
        ),
        column(6,
               tagAppendAttributes(
                 actionButton("clear_outliers", "Clear ±σ outliers", width="100%"),
                 'data-bs-toggle' = "tooltip",
                 title            = "Remove ± n standard deviations (σ) from the regression line from your the accumulated code"
               )
        )
      ),


      hr(),


      fluidRow(
        style = "display: flex; align-items: center; margin-bottom: 0.5rem;",
        column(
          width = 8, style = "padding-right: 0;",
          radioButtons(
            "code_choice", NULL,
            choiceNames  = list(
              tagList(icon("code"), HTML("&nbsp;Current")),
              tagList(icon("list-ul"), HTML("&nbsp;Accumulated"))
            ),
            choiceValues = c("current", "all"),
            inline       = TRUE
          )
        ),
        column(
          width = 4, class = "copy-button-col",
          tags$button(
            id    = "copy_code_btn",
            type  = "button",
            class = "btn btn-outline-secondary",       # ← use outline so it’s lighter on dark
            'data-bs-toggle' = "tooltip",
            title = "Copy visible code",
            icon("clipboard"),
            onclick = HTML("
            // pick current or accumulated
            var which = document.querySelector('input[name=code_choice]:checked').value;
            var srcId = which==='current' ? 'code_current' : 'code_all';
            var txt   = document.getElementById(srcId).innerText;
            // old‐school textarea hack
            var ta = document.createElement('textarea');
            ta.value = txt;
            ta.setAttribute('readonly','');
            ta.style.position = 'absolute';
            ta.style.left = '-9999px';
            document.body.appendChild(ta);
            ta.select();
            document.execCommand('copy');
            document.body.removeChild(ta);
            // fire an input event so Shiny can show its own toast
            Shiny.setInputValue('did_copy_code', Math.random());
          "),
          )
        )
      ),


      # the actual code box (must have IDs matching the above JS)
      uiOutput("code_ui"),

      # only show this when 'Accumulated' is selected
      conditionalPanel(
        "input.code_choice == 'all'",
        actionButton(
          "reset_accum", "Clear accumulated",
          width = "100%",
          'data-bs-toggle'="tooltip",
          title = "Remove all points from accumulated list")),
      hr(),


      # Download & reset
      # in your sidebarPanel, toward the bottom
      fluidRow(
        column(4, downloadButton("download_data", "Export cleaned data",
                                 icon = icon("file-archive"), width="100%"),
               'data-bs-toggle'="tooltip",
               title="Download a .zip containing the cleaned CSV (with NAs applied using the 'Apply Removals' button) and the removal R-script"),

        column(4, actionButton("reset_data", "Reload original data",
                               icon = icon("eraser"), width="100%"),
               'data-bs-toggle'="tooltip",
               title="Reset any changes by re-loading the original .csv file"),

        column(4, div(style="margin-top:0.5em;",checkboxInput("dark_mode","Dark mode",FALSE))
        )
      )

    ),# ← CLOSE sidebarPanel() here







    mainPanel(
      #style = "height: calc(100vh - 80px); overflow-y: auto;",
      width = 8,
      plotlyOutput("qc_plot", width = "100%", height = "80vh")#help with different resolutions
      #plotlyOutput("qc_plot", height = "80vh")
    )
  )  # ← close sidebarLayout()
)




server <- function(input, output, session) {
  output$subtitle <- renderUI({
    req(input$yvar)
    col <- if (isTRUE(input$dark_mode)) "#DDD" else "#555"
    tags$h5(
      paste("Filtering out:", input$yvar),
      style = sprintf("color:%s; margin-top:-10px; margin-bottom:20px;", col)
    )
  })

  observeEvent(input$did_copy_code, {
    showNotification("Code copied ✅", type="message", duration = 1)
  })

  # 1) “Injected” offset → local_tz
  # 1) “Injected” offset → local_tz (inline, no helper)
  offset   <- getOption("shiny.initialOffset", default = 0)
  local_tz <- if (offset == 0) {
    "UTC"
  } else {
    # note: Etc/GMT signs are inverted: Etc/GMT+5 == UTC-5
    sign_chr <- if (offset < 0) "+" else "-"
    paste0("Etc/GMT", sign_chr, abs(offset))
  }

  # 2a) Read raw CSV
  raw_df <- reactive({
    req(input$csv_file)
    read.csv(
      input$csv_file$datapath,
      stringsAsFactors = FALSE,
      colClasses = c(TIMESTAMP_START = "character"),
      na.strings = "-9999"
    )
  })

  # 2b) Parse TIMESTAMP_START → POSIXct in local_tz + keep .row index
  shifted_df <- reactive({
    df0 <- raw_df()
    req(df0)
    df0 %>%
      mutate(
        raw_ts = TIMESTAMP_START,
        ts_str = substr(gsub("[^0-9]", "", raw_ts), 1, 12),
        TIMESTAMP_START = as.POSIXct(ts_str, "%Y%m%d%H%M", tz = local_tz),
        .row            = row_number()
      )
  })



  # 2c) Keep a reactiveValues copy of the current data, plus an immutable original
  rv      <- reactiveValues(df = NULL)
  orig_df <- reactiveVal(NULL)

  #code box
  output$code_ui <- renderUI({
    bg     <- if (input$dark_mode) "#2e2e2e" else "#f9f9f9"
    fg     <- if (input$dark_mode) "#EEE"    else "#000"
    border <- if (input$dark_mode) "#555"    else "#ddd"

    sel <- if (input$code_choice=="current") "code_current" else "code_all"

    div(
      style = sprintf(
        "height:200px; overflow-y:auto; border:1px solid %s; background:%s; color:%s; padding:8px;",
        border, bg, fg
      ),
      verbatimTextOutput(sel)
    )
  })

  # toggle a 'dark-mode' class on <body>
  observe({
    addClass  <- if (isTRUE(input$dark_mode)) "dark-mode" else ""
    removeClass <- if (isTRUE(input$dark_mode)) "" else "dark-mode"
    session$sendCustomMessage("toggleBodyClass", list(add=addClass, remove=removeClass))
  })





  observeEvent(input$reset_accum, {
    removed_ts[[input$yvar]] <- NULL
    sel_keys(integer(0))
    outlier_keys(integer(0))
    session$resetBrush("qc_plot")
  })


  #Copy all logic
  observeEvent(input$copy_code, {
    which_id <- if (input$code_choice == "current") "code_current" else "code_all"
    session$sendCustomMessage("doCopy", which_id)
  })






  # ────────────────────────────────────────────────────────────────────────────
  # When a new file arrives, place it into rv$df, record original copy,
  # and populate “year_sel” with “All” + each unique year
  # ────────────────────────────────────────────────────────────────────────────
  observeEvent(shifted_df(), {
    rv$df <- shifted_df()
    orig_df(shifted_df())

    all_years <- sort(unique(format(rv$df$TIMESTAMP_START, "%Y")))
    # add “All” in front of every other year
    choices_with_all <- c("All", all_years)

    updateSelectizeInput(
      session,
      "year_sel",
      choices  = c("All", all_years),
      selected = "All"
    )
  })

  # 3) Reactive: df_by_year() filters rv$df by whichever years the user picked.
  df_by_year <- reactive({
    req(rv$df, input$year_sel)
    # If the user has "All" selected *and* no other year, return the full data:
    if (identical(input$year_sel, "All")) {
      return(rv$df)
    }


    # Otherwise, drop "All" (if present) and filter by the remaining years:
    chosen_years <- setdiff(input$year_sel, "All")

    rv$df %>%
      filter(format(TIMESTAMP_START, "%Y") %in% chosen_years)
  })

  #  Clear *current* selection in the code box:
  observeEvent(input$clear_sel, {
    # 1) clear the lasso brush
    session$resetBrush("qc_plot")
    # 2) clear the “current” keys
    sel_keys(integer(0))
  })




  # Track manual selections / removals
  sel_keys       <- reactiveVal(integer(0))
  removed_ts     <- reactiveValues()   # for “accumulated‐selection code”
  outlier_keys   <- reactiveVal(integer(0))

  # Track exactly which timestamps have been Confirm Removed
  confirmed_ts <- reactiveValues()

  # Helper: lasso‐selected rows
  selected_keys <- reactive({
    sel <- event_data("plotly_selected", source = "qc_plot")
    if (is.null(sel)) return(integer(0))
    sel$key
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Whenever the Y‐variable changes, clear the “current selection” and outliers
  # ────────────────────────────────────────────────────────────────────────────
  observeEvent(input$yvar, {
    req(input$yvar)                # ← ensure yvar is non‐NULL/non‐empty
    sel_keys(integer(0))
    #outlier_keys(integer(0))
    session$resetBrush("qc_plot")

    # Re‐populate sel_keys() from removed_ts for this new yvar
    # (removed_ts[[ yvar ]] might be a character vector of ts_str values)
    current_ts <- removed_ts[[ input$yvar ]] %||% character()
    if (length(current_ts)) {
      matching_rows <- which(df_by_year()$ts_str %in% current_ts)
      sel_keys(matching_rows)
    } else {
      sel_keys(integer(0))
    }
  })


  # ────────────────────────────────────────────────────────────────────────────
  # Rebuild xvar/yvar dropdowns whenever new data arrives
  # ────────────────────────────────────────────────────────────────────────────
  observe({
    df <- df_by_year()
    req(df)

    num_cols <- df %>%
      select(-TIMESTAMP_START, -raw_ts, -ts_str, -.row) %>%
      select(where(is.numeric)) %>%
      names()

    x_choices <- c("TIMESTAMP_START", num_cols)
    y_choices <- num_cols

    updateSelectInput(
      session, "xvar",
      choices = x_choices,
      selected =
        if (!is.null(input$xvar) && input$xvar %in% x_choices) {
          input$xvar
        } else {
          "TIMESTAMP_START"
        }
    )

    updateSelectInput(
      session, "yvar",
      choices = y_choices,
      selected =
        if (!is.null(input$yvar) && input$yvar %in% y_choices) {
          input$yvar
        } else {
          y_choices[1]
        }
    )
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Compute residuals & flag ±σ outliers
  # ────────────────────────────────────────────────────────────────────────────
  df_clean <- reactive({
    df0 <- df_by_year()
    req(df0, input$xvar, input$yvar, input$sd_thresh)

    df1 <- df0 %>%
      filter(
        !is.na(.data[[input$xvar]]),
        !is.na(.data[[input$yvar]])
      )

    fit0 <- lm(reformulate(input$xvar, input$yvar), data = df1)

    df1 %>%
      mutate(
        fitted = predict(fit0, newdata = .),
        resid  = .data[[input$yvar]] - fitted,
        sigma  = sd(resid, na.rm = TRUE),
        flag   = if_else(
          abs(resid) > input$sd_thresh * sigma,
          "outlier", "inlier"
        )
      )
  })


  ###Theme
  observe({
    session$setCurrentTheme(
      if (isTRUE(input$dark_mode)) dark_theme else light_theme
    )
  })

  helpModal <- function() {
    shiny::modalDialog(
      title     = "Help: fluxtools QA/QC",
      tabsetPanel(
        id = "help_tabs",

        # ─── Quick Start ─────────────────────────────────────────────────────────



        tabPanel(
          "Quick Start",
          tagList(
            tags$ul(
              tags$h4("1. Upload & Choose Variables"),
              tags$ul(
                tags$li(tags$b("Upload")," your AmeriFlux CSV (≤ 100 MB; multi-year enabled)"),
                tags$li(tags$b("X-axis:"),"Defaults to TIMESTAMP_START (e.g., 'YYYYMMDDHHMM', such as '201507281700'); you can switch to any numeric variable"),
                tags$li(tags$b("Time Note:")," TIMESTAMP_START is parsed into POSIXct in your local TZ so you see familiar clock times (e.g. 14:00), but the generated code always uses the original 'YYYYMMDDHHMM' string to avoid ambiguity"),
                tags$li(tags$b("Y-axis:")," The variable you want to remove (i.e. FC_1_1_1)"),
                tags$li(tags$b("Year filter")," select one or more years to scope your QA/QC (defaults to all)"),
                tags$li(tags$b("Theme")," toggle light/dark mode via the switch at the bottom left")
              ),

              tags$h4("2. Flag Data"),
              tags$ul(
                tags$li("Box- or lasso-select points → ",tags$b("Flag Data")),
                tags$li("Or click ",tags$b("Select ±σ outliers")," to auto-flag residuals")
              ),

              tags$h4("3. Review & Copy Code"),
              tags$p("Switch between the ",tags$b("Current")," and ",tags$b("Accumulated")," code tabs, then click 📋 to copy the R snippet for y-variable removal"
              ),

              tags$h4("4. Undo & Reset"),
              tags$ul(
                tags$li(tags$b("Unselect points:")," box- or lasso-select them, then click ",tags$b("Unflag Data")),
                tags$li(tags$b("Clear selection:")," click ",tags$b("Clear Selection")," to reset the current plot selection"),
                tags$li(tags$b("Clear outliers:")," click ",tags$b("Clear ±σ Outliers")," to unflag all ±σ points"),
                tags$li(tags$b("Full reset:")," click ",tags$b("Reload original data")," at the bottom to restore your dataset")
              ),

              tags$h4("5. Apply Removals"),
              tags$p("Click ",tags$b("Apply removals")," to set the selected Y-values to NA and remove these points from view"
              ),

              tags$h4("6. Export Image"),
              tags$p("Because the scatter is powered by Plotly, you can click the camera icon (upper-right corner of the plot) to download a high-resolution PNG of any current view"
              ),

              tags$h4("7. Export cleaned data"),
              tags$p("Click ", tags$b("Export cleaned data"), " in the bottom left to download a ZIP file containing:",
                     tags$ul(
                       tags$li("A cleaned CSV (all points you removed via ", tags$b("Apply removals"), " are set to NA)"),
                       tags$li("An R script with the exact code used to apply those removals")))
            )
          )
        ),

        # ─── Vignette ────────────────────────────────────────────────────────────
        tabPanel(
          "Vignette",
          tagList(
            tags$pre(
              "In your R console run:\n",
              tags$b('library(fluxtools)\n'),
              'vignette("introduction", package = "fluxtools")'
            )
          )
        )

      ),
      easyClose = TRUE,
      size      = "l"
    )
  }

  observeEvent(input$help, {
    shiny::showModal(helpModal())
  })




  # ────────────────────────────────────────────────────────────────────────────
  # Button logic: add/remove outliers & manual selection accumulation
  # ────────────────────────────────────────────────────────────────────────────
  observeEvent(input$add_outliers, {
    ok <- df_clean() %>% filter(flag == "outlier") %>% pull(.row)
    outlier_keys(unique(c(isolate(outlier_keys()), ok)))
    sel_keys(unique(c(isolate(sel_keys()), ok)))

    ts  <- df_by_year() %>% filter(.row %in% ok) %>% pull(ts_str)
    old <- removed_ts[[input$yvar]] %||% character()
    removed_ts[[input$yvar]] <- unique(c(old, ts))
  })

  observeEvent(input$clear_outliers, {
    old_out <- isolate(outlier_keys())
    if (length(old_out) == 0) return()

    sel_keys(setdiff(isolate(sel_keys()), old_out))
    outlier_keys(integer(0))

    ts_out   <- df_by_year() %>% filter(.row %in% old_out) %>% pull(ts_str)
    existing <- removed_ts[[input$yvar]] %||% character()
    removed_ts[[input$yvar]] <- setdiff(existing, ts_out)
  })

  observeEvent(input$add_sel, {
    keys <- selected_keys()
    if (!length(keys)) return()

    sel_keys(unique(c(isolate(sel_keys()), keys)))
    ts    <- df_by_year() %>% filter(.row %in% keys) %>% pull(ts_str)
    old   <- removed_ts[[input$yvar]] %||% character()
    removed_ts[[input$yvar]] <- unique(c(old, ts))
  })

  observeEvent(input$remove, {
    # 1) figure out which rows (in the current filtered view) to remove:
    local_rows <- union(union(
      isolate(selected_keys()),
      isolate(sel_keys())
    ), isolate(outlier_keys()))

    if (length(local_rows)==0) return()

    # 2) map those back to the master dataset via the .row index:
    rows_global <- df_by_year()[local_rows, ]$.row

    # 3) pull out the master copy, set y‐var to NA there, then reassign:
    tmp <- rv$df
    tmp[[ input$yvar ]][ rows_global ] <- NA_real_
    rv$df <- tmp

    # 4) record them under confirmed_ts so we can generate the script later
    just_ts        <- df_by_year()[local_rows, ]$ts_str
    old_confirmed  <- confirmed_ts[[ input$yvar ]] %||% character()
    confirmed_ts[[ input$yvar ]] <- unique(c(old_confirmed, just_ts))

    # 5) and clear out all your selection state:
    removed_ts[[input$yvar]] <- setdiff(
      removed_ts[[input$yvar]] %||% character(),
      just_ts
    )
    sel_keys(integer(0))
    outlier_keys(integer(0))
    session$resetBrush("qc_plot")
  })


  # ────────────────────────────────────────────────────────────────────────────
  # Render the Plotly scatter (with event_register)
  # ────────────────────────────────────────────────────────────────────────────
  output$qc_plot <- renderPlotly({
    df0 <- df_by_year()
    req(df0, input$xvar, input$yvar)


    dfc <- df0 %>%
      filter(
        !is.na(.data[[input$xvar]]),
        !is.na(.data[[input$yvar]])
      ) %>%
      {
        fit0 <- lm(reformulate(input$xvar, input$yvar), data = .)
        mutate(
          .,
          fitted = predict(fit0, newdata = .),
          resid  = .data[[input$yvar]] - fitted,
          sigma  = sd(resid, na.rm = TRUE),
          flag   = if_else(
            abs(resid) > input$sd_thresh * sigma,
            "outlier", "inlier"
          )
        )
      }


    marker_blue <- if (isTRUE(input$dark_mode)) "#1F62FF" else "#1F449C"

    p <- plot_ly(
      data   = dfc,
      x      = ~.data[[input$xvar]],
      y      = ~.data[[input$yvar]],
      key    = ~.row,
      source = "qc_plot",
      mode   = "markers",
      type   = "scatter",
      marker = list(color = marker_blue, opacity = 0.8)
      #marker = list(color = "#228833", opacity = 0.6)
    )%>%
      event_register("plotly_selected")



    # Plot the ±σ outliers as red
    if (input$sd_thresh > 0) {
      p <- p %>%
        add_trace(
          data       = filter(dfc, flag == "outlier"),
          x          = ~.data[[input$xvar]],
          y          = ~.data[[input$yvar]],
          mode       = "markers",
          type       = "scatter",
          marker     = list(color = "#F05039", opacity = 0.8),



          #marker     = list(color = "#ee6677", opacity = 0.8),
          showlegend = FALSE
        )
    }

    # Plot the “accumulated” (orange) points on top
    if (length(sel_keys()) > 0) {
      p <- p %>%
        add_trace(
          data       = dfc %>% filter(.row %in% sel_keys()),
          x          = ~.data[[input$xvar]],
          y          = ~.data[[input$yvar]],
          mode       = "markers",
          type       = "scatter",
          marker     = list(color = "#FFC107"),# size = 10),

          inherit    = FALSE,
          showlegend = FALSE
        )
    }


    #plotly theme dark vs light mode
    if (isTRUE(input$dark_mode)) {
      p <- p %>% layout(
        template    = "plotly_dark",
        paper_bgcolor = "#2E2E2E",
        plot_bgcolor  = "#2E2E2E",
        font = list(color = "white")#,
        # annotationdefaults = list(
        #   font = list(color = "black")                   # overrides all annotation text
        # )
      )
    }


    # R2 value for ALL points,
    # then fit a second time on (all points minus accumulated selections).
    if (input$show_reg && input$xvar != "TIMESTAMP_START") {
      # 1) R² on ALL points (even the ±σ outliers)
      df_all <- df0 %>%
        filter(
          !is.na(.data[[input$xvar]]),
          !is.na(.data[[input$yvar]])
        )

      if (nrow(df_all) >= 2) {
        fit_all <- lm(reformulate(input$xvar, input$yvar), data = df_all)
        r2_all  <- round(summary(fit_all)$r.squared, 2)

        # Add a gray regression line for all points:
        xseq_all <- seq(
          min(df_all[[input$xvar]], na.rm = TRUE),
          max(df_all[[input$xvar]], na.rm = TRUE),
          length.out = 100
        )
        preds_all <- predict(fit_all, newdata = setNames(data.frame(xseq_all), input$xvar))

        r2_bg_all <- if (isTRUE(input$dark_mode)) "#F52100" else "#FFBAAF"
        r2_bg_sel <- if (isTRUE(input$dark_mode)) "#B87700" else "#FFC65C"

        #r2_bg_all <- "#FFBAAF"
        #r2_bg_sel <- "#FFC65C"

        p <- p %>%
          # 1) black line, slightly thicker
          add_lines(
            x     = xseq_all,
            y     = preds_all,
            inherit=FALSE,
            line  = list(
              color = "black",
              width = 8     # a little wider than your pink
            ),
            showlegend = FALSE
          ) %>%
          # 2) your pink line on top
          add_lines(
            x     = xseq_all,
            y     = preds_all,
            inherit=FALSE,
            line  = list(
              color = r2_bg_all,
              width = 6
            ),
            showlegend = FALSE
          )%>%




          # p <- p %>%
          #   add_lines(
          #     x          = xseq_all,
          #     y          = preds_all,
          #     inherit    = FALSE,
          #     line       = list(
          #       color = r2_bg_all,               # your chosen static color
          #       width = 6                        # bump thickness up (default is ~2)
          #     ),
          #     #line       = list(color = "gray50", width = 4),  # ← add width here
          #     #line       = list(color = "gray50"),
          #     showlegend = FALSE
          #   ) %>%
          add_annotations(
            xref        = "paper",
            yref        = "paper",
            x           = 0.02,
            y           = 1.00,
            xanchor     = "left",
            yanchor     = "bottom",
            text        = paste0("<b>R² (all points) = ", r2_all, "</b>"),
            showarrow   = FALSE,
            font        = list(size = 18),
            borderpad   = 6,
            borderwidth = 1.5,
            yshift      = -18,    # ← move it down 10px
            bgcolor     = r2_bg_all,

            bordercolor = list(color = if (isTRUE(input$dark_mode)) "#EEE" else "black")
          )
      }

      # 2) R² with accumulated points dropped
      acc_sel <- isolate(sel_keys())
      if (length(acc_sel) > 0) {
        # Build a dataset that excludes the .row indices in acc_sel
        df_drop_sel <- df0 %>%
          filter(
            !is.na(.data[[input$xvar]]),
            !is.na(.data[[input$yvar]])
          ) %>%
          filter(!(.row %in% acc_sel))

        if (nrow(df_drop_sel) >= 2) {
          fit_sel <- lm(reformulate(input$xvar, input$yvar), data = df_drop_sel)
          r2_sel  <- round(summary(fit_sel)$r.squared, 2)
        } else {
          r2_sel <- NA_real_
        }

        p <- p %>%
          add_annotations(
            xref        = "paper",
            yref        = "paper",
            x           = 0.02,
            y           = 0.96,
            xanchor     = "left",
            yanchor     = "bottom",
            text        = paste0("<b>R² (sel dropped) = ", r2_sel, "</b>"),
            showarrow   = FALSE,
            font        = list(size = 18),
            borderpad   = 6,
            borderwidth = 1.5,
            yshift      = -26,    # ← move it down 10px
            bgcolor     = r2_bg_sel,
            bordercolor = list(color = if (isTRUE(input$dark_mode)) "#EEE" else "black")
          )
      }
    }

    p %>%
      layout(
        autosize = TRUE,#helps with resolution

        dragmode = "select",
        # bump up all text a bit
        font   = list(size = 18),#plot text size
        # loosen the margins so big titles don’t get clipped
        margin = list(l = 80, r = 20, b = 80, t = 20),
        #end plot edits

        xaxis    = if (input$xvar == "TIMESTAMP_START") {
          list(type = "date", tickformat = "%b %d\n%H:%M", title = input$xvar)
        } else {
          list(title = input$xvar)
        },
        yaxis = list(title = input$yvar)
      ) %>%
      event_register("plotly_selected")
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Preview table (same as before)
  # ────────────────────────────────────────────────────────────────────────────
  output$preview <- renderTable({
    keys <- selected_keys()
    if (length(keys) == 0) keys <- sel_keys()
    if (length(keys) == 0) return(NULL)

    local_label <- sprintf("Timestamp (UTC%+d)", offset)

    df_by_year() %>%
      filter(.row %in% keys) %>%
      mutate(
        !!local_label := format(
          TIMESTAMP_START,
          "%Y-%m-%d %H:%M",
          tz = local_tz
        )
      ) %>%
      select(all_of(local_label), !!sym(input$yvar), raw_ts) %>%
      setNames(c(local_label, input$yvar, "raw_ts"))
  }, sanitize.text.function = identity)

  # ────────────────────────────────────────────────────────────────────────────
  # Current‐selection code
  # ────────────────────────────────────────────────────────────────────────────
  output$code_current <- renderText({
    keys <- selected_keys()
    if (length(keys) == 0) keys <- sel_keys()
    if (length(keys) == 0) {
      return("

<!-- draw a box or lasso (or click “Flag Data”) to see its code here -->

")
    }
    sel_ts <- df_by_year() %>% filter(.row %in% keys) %>% pull(ts_str)
    conds  <- paste0("TIMESTAMP_START == '", sel_ts, "' ~ NA_real_", collapse = ",\n      ")
    paste0(
      "df <- df %>%\n",
      "  mutate(\n",
      "    ", input$yvar, " = case_when(\n",
      "      ", conds, ",\n",
      "      TRUE ~ ", input$yvar, "\n",
      "    )\n",
      "  )"
    )
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Accumulated‐selection code
  # ────────────────────────────────────────────────────────────────────────────
  output$code_all <- renderText({
    all_removals <- reactiveValuesToList(removed_ts)
    all_removals <- all_removals[vapply(all_removals, length, FUN.VALUE = integer(1)) > 0]
    if (length(all_removals) == 0) {
      return("

<!-- click “Flag Data” or “Add all ±σ outliers” → see code here -->

")
    }
    snippets <- lapply(names(all_removals), function(var) {
      ts    <- all_removals[[var]]
      conds <- paste0("TIMESTAMP_START == '", ts, "' ~ NA_real_", collapse = ",\n      ")
      paste0(
        "df <- df %>%\n",
        "  mutate(\n",
        "    ", var, " = case_when(\n",
        "      ", conds, ",\n",
        "      TRUE ~ ", var, "\n",
        "    )\n",
        "  )"
      )
    })
    paste(unlist(snippets), collapse = "\n\n")
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Removed‐points code snippet (only those Confirm Removed)
  # ────────────────────────────────────────────────────────────────────────────
  output$removed_code <- renderText({
    # pulled_ts is the character‐vector of ts_str values that we have already “confirmed” as removed, for the current y‐variable
    pulled_ts <- removed_ts[[input$yvar]] %||% character()
    if (length(pulled_ts) == 0) {
      return("<!-- no points have been “Confirmed Remove” yet -->")
    }

    # build a case_when(...) string using TIMESTAMP_START
    conds <- paste0(
      "TIMESTAMP_START == '", pulled_ts, "' ~ NA_real_",
      collapse = ",\n      "
    )
    paste0(
      "df <- df %>%\n",
      "  mutate(\n",
      "    ", input$yvar, " = case_when(\n",
      "      ", conds, ",\n",
      "      TRUE ~ ", input$yvar, "\n",
      "    )\n",
      "  )"
    )
  })


  # ────────────────────────────────────────────────────────────────────────────
  # DOWNLOAD HANDLER for “Download cleaned CSV”
  # ────────────────────────────────────────────────────────────────────────────
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("flux_cleaned_", Sys.Date(), ".zip")
    },
    content = function(zipfile) {
      # 1) Create a brand-new temp directory
      tmpdir <- tempfile("flux_clean_")
      dir.create(tmpdir)

      # 2) Write the cleaned CSV with the exact name you want
      csv_name <- paste0("flux_cleaned_", Sys.Date(), ".csv")
      csv_path <- file.path(tmpdir, csv_name)

      base_df <- raw_df()
      helper  <- df_by_year()
      for (col in setdiff(names(base_df), "TIMESTAMP_START")) {
        if (col %in% names(helper)) {
          base_df[[col]] <- helper[[col]]
        }
      }
      write.csv(base_df, csv_path, row.names = FALSE, na = "NA")

      # 3) Write the removal script under the exact name you want
      script_name <- "flux_remove_script.R"
      script_path <- file.path(tmpdir, script_name)

      cfs <- reactiveValuesToList(confirmed_ts)
      cfs <- cfs[vapply(cfs, length, FUN.VALUE=0L) > 0]
      lines <- c(
        "## Auto-generated removal script",
        "library(dplyr)",
        "df <- read.csv('flux_original.csv', stringsAsFactors=FALSE)",
        ""
      )
      for (var in names(cfs)) {
        tses  <- cfs[[var]]
        conds <- paste0("TIMESTAMP_START == '", tses, "' ~ NA_real_", collapse=",\n  ")
        lines <- c(lines,
                   sprintf("## remove for %s", var),
                   "df <- df %>%",
                   sprintf("  mutate(%s = case_when(\n  %s,\n  TRUE ~ %s\n))", var, conds, var),
                   ""
        )
      }
      lines <- c(lines,
                 "write.csv(df, 'flux_cleaned.csv', row.names=FALSE, na='NA')"
      )
      writeLines(lines, script_path)

      # 4) Zip them up, stripping off the tempdir path so only the basenames appear
      utils::zip(zipfile,
                 files = c(csv_path, script_path),
                 flags = "-j")
    }
  )


  #Unflag Data button logic
  observeEvent(input$remove_acc, {
    keys <- selected_keys()
    if (length(keys) == 0) return()

    # 1) remove those rows from the sel_keys (orange “accumulated” points)
    sel_keys(setdiff(isolate(sel_keys()), keys))

    # 2) remove their ts_str from removed_ts[[yvar]]
    ts_to_drop <- df_by_year() %>% filter(.row %in% keys) %>% pull(ts_str)
    old       <- removed_ts[[ input$yvar ]] %||% character()
    removed_ts[[ input$yvar ]] <- setdiff(old, ts_to_drop)
  })






  # ────────────────────────────────────────────────────────────────────────────
  # Confirm Remove → set selected rows’ y‐value to NA, record them in confirmed_ts
  # ────────────────────────────────────────────────────────────────────────────
  observeEvent(input$remove, {
    # 1) Which keys in the *current* view?
    sel    <- isolate(selected_keys())
    acc    <- isolate(sel_keys())
    out    <- isolate(outlier_keys())
    local  <- unique(c(sel, acc, out))
    if (length(local)==0) return()

    # 2) Pull their .row from the filtered data.frame
    global_rows <- df_by_year()[ local, ]$.row

    # 3) Mutate the master copy
    tmp <- rv$df
    tmp[[ input$yvar ]][ global_rows ] <- NA_real_
    rv$df <- tmp    # this re-triggers df_by_year() everywhere

    # 4) Record for your R-script later
    ts_removed <- df_by_year()[ local, ]$ts_str
    old        <- confirmed_ts[[ input$yvar ]] %||% character()
    confirmed_ts[[ input$yvar ]] <- unique(c(old, ts_removed))

    # 5) Drop them out of the “accumulated” list & clear everything
    removed_ts[[input$yvar]] <- setdiff(
      removed_ts[[input$yvar]] %||% character(),
      ts_removed

    )
    sel_keys(integer(0))
    outlier_keys(integer(0))
    session$resetBrush("qc_plot")
  })


  # ────────────────────────────────────────────────────────────────────────────
  # Reset Data → restore df_by_year() to orig_df() and clear all removal records
  # ────────────────────────────────────────────────────────────────────────────
  observeEvent(input$reset_data, {
    # 1) restore the master data
    rv$df <- orig_df()

    # 2) reset any year‐filter back to “All”
    updateSelectizeInput(session, "year_sel", selected = "All")

    # 3) clear out all your selections
    for (nm in names(reactiveValuesToList(removed_ts))) removed_ts[[nm]] <- NULL
    sel_keys(integer(0)); outlier_keys(integer(0))
    session$resetBrush("qc_plot")
  })
}

shinyApp(ui, server)
