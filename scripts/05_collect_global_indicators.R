# 05_collect_global_indicators.R
# Collect, normalize, and save global economic indicators from multiple sources.
#
# Run this script from the project root to refresh all indicator data:
#   source("scripts/05_collect_global_indicators.R")
#
# Schedule:
#   - FRED series:   Run daily (data updates daily or monthly depending on series)
#   - WDI data:      Run monthly (annual data; new year released ~April)
#   - FX rates:      Run daily (prices update every trading day)
#
# Outputs:
#   data/processed/global_indicators_fred_[DATE].csv
#   data/processed/global_indicators_wdi_[DATE].csv
#   data/processed/global_indicators_fx_[DATE].csv
#   data/processed/global_indicators_combined_[DATE].csv   <- primary output
#   data/processed/global_indicators_summary_[DATE].csv
#
# Prerequisites:
#   - FRED API key set: fredr::fredr_set_key(Sys.getenv("FRED_API_KEY"))
#   - Packages: tidyverse, fredr, WDI, tidyquant, janitor
#
# Usage note: WDI data has a ~1-year lag. For current-year estimates, rely on
# FRED for U.S. data and IMF WEO forecasts (stub; to be implemented).

cat("=======================================================\n")
cat(" Global Investment Advisor — Indicator Collection\n")
cat(" Run date:", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "\n")
cat("=======================================================\n\n")

# ---- 0. Setup ----------------------------------------------------------------

source("R/00_setup.R")
source("R/economic_indicators.R")

library(tidyverse)
library(fredr)
library(WDI)
library(tidyquant)
library(janitor)

# Ensure output directories exist
create_project_dirs()

today <- Sys.Date()
stamp <- format(today, "%Y-%m-%d")

# ---- 1. FRED API key check ---------------------------------------------------

cat("[ 1/5 ] Checking FRED API key...\n")

fred_key <- Sys.getenv("FRED_API_KEY")

if (nchar(fred_key) == 0) {
  cat("  WARNING: FRED_API_KEY environment variable not set.\n")
  cat("  FRED data will be skipped.\n")
  cat("  To enable:\n")
  cat("    1. Get a free key at https://fred.stlouisfed.org/docs/api/api_key.html\n")
  cat("    2. Add to your ~/.Renviron: FRED_API_KEY=your_key_here\n")
  cat("    3. Restart R and re-run this script.\n\n")
  skip_fred <- TRUE
} else {
  fredr::fredr_set_key(fred_key)
  cat("  OK — FRED API key found.\n\n")
  skip_fred <- FALSE
}

# ---- 2. FRED indicators ------------------------------------------------------

cat("[ 2/5 ] Fetching FRED indicators...\n")

fred_data <- if (skip_fred) {
  cat("  Skipped (no API key).\n\n")
  NULL
} else {
  tryCatch(
    {
      d <- fetch_fred_indicators(
        start_date = as.Date(analysis_defaults$start_date),
        end_date   = today
      )
      cat("  Downloaded", format(nrow(d), big.mark = ","), "observations across",
          dplyr::n_distinct(d$indicator_code), "series.\n\n")
      d
    },
    error = function(e) {
      cat("  ERROR: FRED fetch failed:", conditionMessage(e), "\n\n")
      NULL
    }
  )
}

# ---- 3. World Bank WDI indicators --------------------------------------------

cat("[ 3/5 ] Fetching World Bank WDI indicators...\n")
cat("  (This may take 30-60 seconds for a full pull.)\n")

wdi_data <- tryCatch(
  {
    d <- fetch_wdi_indicators(
      countries  = WDI_COUNTRIES,
      indicators = WDI_INDICATORS,
      start_year = 2000,
      end_year   = as.integer(format(today, "%Y"))
    )
    if (!is.null(d)) {
      cat("  Downloaded", format(nrow(d), big.mark = ","), "observations across",
          dplyr::n_distinct(d$indicator_code), "indicators and",
          dplyr::n_distinct(d$geography), "countries.\n\n")
    }
    d
  },
  error = function(e) {
    cat("  ERROR: WDI fetch failed:", conditionMessage(e), "\n\n")
    NULL
  }
)

# ---- 4. FX exchange rates ----------------------------------------------------

cat("[ 4/5 ] Fetching FX exchange rates from Yahoo Finance...\n")

fx_data <- tryCatch(
  {
    d <- fetch_yahoo_fx(
      tickers    = YAHOO_FX_TICKERS,
      start_date = as.Date(analysis_defaults$start_date),
      end_date   = today
    )
    if (!is.null(d)) {
      cat("  Downloaded", format(nrow(d), big.mark = ","), "daily observations across",
          dplyr::n_distinct(d$indicator_code), "currency pairs.\n\n")
    }
    d
  },
  error = function(e) {
    cat("  ERROR: FX fetch failed:", conditionMessage(e), "\n\n")
    NULL
  }
)

# ---- 5. Stub sources (logged but not yet implemented) ------------------------

cat("[ 5/5 ] Checking stub sources...\n")

fetch_oecd_indicators()   # prints stub message
fetch_vdem_indicators()   # prints stub message
fetch_wb_climate()        # prints stub message
fetch_fragile_states()    # prints stub message
fetch_colombia_rates()    # prints stub message

cat("\n")

# ---- 6. Combine and validate -------------------------------------------------

cat("Combining all available sources...\n")

all_sources <- list(fred_data, wdi_data, fx_data)
available   <- Filter(Negate(is.null), all_sources)

if (length(available) == 0) {
  stop(
    "No indicator data was collected from any source.\n",
    "Check internet access, API key configuration, and package installations."
  )
}

indicators_combined <- bind_indicators(!!!available)

cat("Combined dataset:\n")
cat("  Total observations:", format(nrow(indicators_combined), big.mark = ","), "\n")
cat("  Unique indicators: ", dplyr::n_distinct(indicators_combined$indicator_code), "\n")
cat("  Unique geographies:", dplyr::n_distinct(indicators_combined$geography), "\n")
cat("  Date range:        ",
    format(min(indicators_combined$date)), "to",
    format(max(indicators_combined$date)), "\n\n")

# Check for unexpected NAs
na_counts <- indicators_combined |>
  dplyr::summarise(dplyr::across(dplyr::everything(), ~ sum(is.na(.)))) |>
  tidyr::pivot_longer(dplyr::everything(), names_to = "column", values_to = "n_na") |>
  dplyr::filter(n_na > 0)

if (nrow(na_counts) > 0) {
  cat("Missing values detected:\n")
  print(na_counts)
  cat("\n")
}

# ---- 7. Save outputs ---------------------------------------------------------

cat("Saving outputs...\n")

# Individual source files (useful for debugging)
if (!is.null(fred_data)) {
  path <- file.path("data/processed", paste0("global_indicators_fred_", stamp, ".csv"))
  readr::write_csv(fred_data, path)
  cat("  Saved:", path, "\n")
}

if (!is.null(wdi_data)) {
  path <- file.path("data/processed", paste0("global_indicators_wdi_", stamp, ".csv"))
  readr::write_csv(wdi_data, path)
  cat("  Saved:", path, "\n")
}

if (!is.null(fx_data)) {
  path <- file.path("data/processed", paste0("global_indicators_fx_", stamp, ".csv"))
  readr::write_csv(fx_data, path)
  cat("  Saved:", path, "\n")
}

# Combined file (primary output used by downstream scripts)
combined_path <- file.path("data/processed",
                           paste0("global_indicators_combined_", stamp, ".csv"))
readr::write_csv(indicators_combined, combined_path)
cat("  Saved:", combined_path, "\n")

# Summary file
indicator_summary <- summarize_indicators(indicators_combined)
summary_path <- file.path("data/processed",
                          paste0("global_indicators_summary_", stamp, ".csv"))
readr::write_csv(indicator_summary, summary_path)
cat("  Saved:", summary_path, "\n\n")

# ---- 8. Coverage report ------------------------------------------------------

report_indicator_coverage(indicators_combined)

# ---- 9. Colombia FX spotlight ------------------------------------------------

cop_usd <- indicators_combined |>
  dplyr::filter(indicator_code == "COP=X") |>
  dplyr::arrange(dplyr::desc(date)) |>
  dplyr::slice_head(n = 5)

if (nrow(cop_usd) > 0) {
  cat("\n\n--- COP/USD Exchange Rate (most recent 5 observations) ---\n")
  cat("(Interpretation: higher number = more COP per USD = weaker peso)\n\n")
  print(cop_usd[, c("date", "value", "source")])
}

cat("\n=======================================================\n")
cat(" Indicator collection complete.\n")
cat(" Primary output: global_indicators_combined_", stamp, ".csv\n", sep = "")
cat(" Run scripts/09_indicator_driven_portfolio_ranking.R\n")
cat(" to integrate indicators with portfolio conviction scores.\n")
cat("=======================================================\n")
