# ============================================================
# install_packages.R — run once to set up your R environment
# ============================================================

pkgs <- c(
  # project infra
  "rprojroot", "here",
  # data wrangling
  "dplyr", "tidyr", "readr", "readxl", "lubridate", "purrr",
  # ingestion
  "chirps", "sf", "fredr","tidyquant",
  # modeling
  "glmnet", "quantreg", "forecast", "fable", "tsibble",
  # optional: modern alternative to archived rnoaa for station data
  "readnoaa",
  # shiny app
  "shiny", "bslib", "plotly", "leaflet", "DT"
)

installed <- rownames(installed.packages())
to_install <- setdiff(pkgs, installed)

if (length(to_install) > 0) {
  message("Installing: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
} else {
  message("All required packages already installed.")
}

# fable/tsibble/readnoaa may need the r-universe or GitHub source if not yet
# on CRAN mirror you're using -- if install.packages() fails for any of
# these, try:
#   install.packages("readnoaa", repos = c("https://cranhaven.r-universe.dev", "https://cloud.r-project.org"))
