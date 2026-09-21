# 00_setup.R
# Project-wide setup for Global Investment Advisor

# ---- Package management ----

required_packages <- c(
  "tidyverse",
  "tidyquant",
  "quantmod",
  "PerformanceAnalytics",
  "xts",
  "zoo",
  "slider",
  "lubridate",
  "janitor",
  "arrow",
  "readxl",
  "httr2",
  "jsonlite",
  "countrycode",
  "WDI",
  "fredr",
  "ggplot2",
  "patchwork",
  "scales",
  "gt",
  "DT",
  "quarto"
)

install_missing_packages <- function(packages = required_packages) {
  missing_packages <- packages[!packages %in% rownames(installed.packages())]

  if (length(missing_packages) > 0) {
    install.packages(missing_packages)
  }

  invisible(missing_packages)
}

load_required_packages <- function(packages = required_packages) {
  invisible(
    purrr::walk(
      packages,
      ~ suppressPackageStartupMessages(
        library(.x, character.only = TRUE)
      )
    )
  )
}

# Run these manually if needed:
# install_missing_packages()
# load_required_packages()

# ---- Project paths ----

project_paths <- list(
  data_raw = "data/raw",
  data_processed = "data/processed",
  data_external = "data/external",
  outputs_charts = "outputs/charts",
  outputs_tables = "outputs/tables",
  outputs_exports = "outputs/exports",
  reports_investment_memos = "reports/investment_memos",
  reports_country_screens = "reports/country_screens",
  reports_sector_screens = "reports/sector_screens",
  reports_dashboards = "reports/dashboards"
)

create_project_dirs <- function(paths = project_paths) {
  purrr::walk(paths, ~ dir.create(.x, recursive = TRUE, showWarnings = FALSE))
  invisible(paths)
}

# ---- Analysis defaults ----

analysis_defaults <- list(
  base_currency = "USD",
  equity_benchmark = "SPY",
  growth_benchmark = "QQQ",
  small_cap_benchmark = "IWM",
  developed_ex_us_benchmark = "VEA",
  emerging_market_benchmark = "VWO",
  bond_benchmark = "IEF",
  cash_proxy = "BIL",
  start_date = "2015-01-01"
)

theme_gia <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "gray35"),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}

# ---- Utility helpers ----

today_stamp <- function() {
  format(Sys.Date(), "%Y%m%d")
}

write_processed_csv <- function(data, name) {
  file_path <- file.path("data/processed", paste0(name, "_", today_stamp(), ".csv"))
  readr::write_csv(data, file_path)
  file_path
}

write_output_table <- function(data, name) {
  file_path <- file.path("outputs/tables", paste0(name, "_", today_stamp(), ".csv"))
  readr::write_csv(data, file_path)
  file_path
}
