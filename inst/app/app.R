#Goal: UTC offset inside the app
#Add PRM functionality inside the app (able to see selected points when selected, toggle removal on or off)
#PRM description and table inside the helper tool inside the (?)


library(shiny)
library(plotly)
library(dplyr)
library(bslib)     # for theming
library(fluxtools)
library(bslib)


# #DEV ONLY
# #doesnt work for PRM
# # DEV ONLY: auto-load local fluxtools when running from its repo
# if (interactive() && requireNamespace("pkgload", quietly = TRUE)) {
#   desc_up1 <- file.path("..", "DESCRIPTION")
#   if (file.exists(desc_up1)) {
#     pkg <- tryCatch(read.dcf(desc_up1, "Package")[1, 1], error = function(e) NA_character_)
#     if (identical(pkg, "fluxtools")) {
#       try(pkgload::load_all("..", export_all = FALSE, helpers = TRUE, quiet = TRUE), silent = TRUE)
#     }
#   }
# }
# #END DEV ONLY

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
  bootswatch     = "slate", #Vapor, darkly
  base_font_size  = "18px",    # ← bump this up (default is 14px)
  font_scale      = 1.2,        # ← or scale everything to 120%
  fg             = "#EEE",
  bg             = "#222",
  input_bg       = "#333",
  input_fg       = "#EEE"#,
)



ui <- fluidPage(
  style = "height:100vh; overflow:hidden;",
  theme = light_theme,

  tags$head(
    tags$style(HTML('
      h5 { font-weight: 600; letter-spacing: .2px; }
      .card { box-shadow: 0 .25rem .75rem rgba(0,0,0,.05); }
      pre.codebox { margin:0; padding:12px; background: var(--bs-dark-bg-subtle, #f8f9fa);
        border-radius: 10px; border: 1px solid #e5e7eb; font-size: .92rem; }
      .d-grid.gap-2 > .btn { padding:.5rem .75rem; }
      .tz-pill { display:block; width:100%; padding:.375rem .75rem; border:1px solid var(--bs-border-color);
        border-radius:.375rem; background:var(--bs-body-bg); box-shadow:0 1px 2px rgba(0,0,0,.04); font-size:.95rem; }
      .tz-pill i { opacity:.7; margin-right:.5rem; }
      .tz-suffix { margin-left:.35rem; opacity:.8; }
      html[data-bs-theme="slate"] {
        --bs-form-control-bg:#333 !important; --bs-form-control-color:#EEE !important; --bs-form-control-border-color:#555 !important;
        --bs-form-select-bg:#333 !important;  --bs-form-select-color:#EEE !important;  --bs-form-select-border-color:#555 !important;
      }
      .copy-button-col { display:flex !important; justify-content:flex-end !important; align-items:center !important;
        padding-left:0 !important; padding-right:1rem !important; }
      .accordion > .accordion-item { border:1px solid var(--bs-border-color); border-radius: var(--bs-border-radius-lg, .75rem);
        box-shadow:0 .25rem .75rem rgba(0,0,0,.05); overflow:hidden; margin-bottom:.75rem; }
      .accordion-button { font-weight:600; letter-spacing:.2px; padding:.75rem 1rem; }
      .accordion-button .fa, .accordion-button .bi { margin-right:.5rem; }
      .accordion-body { background: var(--bs-body-bg); padding: 1rem 1.25rem; }
      html[data-bs-theme="slate"] .accordion > .accordion-item { border-color:#444; box-shadow:0 .25rem .75rem rgba(0,0,0,.25); }
    ')),

#     tags$style(HTML('
#   /* Cerulean-sized tooltips */
#   .tooltip.tt-compact {
#     --bs-tooltip-bg: #111;
#     --bs-tooltip-color: #fff;
#     --bs-tooltip-opacity: 1;
#     --bs-tooltip-padding-x: .50rem;
#     --bs-tooltip-padding-y: .35rem;
#     --bs-tooltip-border-radius: .375rem;
#     --bs-tooltip-max-width: 260px;
#     --bs-tooltip-box-shadow: 0 .25rem .75rem rgba(0,0,0,.15);
#     --bs-tooltip-font-size: .8rem !important; /* <- same as Cerulean/Bootstrap sm */
#     z-index: 1080;
#   }
#   .tooltip.tt-compact .tooltip-inner {
#     font-size: var(--bs-tooltip-font-size) !important;
#     line-height: 1.25;
#     white-space: normal;
#     max-width: 300px;
#   }
#   html[data-bs-theme="slate"] .tooltip.tt-compact {
#     --bs-tooltip-bg: #1f1f1f;
#     --bs-tooltip-color: #f3f3f3;
#   }
# ')),

    tags$script(HTML("

  function initTooltips(root){
    root = root || document;
    var els = [].slice.call(root.querySelectorAll('[data-bs-toggle=\"tooltip\"]'));
    els.forEach(function(el){
      var inst = bootstrap.Tooltip.getInstance(el);
      if (inst) inst.dispose();
      new bootstrap.Tooltip(el, {
        placement: el.getAttribute('data-bs-placement') || 'right',
        customClass: (el.getAttribute('data-bs-custom-class') || '') + ' tt-compact',
        html: el.getAttribute('data-bs-html') === 'true',
        sanitize: false,
        trigger: 'hover focus',

        delay: { show: 500, hide: 150 },   // ← add a half-second show delay
        animation: true,
        container: 'body'
      });
    });
  }

  // one-time init
  document.addEventListener('shiny:connected', function(){ initTooltips(); });

  // re-init when new tooltip-able nodes are inserted
  new MutationObserver(function(muts){
    for (const m of muts) {
      if (m.type === 'childList') {
        for (const n of m.addedNodes) {
          if (n.nodeType === 1 &&
             ((n.matches && n.matches('[data-bs-toggle=\"tooltip\"]')) ||
              (n.querySelector && n.querySelector('[data-bs-toggle=\"tooltip\"]')))) {
            initTooltips();
            return;
          }
        }
      }
    }
  }).observe(document.body, { childList: true, subtree: true });
")),

    tags$script(HTML('
  Shiny.addCustomMessageHandler("updateTooltip", function(x){
    var el = document.getElementById(x.id);
    if(!el) return;

    el.setAttribute("data-bs-html", "true");
    if (x.title != null) {
      el.setAttribute("data-bs-title", x.title);
      el.removeAttribute("title");
    }

    var inst = bootstrap.Tooltip.getInstance(el);
    if (inst) inst.dispose();

    new bootstrap.Tooltip(el, {
      placement: x.placement || "right",
      customClass: (x.customClass || "") + " tt-compact",
      html: true,
      sanitize: false,          // ← add this
      trigger: "hover",
      animation: false,
      container: "body"
    });
  });
')),

    tags$script(HTML('
  function copyVisibleCode(){
    var which = document.querySelector("input[name=code_choice]:checked").value;
    var srcId = which==="current" ? "code_current" : "code_all";
    var ta    = document.createElement("textarea");
    ta.value  = document.getElementById(srcId).innerText;
    ta.readOnly = true;
    ta.style.position = "absolute"; ta.style.left = "-9999px";
    document.body.appendChild(ta);
    ta.select(); document.execCommand("copy");
    document.body.removeChild(ta);
    Shiny.setInputValue("did_copy_code", Math.random());
  }
  document.addEventListener("shiny:connected", function(){
    var btn = document.getElementById("copy_code_btn");
    if(btn) btn.onclick = copyVisibleCode;
  });
'))
),

  titlePanel(
    div(
      "fluxtools: Interactive QA/QC with Code Generator",
      actionLink("help", label = icon("question-circle"), style = "margin-left:10px;")
    )
  ),  # ← comma was missing after this


  uiOutput("subtitle"),

  sidebarLayout(
    sidebarPanel(
      style = "max-height: calc(100vh - 80px); overflow-y: auto;",
      width = 4,

      tags$h5("Data upload and selection"),
      fileInput("csv_file", "Upload Ameriflux‐style or Fluxnet .csv:", accept = ".csv"),

      hr(),

      # --- UTC select with tooltip on the label ---
      div(
        class = "mb-1",

        # label that owns the tooltip
        tags$label(
          id    = "data_offset_label",
          `for` = "data_offset",
          "View TIMESTAMP_START in:",
          'data-bs-toggle' = "tooltip",
          title = "Display only; no DST. Exports & code keep original timestamps"
        ),


        # the select itself (label=NULL because we just drew our own)
        selectInput(
          "data_offset", label = NULL,
          choices  = sprintf("UTC%+d", -12:14),
          selected = "UTC+0", width = "100%"
        )
      ),

      #how to make this closer to the above? and with smaller italic text?

                tags$details(
            tags$summary("Show timestamp parsing details"),
            tags$pre(style="margin-top:.5rem;", textOutput("tz_check"))
          ),







    # div(style="height:.25rem;"),


      hr(),



      tagAppendAttributes(
        selectizeInput(
          "year_sel", "Select Year(s):",
          choices = NULL, multiple = TRUE,
          options = list(
            placeholder = "– upload to load year(s) –",
            plugins = list("remove_button")
          ),
          width = "100%"
        ),
        'data-bs-toggle' = "tooltip",
        'data-bs-title' = "Filter to one or more years"
      ),
      hr(),


      tags$h5("Plot selection"),
      fluidRow(
        column(
          6,
          tags$label(`for` = "yvar", "Y-axis:", style  = "width:100%; font-weight:500;"),
          tagAppendAttributes(
            selectInput("yvar", NULL, choices = NULL, width = "100%"),
            'data-bs-toggle' = "tooltip",
            title = "Select your Y-axis variable — the column whose values will be set to NA"
          )
        ),
        column(
          6,
          tags$label(`for` = "xvar", "X-axis:", style  = "width:100%; font-weight:500;"),
          tagAppendAttributes(
            selectInput("xvar", NULL, choices = NULL, width = "100%"),
            'data-bs-toggle' = "tooltip",
            title = "Select your X-axis variable"
          )
        )
      ),
      hr(),

      tags$h5("Interact with data"),
      fluidRow(
        column(
          6,
          actionButton(
            "add_sel", "Flag Data",
            width = "100%", icon = icon("check"),
            'data-bs-toggle' = "tooltip",
            title = "Add the selected points to the accumulated removal code"
          )
        ),
        column(
          6,
          actionButton(
            "clear_sel","Clear Selection",
            width = "100%", icon = icon("broom"),
            'data-bs-toggle' = "tooltip",
            title = "Clear all flagged points from the current y-variable from the accumulated removal code"
          )
        )
      ),

      fluidRow(
        column(
          6,
          actionButton(
            "remove_acc","Unflag Data",
            width = "100%", icon = icon("ban"),
            'data-bs-toggle' = "tooltip",
            title = "Remove current selection from the accumulated removal code"
          )
        ),
        column(
          6,
          actionButton(
            "remove","Apply removals",
            width = "100%", icon = icon("trash"),
            'data-bs-toggle' = "tooltip",
            title = "Turn the currently selected Y‐values into NA's and remove from view. These will be reflected in the exported .csv using the 'export cleaned data' button"
          )
        )
      ),

      hr(),

      bslib::accordion(
        id = "qa_sections",
        open = FALSE,

        bslib::accordion_panel(
          title = tagList(icon("sliders-h"), "Flag by value range"),
          value = "range",
          checkboxInput("rng_link_y", "Link selected variable to plot Y-axis", TRUE),
          selectInput("rng_var", "Variable", choices = NULL),
          fluidRow(
            column(6, numericInput("rng_min", "Min (optional)", value = NA)),
            column(6, numericInput("rng_max", "Max (optional)", value = NA))
          ),
          div(class="d-grid gap-2",
              actionButton("rng_flag", "Flag values outside range"))
        ),




        bslib::accordion_panel(
          title = tagList(icon("clock"), "Flag by time"),
          value = "time",
          sliderInput(
            "time_rng", "TIMESTAMP_START range:",
            min   = 0,
            max   = 1,
            value = c(0, 1),
            timeFormat = "%Y-%m-%d\n%H:%M",
            step  = 3600
          ),
          fluidRow(
            column(6, actionButton("time_flag",     "Flag inside",  class = "btn btn-primary w-100")),
            column(6, actionButton("time_flag_out", "Flag outside", class = "btn btn-outline-primary w-100"))
          )
            ),


        bslib::accordion_panel(
          title = tags$span(

            class = "d-inline-flex align-items-center gap-2",
            icon("sliders"),
            tags$span(
              HTML("Physical Range Module&nbsp;(PRM)"),
              'data-bs-toggle'   = "tooltip",
              'data-bs-placement' = "right",
              title              = "Clamp variables to possible physical ranges; out-of-range → NA"
            )
          ),
          value = "prm",

          fluidRow(
            column(
              6,
              actionButton(
                "apply_prm_btn", "Apply PRM",
                width = "100%", icon = icon("sliders-h"),
                'data-bs-toggle'="tooltip",
                title="Clamp to PRM bounds; out-of-range set to NA. Reversible."
              )
            ),
            column(
              6,
              actionButton(
                "undo_prm_btn", "Undo PRM",
                width = "100%", icon = icon("undo"),
                'data-bs-toggle'="tooltip",
                title="Reverts only values changed by the last PRM apply. Other edits unaffected."
              )
            )
          ),


          tags$details(
            tags$summary("PRM options"),
            tagAppendAttributes(
              selectizeInput(
                "prm_families", "Variables (optional):",
                choices = NULL, multiple = TRUE,
                options  = list(
                  placeholder = "Default: All relevant variables matched by PRM",
                  plugins = list("remove_button")
                )
              ),
              'data-bs-toggle'="tooltip",
              title="Type base names like SWC, P, TA, CO2 (we match columns by name prefix, e.g. ^SWC($|_)). Leave empty to apply to all"
            )
          )
        ),

        bslib::accordion_panel(
          title = tagList(icon("bullseye"), "Select outliers"),
          value = "outliers",
          tags$h5("Select outliers"),
          sliderInput("sd_thresh", "Highlight points beyond σ:", min = 0, max = 3, value = 0, step = 1),
          checkboxInput("show_reg", "Show regression line & R²", value = TRUE),
          fluidRow(
            column(
              6,
              tagAppendAttributes(
                actionButton("add_outliers", "Select all ±σ outliers", width="100%"),
                'data-bs-toggle' = "tooltip",
                title = "Select every point whose residual is beyond ± n standard deviations (σ) from the regression line and add to the accumulated code"
              )
            ),
            column(
              6,
              tagAppendAttributes(
                actionButton("clear_outliers", "Clear ±σ outliers", width="100%"),
                'data-bs-toggle' = "tooltip",
                title = "Remove ± n standard deviations (σ) from the regression line from your the accumulated code"
              )
            )
          )
        ),

        bslib::accordion_panel(
          title = tagList(icon("code"), "Code generation"),
          value = "code",

          fluidRow(
            class = "align-items-center g-2",
            style = "display: flex; align-items: center; margin-bottom: 0.5rem;",

            column(
              width = 8, style = "padding-right: 0;",
              div(
                class = "mb-0",
                radioButtons(
                  "code_choice", NULL,
                  choiceNames  = list(
                    tagList(icon("code"), HTML("&nbsp;Current")),
                    tagList(icon("list-ul"), HTML("&nbsp;Accumulated"))
                  ),
                  choiceValues = c("current", "all"),
                  inline       = TRUE
                )
              )
            ),

            column(
              width = 4, class = "copy-button-col",
              tags$button(
                id    = "copy_code_btn",
                type  = "button",
                class = "btn btn-outline-secondary w-100 d-inline-flex align-items-center justify-content-center gap-2",
                #class = "btn btn-outline-secondary w-100",
                #"Copy visible code",
                'data-bs-toggle' = "tooltip",
                title = "Copy visible code",
                icon("clipboard"),
                span("Copy code"),
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
          ")
              )
            )
          ),

          uiOutput("code_ui"),

          conditionalPanel(
            "input.code_choice == 'all'",
            actionButton(
              "reset_accum", "Clear accumulated",
              width = "100%",
              'data-bs-toggle'="tooltip",
              title = "Remove all points from accumulated list"
            )
          )
        )
      ),

      hr(),

      fluidRow(
        column(
          4,
          downloadButton("download_data", "Export cleaned data", icon = icon("file-archive"), width="100%"),
          'data-bs-toggle' = "tooltip",
          title = "Download a .zip containing the cleaned CSV (with NAs applied using the 'Apply Removals' button) and the removal R-script"
        ),
        column(
          4,
          actionButton("reset_data", "Reload original data", icon = icon("eraser"), width="100%"),
          'data-bs-toggle' = "tooltip",
          title = "Reset any changes by re-loading the original .csv file"
        ),
        column(
          4,
          div(style="margin-top:0.5em;", checkboxInput("dark_mode","Dark mode",FALSE))
        )
      )
    ),

    mainPanel(
      width = 8,
      plotlyOutput("qc_plot", width = "100%", height = "80vh")
    )
  )
)





server <- function(input, output, session) {


  #PRM
  # --- init reactive stores early (so we can use rv immediately) ---
  rv <- reactiveValues(
    df = NULL,
    df_before_prm = NULL,
    prm_active = FALSE,
    prm_summary = NULL,
    prm_mask = NULL
  )

  last_sel <- reactiveValues(x = NULL, y = NULL)

  observeEvent(input$xvar, { last_sel$x <- input$xvar }, ignoreInit = TRUE)
  observeEvent(input$yvar, { last_sel$y <- input$yvar }, ignoreInit = TRUE)


  #UTC check

  output$tz_check <- renderText({
    df <- rv$df
    if (is.null(df) || !nrow(df)) return("Upload a CSV to see timestamp parsing…")

    off <- data_off_hr()
    rec <- data_tz()

    paste0(
      "First row:\n",
      "  raw:                   ", df$raw_ts[1], "\n",
      sprintf("  recorded clock (UTC%+d): %s\n", off,
              format(df$TIMESTAMP_START[1] + off*3600, "%Y-%m-%d %H:%M %Z", tz = rec)),
      "  absolute UTC:          ", format(df$TIMESTAMP_START[1], "%Y-%m-%d %H:%M %Z", tz = "UTC")
    )
  })



  # create, don't set yet
  orig_df <- reactiveVal(NULL)

  # put this right after rv/orig_df are created (and BEFORE any observeEvent that uses them)
  sel_keys       <- reactiveVal(integer(0))
  outlier_keys   <- reactiveVal(integer(0))
  removed_ts     <- reactiveValues()
  confirmed_ts   <- reactiveValues()
  selected_keys  <- reactive({
    sel <- tryCatch(plotly::event_data("plotly_selected", source = "qc_plot"),
                    error = function(e) NULL)
    if (is.null(sel)) integer(0) else sel$key
  })


  # small helper used later
  `%||%` <- function(x, y) if (is.null(x)) y else x


  # helper (put near other helpers)
  infer_cadence_sec <- function(ts) {
    d <- diff(sort(unique(as.numeric(ts))))
    if (!length(d)) return(3600L)
    # robust guess: median rounded to 30m or 60m
    guess <- as.integer(round(median(d)))
    if (abs(guess - 1800L) < abs(guess - 3600L)) 1800L else 3600L
  }

  align_to_step <- function(t, step) as.POSIXct(floor(as.numeric(t) / step) * step, origin = "1970-01-01", tz = "UTC")
  ceil_to_step  <- function(t, step) as.POSIXct(ceiling(as.numeric(t) / step) * step, origin = "1970-01-01", tz = "UTC")

  # is the package available? (used by the safe wrappers)
  have_flux <- requireNamespace("fluxtools", quietly = TRUE)

  resolve_prm_fun <- function(name) {
    # 1) dev override from search path
    if (exists(name, mode = "function", inherits = TRUE)) return(get(name, mode = "function"))

    # 2) exported from fluxtools
    if (have_flux) {
      ns <- asNamespace("fluxtools")
      if (exists(name, envir = ns, mode = "function")) return(get(name, envir = ns, mode = "function"))
      if (exists(name, where = "package:fluxtools", mode = "function", inherits = FALSE)) {
        return(get(name, asNamespace("fluxtools")))
      }
    }
    NULL
  }

  get_rules <- function() {
    fn <- resolve_prm_fun("get_prm_rules")
    if (is.null(fn)) return(NULL)
    fn()
  }

  apply_prm_safe <- function(df, include = NULL) {
    fn <- resolve_prm_fun("apply_prm")
    if (is.null(fn)) stop("PRM not available in your installed 'fluxtools' (apply_prm missing)")
    fn(df, include = include, note = FALSE, summarize = TRUE)  # keep pkg defaults (skip_qc=TRUE)
  }

  #time range
  # rng_var -> yvar
  is_syncing <- reactiveVal(FALSE)

  observeEvent(input$rng_var, {
    if (isTRUE(input$rng_link_y) && !is_syncing()) {
      is_syncing(TRUE)
      on.exit(is_syncing(FALSE), add = TRUE)
      if (!is.null(input$rng_var) && !identical(input$yvar, input$rng_var)) {
        freezeReactiveValue(input, "yvar")
        updateSelectInput(session, "yvar", selected = input$rng_var)
      }
    }
  }, ignoreInit = TRUE)

  observeEvent(input$yvar, {
    if (isTRUE(input$rng_link_y) && !is_syncing()) {
      is_syncing(TRUE)
      on.exit(is_syncing(FALSE), add = TRUE)
      if (!is.null(input$yvar) && !identical(input$rng_var, input$yvar)) {
        freezeReactiveValue(input, "rng_var")
        updateSelectInput(session, "rng_var", selected = input$yvar)
      }
    }

    # Clear current brush/selection and rebuild orange “accumulated” for this yvar
    sel_keys(integer(0))
    session$resetBrush("qc_plot")
    current_ts <- removed_ts[[ input$yvar ]] %||% character()
    if (length(current_ts)) {
      matching_rows <- which(df_by_year()$ts_str %in% current_ts)
      sel_keys(matching_rows)
    }
  }, ignoreInit = TRUE)

  observeEvent(input$time_flag, {
    tr <- input$time_rng; req(tr)
    df <- df_by_year()
    idx <- which(df$TIMESTAMP_START >= tr[1] & df$TIMESTAMP_START <= tr[2])
    if (!length(idx)) { showNotification("No points in that time range.", type = "message"); return() }
    rows <- df$.row[idx]
    sel_keys(unique(c(isolate(sel_keys()), rows)))
    ts <- df$ts_str[idx]
    # add to *current Y variable’s* removal set (that’s the one you’ll mutate on “Apply removals”)
    v <- input$yvar
    old <- removed_ts[[v]] %||% character()
    removed_ts[[v]] <- unique(c(old, ts))
  })

  observeEvent(input$time_flag_out, {
    tr <- input$time_rng; req(tr)
    df <- df_by_year()
    idx <- which(df$TIMESTAMP_START < tr[1] | df$TIMESTAMP_START > tr[2])
    if (!length(idx)) { showNotification("No points outside that time range.", type = "message"); return() }
    rows <- df$.row[idx]
    sel_keys(unique(c(isolate(sel_keys()), rows)))
    ts <- df$ts_str[idx]
    v <- input$yvar
    old <- removed_ts[[v]] %||% character()
    removed_ts[[v]] <- unique(c(old, ts))
  })

  # returns +3 for "UTC+3", -5 for "UTC-5"
  # --- helpers ---
  parse_utc_hours <- function(lbl) as.integer(sub("UTC([+-]?\\d+).*", "\\1", lbl))

  data_off_hr <- reactive({ parse_utc_hours(req(input$data_offset)) })
  data_tz <- reactive({
    off <- data_off_hr()
    if (off == 0) "UTC" else paste0("Etc/GMT", if (off < 0) "+" else "-", abs(off))  # POSIX sign flip
  })

  # raw csv
  raw_df <- reactive({
    req(input$csv_file)
    read.csv(
      input$csv_file$datapath,
      stringsAsFactors = FALSE,
      colClasses = c(TIMESTAMP_START = "character"),
      na.strings = "-9999"
    )
  })

  # parse respecting *data*'s stated offset, then map to absolute UTC
  shifted_df <- reactive({
    df0 <- raw_df(); req(df0, input$data_offset)

    # 1) keep only digits, then right-pad minutes to 12 chars
    digits <- gsub("[^0-9]", "", df0$TIMESTAMP_START %||% "")
    digits <- substr(paste0(digits, "0000"), 1, 12)  # handles YYYYMMDDHH or YYYYMMDD

    # 2) parse as clock-time, then shift to absolute UTC by the *data's* stated offset
    off_hr <- parse_utc_hours(input$data_offset)

    ts_parsed <- as.POSIXct(digits, format = "%Y%m%d%H%M", tz = "UTC")
    ts_utc    <- ts_parsed - off_hr * 3600


    #ts_parsed <- suppressWarnings(as.POSIXct(digits, format = "%Y%m%d%H%M", tz = "UTC"))
    # if *everything* failed to parse, abort politely
    if (!any(!is.na(ts_parsed))) {
      showNotification("Could not parse TIMESTAMP_START. Check the column and the UTC offset.", type = "error", duration = 8)
      req(FALSE)
    }



    df0 %>%
      mutate(
        raw_ts          = TIMESTAMP_START,
        ts_str          = digits,
        TIMESTAMP_START = ts_utc,
        .row            = dplyr::row_number()
      )
  })

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

  #PRM Server
  #PRM help table
  output$help_prm_table <- renderTable({
    rules <- get_rules()
    if (is.null(rules)) {
      return(data.frame(
        Note    = "Load 'fluxtools' in this R session to view the PRM table here",
        Example = "library(fluxtools); get_prm_rules()"
      ))
    }
    rules[, c("variable","description","units","min","max")]
  })

  #prm reactive values
  rv$prm_active     <- FALSE
  rv$df_before_prm  <- NULL
  rv$prm_summary    <- NULL

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

#Tooltip thats automatic and obvious (doesnt need mouse hover)
  # observe({
  #   off <- data_off_hr()
  #   tip <- sprintf(
  #     "Viewing timestamps as UTC%+d (fixed offset; no DST)<br>
  #    Viewer-only: this setting does not change the exported file<br>
  #    Generated code and exports match the original TIMESTAMP_START string",
  #     off
  #   )
  #   session$sendCustomMessage(
  #     "updateTooltip",
  #     list(id = "data_offset_label", title = tip, customClass = "tt-compact")
  #   )
  # })

  # observe({
  #   off <- data_off_hr()
  #   tip <- sprintf(
  #     "Viewing timestamps as UTC%+d<br>Fixed offset; no DST<br>Viewer-only: this setting does not change the exported file<br>Generated code and exports match the original TIMESTAMP_START string",
  #     off
  #   )
  #   session$sendCustomMessage(
  #     "updateTooltip",
  #     list(id = "data_offset_label", title = tip, customClass = "tt-compact")
  #   )
  # })

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

    #Prm
    # PRM family choices present in the data
    # PRM variable choices present in the uploaded data
  # Put this somewhere in server() AFTER rv$df exists:
  observe({
    req(rv$df)
    present <- tryCatch({
      rules <- get_rules()
      if (is.null(rules)) character(0) else {
        base <- unique(rules$variable)
        base[vapply(
          base,
          function(b) any(grepl(paste0("^", b, "($|_)"), names(rv$df))),
          logical(1)
        )]
      }
    }, error = function(e) character(0))

    updateSelectizeInput(
      session, "prm_families",
      choices  = present,
      options  = list(
        placeholder = if (length(present)) "All variables" else "PRM not available; install/upgrade fluxtools",
        plugins     = list("remove_button"),
        create      = FALSE
      )
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

  # replace your current observeEvent(df_by_year(), { ... }) with this:
  observe({
    df <- df_by_year(); y <- input$yvar; req(df, y)
    ts <- df$TIMESTAMP_START[!is.na(df[[y]]) & !is.na(df$TIMESTAMP_START)]
    if (length(ts) >= 2) {
      step <- infer_cadence_sec(ts)       # 1800 or 3600
      r    <- range(ts)
      r[1] <- align_to_step(r[1], step)
      r[2] <- ceil_to_step(r[2],  step)
      updateSliderInput(session, "time_rng",
                        min = r[1], max = r[2], value = r,
                        step = step, timeFormat = "%Y-%m-%d\n%H:%M"
      )
    } else {
      # fallback: use whole data range if possible, otherwise a tiny dummy range
      rng_all <- range(df$TIMESTAMP_START, na.rm = TRUE)
      if (all(is.finite(rng_all))) {
        step_f <- 3600L
        r1 <- align_to_step(rng_all[1], step_f)
        r2 <- ceil_to_step(rng_all[2],  step_f)
        updateSliderInput(session, "time_rng",
                          min = r1, max = r2, value = c(r1, r2),
                          step = step_f, timeFormat = "%Y-%m-%d\n%H:%M"
        )
      } else {
        updateSliderInput(session, "time_rng", min = 0, max = 1, value = c(0, 1), step = 3600)
      }
    }
  })

  #  Clear *current* selection in the code box:
  observeEvent(input$clear_sel, {
    # 1) clear the lasso brush
    session$resetBrush("qc_plot")
    # 2) clear the “current” keys
    sel_keys(integer(0))
  })

  # Show PRM summary table in a modal
  output$prm_summary_tbl <- renderTable({
    s <- rv$prm_summary
    req(s)
    rules <- get_rules()
    if (!is.null(rules)) {
      u_map <- setNames(rules$units, rules$variable)
      s$units <- unname(u_map[s$family])
    } else {
      s$units <- NA_character_
    }
    s$pct_replaced <- round(s$pct_replaced, 1)
    s[, c("column","family","units","min","max","n_replaced","pct_replaced")]
  })

  observeEvent(input$apply_prm_btn, {
    req(rv$df)
    if (isTRUE(rv$prm_active)) {
      showNotification("PRM already applied. Use “Undo PRM” to revert", type="message")
      return()
    }
    before <- rv$df
    fam    <- input$prm_families

    res <- try(apply_prm_safe(before, include = if (length(fam)) fam else NULL), silent = TRUE)
    if (inherits(res, "try-error")) {
      showNotification(
        "PRM function not found in your 'fluxtools' version. Update or load the dev build",
        type = "error", duration = 6
      )
      return()
    }
    after <- res$data

    # Build a mask of cells PRM set to NA (by .row so we can map regardless of filters)
    mask <- list()
    common <- intersect(names(before), names(after))
    for (nm in common) {
      if (!is.numeric(before[[nm]]) || !is.numeric(after[[nm]])) next
      idx <- which(!is.na(before[[nm]]) & is.na(after[[nm]]))
      if (length(idx)) {
        mask[[nm]] <- data.frame(.row = before$.row[idx], old = before[[nm]][idx])
      }
    }

    rv$df          <- after
    rv$prm_summary <- res$summary
    rv$prm_mask    <- mask
    rv$prm_active  <- TRUE

    ncols <- if (nrow(res$summary)) length(unique(res$summary$column)) else 0L
    nrep  <- if (nrow(res$summary)) sum(res$summary$n_replaced, na.rm = TRUE) else 0L
    showNotification(sprintf("PRM applied: %d columns checked, %d values set to NA.", ncols, nrep),
                     type = "message", duration = 4)

    showModal(modalDialog(
      title = "PRM summary",
      tagList(
        tags$p("Expected units and PRM bounds are shown per column. Out-of-range values were set to NA."),
        tableOutput("prm_summary_tbl")
      ),
      size = "l",
      easyClose = TRUE
    ))
  })

  observeEvent(input$undo_prm_btn, {
    if (!isTRUE(rv$prm_active) || is.null(rv$prm_mask)) {
      showNotification("Nothing to undo.", type = "message")
      return()
    }
    tmp <- rv$df
    # Restore only cells PRM nulled that are still NA now (so later user edits are preserved)
    for (nm in names(rv$prm_mask)) {
      rows <- rv$prm_mask[[nm]]$.row
      old  <- rv$prm_mask[[nm]]$old
      pos  <- match(rows, tmp$.row)
      keep <- !is.na(pos) & is.na(tmp[[nm]][pos])
      if (any(keep)) tmp[[nm]][pos[keep]] <- old[keep]
    }
    rv$df <- tmp
    rv$prm_mask <- NULL
    rv$prm_summary <- NULL
    rv$prm_active <- FALSE
    showNotification("Undid PRM-only changes.", type = "message", duration = 3)
  })

  observeEvent(shifted_df(), {
    df <- shifted_df(); req(df)
    rv$df <- df; orig_df(df)

    # Choices
    num_cols <- df %>%
      dplyr::select(-TIMESTAMP_START, -raw_ts, -ts_str, -.row) %>%
      dplyr::select(where(is.numeric)) %>% names()
    x_choices <- c("TIMESTAMP_START", num_cols)
    y_choices <- num_cols

    # Remember current selections (if any)
    prev_x <- isolate(input$xvar)
    prev_y <- isolate(input$yvar)

    # Year list
    yrs <- sort(unique(format(df$TIMESTAMP_START, "%Y")))
    yrs <- yrs[!is.na(yrs)]
    if (!length(yrs)) {
      # fall back to "All" only; avoids NA in choices
      updateSelectizeInput(session, "year_sel",
                           choices  = c("All"),
                           selected = "All",
                           server   = TRUE
      )
    } else {
      updateSelectizeInput(session, "year_sel",
                           choices  = c("All", yrs),
                           selected = isolate(if (is.null(input$year_sel)) "All" else input$year_sel),
                           server   = TRUE
      )
    }


    # Only change selected values if they’re invalid under the new choices
    sel_x <- if (!is.null(prev_x) && prev_x %in% x_choices) prev_x else "TIMESTAMP_START"
    sel_y <- if (!is.null(prev_y) && prev_y %in% y_choices) prev_y else (y_choices[1] %||% "")

    # Freeze to avoid triggering observeEvent(input$xvar/yvar) while we update
    freezeReactiveValue(input, "xvar")
    freezeReactiveValue(input, "yvar")

    updateSelectInput(session, "xvar", choices = x_choices, selected = sel_x)
    updateSelectInput(session, "yvar", choices = y_choices, selected = sel_y)

    # Keep rng_var aligned *once* on data reset, not continuously
    freezeReactiveValue(input, "rng_var")
    updateSelectInput(session, "rng_var", choices = y_choices,
                      selected = if (!is.null(sel_y) && sel_y %in% y_choices) sel_y else y_choices[1])

    # Initialize/refresh the time slider from data
    # Initialize/refresh the time slider from data
    rng  <- range(df$TIMESTAMP_START, na.rm = TRUE)
    step <- infer_cadence_sec(df$TIMESTAMP_START)

    updateSliderInput(
      session, "time_rng",
      min = rng[1], max = rng[2], value = rng,
      step = step, timeFormat = "%Y-%m-%d\n%H:%M"
    )

    # Build time slider from actual cadence (30m or 60m) again using non-NA timestamps
    ts_all <- df$TIMESTAMP_START[!is.na(df$TIMESTAMP_START)]
    if (length(ts_all) >= 2) {
      step0 <- infer_cadence_sec(ts_all)
      r0    <- range(ts_all)
      r0[1] <- align_to_step(r0[1], step0)
      r0[2] <- ceil_to_step(r0[2],  step0)
      updateSliderInput(
        session, "time_rng",
        min = r0[1], max = r0[2], value = r0,
        step = step0, timeFormat = "%Y-%m-%d\n%H:%M"
      )
    } else {
      updateSliderInput(session, "time_rng", min = 0, max = 1, value = c(0, 1))
    }





  })

  observeEvent(input$rng_flag, {
    req(input$rng_var)
    df <- df_by_year()
    v  <- input$rng_var
    idx <- which( (!is.na(input$rng_min) & df[[v]] < input$rng_min) |
                    (!is.na(input$rng_max) & df[[v]] > input$rng_max) )
    if (!length(idx)) { showNotification("No points outside that range.", type="message"); return() }
    rows <- df$.row[idx]
    sel_keys(unique(c(isolate(sel_keys()), rows)))
    ts <- df$ts_str[idx]
    old <- removed_ts[[v]] %||% character()
    removed_ts[[v]] <- unique(c(old, ts))
  })

  observeEvent(input$rng_clear, {
    v <- input$rng_var; req(v)
    ts_v <- removed_ts[[v]] %||% character()
    if (!length(ts_v)) return()
    keep <- !(df_by_year()$ts_str %in% ts_v)
    sel_keys(which(keep))
    removed_ts[[v]] <- NULL
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

        #PRM info
        tabPanel(
          "PRM",
          tagList(
            tags$p(
              "The Physical Range Module (PRM) clamps variables to physically ",
              "reasonable ranges (AmeriFlux Technical Note, Table A1). Values ",
              "outside bounds are set to NA. Families are matched by name prefix ",
              "(e.g., '^SWC($|_)')."
            ),
            tags$ul(
              tags$li(tags$b("Apply PRM:"), " Sidebar → ", tags$code("Apply PRM"),
                      " (reversible via ", tags$code("Undo PRM"), ")"),
              tags$li(tags$b("Variables:"), " optionally limit PRM to specific variable groups (e.g., SWC, P, TA, CO2)")
            ),
            tags$h5("PRM bounds"),
            tableOutput("help_prm_table")
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

    # use absolute UTC for data; make a view-only shifted time for plotting/labels
    if (identical(input$xvar, "TIMESTAMP_START")) {
      dfc$ts_view <- dfc$TIMESTAMP_START + data_off_hr()*3600
    }


    p <- plot_ly(
      data   = dfc,
      x      = if (identical(input$xvar, "TIMESTAMP_START")) ~ts_view else ~.data[[input$xvar]],
      y      = ~.data[[input$yvar]],
      key    = ~.row,
      source = "qc_plot",
      mode   = "markers",
      type   = "scatter",
      marker = list(color = marker_blue, opacity = 0.8)
    ) %>%
      event_register("plotly_selected")





    # Plot the ±σ outliers as red
  # outliers layer
  if (input$sd_thresh > 0) {
    p <- p %>%
      add_trace(
        data = dplyr::filter(dfc, flag == "outlier"),
        x    = if (identical(input$xvar, "TIMESTAMP_START")) ~ts_view else ~.data[[input$xvar]],
        y    = ~.data[[input$yvar]],
        mode = "markers",
        type = "scatter",
        marker = list(color = "#F05039", opacity = 0.8),
        showlegend = FALSE
      )
  }

  # accumulated layer
  if (length(sel_keys()) > 0) {
    p <- p %>%
      add_trace(
        data = dfc %>% dplyr::filter(.row %in% sel_keys()),
        x    = if (identical(input$xvar, "TIMESTAMP_START")) ~ts_view else ~.data[[input$xvar]],
        y    = ~.data[[input$yvar]],
        mode = "markers",
        type = "scatter",
        marker = list(color = "#FFC107"),
        inherit = FALSE,
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

        xaxis = if (input$xvar == "TIMESTAMP_START") {
          list(type = "date",
               tickformat = "%b %d\n%H:%M",
               title = sprintf("TIMESTAMP_START (UTC%+d)", data_off_hr()))
        } else list(title = input$xvar),
        yaxis = list(title = input$yvar)
      ) %>%
      event_register("plotly_selected")
  })

  # ────────────────────────────────────────────────────────────────────────────
  # Preview table (same as before)
  # ────────────────────────────────────────────────────────────────────────────
  output$preview <- renderTable({
    keys <- selected_keys(); if (length(keys) == 0) keys <- sel_keys()
    if (length(keys) == 0) return(NULL)

    hrs <- data_off_hr()
    local_label <- sprintf("Timestamp (UTC%+d)", hrs)

    df_by_year() %>%
      dplyr::filter(.row %in% keys) %>%
      dplyr::mutate(
        !!local_label := format(TIMESTAMP_START, "%Y-%m-%d %H:%M", tz = data_tz())
      ) %>%
      dplyr::select(all_of(local_label), !!rlang::sym(input$yvar), raw_ts) %>%
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
    cfs <- reactiveValuesToList(confirmed_ts)
    cfs <- cfs[vapply(cfs, length, FUN.VALUE = integer(1)) > 0]
    if (!length(cfs)) {
      return("\n<!-- no confirmed removals yet (click “Apply removals”) -->\n")
    }
    snippets <- lapply(names(cfs), function(var) {
      ts    <- cfs[[var]]
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

#   output$code_all <- renderText({
#     #all_removals <- reactiveValuesToList(removed_ts)
#     all_removals <- all_removals[vapply(all_removals, length, FUN.VALUE = integer(1)) > 0]
#     if (length(all_removals) == 0) {
#       return("
#
# <!-- click “Flag Data” or “Add all ±σ outliers” → see code here -->
#
# ")
#     }
#     snippets <- lapply(names(all_removals), function(var) {
#       ts    <- all_removals[[var]]
#       conds <- paste0("TIMESTAMP_START == '", ts, "' ~ NA_real_", collapse = ",\n      ")
#       paste0(
#         "df <- df %>%\n",
#         "  mutate(\n",
#         "    ", var, " = case_when(\n",
#         "      ", conds, ",\n",
#         "      TRUE ~ ", var, "\n",
#         "    )\n",
#         "  )"
#       )
#     })
#     paste(unlist(snippets), collapse = "\n\n")
#   })

  # ────────────────────────────────────────────────────────────────────────────
  # Removed‐points code snippet (only those Confirm Removed)
  # ────────────────────────────────────────────────────────────────────────────
  output$removed_code <- renderText({
    # pulled_ts is the character‐vector of ts_str values that we have already “confirmed” as removed, for the current y‐variable
    #pulled_ts <- removed_ts[[input$yvar]] %||% character()
    pulled_ts <- confirmed_ts[[input$yvar]] %||% character()
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


  #UTC helper
  #finish these!
  # put near your other helpers
  # Map offsets to friendlier labels
  pretty_tz_label <- function(h) {
    name <- switch(as.character(h),
                   "-12"="Baker/Howland (UTC-12)",
                   "-11"="Samoa (UTC-11)",
                   "-10"="Hawaii–Aleutian (UTC-10)",
                   "-9" ="Alaska (UTC−9)",
                   "-8" ="Pacific (UTC−8)",
                   "-7" ="Mountain (UTC−7)",
                   "-6" ="Central (UTC−6)",
                   "-5" ="Eastern (UTC−5)",
                   "-4" ="Atlantic (UTC−4)",
                   "-3" ="Argentina/Brazil (UTC−3)",
                   "-2" ="UTC−2",                         # ← this is present
                   "-1" ="Azores (UTC−1)",
                   "0"  ="Coordinated Universal Time (UTC±0)",
                   "1"  ="Central Europe (UTC+1)",
                   "2"  ="Eastern Europe (UTC+2)",
                   "3"  ="Moscow/East Africa (UTC+3)",
                   "4"  ="Gulf (UTC+4)",
                   "5"  ="Pakistan (UTC+5)",
                   "6"  ="Bangladesh (UTC+6)",
                   "7"  ="Indochina (UTC+7)",
                   "8"  ="China/Western Australia (UTC+8)",
                   "9"  ="Japan/Korea (UTC+9)",
                   "10" ="AEST (UTC+10)",
                   "11" ="New Caledonia (UTC+11)",
                   "12" ="NZST/Fiji (UTC+12)",
                   "13" ="Tonga (UTC+13)",
                   "14" ="Line Islands (UTC+14)",
                   sprintf("UTC%+d", h)
    )
    name
  }


  # Build labeled choices once (−12…+14)
  observe({
    offs   <- -12:14
    values <- sprintf("UTC%+d", offs)
    labels <- vapply(offs, pretty_tz_label, character(1))
    names(values) <- labels

    # keep current selection if present; otherwise default to UTC+0
    sel <- isolate(input$data_offset)
    if (is.null(sel) || !sel %in% values) sel <- "UTC+0"

    updateSelectInput(session, "data_offset", choices = values, selected = sel)
  })



  # --- put near other helpers ---
  nearest_stamp <- function(x, pool) {
    pool[ which.min(abs(as.numeric(pool) - as.numeric(x))) ]
  }

  # Debounce slider changes so we only react after the user pauses/releases.
  time_rng_raw <- reactive({ input$time_rng })
  time_rng_debounced <- debounce(time_rng_raw, 150)   # 150–250ms feels snappy

  # Replace your existing is_snapping/observeEvent(input$time_rng, ...) with this:
  observeEvent(time_rng_debounced(), ignoreInit = TRUE, {
    df <- df_by_year(); y <- input$yvar; req(df, y)
    pool <- sort(unique(df$TIMESTAMP_START[!is.na(df[[y]]) & !is.na(df$TIMESTAMP_START)]))
    if (length(pool) < 2) return()

    tr   <- time_rng_debounced()
    tr2  <- c(nearest_stamp(tr[1], pool), nearest_stamp(tr[2], pool))
    if (!identical(tr, tr2)) {
      updateSliderInput(session, "time_rng", value = tr2)
    }
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
    rv$df <- orig_df()
    updateSelectizeInput(session, "year_sel", selected = "All")

    for (nm in names(reactiveValuesToList(removed_ts)))   removed_ts[[nm]]   <- NULL
    for (nm in names(reactiveValuesToList(confirmed_ts))) confirmed_ts[[nm]] <- NULL  # ✅ add this

    sel_keys(integer(0)); outlier_keys(integer(0))
    session$resetBrush("qc_plot")
  })

}

shinyApp(ui, server)
