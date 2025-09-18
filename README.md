# fluxtools v0.7.0

Interactive **Shiny** application for exploration and QA/QC of eddy covariance data.  
Streamlines post-processing of eddy covariance datasets (e.g., after EddyPro) to detect and remove outliers, enforce physical ranges, and generate reproducible R code for AmeriFlux submissions.

*Fluxtools is an independent project and is not affiliated with or endorsed by the AmeriFlux Network. “AmeriFlux” is a registered trademark of Lawrence Berkeley National Laboratory and is used here for identification purposes only.*

If you use **fluxtools** in your workflow, please cite:

> Key, K. (2025). *fluxtools* (version 0.7.0) [Computer software]. Zenodo.  
> https://doi.org/10.5281/zenodo.15597159

---

## Table of Contents

- [Key Features](#key-features)  
- [Installation](#installation)  
- [Quickstart](#quickstart)  
- [Data Requirements](#data-requirements)  
- [How It Works](#how-it-works)  
  - [Timestamp Parsing & Time Zones](#timestamp-parsing--time-zones)  
  - [Interactive QC & Selection](#interactive-qc--selection)  
  - [Outlier Detection](#outlier-detection)  
  - [Time Slider (Inside / Outside)](#time-slider-inside--outside)  
  - [Manual Range Filters](#manual-range-filters)  
  - [Physical Range Module (PRM)](#physical-range-module-prm)  
  - [Code Generation & Copy-All](#code-generation--copy-all)  
- [Download & Reset](#download--reset)  
- [Vignette & Docs](#vignette--docs)  
- [Citation](#citation)  
- [License](#license)  

---

## Key Features
#key-features

- **Interactive scatter**  
  Choose TIMESTAMP_START (time) or any numeric variable for X; choose any numeric variable for Y. Drag a box or lasso to flag points

- **Multi-year support**  
  Upload up to ~1GB CSV (all years by default, or select one/more years)
  
  - **Time subset support**  
  Subset data view based on year(s), month(s), day(s), or time of day
  
  - **Compare two datasets (A/B)**  
  Upload Dataset B, choose labels/colors, and compare variables side by side (with optional smoothers and bottom legend)

- **Overlay multiple variables**  
  Plot several Y variables together with color palettes or custom overrides

- **Add smoothed line(s)**  
  LOESS smoother with optional 95% CI; toggle “Only smoothed line(s)” to hide base traces


- **±σ outlier highlighting**  
  Slider marks points beyond *n* standard deviations from a linear fit; click **Select ±σ outliers** to add them

- **Accumulate & undo**  
  Add selections to an accumulated list and remove them later if needed
  Use Apply removals to commit NA changes, and Reload original data to revert

- **Physical Range Module (PRM)**  
  Clamp variables to physically reasonable ranges (AmeriFlux Technical Note, Table A1)
  Out-of-range → NA. QC columns are ignored by PRM by default 
  Undo PRM reverts only PRM-applied changes

- **Reproducible outputs**  
  Export a cleaned CSV (removed values set to NA) and an R script with the exact transformations
  *If PRM was applied, a summary table, audit CSV, and a manual replay script are included*
  
- **Dark/Light mode**  
  Toggle theme on the fly

---

## Installation
#installation

```r
# From CRAN
install.packages("fluxtools")

# Newest version from GitHub
library(devtools)
devtools::install_github("kesondrakey/fluxtools")
```

## Quickstart
#quickstart

```r
library(fluxtools)

# Launch the QA/QC Shiny app
run_fluxtools()
```

## Data Requirements
#data-requirements
- Input: AmeriFlux BASE (or FLUXNET-style) CSV
- Must include TIMESTAMP_START (e.g., YYYYMMDDHHMM for 30-min or hourly data)
- Typical missing values such as `-9999`, `-9999.0`, `-9999.00`, `-9999.000`, `NaN`, and empty strings are treated as `NA`


## How It Works
#how-it-works
**Timestamp Parsing & Time Zones** 
#timestamp-parsing--time-zones
- TIMESTAMP_START is parsed automatically
- Viewer can display times with a fixed UTC±offset (no DST)
- Selections, code, and exports are keyed to the original timestamp string. Underlying values and exported timestamps are preserved

**Interactive QC & Selection** 
#interactive-qc--selection
- Box/lasso select points in the plot
- Click **Flag Data** to stage selections; **Unflag Data** or **Clear Selection** to remove
- Click **Apply removals** to set Y-values to `NA_real_`
- Use **Reload original data** to revert to the initial upload

**Outlier Detection** 
#outlier-detection
- Fit a simple linear model between X and Y, compute residuals, and highlight points exceeding ±σ (user-controlled)
- Select all ±σ outliers to add them to your accumulated code; clear ±σ outliers if needed

**Time Slider (Inside / Outside)** 
#time-slider-inside--outside
- Adjustable time window on TIMESTAMP_START
- Flag inside: add only points within the chosen time range
- Flag outside: add all points except those within the chosen range
- The slider snaps to your data cadence (30 min / 60 min) and supports multi-year files

**Manual Range Filters**
#manual-range-filters
- Define custom min/max for any variable
- Flag values outside range to add out-of-bounds points to the accumulated set
- Complements PRM by allowing site- or project-specific thresholds

**Compare two datasets**
- Enable **Compare two datasets** and upload **Dataset B**
- Choose labels and colors per dataset
- Plot the same variables from A and B; legend appears at the bottom (horizontal)
- Works with Scatter or Line; optional transparent points on top of lines enable lasso
- **Smoother** can be added per (variable, dataset); “Only smoothed line(s)” hides base points/lines and shows just the LOESS curves (with optional 95% CI)

**Plot multiple variables**
- Enable **Plot multiple variables** to select several Y variables from the same dataset
- Color palette is applied automatically; you can override per-variable colors if desired
- Flags (rings) can match variable color (darker/lighter) or use classic yellow

**Add smoothed line**
- Toggle **Add smoothed line**
- Method: LOESS with configurable span; optional 95% CI band
- **Only smoothed line(s)** hides base markers/lines and keeps the legend so variables/datasets remain selectable
- Legend is positioned at the bottom (horizontal)

**Physical Range Module (PRM)**
#physical-range-module-prm
- **Available in the app or through fluxtools directly in R**
- Applies physical bounds to variables (e.g., SWC, P, TA, CO2) using name-family matching (e.g., ^SWC($|_).)
-   Example: the "SWC" *family* refers to all variables starting with SWC (e.g., SWC_1_1_1, SWC_2_1_3)
- Out-of-range values → `NA`; QC columns are ignored by default
- Apply to all families detected in your data, or select a subset in the UI
- **Undo PRM** reverts only PRM-applied changes (later user edits are preserved)
- In exports, PRM produces:
  - `prm_summary.csv` (bounds and counts)
  - `prm_removed_values.csv` (cell-level audit)
  - `manual_prm_removed.R` (replay script)
  
Example:
```r
# View PRM rule table
get_prm_rules()

# Apply to all present families
res <- apply_prm(df)
res$data     # clamped data
res$summary  # per-column stats (min, max, n_replaced, pct_replaced)

# Apply to selected families
res2 <- apply_prm(df, include = c("SWC", "P"))
```
*PRM ranges (and name) were sourced from Ameriflux*

**Code Generation & Copy-All** 
#code-generation--copy-all
- The app continuously builds tidy dplyr code that sets selected Y-values to NA via case_when()
- Switch between Current and Accumulated snippets; click Copy code to paste into your own scripts and version control

## Download & Reset
- Export cleaned data: downloads a ZIP containing
-   *raw_df.csv* (original upload, unchanged)
-   *fluxtools_processed_df_<date>.csv* (cleaned, NA applied)
-   *fluxtools_removal_script.R* (replays removals)

- If PRM was applied:
-   *prm_summary.csv* (bounds + replacements)
-   *prm_removed_values.csv* (audit of values removed)
-   *manual_prm_removed.R* (cell-level replay)

- Reload original data: restores the initial CSV to start over

## Vignette & Docs
```r
browseVignettes("fluxtools")
# or
vignette("introduction", package = "fluxtools")
```


## Citation
If you use fluxtools in publications, please cite:
> Key, K. (2025). fluxtools (version 0.7.0) [Computer software]. Zenodo.
> https://doi.org/10.5281/zenodo.15597159


## License
This package is free software, released under the GNU General Public License v3 (GPL-3).
*See the LICENSE file for details.*

*Fluxtools is an independent project and is not affiliated with or endorsed by the AmeriFlux Network. “AmeriFlux” is a registered trademark of Lawrence Berkeley National Laboratory and is used here for identification purposes only.*
