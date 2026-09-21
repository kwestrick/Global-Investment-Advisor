# ============================================================
# ingest_fx.R
# FX rates via FRED (fredr package) — free API key required
# ============================================================
#
# install.packages("fredr")
# Register at https://fred.stlouisfed.org/docs/api/api_key.html
# Then: Sys.setenv(FRED_API_KEY = "your_key_here")  or add to .Renviron

library(fredr)
library(dplyr)
library(purrr)

fetch_fx_series <- function(fx_series = FX_SERIES,
                             start_date = as.Date("2000-01-01"),
                             save_raw = TRUE) {

  fredr::fredr_set_key(get_key("FRED_API_KEY"))

  fx_list <- purrr::imap(fx_series, function(series_id, ccy_name) {
    fredr::fredr(
      series_id = series_id,
      observation_start = start_date
    ) %>%
      dplyr::mutate(currency = ccy_name) %>%
      dplyr::select(date, currency, value)
  })

  fx_df <- dplyr::bind_rows(fx_list)

  if (save_raw) {
    out_path <- file.path(RAW_DIR, "fx", "fx_rates.csv")
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(fx_df, out_path)
    message("Saved FX series to: ", out_path)
  }

  fx_df
}

# NOTE: verify FRED series IDs before first run — series codes occasionally
# get renamed/discontinued. FX_SERIES (config.R) currently has NO VND entry —
# FRED has no direct USD/VND series (DEXVZUS is Venezuelan Bolivares, wrong
# currency). Until a suitable source is wired in, pull VND from the State
# Bank of Vietnam or a manual CSV and add it to FX_SERIES once resolved.

# Usage:
#   source("R/utils/config.R")
#   source("R/ingest/ingest_fx.R")
#   fx <- fetch_fx_series()
