# scripts/11_cop_usd_forecast.R
# USD/COP FOREX decision-support report.
#
# Answers: "Is now a relatively good time to convert USD to COP?"
#
# Runs in ~15-20 seconds (GARCH fitting + macro data fetch).
# Output:
#   - Console: print_cop_brief() summary
#   - Chart: outputs/charts/cop_usd_forecast_bands_YYYY-MM-DD.png
#
# Usage:
#   source("scripts/11_cop_usd_forecast.R")
#
# Dependencies: rugarch, tidyquant, ggplot2, dplyr, lubridate, glue, zoo, scales
# Requires no API keys.

suppressPackageStartupMessages({
  library(tidyverse)
  library(tidyquant)
  library(lubridate)
  library(glue)
  library(zoo)
  library(scales)
})

source("R/00_setup.R")
source("R/economic_indicators.R")
source("R/colombia_indicators.R")
source("R/fx_forecasting.R")

# Check rugarch
if (!requireNamespace("rugarch", quietly = TRUE)) {
  stop(
    "Package 'rugarch' is required for GARCH volatility bands.\n",
    "Install with: install.packages('rugarch')"
  )
}

cat("Fetching COP/USD data (10 years)...\n")
raw_fx <- fetch_cop_exchange_rate(
  start_date = Sys.Date() - 10 * 365,
  end_date   = Sys.Date()
)

if (is.null(raw_fx) || nrow(raw_fx) == 0) {
  stop("COP/USD data fetch failed. Check internet connection.")
}

series <- prepare_cop_series(raw_fx)
cat(sprintf("  %d trading days loaded (%s to %s)\n",
            nrow(series),
            format(min(series$date)),
            format(max(series$date))))

# --- Full brief (percentiles + GARCH + macro + signal) -----------------------
result <- print_cop_brief(series, run_garch = TRUE, horizon_days = 90)

# --- Chart -------------------------------------------------------------------
chart_path <- glue("outputs/charts/cop_usd_forecast_bands_{Sys.Date()}.png")
dir.create("outputs/charts", recursive = TRUE, showWarnings = FALSE)

plot_cop_bands(series, result$garch_result, history_days = 365, save_path = chart_path)
cat("Chart saved to:", chart_path, "\n")
