# fluxtools v0.3.0

Interactive Shiny application for QA/QC for eddy covariance data processing.  
Designed to streamline the post‐processing of eddy covariance datasets (e.g., after EddyPro, physical boundary filtering) to detect and remove outliers, and generate reproducible R code for QA/QC public repository submission (i.e., AmeriFlux).

*Fluxtools is an independent project and is not affiliated with or endorsed by the AmeriFlux Network. “AmeriFlux” is a registered trademark of Lawrence Berkeley National Laboratory and is used here for identification purposes only.*

If you use fluxtools in your workflow, please cite the use of this product. 

If you use fluxtools in your workflow, please cite:
Key, K. (2025). fluxtools (version 0.3.0) [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.15597159

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
  - [Code Generation & Copy-All](#code-generation--copy-all)  
- [Download & Reset](#download--reset)  
- [Vignette & Docs](#vignette--docs)  
- [Citation](#citation)  
- [License](#license)  

---

## Key Features

- **Interactive Scatter Plot**  
  Choose any numeric variable for X (often `TIMESTAMP_START`) and Y; drag a box or lasso to flag points

- **Multi-Year Support**  
  Upload up to 500 MB of flux‐tower CSV (all years by default, or pick a subset by year)

- **Dark/Light Mode**  
  Toggle UI theme on the fly (switch is in the bottom-right of the side panel)

- **±σ Outlier Highlighting**  
  Use the slider to mark points beyond N standard deviations from a linear fit; click **Select ±σ outliers** to add them

- **Accumulate & Undo**  
  - **Select data** current selection to an accumulated list across variables
  - **Clear Selection** individual points or clear outliers and selections

- **Confirm Removal**  
  Hit **Apply removals** to convert flagged Y-values to `NA` in your data frame and immediately refresh the plot.

- **Export Cleaned Data**  
  Download a .csv with removed points set to `NA` plus an R-script of all your removal code in one go.

---

## Installation

```r
# Install from CRAN 
install.packages("fluxtools")

# Install from directly from GitHub
library(devtools) 
devtools::install_github("kesondrakey/fluxtools")


#Load fluxtools and launch the QA/QC application:
library(fluxtools)

# Add the UTC offset for your flux tower site (e.g., UTC-5 for EST)
run_flux_qaqc(-5)
