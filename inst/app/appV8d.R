#Fluxtools code

#UPDATES (9/2025)
# - [X]  add  line (instead of scatterplot) option
# - [X]  add smoothed line option (with options for how smoothed with loess)
# - [X]  add overlay option, for line or smooth on top of scatterplot (or line) with opacity feature
# - [X]  time filter (allow for night vs day); Bonus: If time picked is between 6am and 8pm, have a sun icon pop up, or a moon during 8pm to 6am
# - [X]  Select months (similar to select years) or specific day (subset plots to these timeframes)

#SUPER ADVANCED:
#current working here!
#working on how to get comparison dataset to work and colors, labels...

#Getting errors... unsure this is worth it
#UTC stuff - not sure this is being done correctly. takes raw data and -5 for UTC-5 when data is already in  eastern timezone. hrm...

#Flags work in comparison mode but only for dataset 1!

# - [ ]  how to assign colors for each variable without being a huge pain
# - [ ]  two data comparison option? this would allow the user to upload a second dataset
# the goal for second dataset is for data comparison, not necessarily flagging! is there a good way to do this?

#Packages
library(shiny)
library(plotly)
library(dplyr)
library(bslib)     # for theming
library(shinyWidgets) #for time selector
library(readr)

#File Size Limit
# Allow larger uploads (here: up to 1gb)
options(shiny.maxRequestSize = 1024 * 1024 * 1024)

#Theme----
light_theme <- bs_theme(
  bootswatch = "cerulean",
  base_font_size  = "14px",
  font_scale      = 1
)

dark_theme <- bs_theme(
  version        = 5,
  bootswatch     = "slate",
  base_font_size  = "14px",
  font_scale      = 1,
  fg             = "#EEE",
  bg             = "#222",
  input_bg       = "#333",
  input_fg       = "#EEE"
)

#UI----

#<head> assets in one object
head_assets <- tags$head(
  # ⬇️ paste your exact tags$style / tags$script blocks here
  tags$style(HTML("
  /* shrink tables inside modals + PRM help */
  #help_prm_table, #prm_summary_tbl, .modal-body table { font-size: 0.8rem; }
  /* wrap tables so they scroll instead of overflowing */
  .table-wrap { max-width:100%; overflow-x:auto; }
")),
  tags$style(HTML('
     /* Slightly smaller, grayscale icons by default; restore on hover/focus */
    .btn .fa, .btn .bi,
    .accordion-button .fa, .accordion-button .bi,
    summary .fa, summary .bi {
    font-size: 0.95em;
    filter: grayscale(100%);
    opacity: .85;
    transition: filter .15s ease, opacity .15s ease, transform .15s ease;
    }
    .btn:hover .fa, .btn:focus .fa,
    .btn:hover .bi, .btn:focus .bi,
    .accordion-button:hover .fa, .accordion-button:focus .fa,
    .accordion-button:hover .bi, .accordion-button:focus .bi,
    summary:hover .fa, summary:focus .fa,
    summary:hover .bi, summary:focus .bi {
      filter: none;
      opacity: 1;
    }
    /* Also trim icon padding so they feel tighter */
    .btn .fa, .btn .bi { margin-right: .4rem; }

    /* Optional: make icon-only links (like the ? help) a touch smaller */
    .navbar .fa, .navbar .bi,
    .title-panel .fa, .title-panel .bi {
      font-size: 0.9em;
    }
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

  #for colors
  tags$script(HTML('
  Shiny.addCustomMessageHandler("markBadHex", function(x){
    var el = document.getElementById(x.id);
    if(!el) return;
    if(x.bad) el.classList.add("bad-hex"); else el.classList.remove("bad-hex");
  });
')),



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
)

#make tiny title + subtitle blocks----
title_bar <- titlePanel(
  div(
    "fluxtools: Interactive QA/QC with Code Generator",
    actionLink("help", label = icon("question-circle"), style = "margin-left:10px;")
  )
)

subtitle_bar <- uiOutput("subtitle")


#Side Panel ----
sidebar_controls <- sidebarPanel(
  width = 4,
  style = "max-height: calc(100vh - 80px); overflow-y: auto;",

  # Data Upload and Selection ----
  tags$h5("Data upload and selection"),
  fileInput("csv_file", "Upload Ameriflux‐style or Fluxnet .csv:", accept = ".csv"),



  # UTC offset ----
  bslib::accordion(
    id = "advanced_tz_box",
    open = "advanced",
    bslib::accordion_panel(
      title = tagList(icon("sliders-h"), "Set timezone"),
      value = "advanced",
      div(class = "mb-2 mt-2",
          tags$label(
            id    = "data_offset_label",
            `for` = "data_offset",
            "Interpret TIMESTAMP_START as local time in:",
            'data-bs-toggle' = "tooltip",
            title = "Fixed timestamp; no DST (Raw timestamps are not changed)"
          ),
          selectInput(
            "data_offset", label = NULL,
            choices  = sprintf("UTC%+d", -12:14),
            selected = "UTC+0", width = "100%"
          ),
          tags$small(class = "form-text text-muted fst-italic",
                     "This only changes how times are shown in the app; exports keep original strings.")
      ),
      tags$details(
        class = "mt-1",
        tags$summary("Show timestamp parsing details"),
        tags$pre(style = "margin-top:.5rem;", textOutput("tz_check"))
      )
    )
  ),

  #Compare option:
  tags$h5("Compare two datasets"),

  #This is too complicated at the moment, need to simplify color and line options here. per dataset makes more sense than per variable for two data comparision

  checkboxInput("compare_mode", "Compare two datasets", FALSE),
  conditionalPanel("input.compare_mode",
                   tags$h6("Dataset B"),
                   fileInput("csv_file_b", "Upload comparison CSV:", accept = ".csv"),

                   # --- Dataset color pickers (simple, no extra pkgs) ---
                   #also have line type options!
                   tags$h6("Dataset colors"),
                   uiOutput("ds_color_ui")

                   ),
  tags$small(class = "form-text text-muted fst-italic",
             "IMPORTANT: Flag options do not work with this option!"),
  hr(),

  # Plot selection ----
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

  # Overlay mode ----
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
                         plugins = list("remove_button")),
          width = "100%"
        ),
        checkboxInput("overlay_include_y", "Include current y-variable", TRUE)
      )
    )
  ),

  # Advanced (style & markers) ----
  bslib::accordion(
    id = "advanced_flg_box",
    open = FALSE,
    bslib::accordion_panel(
      title = tagList(icon("sliders-h"), "Advanced (flag style & markers)"),
      value = "advanced",

      tags$h5("Select Plot type (default: Scatterplot)"),

      radioButtons(
        "geom_mode", NULL,
        choices  = c("Scatter" = "scatter", "Line" = "line"),
        selected = "scatter",
        inline   = TRUE
      ),

      sliderInput("overlay_alpha", "Point/line opacity",
                  min = 0, max = 1, value = 0.70, step = 0.05),

      # Scatter options
      conditionalPanel(
        "input.geom_mode == 'scatter'",
        bslib::accordion(
          id = "scatterplot_opt", open = FALSE,
          bslib::accordion_panel(
            title = tagList(icon("sliders-h"), "Scatter options"),
            value = "scatter_opts",
            tags$h5("Scatter options"),
            sliderInput("overlay_size", "Point size",
                        min = 1, max = 14, value = 6, step = 1),

            checkboxInput("overlay_hollow", "Use hollow circles", TRUE)
          )
       )
      ),

      # Line options
      conditionalPanel(
        "input.geom_mode == 'line'",
        bslib::accordion(
          id = "line_opt", open = FALSE,
          bslib::accordion_panel(
            title = tagList(icon("sliders-h"), "Line options"),
            value = "line_opts",
            tags$h5("Line options"),
            sliderInput("line_lwd", "Line width",
                        min = 1, max = 8, value = 2, step = 1),
            checkboxInput("line_show_points",
                          "Add transparent points so lasso selection works (use for flag selection!)", TRUE)
          )
        )
      ),

      # Smoother overlay
      bslib::accordion(
        id = "smooth_opt", open = FALSE,
        bslib::accordion_panel(
          title = tagList(icon("chart-line"), "Smoother overlay"),
          value = "smooth_opts",
          checkboxInput("show_smooth", "Add smoothed line", FALSE),

          conditionalPanel(
            "input.show_smooth",
            selectInput(
              "smooth_method", "Method",
              choices = c("LOESS (loess)" = "loess"),
              selected = "loess"
            ),
            conditionalPanel(
              "input.smooth_method == 'loess'",
              sliderInput("smooth_span", "LOESS span", min = .05, max = 1, value = .4, step = .05)
            ),
            checkboxInput("smooth_show_ci", "Show 95% CI band", FALSE),
            sliderInput("smooth_lwd",   "Smoother width",   min = 1, max = 8, value = 3,  step = 1),
            sliderInput("smooth_alpha", "Smoother opacity", min = 0, max = 1, value = .6, step = .05)
          )
        )
      ),

      hr(),

      tags$h5("Flag Options"),
      sliderInput("flag_size", "Flag point size", min = 1, max = 14, value = 8, step = 1),

      hr(),

      # Color
      tags$h5("Color"),

      radioButtons(
        "compare_style", "Coloring mode",
        choices = c("By variable" = "varcolor",
                    "By dataset (A/B)" = "dscolor"),
        selected = "dscolor", inline = TRUE
      ),

      #currentlty not working:
      selectInput(
        "overlay_palette", "Palette",
        choices = c(
          "Okabe–Ito"     = "okabe",
          "Tableau 10"    = "tableau10",
          "Set2 (pastel)" = "set2",
          "Viridis (dark)"= "viridis",
          "Key"           = "key"
        ),
        selected = "okabe", width = "100%"
      ),
      tags$small(class="text-muted d-block",
                 "y-axis color selection applies only to the single-variable view"),
      tags$small(class="text-muted d-block",
                 "Plotting multiple variables uses the palette"),

      conditionalPanel(
        "!input.overlay_mode",
        selectInput(
          "y_color_style", "y-axis color (single view)",
          choices = c(
            "Theme accent (default)" = "default",
            "Black"                  = "black",
            "Custom"                 = "custom"
          ),
          selected = "default", width = "100%"
        ),
        conditionalPanel(
          "input.y_color_style == 'custom'",
          textInput("y_color_custom", "Custom hex", value = "#1F449C", width = "100%")
        )
      ),

      selectInput(
        "flag_color_scheme", "Flag color style",
        choices = c(
          "Yellow (classic)"        = "yellow",
          "Match variable (darker)" = "match_dark",
          "Match variable (lighter)"= "match_light"
        ),
        selected = "yellow", width = "100%"
      ),

      uiOutput("pair_legend"),
      checkboxInput("show_pair_legend", "Show color key", TRUE)
    )
  ),

  hr(),

  # Interact with data ----
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

  # Time subset ----
  tags$h5("Data subset options"),
  bslib::accordion(
    id = "advanced_timesub_box",
    open = FALSE,
    bslib::accordion_panel(
      title = tagList(icon("clock"), "Time subset"),
      value = "advanced",

      tags$h5("Select by Year"),
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
        'data-bs-title'  = "Filter to one or more years"
      ),

      tags$h5("Select by Month"),
      shinyWidgets::pickerInput(
        inputId = "month_sel",
        label   = "Select month(s):",
        choices = stats::setNames(1:12, month.abb),
        multiple = TRUE,
        options = list(
          `actions-box` = TRUE,
          `selected-text-format` = "count > 3",
          `none-selected-text`   = "All months"
        )
      ),

      tags$h5("Select by Day"),
      shinyWidgets::airDatepickerInput(
        inputId    = "day_sel",
        label      = "Specific day(s):",
        multiple   = TRUE,
        autoClose  = TRUE,
        clearButton = TRUE,
        placeholder = "Pick one or more days"
      ),

      tags$h5("Select by Hour"),
      shinyWidgets::sliderTextInput(
        inputId  = "hod_rng",
        label    = "Hours of day (local):",
        choices  = sprintf("%02d:00", 0:24),
        selected = c("00:00", "24:00"),
        grid     = TRUE,
        dragRange = TRUE
      ),
      checkboxInput("hod_invert", "Use outside these hours (night)", FALSE),

      tags$small(class = "text-muted",
                 "*Time filters are applied in the chosen viewing timezone")
    )
  ),

  # PRM + Range/Time/Outliers/Code (grouped) ----
  bslib::accordion(
    id = "prm_sections",
    open = FALSE,

    # PRM
    bslib::accordion_panel(
      title = tags$span(
        class = "d-inline-flex align-items-center gap-2",
        icon("seedling"),
        tags$span(
          HTML("Physical Range Module&nbsp;(PRM)"),
          'data-bs-toggle'   = "tooltip",
          'data-bs-placement' = "right",
          title              = "Clamp variables to possible physical ranges; out-of-range → NA"
        )
      ),
      value = "prm",

      tags$h5("Use the Physical Range Module"),
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
            title="Reverts only values changed by the last PRM apply. Other edits unaffected.")
        )
      ),
      tags$small(class = "text-muted",
                 "Note: This turns data values into 'NA' when outside of the PRM range (See Help: PRM for specific values)"),
      hr(),
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
            actionButton("apply_prm_subset", "Apply PRM to selected", icon = icon("play")))
      )
    ),


    hr(),
    tags$h5("Flag options"),

    # Flag by range
    bslib::accordion_panel(
      title = tagList(icon("sliders-h"), "Flag by value range"),
      value = "range",
      tags$h5("Flag Values based on range"),
      selectInput("rng_var", "Variable", choices = NULL),
      checkboxInput("rng_link_y", "Link selected variable to plot Y-axis", TRUE),
      fluidRow(
        column(6, numericInput("rng_min", "Min (optional)", value = NA)),
        column(6, numericInput("rng_max", "Max (optional)", value = NA))
      ),
      div(class="d-grid gap-2",
          actionButton("rng_flag", "Flag values outside range"))
    ),

    # Flag by time
    bslib::accordion_panel(
      title = tagList(icon("clock"), "Flag by date range"),
      value = "time",
      tags$h5("Flag Values based on Date"),
      sliderInput(
        "time_rng", "TIMESTAMP_START range:",
        min = 0, max = 1, value = c(0, 1),
        timeFormat = "%Y-%m-%d\n%H:%M", step  = 3600
      ),
      fluidRow(
        column(
          6,
          shinyWidgets::airDatepickerInput(
            inputId    = "start_dt", label = "Start:",
            timepicker = TRUE, autoClose  = TRUE,
            placeholder = "Select start"
          )
        ),
        column(
          6,
          shinyWidgets::airDatepickerInput(
            inputId    = "end_dt", label = "End:",
            timepicker = TRUE, autoClose  = TRUE,
            placeholder = "Select end"
          )
        )
      ),
      fluidRow(
        column(6, actionButton("time_flag",     "Flag inside",  class = "btn btn-primary w-100")),
        column(6, actionButton("time_flag_out", "Flag outside", class = "btn btn-outline-primary w-100"))
      )
    ),

    # Outliers
    bslib::accordion_panel(
      title = tagList(icon("wave-square"), "Flag outliers"),
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
      ),
      tags$small(class = "text-muted",
                 "Note: outlier detection uses the current Y variable only (does not support multi-selected variables)")
    ),

    # Code generation
    bslib::accordion_panel(
      title = tagList(icon("code"), "Code generation"),
      value = "code",

      tags$h5("Automatic code generation for nullifying data"),

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
            'data-bs-toggle' = "tooltip",
            title = "Copy visible code",
            icon("clipboard"),
            span("Copy code"),
            onclick = HTML("
              var which = document.querySelector('input[name=code_choice]:checked').value;
              var srcId = which==='current' ? 'code_current' : 'code_all';
              var txt   = document.getElementById(srcId).innerText;
              var ta = document.createElement('textarea');
              ta.value = txt; ta.setAttribute('readonly','');
              ta.style.position = 'absolute'; ta.style.left = '-9999px';
              document.body.appendChild(ta); ta.select(); document.execCommand('copy');
              document.body.removeChild(ta);
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
      ),
      tags$small(class = "text-muted",
                 "Note: Current code turns the currently selected data flags into 'NA'. Accumulated code shows code for all removals; it will be included in the exported ZIP as an R script.")
    )
  ),  # end prm_sections accordion

  hr(),

  # Downloads / toggles ----
  fluidRow(
    column(
      3,
      tagAppendAttributes(
        downloadButton("download_csv", "Save cleaned CSV", icon = icon("file-csv"), width = "100%"),
        'data-bs-toggle' = "tooltip",
        title = "Download just the cleaned CSV (keeps original TIMESTAMP_START strings)"
      )
    ),
    column(
      3,
      tagAppendAttributes(
        downloadButton("download_data", "Export zip file", icon = icon("file-archive"), width="100%"),
        'data-bs-toggle' = "tooltip",
        title = "Download a .zip containing the cleaned CSV and the removal R script"
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
)












#server----
server <- function(input, output, session) {
  phase_badge <- reactive({
    .current_phase_icons(input$hod_rng, isTRUE(input$hod_invert))
  })

  #NA strings for r script output
  NA_STRINGS <- c("NA","NaN","","-9999","-9999.0","-9999.00","-9999.000")

  # --- init reactive stores early (so we can use rv immediately) ---
  rv <- reactiveValues(
    df = NULL,
    df_before_prm = NULL,
    prm_active = FALSE,
    prm_summary = NULL,
    prm_mask = NULL,
    prm_include = NULL   # <- add this
  )

  labA <- reactive({
    req(input$compare_mode)          # only valid when compare UI exists
    input$label_a %||% "Dataset A"
  })
  labB <- reactive({
    req(input$compare_mode)
    input$label_b %||% "Dataset B"
  })


  raw_df_b <- reactive({
    req(input$compare_mode, input$csv_file_b)
    read.csv(input$csv_file_b$datapath, stringsAsFactors = FALSE,
             colClasses = c(TIMESTAMP_START = "character"), na.strings = NA_STRINGS)
  })

  shifted_df_b <- reactive({
    df0 <- raw_df_b(); req(df0)
    digits <- gsub("[^0-9]", "", df0$TIMESTAMP_START %||% "")
    digits <- substr(paste0(digits, "0000"), 1, 12)
    off_hr <- data_off_hr()
    ts_utc <- as.POSIXct(digits, format = "%Y%m%d%H%M", tz = "UTC") - off_hr*3600
    df0 %>% mutate(raw_ts = TIMESTAMP_START, ts_str = digits,
                   TIMESTAMP_START = ts_utc, .row = dplyr::row_number())
  })

  df_compare_long <- reactive({
    req(input$compare_mode, rv$df, shifted_df_b())
    make_long <- function(df, src){
      num <- df %>% select(-TIMESTAMP_START, -raw_ts, -ts_str, -.row) %>% select(where(is.numeric))
      tidyr::pivot_longer(
        df, cols = all_of(names(num)), names_to = "variable", values_to = "value"
      ) %>% mutate(source = src)
    }
    bind_rows(
      make_long(df_by_year(), "A"),
      make_long({
        # apply same year/month/day/hour filters to B
        tmp <- shifted_df_b()
        # re-use your df_by_year logic by factoring into a function or quickly mimicking:
        off_hours <- data_off_hr()
        tmp$local_ts    <- tmp$TIMESTAMP_START + off_hours*3600
        tmp$local_date  <- as.Date(tmp$local_ts, tz = data_tz())
        tmp$local_month <- as.integer(format(tmp$local_ts, "%m"))
        tmp$local_hour  <- as.numeric(format(tmp$local_ts, "%H")) + as.numeric(format(tmp$local_ts, "%M"))/60
        # apply the same filters you used above...
        if (!identical(input$year_sel, "All")) {
          yrs <- setdiff(input$year_sel, "All")
          tmp <- tmp[format(tmp$TIMESTAMP_START, "%Y") %in% yrs, , drop = FALSE]
        }
        if (length(input$month_sel)) tmp <- tmp[tmp$local_month %in% as.integer(input$month_sel), , drop = FALSE]
        if (length(input$day_sel))   tmp <- tmp[tmp$local_date %in% as.Date(input$day_sel), , drop = FALSE]
        if (length(input$hod_rng) == 2) {
          hh <- .parse_hhmm(input$hod_rng)
          in_rng <- .hod_in_range(tmp$local_hour, hh[1], hh[2])
          tmp <- tmp[ if (isTRUE(input$hod_invert)) !in_rng else in_rng , , drop = FALSE]
        }
        tmp
      }, "B")
    )
  })

  var_colors <- reactiveValues()  # map: var -> hex

  observe({
    req(rv$df)
    vars <- names(rv$df %>% dplyr::select(where(is.numeric)))
    # ensure we always have a default palette entry
    defaults <- setNames(pal_overlay(length(vars)), vars)
    for (v in vars) if (is.null(var_colors[[v]])) var_colors[[v]] <- defaults[[v]]
  })

  # keep map in sync with inputs
  observe({
    if (!isTRUE(input$enable_var_colors)) return()
    req(rv$df)
    vars <- names(rv$df %>% dplyr::select(where(is.numeric)))
    for (v in vars) {
      id <- paste0("col_", v)
      val <- input[[id]]
      if (!is.null(val) && nzchar(val)) var_colors[[v]] <- val
    }
  })

  # validate & store
  .valid_hex <- function(x) isTRUE(grepl("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", x))
  observe({
    if (!isTRUE(input$enable_var_colors)) return()
    req(rv$df)
    vars <- names(rv$df %>% dplyr::select(where(is.numeric)))
    for (v in vars) {
      id  <- paste0("col_", v)
      val <- input[[id]]
      # keep defaults if empty
      if (is.null(val) || !nzchar(val)) next
      # set reactive map only when valid
      if (.valid_hex(val)) var_colors[[v]] <- toupper(val)
      # mark invalid in the DOM (no extra libs)
      session$sendCustomMessage("markBadHex", list(id = id, bad = !.valid_hex(val)))
    }
  })
  # JS helper once (near your other addCustomMessageHandler blocks)
  session$onFlushed(function(){
    session$sendCustomMessage("noop", NULL)
  }, once = TRUE)

  # returns the proper x vector for the given data.frame and current xvar
  x_for <- function(d) {
    if (identical(input$xvar, "TIMESTAMP_START")) d$ts_view else d[[input$xvar]]
  }


  # small helper used later
  # NULL-coalescing that’s safe for vectors
  `%||%` <- function(x, y) if (is.null(x)) y else x

  # # NULL-coalescing that’s safe for vectors
  # `%||%` <- function(x, y) {
  #   if (is.null(x)) return(y)
  #   # optionally treat a single empty string as NULL
  #   if (is.character(x) && length(x) == 1 && !nzchar(x)) return(y)
  #   x
  # }


  #color helpers
  .valid_hex <- function(x) isTRUE(grepl("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", x))

  # Pretty label helper for colored swatches
  .pretty_opt <- function(hex_or_custom) {
    if (hex_or_custom == "custom") return(HTML("Custom…"))
    HTML(sprintf(
      "<span style='display:inline-block;width:0.9em;height:0.9em;border-radius:50%%;margin-right:.4em;background:%s;'></span>%s",
      hex_or_custom, hex_or_custom
    ))
  }

  output$ds_color_ui <- renderUI({
    # same values you defined earlier
    ds_vals <- c("#fe4a49", "#009fb7", "#721cb8", "#509724",
                 "#ffbf00", "#1F77B4", "#FF7F0E", "custom")

    label_html <- function(hex) {
      if (hex == "custom") return("Custom…")
      sprintf(
        "<span style='display:inline-block;width:0.9em;height:0.9em;border-radius:50%%;margin-right:.4em;background:%s;'></span>%s",
        hex, hex
      )
    }
    labels <- vapply(ds_vals, label_html, "")

    tagList(
      fluidRow(
        column(
          6,
          shinyWidgets::pickerInput(
            inputId = "pick_ds_A", label = "Dataset A color",
            choices = ds_vals, selected = "#fe4a49",
            options = list(`live-search` = FALSE),
            choicesOpt = list(content = as.list(labels))
          ),
          conditionalPanel(
            "input.pick_ds_A == 'custom'",
            textInput("col_ds_A", NULL, value = "#fe4a49", width = "100%", placeholder = "#RRGGBB")
          )
        ),
        column(
          6,
          shinyWidgets::pickerInput(
            inputId = "pick_ds_B", label = "Dataset B color",
            choices = ds_vals, selected = "#009fb7",
            options = list(`live-search` = FALSE),
            choicesOpt = list(content = as.list(labels))
          ),
          conditionalPanel(
            "input.pick_ds_B == 'custom'",
            textInput("col_ds_B", NULL, value = "#009fb7", width = "100%", placeholder = "#RRGGBB")
          )
        )
      ),
      tags$style(HTML("input.bad-hex { border-color:#dc3545!important; box-shadow:none!important; }"))
    )
  })


  # Optional: live hex validation (re-uses your markBadHex handler)
  observe({
    if (!is.null(input$col_ds_A))
      session$sendCustomMessage("markBadHex", list(id = "col_ds_A", bad = !.valid_hex(input$col_ds_A)))
    if (!is.null(input$col_ds_B))
      session$sendCustomMessage("markBadHex", list(id = "col_ds_B", bad = !.valid_hex(input$col_ds_B)))
  })

  # Final dataset color reactive (names MUST match df_compare_long()$source values "A"/"B")

  ds_cols <- reactive({
    a <- if (identical(input$pick_ds_A, "custom")) input$col_ds_A else input$pick_ds_A
    b <- if (identical(input$pick_ds_B, "custom")) input$col_ds_B else input$pick_ds_B
    a <- if (.valid_hex(a)) toupper(a) else "#fe4a49"
    b <- if (.valid_hex(b)) toupper(b) else "#009fb7"
    c(A = a, B = b)
  })

  #time helper
  .parse_hhmm <- function(x) {
    if (is.null(x) || length(x) != 2) return(c(0, 24))
    as.numeric(sub(":.*","", x)) + as.numeric(sub(".*:","", x))/60
  }
  .hod_in_range <- function(h, start, end) {
    if (is.na(start) || is.na(end) || start == end) return(rep(TRUE, length(h)))   # all day
    if (start < end) (h >= start & h < end) else (h >= start | h < end)            # wrap-aware
  }
  # Returns ☀️, 🌙, or "☀️ 🌙" depending on selected hours (with invert)
  .current_phase_icons <- function(hh_vec, invert = FALSE) {
    hh  <- .parse_hhmm(hh_vec)
    hrs <- seq(0, 24, by = 0.5)
    sel <- .hod_in_range(hrs, hh[1], hh[2])
    if (invert) sel <- !sel

    day     <- .hod_in_range(hrs, 6, 18)
    day_on  <- any(sel & day)
    nite_on <- any(sel & !day)

    icons <- character(0)
    if (day_on)  icons <- c(icons, "☀")
    if (nite_on) icons <- c(icons, "☾")

    if (length(icons) == 0) return("—")
    paste(icons, collapse = " ")
  }

  x_title_with_phase <- function() {
    badge <- phase_badge()
    if (length(badge) == 0 || is.na(badge)) badge <- ""   # ← guard
    if (identical(input$xvar, "TIMESTAMP_START")) {
      sprintf("%s  TIMESTAMP_START (UTC%+d)", badge, data_off_hr())
    } else {
      sprintf("%s  %s", badge, input$xvar)
    }
  }

  # ---- visual constants (no sliders needed) ----
  POINT_ALPHA      <- 0.70   # base points
  RING_ALPHA       <- 0.90   # flagged ring
  RING_LINE_WIDTH  <- 3
  RING_SIZE_EXTRA  <- 4      # flagged ring vs base size delta
  DARKEN_AMT       <- 0.50   # stronger dark
  TINT_AMT         <- 0.60   # stronger light


  #control y color
  y_base_color <- reactive({
    s <- input$y_color_style %||% "default"
    if (s == "black") return("#000000")
    if (s == "default")      return("#1F449C")
    if (s == "custom")     return(input$y_color_custom %||% "#1F449C")
    # theme default (light/dark)
    if (isTRUE(input$dark_mode)) "#1F62FF" else "#1F449C"

    #new
    pal_overlay(1)[1] #new
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


  #PRM----
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
      #enhance number of decimals written
      readr::write_csv(out, file, na = "NA", num_threads = 1)
      #utils::write.csv(out, file, row.names = FALSE, na = "NA")
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

  #time helper
  # Helper: safe range for POSIXct; returns NULL if no finite values
  safe_posix_range <- function(x) {
    if (is.null(x)) return(NULL)
    x_ok <- x[is.finite(as.numeric(x))]
    if (!length(x_ok)) return(NULL)
    range(x_ok)
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
    if (!length(vars)) return(base)
    # no overlay → whole timeline
    any_non_na <- Reduce(`|`, lapply(vars, function(v) !is.na(df[[v]])))  # vectorized per row
    #any_non_na <- Reduce(`|`, lapply(vars, function(v) isTRUE(!is.na(df[[v]]))))
    #any_non_na <- Reduce(`|`, lapply(vars, function(v) !is.na(df[[v]])))
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

  #observeEvents----
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

  data_off_hr <- reactive({
    val <- input$data_offset
    if (is.null(val) || !nzchar(val)) return(0L)   # default UTC+0 if control absent
    parse_utc_hours(val)
  })

  data_tz <- reactive({
    off <- data_off_hr()
    if (off == 0) "UTC" else sprintf("Etc/GMT%s%d", if (off < 0) "+" else "-", abs(off))
  })


  # data_tz <- reactive({
  #   off <- data_off_hr()
  #   if (off == 0) "UTC" else paste0("Etc/GMT", if (off < 0) "+", "-")[1] %||% ""  # sign flip handled below
  #   if (off == 0) "UTC" else paste0("Etc/GMT", if (off < 0) "+" else "-", abs(off))
  # })



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

  #color overlay----
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


  #PRM Server----
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


  df_by_year <- reactive({
    req(rv$df, input$year_sel)
    df <- rv$df

    # Year filter (unchanged)
    if (!identical(input$year_sel, "All")) {
      yrs <- setdiff(input$year_sel, "All")
      df  <- df[format(df$TIMESTAMP_START, "%Y") %in% yrs, , drop = FALSE]
    }

    # Local time columns
    off_hours <- data_off_hr()
    df$local_ts    <- df$TIMESTAMP_START + off_hours * 3600
    df$local_date  <- as.Date(df$local_ts, tz = data_tz())
    df$local_month <- as.integer(format(df$local_ts, "%m"))
    df$local_hour  <- as.numeric(format(df$local_ts, "%H")) +
      as.numeric(format(df$local_ts, "%M"))/60

    # Month filter (optional)
    if (!is.null(input$month_sel) && length(input$month_sel) > 0) {
      df <- df[df$local_month %in% as.integer(input$month_sel), , drop = FALSE]
    }

    # Specific day(s) filter (optional)
    if (!is.null(input$day_sel) && length(input$day_sel) > 0) {
      sel_dates <- as.Date(input$day_sel)
      df <- df[df$local_date %in% sel_dates, , drop = FALSE]
    }

    # Hour-of-day filter (wrap-aware + invert; full-day passes through)
    if (!is.null(input$hod_rng) && length(input$hod_rng) == 2) {
      hh <- .parse_hhmm(input$hod_rng)
      in_rng <- .hod_in_range(df$local_hour, hh[1], hh[2])
      df <- df[ if (isTRUE(input$hod_invert)) !in_rng else in_rng , , drop = FALSE]
    }



    df
  })



  # replace your current observeEvent(df_by_year(), { ... }) with this:
  observe({
    df <- df_by_year(); req(df)

    ts <- df$TIMESTAMP_START[ rows_for_time(df) ]
    ts <- ts[is.finite(as.numeric(ts))]

    if (length(ts) >= 2) {
      step <- infer_cadence_sec(ts)
      r    <- safe_posix_range(ts)
      if (is.null(r)) {
        updateSliderInput(session, "time_rng", min = 0, max = 1, value = c(0,1), step = 3600)
        return()
      }
      r[1] <- align_to_step(r[1], step)
      r[2] <- ceil_to_step(r[2],  step)
      updateSliderInput(session, "time_rng",
                        min = r[1], max = r[2], value = r,
                        step = step, timeFormat = "%Y-%m-%d\n%H:%M")
    } else {
      rng_all <- safe_posix_range(df$TIMESTAMP_START)
      if (is.null(rng_all)) {
        updateSliderInput(session, "time_rng", min = 0, max = 1, value = c(0,1), step = 3600)
      } else {
        step_f <- 3600L
        r1 <- align_to_step(rng_all[1], step_f)
        r2 <- ceil_to_step(rng_all[2],  step_f)
        updateSliderInput(session, "time_rng",
                          min = r1, max = r2, value = c(r1, r2),
                          step = step_f, timeFormat = "%Y-%m-%d\n%H:%M")
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
    rng  <- safe_posix_range(df$TIMESTAMP_START)
    if (is.null(rng)) {
      updateSliderInput(session, "time_rng", min = 0, max = 1, value = c(0,1), step = 3600)
    } else {
      step <- infer_cadence_sec(df$TIMESTAMP_START)
      updateSliderInput(session, "time_rng",
                        min = rng[1], max = rng[2], value = rng,
                        step = step, timeFormat = "%Y-%m-%d\n%H:%M")
    }

    # overlay-aware initialization
    ts_all <- df$TIMESTAMP_START[ rows_for_time(df) ]
    ts_all <- ts_all[is.finite(as.numeric(ts_all))]
    if (length(ts_all) >= 2) {
      step0 <- infer_cadence_sec(ts_all)
      r0    <- safe_posix_range(ts_all)
      if (!is.null(r0)) {
        r0[1] <- align_to_step(r0[1], step0)
        r0[2] <- ceil_to_step(r0[2],  step0)
        updateAirDateInput(session, "start_dt", value = to_view_time(r0[1]))
        updateAirDateInput(session, "end_dt",   value = to_view_time(r0[2]))
        updateSliderInput(session, "time_rng",
                          min = r0[1], max = r0[2], value = r0,
                          step = step0, timeFormat = "%Y-%m-%d\n%H:%M")
      } else {
        updateSliderInput(session, "time_rng", min = 0, max = 1, value = c(0,1), step = 3600)
      }
    } else {
      updateSliderInput(session, "time_rng", min = 0, max = 1, value = c(0,1), step = 3600)
    }

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
  #helpModal----
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
  # Plot tools
  # ────────────────────────────────────────────────────────────────────────────
  # Is the x-axis time?
  is_time_x <- function() identical(input$xvar, "TIMESTAMP_START")

  # Convert to/from "view time" (adds your fixed UTC offset for plotting)
  to_view_x <- function(x) if (is_time_x()) x + data_off_hr()*3600 else x

  # numeric version of any x for modeling
  x_to_num <- function(x) if (inherits(x, "POSIXt")) as.numeric(x) else x
  num_to_x <- function(x_num, proto) {
    if (inherits(proto, "POSIXt")) as.POSIXct(x_num, origin="1970-01-01", tz="UTC") else x_num
  }

  # Make a smooth grid along x
  make_grid <- function(x, n = 400L) {
    rng <- range(x, na.rm = TRUE)
    if (!is.finite(rng[1]) || !is.finite(rng[2]) || rng[1] >= rng[2]) return(x)
    seq(rng[1], rng[2], length.out = n)
  }

  # Fit smoother and return yhat (+/- CI when available)
  fit_smoother_df <- function(x, y, method = "loess", span = .4, k = 10, want_ci = FALSE) {
    ok <- is.finite(x) & is.finite(y)
    x <- x[ok]; y <- y[ok]
    if (length(x) < 3) return(NULL)

    xg <- make_grid(x)
    out <- data.frame(x = xg, yhat = NA_real_, ymin = NA_real_, ymax = NA_real_)


    if (method == "loess") {
      fit <- try(loess(y ~ x, span = span, control = loess.control(surface = "direct")), silent = TRUE)
      if (inherits(fit, "try-error")) return(NULL)
      if (want_ci) {
        pr <- predict(fit, newdata = xg, se = TRUE)
        out$yhat <- pr$fit
        se <- pr$se.fit
        out$ymin <- pr$fit - 1.96 * se
        out$ymax <- pr$fit + 1.96 * se
      } else {
        out$yhat <- predict(fit, newdata = xg)
      }
      return(out)
    }

    NULL
  }

  # Add smoother as lines (+ optional ribbons) to a plotly object
  add_smoother_layer <- function(p, df, xcol, ycol, col_hex, name_prefix = "", lwd = 3,
                                 line_alpha = .6, show_ci = FALSE) {
    x_raw <- df[[xcol]]; y_raw <- df[[ycol]]
    x_num <- x_to_num(x_raw)

    sm <- fit_smoother_df(
      x = x_num, y = y_raw,
      method  = input$smooth_method %||% "loess",
      span    = input$smooth_span %||% .4,
      k       = input$smooth_k %||% 10,
      want_ci = isTRUE(show_ci)
    )
    if (is.null(sm)) return(p)

    # back to original x scale and then to "view time" if needed
    x_grid <- num_to_x(sm$x, x_raw)
    x_plot <- to_view_x(x_grid)

    p <- p %>% plotly::add_lines(
      x = x_plot, y = sm$yhat,
      name = paste0(name_prefix, if (nchar(name_prefix)) " " else "", "smooth"),
      inherit = FALSE, showlegend = FALSE,
      line = list(color = col_hex, width = lwd),
      opacity = line_alpha
    )

    if (isTRUE(show_ci) && any(is.finite(sm$ymin) & is.finite(sm$ymax))) {
      p <- p %>% plotly::add_ribbons(
        x = x_plot, ymin = sm$ymin, ymax = sm$ymax,
        inherit = FALSE, showlegend = FALSE,
        line = list(width = 0),
        fillcolor = hex_to_rgba(col_hex, min(0.35, line_alpha*0.6))
      )
    }
    p
  }


  # ────────────────────────────────────────────────────────────────────────────
  # Render the Plotly scatter (with event_register)
  # ────────────────────────────────────────────────────────────────────────────
  output$qc_plot <- renderPlotly({
    geom <- input$geom_mode %||% "scatter"
    a    <- input$overlay_alpha %||% 0.70

    df0 <- df_by_year()
    req(df0, input$xvar, input$yvar)

    # ─────────── NEW: compare branch ───────────
    if (isTRUE(input$compare_mode)) {
      req(shifted_df_b())                       # ensure B exists
      labsrc <- c(A = labA(), B = labB())

      # decide which variables to show
      vars_plot <- if (isTRUE(input$overlay_mode) && length(input$overlay_vars)) {
        unique(c(if (isTRUE(input$overlay_include_y)) input$yvar, input$overlay_vars))
      } else input$yvar

      dd <- df_compare_long() %>%
        dplyr::filter(variable %in% vars_plot, !is.na(value))

      # time axis prep
      if (identical(input$xvar, "TIMESTAMP_START")) {
        dd$ts_view <- dd$TIMESTAMP_START + data_off_hr()*3600
      }

      p <- plotly::plot_ly(source = "qc_plot") %>% plotly::event_register("plotly_selected")

      if (identical(input$compare_style, "varcolor")) {
        # color by variable; linetype/marker symbol by dataset
        cols <- setNames(pal_overlay(length(vars_plot)), vars_plot)

        # allow per-variable overrides
        for (v in names(cols)) {
          if (!is.null(var_colors[[v]])) cols[[v]] <- var_colors[[v]]
        }

        for (v in vars_plot) {
          for (src in c("A","B")) {
            dds <- dd[dd$variable == v & dd$source == src, , drop = FALSE]
            if (!nrow(dds)) next
            nm <- paste0(v, " — ", labsrc[[src]])
            if (geom == "line") {
              p <- p %>% plotly::add_lines(
                data = dds,
                x    = if (identical(input$xvar, "TIMESTAMP_START")) dds$ts_view else dds[[input$xvar]],
                y    = ~value,
                name = nm,
                inherit = FALSE,
                line  = list(width = input$line_lwd %||% 2,
                             dash  = if (src=="A") "solid" else "dash",
                             color = cols[[v]]),
                opacity = a
              )
              if (isTRUE(input$line_show_points)) {
                p <- p %>% plotly::add_markers(
                  data = dds,
                  x    = if (identical(input$xvar, "TIMESTAMP_START")) dds$ts_view else dds[[input$xvar]],
                  y    = ~value,
                  name = paste0(nm, " pts"),
                  showlegend = FALSE,
                  marker = list(size = 6, color = cols[[v]], opacity = 0.001)
                )
              }
            } else {
              p <- p %>% plotly::add_markers(
                data = dds,
                x    = if (identical(input$xvar, "TIMESTAMP_START")) dds$ts_view else dds[[input$xvar]],
                y    = ~value,
                key  = paste0(dds$ts_str, "||", v),
                name = nm,
                inherit = FALSE,
                marker = list(
                  symbol = if (src=="A") "circle" else "diamond",
                  size   = input$overlay_size %||% 6,
                  opacity = a,
                  color  = cols[[v]]
                )
              )
            }
          }
        }
      } else { # compare_style == "dscolor": color by dataset; iterate (var, src)
        cols_ds <- ds_cols()   # A/B from pickers
        for (v in vars_plot) {
          for (src in c("A","B")) {
            dds <- dd[dd$variable == v & dd$source == src, , drop = FALSE]
            if (!nrow(dds)) next
            nm <- paste0(labsrc[[src]], " — ", v)

            if (geom == "line") {
              p <- p %>% plotly::add_lines(
                data = dds,
                x    = if (identical(input$xvar, "TIMESTAMP_START")) dds$ts_view else dds[[input$xvar]],
                y    = ~value,
                name = nm,
                legendgroup = src,                    # group legend by dataset
                inherit = FALSE,
                line  = list(width = input$line_lwd %||% 2, color = cols_ds[[src]]),
                opacity = a
              )
              if (isTRUE(input$line_show_points)) {
                p <- p %>% plotly::add_markers(
                  data = dds,
                  x    = if (identical(input$xvar, "TIMESTAMP_START")) dds$ts_view else dds[[input$xvar]],
                  y    = ~value,
                  name = paste0(nm, " pts"),
                  legendgroup = src,
                  showlegend = FALSE,
                  marker = list(size = 6, color = cols_ds[[src]], opacity = 0.001)
                )
              }
            } else {
              p <- p %>% plotly::add_markers(
                data = dds,
                x    = if (identical(input$xvar, "TIMESTAMP_START")) dds$ts_view else dds[[input$xvar]],
                y    = ~value,
                key  = paste0(dds$ts_str, "||", v),
                name = nm,
                legendgroup = src,
                inherit = FALSE,
                marker = list(
                  size = input$overlay_size %||% 6,
                  opacity = a,
                  color = cols_ds[[src]],
                  symbol = if (src == "A") "circle" else "diamond"  # shape per dataset
                )
              )
            }

            # Smoother per (v, src)
            if (isTRUE(input$show_smooth)) {
              p <- add_smoother_layer(
                p, dds,
                xcol = if (identical(input$xvar, "TIMESTAMP_START")) "TIMESTAMP_START" else input$xvar,
                ycol = "value",
                col_hex     = cols_ds[[src]],
                name_prefix = nm,
                lwd         = input$smooth_lwd   %||% 3,
                line_alpha  = input$smooth_alpha %||% 0.6,
                show_ci     = isTRUE(input$smooth_show_ci)
              )
            }
          }
        }
      }


      p <- p %>% plotly::layout(
        legend = list(itemclick="toggleothers", itemdoubleclick="toggle"),
        autosize = TRUE, dragmode = "select", font = list(size = 18),
        margin = list(l=80,r=20,b=80,t=20),
        xaxis = list(
          type = if (identical(input$xvar, "TIMESTAMP_START")) "date" else "-",
          tickformat = if (identical(input$xvar, "TIMESTAMP_START")) "%b %d, %Y %H:%M" else NULL,
          title = x_title_with_phase(), title_standoff = 10, tickfont = list(size = 12)
        ),
        yaxis = list(title = paste(vars_plot, collapse = ", "))
      )

      if (isTRUE(input$dark_mode)) {
        p <- p %>% plotly::layout(template = "plotly_dark",
                                  paper_bgcolor="#2E2E2E", plot_bgcolor="#2E2E2E",
                                  font = list(color="white"))
      }

      return(plotly::toWebGL(p))
    }
    # ─────────── end compare branch ───────────

    overlay_on <- isTRUE(input$overlay_mode) && length(input$overlay_vars)

    # ───────────────────────── Overlay mode ─────────────────────────
    if (overlay_on) {
      df <- df0
      if (identical(input$xvar, "TIMESTAMP_START"))
        df$ts_view <- df$TIMESTAMP_START + data_off_hr()*3600

      vars_plot <- unique(c(if (isTRUE(input$overlay_include_y)) input$yvar, input$overlay_vars))
      p <- plotly::plot_ly(source = "qc_plot") %>% plotly::event_register("plotly_selected")

      all_num <- names(df %>% dplyr::select(-TIMESTAMP_START, -raw_ts, -ts_str, -.row) %>% dplyr::select(where(is.numeric)))
      cmap    <- setNames(pal_overlay(length(all_num)), all_num)
      # AFTER (only for vars we’re plotting)
      cols  <- setNames(pal_overlay(length(vars_plot)), vars_plot)

      # allow per-variable overrides (applies to both A and B)
      for (v in names(cols)) {
        if (!is.null(var_colors[[v]])) cols[[v]] <- var_colors[[v]]
      }

      fcols <- flag_cols_for(vars_plot, cols, flag_scheme())

      s  <- input$overlay_size  %||% 6
      fs <- input$flag_size     %||% (s + 2)

      for (v in vars_plot) {
        dd <- dplyr::filter(df, !is.na(.data[[v]]), !is.na(.data[[input$xvar]]))
        if (!NROW(dd)) next

        x_base <- if (identical(input$xvar, "TIMESTAMP_START")) dd$ts_view else dd[[input$xvar]]
        ts_v   <- removed_ts[[v]] %||% character()

        # Base layer (scatter or line), excluding flagged
        dd_base <- if (length(ts_v)) dd[!(dd$ts_str %in% ts_v), , drop = FALSE] else dd

        if (NROW(dd_base)) {
          if (geom == "line") {
            p <- p %>% plotly::add_lines(
              data = dd_base, x_for(dd_base), y = dd_base[[v]],
              name = v, inherit = FALSE, opacity = a,
              line  = list(width = input$line_lwd %||% 2, color = unname(cols[[v]]))

            )
            if (isTRUE(input$line_show_points)) {
              p <- p %>% plotly::add_markers(
                data = dd_base, x_for(dd_base), y = dd_base[[v]],
                key = paste(dd_base$ts_str, v, sep = "||"),
                inherit = FALSE, showlegend = FALSE, hoverinfo = "skip",
                marker = list(size = 6, color = unname(cols[[v]]), opacity = 0.001)
              )
            }
          } else {
            p <- p %>% plotly::add_markers(
              data = dd_base, x_for(dd_base), y = dd_base[[v]],
              key = paste(dd_base$ts_str, v, sep = "||"),
              name = v, inherit = FALSE,
              marker = list(
                symbol = if (isTRUE(input$overlay_hollow)) "circle-open" else "circle",
                size   = s, opacity = a, color = cols[[v]],
                line   = list(width = if (isTRUE(input$overlay_hollow)) 1.5 else 0)
              )
            )
          }
        }

        # Flag rings
        if (length(ts_v)) {
          dd_flag <- dd[dd$ts_str %in% ts_v, , drop = FALSE]
          x_flag  <- if (identical(input$xvar, "TIMESTAMP_START")) dd_flag$ts_view else dd_flag[[input$xvar]]
          p <- p %>% plotly::add_markers(
            data = dd_flag, x = x_flag, y = dd_flag[[v]],
            key = paste(dd_flag$ts_str, v, sep = "||"),
            name = paste0(v, " (flagged)"),
            legendgroup = v, showlegend = FALSE, inherit = FALSE, hoverinfo = "x+y+name",
            marker = list(
              symbol = "circle-open", size = fs,
              color = hex_to_rgba(fcols[[v]], RING_ALPHA),
              line  = list(width = RING_LINE_WIDTH)
            )
          )
        }

        # Optional smoother
        if (isTRUE(input$show_smooth)) {
          p <- add_smoother_layer(
            p, dd,
            xcol = if (identical(input$xvar, "TIMESTAMP_START")) "TIMESTAMP_START" else input$xvar,
            ycol = v,
            col_hex     = cols[[v]],
            name_prefix = v,
            lwd         = input$smooth_lwd %||% 3,
            line_alpha  = input$smooth_alpha %||% 0.6,
            show_ci     = isTRUE(input$smooth_show_ci)
          )
        }
      }

      p <- p %>% plotly::layout(
        legend = list(itemclick = "toggleothers", itemdoubleclick = "toggle"),
        autosize = TRUE, dragmode = "select", font = list(size = 18),
        margin = list(l = 80, r = 20, b = 80, t = 20),
        xaxis = list(
          type = if (identical(input$xvar, "TIMESTAMP_START")) "date" else "-",
          tickformat = if (identical(input$xvar, "TIMESTAMP_START")) "%b %d, %Y %H:%M" else NULL,
          title = x_title_with_phase(),        # << string, not a list
          title_standoff = 10,                 # << put standoff here
          tickfont = list(size = 12)
        ),
        yaxis = list(title = "Overlayed variables")
      )

      if (isTRUE(input$dark_mode)) {
        p <- p %>% plotly::layout(template = "plotly_dark",
                                  paper_bgcolor = "#2E2E2E", plot_bgcolor = "#2E2E2E",
                                  font = list(color = "white"))
      }

      # force WebGL for performance when many points
      p <- plotly::toWebGL(p)

      return(p)
    }

    # ─────────────────────── Single-variable mode ───────────────────────
    v <- input$yvar
    dd <- dplyr::filter(df0, !is.na(.data[[v]]), !is.na(.data[[input$xvar]]))

    if (identical(input$xvar, "TIMESTAMP_START")) dd$ts_view <- dd$TIMESTAMP_START + data_off_hr()*3600
    x_base <- if (identical(input$xvar, "TIMESTAMP_START")) dd$ts_view else dd[[input$xvar]]

    base_col <- y_base_color()
    fcol <- switch(input$flag_color_scheme %||% "match_dark",
                   yellow      = "#FFC20A",
                   match_dark  = darken_hex(base_col, .50),
                   match_light = tint_hex(base_col,  .60),
                   darken_hex(base_col, .50))

    s  <- input$overlay_size  %||% 6
    fs <- input$flag_size     %||% (s + 2)
    ts_v <- removed_ts[[v]] %||% character()

    p <- plotly::plot_ly(source = "qc_plot") %>% plotly::event_register("plotly_selected")

    # Base (exclude flagged)
    dd_base <- if (length(ts_v)) dd[!(dd$ts_str %in% ts_v), , drop = FALSE] else dd
    if (NROW(dd_base)) {
      if (geom == "line") {
        p <- p %>% plotly::add_lines(
          data = dd_base, x_for(dd_base), y = dd_base[[v]],
          name = v, inherit = FALSE, opacity = a,
          #line  = list(width = input$line_lwd %||% 2, color = unname(cols[[v]]))
          line  = list(width = input$line_lwd %||% 2, color = base_col)

          #line = list(width = input$line_lwd %||% 2, color = base_col)
        )
        if (isTRUE(input$line_show_points)) {
          p <- p %>% plotly::add_markers(
            data = dd_base, x_for(dd_base), y = dd_base[[v]],
            key = dd_base$ts_str,
            inherit = FALSE, showlegend = FALSE, hoverinfo = "skip",
            marker = list(size = 6, color = base_col, opacity = 0.001),
            type = "scattergl"
            #marker = list(size = 6, color = unname(cols[[v]]), opacity = 0.001)
          )
        }
      } else {
        p <- p %>% plotly::add_markers(
          data = dd_base, x_for(dd_base), y = dd_base[[v]],
          key = dd_base$ts_str,
          name = v, inherit = FALSE,
          marker = list(
            symbol = if (isTRUE(input$overlay_hollow)) "circle-open" else "circle",
            size   = s, opacity = a, color = base_col,
            line   = list(width = if (isTRUE(input$overlay_hollow)) 1.5 else 0)
          )
        )
      }
    }

    # Flag rings
    if (length(ts_v)) {
      dd_flag <- dd[dd$ts_str %in% ts_v, , drop = FALSE]
      p <- p %>% plotly::add_markers(
        data = dd_flag,
        x = if (identical(input$xvar, "TIMESTAMP_START")) dd_flag$ts_view else dd_flag[[input$xvar]],
        y = dd_flag[[v]],
        type = "scattergl",
        key = dd_flag$ts_str,
        name = paste0(v, " (flagged)"),
        inherit = FALSE, showlegend = FALSE, hoverinfo = "x+y+name",
        marker = list(symbol = "circle-open", size = fs,
                      color  = hex_to_rgba(fcol, RING_ALPHA),
                      line   = list(width = RING_LINE_WIDTH))
      )
    }

    # Optional smoother (single var)
    if (isTRUE(input$show_smooth)) {
      p <- add_smoother_layer(
        p, dd,
        xcol = if (identical(input$xvar, "TIMESTAMP_START")) "TIMESTAMP_START" else input$xvar,
        ycol = v,
        col_hex     = base_col,
        name_prefix = v,
        lwd         = input$smooth_lwd %||% 3,
        line_alpha  = input$smooth_alpha %||% 0.6,
        show_ci     = isTRUE(input$smooth_show_ci)
      )
    }

    p <- p %>% plotly::layout(
      autosize = TRUE, dragmode = "select", font = list(size = 18),
      margin = list(l = 80, r = 20, b = 80, t = 20),
      xaxis = list(
        type = if (identical(input$xvar, "TIMESTAMP_START")) "date" else "-",
        tickformat = if (identical(input$xvar, "TIMESTAMP_START")) "%b %d, %Y %H:%M" else NULL,
        title = x_title_with_phase(),        # << string, not a list
        title_standoff = 10,                 # << put standoff here
        tickfont = list(size = 12)
      ),
      yaxis = list(title = input$yvar)
    )

    if (isTRUE(input$dark_mode)) {
      p <- p %>% plotly::layout(template = "plotly_dark",
                                paper_bgcolor = "#2E2E2E", plot_bgcolor = "#2E2E2E",
                                font = list(color = "white"))
    }

    p
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

  #UTC helper----
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
    pool <- pool[is.finite(as.numeric(pool))]
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
  # DOWNLOAD HANDLER for “Download cleaned CSV”----
  # ────────────────────────────────────────────────────────────────────────────
  output$download_data <- downloadHandler(
    filename = function() paste0("fluxtools_", Sys.Date(), ".zip"),
    content = function(zipfile) {
      tmpdir <- tempfile("fluxtools_"); dir.create(tmpdir)

      # 0) ORIGINAL input (what the scripts will read)
      orig_path <- file.path(tmpdir, "raw_df.csv")
      readr::write_csv(raw_df(), orig_path, na = "NA", num_threads = 1)
      #write.csv(raw_df(), orig_path, row.names = FALSE, na = "NA")

      # 1) CLEANED CSV reflecting in-app removals
      csv_name <- paste0("fluxtools_processed_df_", Sys.Date(), ".csv")
      csv_path <- file.path(tmpdir, csv_name)

      out <- rv$df
      out$TIMESTAMP_START <- out$raw_ts          # keep original strings
      out <- dplyr::select(out, -raw_ts, -ts_str, -.row)
      readr::write_csv(out, csv_path, na = "NA", num_threads = 1)
      #write.csv(out, csv_path, row.names = FALSE, na = "NA")

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

      # 2) Main manual-removal script
      script_name <- "fluxtools_removal_script.R"
      script_path <- file.path(tmpdir, script_name)

      cfs <- reactiveValuesToList(confirmed_ts)
      cfs <- cfs[vapply(cfs, length, FUN.VALUE = integer(1)) > 0]

      extra_files <- c(orig_path, csv_path, script_path)

      # 3) Include PRM summary if present
      if (isTRUE(rv$prm_active) && !is.null(rv$prm_summary)) {
        prm_csv <- file.path(tmpdir, "prm_summary.csv")
        readr::write_csv(rv$prm_summary, prm_csv, na = "NA", num_threads = 1)
        #write.csv(rv$prm_summary, prm_csv, row.names = FALSE, na = "NA")
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

      #lines <- c(lines, "write.csv(df, 'fluxtools_processed.csv', row.names = FALSE, na = 'NA')")
      lines <- c(
        lines,
        "if (requireNamespace('readr', quietly = TRUE)) {",
        "  readr::write_csv(df, 'fluxtools_processed.csv', na = 'NA', num_threads = 1)",
        "} else {",
        "  utils::write.csv(df, 'fluxtools_processed.csv', row.names = FALSE, na = 'NA')",
        "}"
      )

      writeLines(lines, script_path)

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
      sprintf(
        "Applied removals: %d timestamp%s across %d variable%s.",
        total_tses, (if (total_tses == 1) "" else "s"),
        length(vars_all), (if (length(vars_all) == 1) "" else "s")
      ),
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

# Main panel (define this before assembling the UI)
main_content <- mainPanel(
  width = 8,
  plotlyOutput("qc_plot", width = "100%", height = "80vh")
)


#assemble the UI----
ui <- fluidPage(
  style = "height:100vh; overflow:hidden;",
  theme = light_theme,

  head_assets,
  title_bar,
  subtitle_bar,

  sidebarLayout(
    sidebar_controls,
    main_content
  )                    # closes sidebarLayout
)                      # closes fluidPage





#run app----
shinyApp(ui, server)
