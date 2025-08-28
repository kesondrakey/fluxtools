library(shiny)
library(plotly)
library(dplyr)
library(bslib)     # for theming
library(shinyWidgets) #for time selector

# Allow larger uploads (here: up to 1gb)
options(shiny.maxRequestSize = 1024 * 1024 * 1024) #1gb

## ── 1) Theme ───────────────────────────────────────────────────────
light_theme <- bs_theme(
  bootswatch = "cerulean",
  base_font_size  = "14px",    # ← bump this up (default is 14px)
  font_scale      = 1        # ← or scale everything to 120%
)

dark_theme <- bs_theme(
  version        = 5,
  bootswatch     = "slate",
  base_font_size  = "14px",    # ← bump this up (default is 14px)
  font_scale      = 1,        # ← or scale everything to 120%
  fg             = "#EEE",
  bg             = "#222",
  input_bg       = "#333",
  input_fg       = "#EEE"#,
)

ui <- fluidPage(
  style = "height:100vh; overflow:hidden;",
  theme = light_theme,

  tags$head(
    tags$style(HTML("
  /* shrink tables inside modals + PRM help */
  #help_prm_table, #prm_summary_tbl, .modal-body table {
    font-size: 0.8rem;
  }
  /* wrap tables so they scroll instead of overflowing */
  .table-wrap { max-width:100%; overflow-x:auto; }
")),

    tags$style(HTML('
          .swatch-row { display:flex; align-items:center; gap:.5rem; margin:.25rem 0; }
      .sw { width:14px; height:14px; border-radius:50%; display:inline-block;
            border:1px solid rgba(0,0,0,.25); }
      .ring { width:14px; height:14px; border-radius:50%; display:inline-block;
              background:transparent; border:2px solid currentColor; box-sizing:border-box; }
      html[data-bs-theme="slate"] .sw { border-color: rgba(255,255,255,.35); }

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




tags$script(HTML("
document.addEventListener('keydown', function(e){
  // when focus is inside the Selectize control for prm_families
  var wrap = document.querySelector('#prm_families + .selectize-control');
  if (!wrap) return;
  var hasFocus = wrap.contains(document.activeElement);
  if (hasFocus && e.key === 'Enter') {
    var btn = document.getElementById('apply_prm_btn');
    if (btn) btn.click();
  }
});
")),

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

     # --- UTC select with tooltip on the label ---
     tags$details(
       # default is closed; omit or set open = FALSE
       # open = FALSE,
       tags$summary(HTML('<i class="fa fa-globe"></i> Set Timezone')),

       # UTC select with tooltipbed label
       div(class = "mb-2 mt-2",
           tags$label(
             id    = "data_offset_label",
             `for` = "data_offset",
             "View TIMESTAMP_START in:",
             'data-bs-toggle' = "tooltip",
             title = "Fixed timestamp; no DST"
           ),
           selectInput(
             "data_offset", label = NULL,
             choices  = sprintf("UTC%+d", -12:14),
             selected = "UTC+0", width = "100%"
           ),
           tags$small(class = "form-text text-muted fst-italic",
                      "This only changes how times are shown in the app; exports keep original strings.")
       ),

       # Nest the parsing details inside the same wrapper
       tags$details(
         class = "mt-1",
         tags$summary("Show timestamp parsing details"),
         tags$pre(style = "margin-top:.5rem;", textOutput("tz_check"))
       )
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

    # --- Overlay mode ---
    checkboxInput("overlay_mode", "Plot multiple variables", FALSE),
    conditionalPanel(
      "input.overlay_mode",
      div(
        class = "d-flex align-items-end gap-2",
        div(
          style="flex:1;",
          selectizeInput(
            "overlay_vars", "Overlay variables",
            choices = NULL, multiple = TRUE,
            options = list(placeholder = "Choose ≥1 variables",
                           plugins = list("remove_button")), #did i mess this up?
            width = "100%"
          ),
          checkboxInput("overlay_include_y", "Include current y-variable", TRUE),
          selectInput(
            "overlay_palette", "Overlay palette",
            choices = c(
              "Okabe–Ito"       = "okabe",
              "Tableau 10"      = "tableau10",
              "Set2 (pastel)"   = "set2",
              "Viridis (dark)"  = "viridis",
              "Key"             = "key"
            ),
            selected = "okabe", width = "100%"
          )
        )
      )
    ),

    # Advanced: flag style & markers (applies to overlay and single-Y)
    tags$details(
      id = "adv_flags",
      tags$summary(HTML('<i class="fa fa-sliders-h"></i> Advanced (flag style & markers)')),

      #color selection
      # Y color (single-Y only)
      tags$small(class="text-muted",
                 "y-axis color selection applies only to the single-variable view. ",
                 "Plotting multiple variables use color palettes"),

      conditionalPanel(
        "!input.overlay_mode",
        selectInput(
          "y_color_style", "y-axis color (single view)",
          choices = c(
            "Theme accent (default)" = "default",
            "Black"        = "black",
            "Custom"                = "custom"
          ),
          selected = "default", width = "100%"
        ),
        conditionalPanel(
          "input.y_color_style == 'custom'",
          textInput("y_color_custom", "Custom hex", value = "#1F449C", width = "100%")
        )
      ),


      # universal: used in overlay and single-Y
      selectInput(
        "flag_color_scheme", "Flag color style",
        choices = c(
          "Yellow (classic)"              = "yellow",
          "Match variable (darker)"       = "match_dark",
          "Match variable (lighter)"      = "match_light"#,
          #"Accessible pair (color-blind)" = "accessible"
        ),
        selected = "yellow", width = "100%"
      ),

      # small copy tweak so it makes sense in single-Y too
      checkboxInput("show_pair_legend", "Show color key", TRUE),
      uiOutput("pair_legend"),
      checkboxInput("overlay_hollow", "Use hollow circles", TRUE),
      sliderInput("overlay_size",  "Point size",        min = 1,  max = 14, value = 6,  step = 1),
      sliderInput("flag_size",     "Flag point size",   min = 1,  max = 14, value = 8,  step = 1),


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

#flag by range
        bslib::accordion_panel(
          title = tagList(icon("sliders-h"), "Flag by value range"),
          value = "range",
          checkboxInput("rng_link_y", "Link selected variable to plot Y-axis", TRUE),
          selectInput("rng_var", "Variable", choices = NULL),
          div(class = "mt-1", uiOutput("rng_scope_ui")),

          fluidRow(
            column(6, numericInput("rng_min", "Min (optional)", value = NA)),
            column(6, numericInput("rng_max", "Max (optional)", value = NA))
          ),
          div(class="d-grid gap-2",
              actionButton("rng_flag", "Flag values outside range"))
        ),

#flag by time
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
            column(
              6,
              shinyWidgets::airDatepickerInput(
                inputId    = "start_dt",
                label      = "Start:",
                timepicker = TRUE,
                autoClose  = TRUE,
                placeholder = "Select start"
              )
            ),
            column(
              6,
              shinyWidgets::airDatepickerInput(
                inputId    = "end_dt",
                label      = "End:",
                timepicker = TRUE,
                autoClose  = TRUE,
                placeholder = "Select end"
              )
            )
          ),

          fluidRow(
            column(6, actionButton("time_flag",     "Flag inside",  class = "btn btn-primary w-100")),
            column(6, actionButton("time_flag_out", "Flag outside", class = "btn btn-outline-primary w-100"))
          )
            ),

#Select outliers
        bslib::accordion_panel(
          title = tagList(icon("wave-square"), "Select outliers"),
          #title = tagList(icon("bullseye"), "Select outliers"),
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

            ),
            tags$small(class = "text-muted",
                       "Note: outlier detection uses the current Y variable only; overlay is ignored")
          )
        ),

#prm module
bslib::accordion_panel(
  title = tags$span(

    class = "d-inline-flex align-items-center gap-2",
    icon("seedling"),  # far = Font Awesome Regular
    #icon("sliders"),
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
        options = list(
          placeholder = "Default: All relevant variables matched by PRM",
          plugins = list("remove_button")
        )
      ),
      'data-bs-toggle'="tooltip",
      title="Type base names like SWC, P, TA, CO2 (we match columns by name prefix, e.g. ^SWC($|_)). Leave empty to apply to all"
    ),
    div(class="d-grid gap-2 mt-2",
        actionButton("apply_prm_subset", "Apply PRM to selected", icon = icon("play"))
    )
  )

),

#code generation
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
        # inside the same fluidRow as the ZIP/download
        column(
          3,
          tagAppendAttributes(
            downloadButton("download_csv", "Save cleaned CSV", icon = icon("file-csv"), width = "100%"),
            'data-bs-toggle' = "tooltip",
            title = "Download just the cleaned CSV (keeps original TIMESTAMP_START strings)"
          )
        )
        ,

        column(
          3,
          tagAppendAttributes(
            downloadButton("download_data", "Export zip file", icon = icon("file-archive"), width="100%"),
            'data-bs-toggle' = "tooltip",
            title = "Download a .zip containing the cleaned CSV (with NAs applied using the 'Apply Removals' button) and the removal R-script"
          )
        ),
        column(
          3,
          tagAppendAttributes(
            actionButton("reset_data", "Reload original data", icon = icon("eraser"), width="100%"),
            'data-bs-toggle' = "tooltip",
            title = "Reset any changes by re-loading the original .csv file"
          )
        ),
        column(
          3,
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

  #NA strings for r script output
  NA_STRINGS <- c("NA","NaN","","-9999","-9999.0","-9999.00","-9999.000")

  # ---- visual constants (no sliders needed) ----
  POINT_ALPHA      <- 0.70   # base points
  RING_ALPHA       <- 0.90   # flagged ring
  RING_LINE_WIDTH  <- 3
  RING_SIZE_EXTRA  <- 4      # flagged ring vs base size delta
  DARKEN_AMT       <- 0.50   # stronger dark
  TINT_AMT         <- 0.60   # stronger light


  #control y color
  y_base_color <- reactive({
    s <- input$y_color_style %||% "theme"
    if (s == "black") return("#000000")
    if (s == "default")      return("#1F449C")
    #if (s == "tableau")    return("#4E79A7")
    if (s == "custom")     return(input$y_color_custom %||% "#1F449C")
    # theme default (light/dark)
    if (isTRUE(input$dark_mode)) "#1F62FF" else "#1F449C"
  })



  #A tiny scope note under the Flag by value range button
  output$rng_scope_ui <- renderUI({
    vars <- vars_to_edit()
    if (length(vars) > 1) {
      tags$small(
        class = "text-muted",
        sprintf("Overlay ON: will flag values outside the range for: %s.", paste(vars, collapse = ", "))
      )
    } else {
      tags$small(class = "text-muted", sprintf("Scope: %s.", vars))
    }
  })

  #color match legend
  output$pair_legend <- renderUI({
    if (!isTRUE(input$show_pair_legend)) return(NULL)

    overlay_on <- isTRUE(input$overlay_mode) && length(input$overlay_vars)
    if (overlay_on) {
      # inside output$pair_legend, overlay branch
      vars_plot <- unique(c(if (isTRUE(input$overlay_include_y)) input$yvar, input$overlay_vars))
      cols  <- pal_overlay(length(vars_plot)); names(cols) <- vars_plot
      fcols <- flag_cols_for(vars_plot, cols, flag_scheme())  # ← add this

      tagList(
        tags$h6("Color key"),
        lapply(vars_plot, function(v){
          tags$div(class="swatch-row",
                   tags$span(class="sw",  style = paste0("background:", cols[[v]],  ";")),
                   tags$span(v),
                   tags$span(class="ring",
                             style = paste0("color:", hex_to_rgba(fcols[[v]], RING_ALPHA), ";"))
          )
        })
      )
    } else {
      base <- y_base_color()
      fcol <- switch(input$flag_color_scheme %||% "match_dark",
                     yellow      = "#FFC20A",
                     match_dark  = darken_hex(base, .50),
                     match_light = tint_hex(base,  .60)#,
                     #accessible  = contrast_pairs()[1, 2] # generic high-contrast mate
      )
      tagList(
        tags$h6("Color key"),
        tags$div(class="swatch-row",
                 tags$span(class="sw",  style = paste0("background:", base, ";")),
                 tags$span(input$yvar %||% "Y"),
                 tags$span(class="ring",
                           style = paste0("color:", hex_to_rgba(fcol, RING_ALPHA), ";"))
        )
      )
    }
  })



  #PRM
  # --- init reactive stores early (so we can use rv immediately) ---
  rv <- reactiveValues(
    df = NULL,
    df_before_prm = NULL,
    prm_active = FALSE,
    prm_summary = NULL,
    prm_mask = NULL,
    prm_include = NULL   # <- add this
  )

  last_sel <- reactiveValues(x = NULL, y = NULL)

  observeEvent(input$xvar, { last_sel$x <- input$xvar }, ignoreInit = TRUE)
  observeEvent(input$yvar, { last_sel$y <- input$yvar }, ignoreInit = TRUE)

  #export csv
  output$download_csv <- downloadHandler(
    filename = function() paste0("fluxtools_cleaned_", Sys.Date(), ".csv"),
    content  = function(file) {
      req(rv$df)
      # Start from the fully edited data in rv$df
      out <- rv$df
      # Put back the original timestamp string, then drop helper cols
      out$TIMESTAMP_START <- out$raw_ts
      out <- dplyr::select(out, -raw_ts, -ts_str, -.row)
      utils::write.csv(out, file, row.names = FALSE, na = "NA")
    }
  )

  #UTC check
  output$tz_check <- renderText({
    df <- rv$df
    if (is.null(df) || NROW(df) == 0) return("Upload a CSV to see timestamp parsing…")

    off <- data_off_hr()
    rec <- data_tz()

    paste0(
      "TIMESTAMP_START details:\n",
      "  raw value (as stored):   ", df$raw_ts[1], "\n",
      sprintf("  displayed (UTC%+d):       %s\n", off,
              format(df$TIMESTAMP_START[1] + off*3600, "%Y-%m-%d %H:%M %Z", tz = rec)),
      "  absolute UTC reference:  ", format(df$TIMESTAMP_START[1], "%Y-%m-%d %H:%M %Z", tz = "UTC"),
      "\n\nNote (display only):\n",
      sprintf("- Viewing times with a fixed UTC offset of UTC%+d (%s); daylight saving time is not applied\n", off, rec),
      "- This setting affects how times are shown in the app only\n",
      "- Selections, removals, and exports are keyed to the original TIMESTAMP_START string; underlying values are unchanged\n",
      "- Exported files preserve the original timestamp column from the input\n"
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

  # flag_cols_for <- function(vars, base_cols, scheme = "match_dark") {
  #   n <- length(vars); if (!n) return(setNames(character(0), character(0)))
  #   scheme <- scheme %||% "match_dark"
  #
  #   if (scheme == "yellow")
  #     return(setNames(rep("#FFC20A", n), vars))
  #
  #   if (scheme == "match_dark")
  #     return(setNames(vapply(base_cols, function(h) darken_hex(h, .50), ""), vars))
  #
  #   if (scheme == "match_light")
  #     return(setNames(vapply(base_cols, function(h) tint_hex(h, .60), ""), vars))
  #
  #   # fallback
  #   setNames(vapply(base_cols, function(h) darken_hex(h, .50), ""), vars)
  # }


  # Auto-pick “pairs” for color-blind friendly palettes; else use user choice
  # was auto-switching to "pairs" for some palettes — remove that
  flag_scheme <- reactive({
    input$flag_color_scheme %||% "match_dark"
  })

  # keep explicit options; fall back to match_dark (not pairs)
  flag_cols_for <- function(vars, base_cols, scheme = "match_dark") {
    n <- length(vars); if (!n) return(character(0))
    scheme <- scheme %||% "match_dark"

    if (scheme == "yellow")
      return(setNames(rep("#FFC20A", n), vars))

    if (scheme == "match_dark")
      return(setNames(vapply(base_cols, function(h) darken_hex(h, .50), ""), vars))

    if (scheme == "match_light")
      return(setNames(vapply(base_cols, function(h) tint_hex(h, .60), ""), vars))

    # fallback: behave like match_dark
    setNames(vapply(base_cols, function(h) darken_hex(h, .50), ""), vars)
  }

  # rgba string from hex (base)
  hex_to_rgba <- function(hex, alpha = 1) {
    rgb <- grDevices::col2rgb(hex)
    sprintf("rgba(%d,%d,%d,%.3f)", rgb[1], rgb[2], rgb[3], alpha)
  }

  # simple base subsampler
  resample_base <- function(df, nmax) {
    if (!NROW(df) || NROW(df) <= nmax) return(df)
    df[sample.int(NROW(df), nmax), , drop = FALSE]
  }

  # --- code output helper ---
  format_vec <- function(x, chunk = 80) {
    if (!length(x)) return("c()")
    groups <- split(x, ceiling(seq_along(x)/chunk))
    inside <- vapply(groups, function(g) paste(sprintf("'%s'", g), collapse = ", "), character(1))
    paste0("c(\n  ", paste(inside, collapse = ",\n  "), "\n)")
  }


  # --- color helpers ---
  tint_hex <- function(hex, amt = 0.45) {
    # move color toward white by amt (0..1)
    rgb <- grDevices::col2rgb(hex)/255
    out <- pmin(1, rgb + (1 - rgb) * amt)
    grDevices::rgb(out[1], out[2], out[3])
  }
  darken_hex <- function(hex, amt = 0.25) {
    # move color toward black by amt (0..1)
    rgb <- grDevices::col2rgb(hex)/255
    out <- pmax(0, rgb * (1 - amt))
    grDevices::rgb(out[1], out[2], out[3])
  }
  alpha_hex <- function(hex, alpha = 0.3) grDevices::adjustcolor(hex, alpha.f = alpha)

  #end color helpers

  #time slider helper
  rows_for_time <- function(df) {
    vars <- vars_to_edit()
    base <- !is.na(df$TIMESTAMP_START)
    if (!length(vars)) return(base)                       # no overlay → whole timeline
    any_non_na <- Reduce(`|`, lapply(vars, function(v) !is.na(df[[v]])))
    base & any_non_na
  }

  #overlay helper
  # which variables should edits apply to?
  vars_to_edit <- reactive({
    base <- if (isTRUE(input$overlay_mode) && length(input$overlay_vars))
      unique(c(input$overlay_vars, if (isTRUE(input$overlay_include_y)) input$yvar))
    else input$yvar
    if (is.null(rv$df)) base else intersect(base, names(rv$df))
  })

  # selection → timestamps (ts_str)
  selected_ts <- reactive({
    # coerce to data.frame to make NROW reliable
    sel <- tryCatch({
      d <- plotly::event_data("plotly_selected", source = "qc_plot")
      if (is.null(d)) NULL else as.data.frame(d)
    }, error = function(e) NULL)

    if (is.null(sel) || NROW(sel) == 0) return(character(0))

    k <- as.character(sel$key)
    k <- k[!is.na(k) & nzchar(k)]
    # keys may be "YYYY...||VAR" in overlay; keep only the timestamp part
    k <- sub("^(.*)\\|\\|.*$", "\\1", k)
    unique(k)
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
      is_syncing(TRUE); on.exit(is_syncing(FALSE), add = TRUE)
      if (!is.null(input$yvar) && !identical(input$rng_var, input$yvar)) {
        freezeReactiveValue(input, "rng_var")
        updateSelectInput(session, "rng_var", selected = input$yvar)
      }
    }

    # Clear brush/selection
    sel_keys(integer(0))
    session$resetBrush("qc_plot")

    # Rebuild orange “accumulated” from ALL vars we’re editing (overlay-aware)
    ts_all <- unique(unlist(lapply(vars_to_edit(), function(v) removed_ts[[v]] %||% character())))
    if (length(ts_all)) {
      matching_rows <- which(df_by_year()$ts_str %in% ts_all)
      sel_keys(matching_rows)
    }
  }, ignoreInit = TRUE)

  #flag helper
  observeEvent(input$add_sel, {
    pairs <- selected_pairs()
    if (nrow(pairs) == 0) return()

    # only keep vars that exist in df
    keep_vars <- intersect(unique(pairs$var), names(rv$df) %||% character())
    if (!length(keep_vars)) return()

    rows <- df_by_year()$.row[df_by_year()$ts_str %in% pairs$ts]
    sel_keys(unique(c(isolate(sel_keys()), rows)))

    for (v in keep_vars) {
      ts_v <- unique(pairs$ts[pairs$var == v])
      old  <- removed_ts[[v]] %||% character()
      removed_ts[[v]] <- unique(c(old, ts_v))
    }

    showNotification(
      sprintf("Flagged %d timestamp(s) across %d variable(s).",
              length(unique(pairs$ts[pairs$var %in% keep_vars])), length(keep_vars)),
      type = "message", duration = 2
    )
  })



  observeEvent(input$time_flag, {
    tr <- input$time_rng; req(tr)
    df <- df_by_year()
    idx <- which(df$TIMESTAMP_START >= tr[1] & df$TIMESTAMP_START <= tr[2])
    if (!length(idx)) { showNotification("No points in that time range.", type = "message"); return() }

    rows <- df$.row[idx]
    sel_keys(unique(c(isolate(sel_keys()), rows)))
    ts <- df$ts_str[idx]

    for (v in vars_to_edit()) {
      old <- removed_ts[[v]] %||% character()
      removed_ts[[v]] <- unique(c(old, ts))
    }

    # 👇 important: kill any stale plot selection so Apply reads staged, not brush
    session$resetBrush("qc_plot")
  })

  observeEvent(input$time_flag_out, {
    tr <- input$time_rng; req(tr)
    df <- df_by_year()
    idx <- which(df$TIMESTAMP_START < tr[1] | df$TIMESTAMP_START > tr[2])
    if (!length(idx)) { showNotification("No points outside that time range.", type = "message"); return() }

    rows <- df$.row[idx]
    sel_keys(unique(c(isolate(sel_keys()), rows)))
    ts <- df$ts_str[idx]

    for (v in vars_to_edit()) {
      old <- removed_ts[[v]] %||% character()
      removed_ts[[v]] <- unique(c(old, ts))
    }

    # 👇 same here
    session$resetBrush("qc_plot")
  })

  # returns +3 for "UTC+3", -5 for "UTC-5"
  # --- helpers ---
  parse_utc_hours <- function(lbl) as.integer(sub("UTC([+-]?\\d+).*", "\\1", lbl))

  data_off_hr <- reactive({ parse_utc_hours(req(input$data_offset)) })
  data_tz <- reactive({
    off <- data_off_hr()
    if (off == 0) "UTC" else paste0("Etc/GMT", if (off < 0) "+" else "-", abs(off))  # POSIX sign flip
  })

  #Date selection helper
  #to_view_time   <- function(x) as.POSIXct(as.numeric(x) + data_off_hr()*3600, origin="1970-01-01", tz = data_tz())
  #from_view_time <- function(x) as.POSIXct(as.numeric(x) - data_off_hr()*3600, origin="1970-01-01", tz = "UTC")

  # raw csv
  raw_df <- reactive({
    req(input$csv_file)
    read.csv(
      input$csv_file$datapath,
      stringsAsFactors = FALSE,
      colClasses = c(TIMESTAMP_START = "character"),
      na.strings = NA_STRINGS
    )
  })

  # parse respecting *data*'s stated offset, then map to absolute UTC
  shifted_df <- reactive({
    df0 <- raw_df(); req(df0)

    # keep only digits, right-pad minutes to 12 chars (YYYYMMDDHH or YYYYMMDD)
    digits <- gsub("[^0-9]", "", df0$TIMESTAMP_START %||% "")
    digits <- substr(paste0(digits, "0000"), 1, 12)

    # parse "clock time" and map to absolute UTC by removing the (fixed) offset
    off_hr <- data_off_hr()
    ts_local_as_utc <- as.POSIXct(digits, format = "%Y%m%d%H%M", tz = "UTC")
    ts_utc          <- ts_local_as_utc - off_hr*3600

    df0 %>%
      mutate(
        raw_ts          = TIMESTAMP_START,  # original string kept for export/code
        ts_str          = digits,           # canonical "YYYYMMDDHHMM" key
        TIMESTAMP_START = ts_utc,           # absolute UTC inside the app
        .row            = dplyr::row_number()
      )
  })


  output$subtitle <- renderUI({
    req(rv$df)
    vars <- vars_to_edit()
    lab  <- paste(vars, collapse = ", ")
    col  <- if (isTRUE(input$dark_mode)) "#DDD" else "#555"
    tags$h5(
      paste("Filtering out:", lab),
      style = sprintf("color:%s; margin-top:-10px; margin-bottom:20px;", col)
    )
  })

  observeEvent(input$did_copy_code, {
    showNotification("Code copied ✅", type="message", duration = 1)
  })

  #color overlay
  # color overlay (no extra packages)
  pal_overlay <- function(n, which = input$overlay_palette) {
    which <- which %||% "tableau10"

    okabe <- c("#E69F00","#56B4E9","#009E73","#F0E442",
               "#0072B2","#D55E00","#CC79A7","#000000")

    tab10 <- c("#4E79A7","#F28E2B","#E15759","#76B7B2",
               "#59A14F","#EDC948","#B07AA1","#FF9DA7",
               "#9C755F","#BAB0AC")

    set2  <- c("#66C2A5","#FC8D62","#8DA0CB","#E78AC3",
               "#A6D854","#FFD92F","#E5C494","#B3B3B3")

    key   <- c("#fe4a49", "#009fb7",
               "#721cb8", "#509724",
               "#ffbf00")

    base <- switch(which,
                   okabe     = okabe,
                   tableau10 = tab10,
                   set2      = set2,
                   key       = key,
                   viridis   = grDevices::hcl.colors(max(n, 1), "viridis"),  # dark-ish viridis only
                   tab10
    )

    if (n <= length(base)) base[seq_len(n)] else grDevices::colorRampPalette(base)(n)
  }


  #color overlay end

  #UTC helper
  to_view_time   <- function(x)
    as.POSIXct(as.numeric(x) + data_off_hr()*3600,
               origin = "1970-01-01", tz = data_tz())

  from_view_time <- function(x)
    as.POSIXct(as.numeric(x) - data_off_hr()*3600,
               origin = "1970-01-01", tz = "UTC")


  #PRM Server
  observeEvent(input$apply_prm_subset, {
    req(rv$df)


    if (isTRUE(rv$prm_active)) {
      showNotification("PRM already applied. Use “Undo PRM” to revert", type="message"); return()
    }

    fam <- input$prm_families
    if (!length(fam)) {
      showNotification("No variables selected. Using all PRM families present.", type="message")
    }

    rv$prm_include <- if (length(fam)) fam else NULL

    before <- rv$df
    res <- try(apply_prm_safe(before, include = if (length(fam)) fam else NULL), silent = TRUE)
    if (inherits(res, "try-error")) {
      showNotification("PRM function not available. Update or load 'fluxtools'.", type="error", duration=6); return()
    }

    after <- res$data

    # Build mask & set state (same as your apply_prm_btn handler)
    mask <- list(); common <- intersect(names(before), names(after))
    for (nm in common) {
      if (!is.numeric(before[[nm]]) || !is.numeric(after[[nm]])) next
      idx <- which(!is.na(before[[nm]]) & is.na(after[[nm]]))
      if (length(idx)) mask[[nm]] <- data.frame(.row = before$.row[idx], old = before[[nm]][idx])
    }

    rv$df <- after
    rv$prm_summary <- res$summary
    rv$prm_mask <- mask
    rv$prm_active <- TRUE

    ncols <- if (nrow(res$summary)) length(unique(res$summary$column)) else 0L
    nrep  <- if (nrow(res$summary)) sum(res$summary$n_replaced, na.rm = TRUE) else 0L
    showNotification(sprintf("PRM applied: %d columns checked, %d values set to NA.", ncols, nrep),
                     type="message", duration=4)

    showModal(modalDialog(
      title = "PRM summary",
      tagList(
        tags$p("Expected units and PRM bounds are shown per column. Out-of-range values were set to NA."),
        tableOutput("prm_summary_tbl")
      ),
      size = "l", easyClose = TRUE
    ))
  })


  #PRM help table
  output$help_prm_table <- renderTable({
    rules <- get_rules()
    if (is.null(rules)) {
      return(data.frame(
        Note    = "Load 'fluxtools' in this R session to view the PRM table here",
        Example = "library(fluxtools); get_prm_rules()"
      ))
    }

    # If PRM applied, show per-column summary; else the static rule table
    if (!is.null(rv$prm_summary)) {
      s <- rv$prm_summary
      s$pct_replaced <- round(s$pct_replaced, 1)
      want <- c("column","family","units","min","max","n_replaced","pct_replaced")
      s[, intersect(want, names(s)), drop = FALSE]
    } else {
      want <- c("variable","description","units","min","max")
      rules[, intersect(want, names(rules)), drop = FALSE]
    }
  })

  output$prm_summary_tbl <- renderTable({
    s <- rv$prm_summary; req(s)
    rules <- get_rules()
    if (!is.null(rules) && all(c("variable","units") %in% names(rules))) {
      u_map <- setNames(rules$units, rules$variable)
      s$units <- unname(u_map[s$family])
    } else {
      s$units <- NA_character_
    }
    s$pct_replaced <- round(s$pct_replaced, 1)
    want <- c("column","family","units","min","max","n_replaced","pct_replaced")
    s[, intersect(want, names(s)), drop = FALSE]
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

  # # toggle a 'dark-mode' class on <body>
  # observe({
  #   addClass  <- if (isTRUE(input$dark_mode)) "dark-mode" else ""
  #   removeClass <- if (isTRUE(input$dark_mode)) "" else "dark-mode"
  #   #session$sendCustomMessage("toggleBodyClass", list(add=addClass, remove=removeClass))
  # })

  #overlay
  observe({
    req(rv$df)
    num_cols <- rv$df %>%
      dplyr::select(-TIMESTAMP_START, -raw_ts, -ts_str, -.row) %>%
      dplyr::select(where(is.numeric)) %>%
      names()

    old <- isolate(input$overlay_vars) %||% character()
    keep <- intersect(old, num_cols)

    freezeReactiveValue(input, "overlay_vars")
    updateSelectizeInput(
      session, "overlay_vars",
      choices  = num_cols,
      selected = keep,
      server   = TRUE
    )
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

  #Dynamic label on the variable selector
  observe({
    lbl <- if (isTRUE(input$overlay_mode) && length(vars_to_edit()) > 1)
      "Variable (overlay: applies to all selected)"
    else
      "Variable"
    updateSelectInput(session, "rng_var", label = lbl)
  })

    #Prm
  # server()
  observe({
    fam <- input$prm_families
    lab <- if (length(fam)) sprintf("Apply PRM (%d selected)", length(fam)) else "Apply PRM (all)"
  updateActionButton(session, "apply_prm_btn", label = lab)
  })

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
    df <- df_by_year(); req(df)
    ts <- df$TIMESTAMP_START[ rows_for_time(df) ]


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
    # 2) clear the orange preview
    sel_keys(integer(0))

    # 3) clear staged flags for the variables we’re editing (overlay aware)
    vars <- vars_to_edit()
    vars <- intersect(vars, names(rv$df) %||% character())
    if (length(vars)) {
      for (v in vars) removed_ts[[v]] <- NULL
      showNotification(sprintf("Cleared staged flags for %d variable%s.",
                               length(vars), if (length(vars)==1) "" else "s"),
                       type="message", duration=2)
    }
  })

  # Show PRM summary table in a modal
  # output$prm_summary_tbl <- renderTable({
  #   s <- rv$prm_summary
  #   req(s)
  #   rules <- get_rules()
  #   if (!is.null(rules)) {
  #     u_map <- setNames(rules$units, rules$variable)
  #     s$units <- unname(u_map[s$family])
  #   } else {
  #     s$units <- NA_character_
  #   }
  #   s$pct_replaced <- round(s$pct_replaced, 1)
  #   s[, c("column","family","units","min","max","n_replaced","pct_replaced")]
  # })

  observeEvent(input$apply_prm_btn, {
    req(rv$df)


    if (isTRUE(rv$prm_active)) {
      showNotification("PRM already applied. Use “Undo PRM” to revert", type="message")
      return()
    }
    before <- rv$df
    fam    <- input$prm_families
    rv$prm_include <- if (length(fam)) fam else NULL

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
        div(class = "table-wrap", tableOutput("prm_summary_tbl"))
      ),
      size = "l", easyClose = TRUE
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
    rv$prm_include <- NULL

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
    rng  <- range(df$TIMESTAMP_START, na.rm = TRUE)
    step <- infer_cadence_sec(df$TIMESTAMP_START)

    updateSliderInput(
      session, "time_rng",
      min = rng[1], max = rng[2], value = rng,
      step = step, timeFormat = "%Y-%m-%d\n%H:%M"
    )

    # Build time slider from actual cadence (30m or 60m) again using non-NA timestamps
    # overlay-aware initialization
    ts_all <- df$TIMESTAMP_START[ rows_for_time(df) ]
    if (length(ts_all) >= 2) {
      step0 <- infer_cadence_sec(ts_all)
      r0    <- range(ts_all)
      r0[1] <- align_to_step(r0[1], step0)
      r0[2] <- ceil_to_step(r0[2],  step0)

      updateAirDateInput(session, "start_dt", value = to_view_time(r0[1]))
      updateAirDateInput(session, "end_dt",   value = to_view_time(r0[2]))
      updateSliderInput(session, "time_rng",
                        min = r0[1], max = r0[2], value = r0,
                        step = step0, timeFormat = "%Y-%m-%d\n%H:%M"
      )
    } else {
      updateSliderInput(session, "time_rng", min = 0, max = 1, value = c(0, 1), step = 3600)
    }


  })

  observeEvent(input$rng_flag, {
    df <- df_by_year(); req(df)

    # variables we’re editing right now
    vars <- vars_to_edit()
    vars <- intersect(vars, names(df))               # guard
    if (!length(vars)) return()

    # build a row mask (for the orange preview) over all vars
    all_rows <- integer(0)

    for (v in vars) {
      # compute per-variable range outside test
      idx_v <- which(
        (!is.na(input$rng_min) & df[[v]] < input$rng_min) |
          (!is.na(input$rng_max) & df[[v]] > input$rng_max)
      )
      if (!length(idx_v)) next

      all_rows <- c(all_rows, df$.row[idx_v])

      ts_v <- df$ts_str[idx_v]
      old  <- removed_ts[[v]] %||% character()
      removed_ts[[v]] <- unique(c(old, ts_v))
    }

    if (!length(all_rows)) {
      showNotification("No points outside that range for selected variable(s).", type="message")
      return()
    }

    sel_keys(unique(c(isolate(sel_keys()), unique(all_rows))))
    showNotification("Range flags applied per overlaid variable.", type="message", duration=2)
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
                tags$li(tags$b("Upload")," your AmeriFlux CSV (≤ 1 GB; multi-year enabled)"),
                tags$li(tags$b("X-axis:"),"Defaults to TIMESTAMP_START (e.g., 'YYYYMMDDHHMM', such as '201507281700'); you can switch to any numeric variable"),
                tags$li(tags$b("Time Note:")," TIMESTAMP_START is parsed into POSIXct in user-selected UCT offset so you see familiar clock times (e.g. 14:00), but the generated code always uses the original 'YYYYMMDDHHMM' string to avoid ambiguity"),
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
            div(class = "table-wrap", tableOutput("help_prm_table"))

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

  # ────────────────────────────────────────────────────────────────────────────
  # Render the Plotly scatter (with event_register)
  # ────────────────────────────────────────────────────────────────────────────
output$qc_plot <- renderPlotly({
  overlay_on <- isTRUE(input$overlay_mode)
  vars_plot  <- unique(c(if (isTRUE(input$overlay_include_y)) input$yvar, input$overlay_vars))
  if (!length(vars_plot)) vars_plot <- input$yvar


  df0 <- df_by_year()
  req(df0, input$xvar, input$yvar)

  overlay_on <- isTRUE(input$overlay_mode) && length(input$overlay_vars)

  # ── Overlay mode ────────────────────────────────────────────────────────────
  if (overlay_on) {
    df <- df0
    if (identical(input$xvar, "TIMESTAMP_START")) df$ts_view <- df$TIMESTAMP_START + data_off_hr()*3600
    vars_plot <- unique(c(if (isTRUE(input$overlay_include_y)) input$yvar, input$overlay_vars))

    p <- plotly::plot_ly(source = "qc_plot") %>% plotly::event_register("plotly_selected")


    # base colors and flag partner colors
    cols  <- pal_overlay(length(vars_plot)); names(cols) <- vars_plot
    fcols <- flag_cols_for(vars_plot, cols, flag_scheme())  # ← uses auto “pairs” for cb palettes

    s <- input$overlay_size  %||% 6
    #a <- input$overlay_alpha %||% 0.6
    fs <- input$flag_size    %||% (s + 2)  # ← same size by default, adjustable

    for (v in vars_plot) {
      # data for this variable
      dd <- dplyr::filter(df, !is.na(.data[[v]]), !is.na(.data[[input$xvar]]))
      if (!NROW(dd)) next
      xvec <- if (identical(input$xvar, "TIMESTAMP_START")) dd$ts_view else dd[[input$xvar]]

      # timestamps flagged for THIS var
      ts_v <- removed_ts[[v]] %||% character()

      # 1) base points EXCLUDING flagged ones (prevents the “blob” effect)
      if (length(ts_v)) {
        dd_base <- dd[!(dd$ts_str %in% ts_v), , drop = FALSE]
      } else {
        dd_base <- dd
      }
      # base (unflagged) points
      if (NROW(dd_base)) {
        x_base <- if (identical(input$xvar, "TIMESTAMP_START")) dd_base$ts_view else dd_base[[input$xvar]]
        p <- p %>% plotly::add_markers(
          data = dd_base,
          x = x_base, y = dd_base[[v]],
          key = paste(dd_base$ts_str, v, sep = "||"),
          name = v, inherit = FALSE,
          marker = list(
            symbol  = if (isTRUE(input$overlay_hollow)) "circle-open" else "circle",
            size    = (input$overlay_size %||% 6),
            opacity = POINT_ALPHA,
            color   = cols[[v]],
            line    = list(width = if (isTRUE(input$overlay_hollow)) 1.5 else 0)
          )
        )
      }

      # flagged points as hollow rings (same x/y, flag color)
      if (length(ts_v)) {
        dd_flag <- dd[dd$ts_str %in% ts_v, , drop = FALSE]
        x_flag  <- if (identical(input$xvar, "TIMESTAMP_START")) dd_flag$ts_view else dd_flag[[input$xvar]]
        p <- p %>% plotly::add_markers(
          data = dd_flag,
          x = x_flag, y = dd_flag[[v]],
          key = paste(dd_flag$ts_str, v, sep = "||"),
          name = paste0(v, " (flagged)"),
          legendgroup = v, showlegend = FALSE, inherit = FALSE, hoverinfo = "x+y+name",
          marker = list(
            symbol = "circle-open",
            size   = (input$flag_size %||% ((input$overlay_size %||% 6) + RING_SIZE_EXTRA)),
            color  = hex_to_rgba(fcols[[v]], RING_ALPHA),
            line   = list(width = RING_LINE_WIDTH)
          )
        )
      }
    }


    p <- p %>% plotly::layout(
      legend = list(itemclick = "toggleothers", itemdoubleclick = "toggle"),
      autosize = TRUE, dragmode = "select", font = list(size = 18),
      margin = list(l = 80, r = 20, b = 80, t = 20),
      xaxis = if (identical(input$xvar, "TIMESTAMP_START")) {
        list(type = "date", tickformat = "%b %d\n%H:%M",
             title = sprintf("TIMESTAMP_START (UTC%+d)", data_off_hr()))
      } else list(title = input$xvar),
      yaxis = list(title = "Overlayed variables")
    )
    if (isTRUE(input$dark_mode)) {
      p <- p %>% plotly::layout(template = "plotly_dark",
                                paper_bgcolor = "#2E2E2E", plot_bgcolor  = "#2E2E2E", font = list(color = "white"))
    }
    return(p)
  }

  # ── Single-variable mode ───────────────────
  df_filtered <- df0 %>%
    dplyr::filter(!is.na(.data[[input$xvar]]), !is.na(.data[[input$yvar]]))

  if (nrow(df_filtered) >= 2) {
    fit0 <- lm(reformulate(input$xvar, input$yvar), data = df_filtered)
    dfc <- df_filtered %>%
      mutate(
        fitted = predict(fit0, newdata = .),
        resid  = .data[[input$yvar]] - fitted,
        sigma  = sd(resid, na.rm = TRUE),
        flag   = if_else(abs(resid) > input$sd_thresh * sigma, "outlier", "inlier")
      )
  } else {
    # Not enough data to fit a model → plot raw points without outlier logic
    dfc <- df_filtered %>%
      mutate(fitted = NA_real_, resid = NA_real_, sigma = NA_real_, flag = NA_character_)
  }

  #marker_blue <- if (isTRUE(input$dark_mode)) "#1F62FF" else "#1F449C"
  marker_blue <- y_base_color()


  if (identical(input$xvar, "TIMESTAMP_START")) {
    dfc$ts_view <- dfc$TIMESTAMP_START + data_off_hr()*3600
  }

  # NEW: exclude selected rows from the filled base layer
  df_base <- dfc[ !(dfc$.row %in% sel_keys()), , drop = FALSE ]

  p <- plotly::plot_ly(
    data   = df_base,   # ← CHANGED from dfc
    x      = if (identical(input$xvar, "TIMESTAMP_START")) ~ts_view else ~.data[[input$xvar]],
    y      = ~.data[[input$yvar]],
    key    = ~ts_str,
    source = "qc_plot",
    mode   = "markers",
    type   = "scatter",
    marker = list(
      size    = input$overlay_size  %||% 6,
      opacity = POINT_ALPHA,
      color   = marker_blue,
      line    = list(width = if (isTRUE(input$overlay_hollow)) 1.5 else 0)
    ),
    symbol = if (isTRUE(input$overlay_hollow)) I("circle-open") else I("circle")
  ) %>% plotly::event_register("plotly_selected")

  if (input$sd_thresh > 0) {
    p <- p %>% plotly::add_trace(
      data = dplyr::filter(dfc, flag == "outlier"),
      x    = if (identical(input$xvar, "TIMESTAMP_START")) ~ts_view else ~.data[[input$xvar]],
      y    = ~.data[[input$yvar]],
      mode = "markers",
      type = "scatter",
      marker = list(
        size    = input$overlay_size  %||% 6,
        opacity = POINT_ALPHA,
        color   = "#F05039"
      ),
      showlegend = FALSE
    )
  }

  if (length(sel_keys()) > 0) {
    df_flag1 <- dplyr::filter(dfc, .row %in% sel_keys())
    xcol_nm  <- if (identical(input$xvar, "TIMESTAMP_START")) "ts_view" else input$xvar

    # ring color derived from the current base color and the chosen scheme
    flag_col_single <- switch(input$flag_color_scheme %||% "match_dark",
                              yellow      = "#FFC20A",
                              match_dark  = darken_hex(marker_blue, .50),
                              match_light = tint_hex(marker_blue,  .60)#,
                              #accessible  = contrast_pairs()[1, 2]
    )

    fs <- (input$flag_size %||% ((input$overlay_size %||% 6) + RING_SIZE_EXTRA))

    p <- p %>% plotly::add_markers(
      data = df_flag1,
      x = df_flag1[[xcol_nm]],
      y = df_flag1[[input$yvar]],
      inherit = FALSE, showlegend = FALSE, hoverinfo = "x+y+name",
      marker = list(
        symbol = "circle-open",
        size   = fs,
        color  = hex_to_rgba(flag_col_single, RING_ALPHA),
        line   = list(width = RING_LINE_WIDTH)
      )
    )
  }


  if (isTRUE(input$dark_mode)) {
    p <- p %>% plotly::layout(
      template = "plotly_dark",
      paper_bgcolor = "#2E2E2E",
      plot_bgcolor  = "#2E2E2E",
      font = list(color = "white")
    )
  }

  if (input$show_reg && input$xvar != "TIMESTAMP_START") {
    # R² (all points)
    df_all <- df0 %>% dplyr::filter(!is.na(.data[[input$xvar]]), !is.na(.data[[input$yvar]]))
    if (nrow(df_all) >= 2) {
      fit_all <- lm(reformulate(input$xvar, input$yvar), data = df_all)
      r2_all  <- round(summary(fit_all)$r.squared, 2)
      xseq_all <- seq(min(df_all[[input$xvar]], na.rm = TRUE),
                      max(df_all[[input$xvar]], na.rm = TRUE), length.out = 100)
      preds_all <- predict(fit_all, newdata = setNames(data.frame(xseq_all), input$xvar))
      r2_bg_all <- if (isTRUE(input$dark_mode)) "#F52100" else "#FFBAAF"
      r2_bg_sel <- if (isTRUE(input$dark_mode)) "#B87700" else "#FFC65C"

      p <- p %>%
        plotly::add_lines(x = xseq_all, y = preds_all, inherit = FALSE,
                          line = list(color = "black", width = 8), showlegend = FALSE) %>%
        plotly::add_lines(x = xseq_all, y = preds_all, inherit = FALSE,
                          line = list(color = r2_bg_all, width = 6), showlegend = FALSE) %>%
        plotly::add_annotations(
          xref="paper", yref="paper", x=0.02, y=1.00, xanchor="left", yanchor="bottom",
          text=paste0("<b>R² (all points) = ", r2_all, "</b>"),
          showarrow=FALSE, font=list(size=18), borderpad=6, borderwidth=1.5, yshift=-18,
          bgcolor=r2_bg_all,
          bordercolor = if (isTRUE(input$dark_mode)) "#EEE" else "black"
        )

      # R² with “accumulated” dropped
      acc_sel <- isolate(sel_keys())
      if (length(acc_sel) > 0) {
        df_drop_sel <- df_all %>% dplyr::filter(!(.row %in% acc_sel))
        r2_sel <- if (nrow(df_drop_sel) >= 2)
          round(summary(lm(reformulate(input$xvar, input$yvar), data = df_drop_sel))$r.squared, 2) else NA_real_
        p <- p %>% plotly::add_annotations(
          xref="paper", yref="paper", x=0.02, y=0.96, xanchor="left", yanchor="bottom",
          text=paste0("<b>R² (sel dropped) = ", r2_sel, "</b>"),
          showarrow=FALSE, font=list(size=18), borderpad=6, borderwidth=1.5, yshift=-26,
          bgcolor=r2_bg_sel,
          bordercolor = if (isTRUE(input$dark_mode)) "#EEE" else "black"
        )
      }
    }
  }

  p %>% plotly::layout(
    autosize = TRUE,
    dragmode = "select",
    font   = list(size = 18),
    margin = list(l = 80, r = 20, b = 80, t = 20),
    xaxis = if (input$xvar == "TIMESTAMP_START") {
      list(type = "date",
           tickformat = "%b %d\n%H:%M",
           title = sprintf("TIMESTAMP_START (UTC%+d)", data_off_hr()))
    } else list(title = input$xvar),
    yaxis = list(title = input$yvar)
  )
})

  output$preview <- renderTable({
    ts <- selected_ts()
    if (!length(ts) && length(sel_keys()) > 0) {
      ts <- df_by_year()$ts_str[df_by_year()$.row %in% sel_keys()]
    }
    if (!length(ts)) return(NULL)

    hrs <- data_off_hr()
    local_label <- sprintf("Timestamp (UTC%+d)", hrs)

    df_by_year() %>%
      dplyr::filter(ts_str %in% ts) %>%
      dplyr::mutate(
        !!local_label := format(TIMESTAMP_START, "%Y-%m-%d %H:%M", tz = data_tz())
      ) %>%
      dplyr::select(all_of(local_label), !!rlang::sym(input$yvar), raw_ts) %>%
      setNames(c(local_label, input$yvar, "raw_ts"))
  }, sanitize.text.function = identity)

  # Current
  output$code_current <- renderText({
    staged <- reactiveValuesToList(removed_ts)
    staged <- staged[vapply(staged, length, FUN.VALUE = integer(1)) > 0]
    if (!length(staged)) return("\n<!-- no staged points yet (box/lasso + Flag Data) -->\n")

    paste(lapply(names(staged), function(var){
      ts_v <- unique(staged[[var]])
      sprintf(
        "bad_%s <- %s
df$%s[df$TIMESTAMP_START %%in%% bad_%s] <- NA_real_",
        var, format_vec(ts_v, chunk = 80), var, var
      )
    }), collapse = "\n\n")
  })

  # Accumulated
  output$code_all <- renderText({
    cfs <- reactiveValuesToList(confirmed_ts)
    cfs <- cfs[vapply(cfs, length, FUN.VALUE = integer(1)) > 0]
    if (!length(cfs)) return("\n<!-- no confirmed removals yet (click “Apply removals”) -->\n")

    paste(lapply(names(cfs), function(var){
      ts_v <- unique(cfs[[var]])
      sprintf(
        "bad_%s <- %s
df$%s[df$TIMESTAMP_START %%in%% bad_%s] <- NA_real_",
        var, format_vec(ts_v, chunk = 80), var, var
      )
    }), collapse = "\n\n")
  })

  output$removed_code <- renderText({
    ts_v <- confirmed_ts[[input$yvar]] %||% character()
    if (!length(ts_v)) return("<!-- no points have been “Confirmed Remove” yet -->")
    sprintf(
      "bad_%s <- %s
df$%s[df$TIMESTAMP_START %%in%% bad_%s] <- NA_real_",
      input$yvar, format_vec(unique(ts_v), chunk = 80), input$yvar, input$yvar
    )
  })

  #overlay helper
  selected_pairs <- reactive({
    sel <- tryCatch({
      d <- plotly::event_data("plotly_selected", source = "qc_plot")
      if (is.null(d)) NULL else as.data.frame(d)
    }, error = function(e) NULL)

    if (is.null(sel) || NROW(sel) == 0) {
      return(data.frame(ts = character(0), var = character(0)))
    }

    k <- as.character(sel$key)
    k <- k[!is.na(k) & nzchar(k)]  # drop NA/""
    if (length(k) == 0) {
      return(data.frame(ts = character(0), var = character(0)))
    }

    if (all(grepl("\\|\\|", k))) {
      parts <- strsplit(k, "\\|\\|")
      df <- data.frame(
        ts  = vapply(parts, `[`, character(1), 1),
        var = vapply(parts, `[`, character(1), 2),
        stringsAsFactors = FALSE
      )
    } else {
      df <- data.frame(ts = k, var = rep(input$yvar, length(k)), stringsAsFactors = FALSE)
    }

    # sanitize
    df <- df[!is.na(df$ts)  & nzchar(df$ts), ]
    df <- df[!is.na(df$var) & nzchar(df$var), ]
    if (!is.null(rv$df)) df <- df[df$var %in% names(rv$df), ]
    rownames(df) <- NULL
    df
  })

  #UTC helper
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

  #overlay
  observe({
    if (!isTRUE(input$overlay_mode)) {
      hidden <- setdiff(names(Filter(length, reactiveValuesToList(removed_ts))), input$yvar)
      if (length(hidden)) {
        showNotification(
          sprintf("Overlay is OFF. %d variable%s have staged flags (ignored until overlay is ON).",
                  length(hidden), if (length(hidden)==1) "" else "s"),
          type="message", duration=3
        )
      }
    }
  })

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
    df <- df_by_year(); req(df)
    pool <- sort(unique(df$TIMESTAMP_START[ rows_for_time(df) ]))
    if (length(pool) < 2) return()

    tr   <- time_rng_debounced()
    tr2  <- c(nearest_stamp(tr[1], pool), nearest_stamp(tr[2], pool))
    if (!identical(tr, tr2)) {
      updateSliderInput(session, "time_rng", value = tr2)
    }

    # keep pickers in sync (display only)
    s_view <- to_view_time(tr2[1])
    e_view <- to_view_time(tr2[2])
    if (is.null(input$start_dt) || abs(as.numeric(input$start_dt) - as.numeric(s_view)) > 0.5) {
      updateAirDateInput(session, "start_dt", value = s_view)
    }
    if (is.null(input$end_dt) || abs(as.numeric(input$end_dt) - as.numeric(e_view)) > 0.5) {
      updateAirDateInput(session, "end_dt", value = e_view)
    }
  })

  # helper once
  snap_to_pool <- function(x, pool) pool[ which.min(abs(as.numeric(pool) - as.numeric(x))) ]

#   ──────────────────────────────────────────────────────────────────
  # DOWNLOAD HANDLER for “Download cleaned CSV”
  # ────────────────────────────────────────────────────────────────────────────
  output$download_data <- downloadHandler(
    filename = function() paste0("fluxtools_", Sys.Date(), ".zip"),
    content = function(zipfile) {
      tmpdir <- tempfile("fluxtools_"); dir.create(tmpdir)

      # 0) ORIGINAL input (what the scripts will read)
      orig_path <- file.path(tmpdir, "raw_df.csv")
      write.csv(raw_df(), orig_path, row.names = FALSE, na = "NA")

      # 1) CLEANED CSV reflecting in-app removals
      csv_name <- paste0("fluxtools_processed_df_", Sys.Date(), ".csv")
      csv_path <- file.path(tmpdir, csv_name)

      out <- rv$df
      out$TIMESTAMP_START <- out$raw_ts          # keep original strings
      out <- dplyr::select(out, -raw_ts, -ts_str, -.row)
      write.csv(out, csv_path, row.names = FALSE, na = "NA")

      # Build a colClasses vector from the data we’re writing (no separate file)
      base_df <- raw_df()
      # keep TIMESTAMP_START as character; everything truly numeric stays numeric
      num_cols <- setdiff(names(base_df)[vapply(base_df, is.numeric, logical(1))], "TIMESTAMP_START")

      cc_vec <- c(TIMESTAMP_START = "character",
                  setNames(rep("numeric", length(num_cols)), num_cols))

      # turn that into a literal R line to paste in the script
      cc_line <- paste0(
        "cc <- c(",
        paste(sprintf("'%s'='%s'", names(cc_vec), unname(cc_vec)), collapse = ", "),
        ")"
      )
#
#       helper  <- df_by_year()
#       for (col in setdiff(names(base_df), "TIMESTAMP_START")) {
#         if (col %in% names(helper)) base_df[[col]] <- helper[[col]]
#       }
#       write.csv(base_df, csv_path, row.names = FALSE, na = "NA")

      # 2) Main manual-removal script
      script_name <- "fluxtools_removal_script.R"
      script_path <- file.path(tmpdir, script_name)

      cfs <- reactiveValuesToList(confirmed_ts)
      cfs <- cfs[vapply(cfs, length, FUN.VALUE = integer(1)) > 0]

      extra_files <- c(orig_path, csv_path, script_path)

      # 3) Include PRM summary if present
      if (isTRUE(rv$prm_active) && !is.null(rv$prm_summary)) {
        prm_csv <- file.path(tmpdir, "prm_summary.csv")
        write.csv(rv$prm_summary, prm_csv, row.names = FALSE, na = "NA")
        extra_files <- c(extra_files, prm_csv)
      }

      # 4) Write the main script (fix: read raw_df.csv)
      lines <- c(
        "## Auto-generated QA/QC script",
        "suppressPackageStartupMessages({",
        "  library(dplyr)",
        "})",
        "na_vals <- c('NA','NaN','','-9999','-9999.0','-9999.00','-9999.000')",
        cc_line,
        "df <- read.csv('raw_df.csv', stringsAsFactors = FALSE,
                na.strings = na_vals, colClasses = cc)",
        "df$TIMESTAMP_START <- as.character(df$TIMESTAMP_START)",
        ""
      )


      if (isTRUE(rv$prm_active)) {
        include_vec <- rv$prm_include
        include_txt <- if (is.null(include_vec)) "NULL" else
          paste0("c(", paste(sprintf("'%s'", include_vec), collapse = ", "), ")")

        lines <- c(
          lines,
          "## --- Physical Range Module (PRM) -------------------------------------",
          "if (requireNamespace('fluxtools', quietly = TRUE)) {",
          sprintf("  res <- try(fluxtools::apply_prm(df, include = %s, note = TRUE, summarize = TRUE), silent = TRUE)",
                  include_txt),
          "  if (!inherits(res, 'try-error') && is.list(res) && !is.null(res$data)) {",
          "    df <- res$data",
          "    if (!is.null(res$summary) && is.data.frame(res$summary)) {",
          "      try(utils::write.csv(res$summary, 'prm_summary.csv', row.names = FALSE), silent = TRUE)",
          "    }",
          "  }",
          "} else { message('fluxtools not installed; PRM step skipped.') }",
          ""
        )

      }

      if (length(cfs)) {
        for (var in names(cfs)) {
          tses  <- cfs[[var]]
          #vec  <- paste(sprintf("'%s'", tses), collapse = ", ")
          vec_ml <- format_vec(tses, chunk = 80)  # <-- wraps across lines
          lines <- c(
            lines,
            sprintf("## --- Manually Selected (%d) Turned NA -------------------------------", length(tses)),
            sprintf("## Variable: %s", var),
            sprintf("bad_%s <- %s", var, vec_ml),
            sprintf("df$%s[df$TIMESTAMP_START %%in%% bad_%s] <- NA_real_", var, var),
            ""
          )

        }
      } else {
        lines <- c(lines, "## (No manual removals were confirmed in the app)", "")
      }

      lines <- c(lines, "write.csv(df, 'fluxtools_processed.csv', row.names = FALSE, na = 'NA')")
      writeLines(lines, script_path)

      # 5) PRM audit → wide + long + manual replay script
      # 5) PRM audit → write manual_prm_removed.R only (no CSV)
      if (isTRUE(rv$prm_active) && !is.null(rv$prm_mask)) {
        removed_list <- lapply(names(rv$prm_mask), function(nm) {
          df_rows <- rv$prm_mask[[nm]]
          if (is.null(df_rows) || nrow(df_rows) == 0) return(NULL)
          ts_vec <- rv$df$ts_str[ match(df_rows$.row, rv$df$.row) ]
          data.frame(
            TIMESTAMP_START = ts_vec,
            column          = nm,
            stringsAsFactors = FALSE
          )
        })
        removed_df <- do.call(rbind, removed_list)

        manual_script <- file.path(tmpdir, "manual_prm_removed.R")

        if (is.null(removed_df) || nrow(removed_df) == 0) {
          # still include a tiny script so users know PRM had nothing to undo
          writeLines(c(
            "## Manual PRM removal (no-op)",
            "## No PRM-removed timestamps were recorded in the session."
          ), manual_script)
          extra_files <- c(extra_files, manual_script)
        } else {
          by_col <- split(removed_df, removed_df$column)

          # Self-contained replay script: embeds timestamp vectors; no CSV needed
          lines_manual <- c(
            "## Auto-generated: Replay PRM removals (self-contained; no CSV)",
            "na_vals <- c('NA','NaN','','-9999','-9999.0','-9999.00','-9999.000')",
            "if (!exists('df')) df <- read.csv('raw_df.csv', stringsAsFactors = FALSE, na.strings = na_vals)",
            "df$TIMESTAMP_START <- as.character(df$TIMESTAMP_START)",
            ""
          )

          for (nm in names(by_col)) {
            tses   <- unique(by_col[[nm]]$TIMESTAMP_START)
            vec_ml <- format_vec(tses, chunk = 80)  # uses helper defined above
            lines_manual <- c(
              lines_manual,
              sprintf("## %s: %d timestamp(s)", nm, length(tses)),
              sprintf("bad_%s <- %s", nm, vec_ml),
              sprintf("if ('%s' %%in%% names(df)) df[['%s']][df$TIMESTAMP_START %%in%% bad_%s] <- NA", nm, nm, nm),
              ""
            )
          }
#is this correct...???
          # lines_manual <- c(lines_manual,
          #                   "write.csv(df, 'prm_manual_removal.csv', row.names = FALSE, na = 'NA')"
          #)
          writeLines(lines_manual, manual_script)
          extra_files <- c(extra_files, manual_script)  # <- script only, no CSV
        }
      }


      # 6) Zip everything
      try(utils::zip(zipfile, files = extra_files, flags = "-j", extras = "-q"),
          silent = TRUE)
      if (!file.exists(zipfile) && requireNamespace("zip", quietly = TRUE)) {
        zip::zipr(zipfile, files = extra_files)
      }

      #utils::zip(zipfile, files = extra_files, flags = "-j", extras = "-q")
    }
  )

  #Unflag Data button logic
  observeEvent(input$remove_acc, {
    pairs <- selected_pairs()
    if (nrow(pairs) == 0) return()

    # keep orange layer tidy for current view
    rows <- df_by_year()$.row[df_by_year()$ts_str %in% pairs$ts]
    sel_keys(setdiff(isolate(sel_keys()), rows))

    # per-variable unflag
    byv <- split(pairs$ts, pairs$var)
    for (v in names(byv)) {
      old <- removed_ts[[v]] %||% character()
      removed_ts[[v]] <- setdiff(old, unique(byv[[v]]))
    }
  })
#slider fix
  observeEvent(input$start_dt, {
    df <- df_by_year(); req(df, input$start_dt)
    pool <- sort(unique(df$TIMESTAMP_START[ rows_for_time(df) ])); if (!length(pool)) return()
    s <- snap_to_pool(from_view_time(input$start_dt), pool)
    e <- isolate(input$time_rng[2]); if (is.null(e) || s > e) e <- s
    updateSliderInput(session, "time_rng", value = c(s, e))
  }, ignoreInit = TRUE)

  observeEvent(input$end_dt, {
    df <- df_by_year(); req(df, input$end_dt)
    pool <- sort(unique(df$TIMESTAMP_START[ rows_for_time(df) ])); if (!length(pool)) return()
    e <- snap_to_pool(from_view_time(input$end_dt), pool)
    s <- isolate(input$time_rng[1]); if (is.null(s) || e < s) s <- e
    updateSliderInput(session, "time_rng", value = c(s, e))
  }, ignoreInit = TRUE)



  #overlay
  observeEvent(input$overlay_mode, {
    if (!isTRUE(input$overlay_mode)) {
      # Keep Y’s staged flags, purge the rest so nothing “hidden” lingers
      all_staged <- names(Filter(length, reactiveValuesToList(removed_ts)))
      for (v in setdiff(all_staged, input$yvar)) removed_ts[[v]] <- NULL
      # Also tidy the orange layer preview
      sel_keys(integer(0)); session$resetBrush("qc_plot")
      showNotification("Overlay off: cleared staged flags for non-Y variables.", type="message", duration=2)
    }
  }, ignoreInit = TRUE)


  observeEvent(input$remove, {
    pairs  <- selected_pairs()                         # ts + var from plotly keys
    staged <- reactiveValuesToList(removed_ts)         # per-var staged flags

    # variables we’re allowed to touch right now:
    allowed <- intersect(vars_to_edit(), names(rv$df) %||% character())

    # staged vars in-scope
    staged_vars <- intersect(names(Filter(function(z) length(z) > 0, staged)), allowed)
    # brushed vars in-scope
    brushed_vars <- if (NROW(pairs) > 0) intersect(unique(pairs$var), allowed) else character(0)

    vars_all <- unique(c(staged_vars, brushed_vars))
    if (length(vars_all) == 0) {
      showNotification("Nothing to remove for current selection.", type = "message")
      return()
    }

    tmp <- rv$df
    total_tses <- 0L

    for (v in vars_all) {
      ts_v <- unique(c(staged[[v]] %||% character(), pairs$ts[pairs$var == v]))
      if (length(ts_v) == 0 || !is.numeric(tmp[[v]])) next

      idx <- tmp$ts_str %in% ts_v
      tmp[[v]][idx] <- NA_real_

      confirmed_ts[[v]] <- unique(c(confirmed_ts[[v]] %||% character(), ts_v))
      removed_ts[[v]]   <- setdiff(removed_ts[[v]] %||% character(), ts_v)

      total_tses <- total_tses + length(ts_v)
    }

    rv$df <- tmp

    showNotification(
      sprintf("Applied removals: %d timestamp%s across %d variable%s.",
              total_tses, if (total_tses == 1) "" else "s",
              length(vars_all), if (length(vars_all) == 1) "" else "s"),
      type = "message", duration = 3
    )

    sel_keys(integer(0)); outlier_keys(integer(0)); session$resetBrush("qc_plot")
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
