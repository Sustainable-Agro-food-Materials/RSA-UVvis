# RSA-UVvis
RSA-UVvis is a desktop and web-based application for the analysis of antioxidant activity using UV–Vis spectroscopy data, specifically designed for DPPH and ABTS assays.

The software enables automated processing of spectral data, peak detection, baseline correction, and calculation of Radical Scavenging Activity (RSA), providing both visualization and exportable results.
# Features
- Batch processing of CSV spectral files
- Automatic detection and analysis of DPPH and ABTS assays
- Baseline correction and peak identification
- RSA (%) calculation with statistical analysis (mean and SD)
- Interactive plots and diagnostic visualizations
- Export of results to Excel (.xlsx)
- Standalone desktop version (Electron-based)

# Methodology
The application follows this workflow:

1. Import UV–Vis spectral data (CSV format)
2. Automatic detection of spectral regions depending on assay type
3. Baseline estimation using selected reference points
4. Peak height calculation (corrected absorbance)
5. RSA (%) computation relative to control samples
6. Statistical analysis (mean, standard deviation)
7. Visualization and export of results

# Installation
## Option 1: Open from source (recommended for researchers)
**Requirements**
- R (≥ 4.0)
- Node.js (if using Electron mode)

**Install R dependencies:**

install.packages(c(
  "shiny", "bslib", "ggplot2", "dplyr",
  "readr", "tidyr", "stringr", "openxlsx"
))

**Run the app:**

shiny::runApp("app")

## Option 2: Standalone desktop application
A precompiled Windows executable (.exe) is available in the Releases section of the repository on GitHub.

This version includes a portable R environment and does not require any prior installation.

# Input data
The application expects CSV files containing UV–Vis spectra:

- Column 1: Wavelength (nm)
- Column 2: Absorbance

It also supports multi-spectra files with multiple columns.

File naming should include time information in hours (e.g., sample_T20.csv), which will be automatically detected.

# Output
The software generates:

- Processed spectral data
- RSA (%) values
- Summary statistics (mean, SD)
- Diagnostic plots
- Excel reports with multiple sheets:
  - Raw RSA values
  - Summary results
  - Peak heights

 # Assays supported 
- **DPPH assay** (λ ≈ 517 nm)
- **ABTS assay** (λ ≈ 730 nm)

The software automatically adapts analysis parameters depending on the assay selected.

# Autors
- Diego Rodríguez-Rodríguez
- Francisco Javier Solano-Moreno
- María del Rocío Muñoz-Pérez
- Susana Guzmán-Puyol
- José Alejandro Heredia-Guerrero

# Affialiation
Sustainable Agro-Food Materials Research Group
IHSM La Mayora (CSIC–UMA)

# License
This project is licensed under the MIT License.

# Citation
If you use this software in your research, please cite:

Rodriguez-Rodriguez D, Solano-Moreno FJ, Muñoz-Perez MR, Guzman-Puyol S, Heredia-Guerrero JA. (2026).
**RSA-UVvis: A desktop software for antioxidant capacity analysis**. Version 1.0.0.

DOI: to be assigned

# Notes
- The repository contains the source code only
- The standalone executable (including R portable) is distributed via GitHub Releases
- Large dependencies (R portable, node_modules) are intentionally excluded
