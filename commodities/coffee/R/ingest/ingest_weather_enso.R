# ============================================================
# ingest_weather_enso.R
# NOAA CPC Oceanic Nino Index (ONI) — no API key required
# ============================================================
#
# ONI is your primary macro-climate regime variable: El Nino years tend to
# bring drought risk to Brazil's coffee belt and wetter conditions to
# Vietnam/Indonesia (and vice versa in La Nina years). Use this as a
# slow-moving regime feature, then layer CHIRPS rainfall anomalies
# (ingest_weather_chirps.R) for regional/monthly granularity.

library(readr)
library(dplyr)

fetch_oni <- function(save_raw = TRUE) {
  url <- "https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt"

  raw <- readr::read_table(url, col_types = readr::cols())

  # Columns: SEAS YR TOTAL ANOM  (SEAS = 3-month season label, e.g. "DJF")
  oni <- raw %>%
    rename(season = SEAS, year = YR, sst_total = TOTAL, oni_anom = ANOM) %>%
    mutate(
      # crude midpoint month for each 3-month season label, for joining to
      # monthly panels later
      season_mid_month = case_when(
        season == "DJF" ~ 1, season == "JFM" ~ 2, season == "FMA" ~ 3,
        season == "MAM" ~ 4, season == "AMJ" ~ 5, season == "MJJ" ~ 6,
        season == "JJA" ~ 7, season == "JAS" ~ 8, season == "ASO" ~ 9,
        season == "SON" ~ 10, season == "OND" ~ 11, season == "NDJ" ~ 12,
        TRUE ~ NA_real_
      ),
      enso_phase = case_when(
        oni_anom >= 0.5  ~ "El Nino",
        oni_anom <= -0.5 ~ "La Nina",
        TRUE             ~ "Neutral"
      )
    )

  if (save_raw) {
    out_path <- file.path(RAW_DIR, "weather", "oni_monthly.csv")
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(oni, out_path)
    message("Saved ONI series to: ", out_path)
  }

  oni
}

# Usage:
#   source("R/utils/config.R")
#   source("R/ingest/ingest_weather_enso.R")
#   oni <- fetch_oni()
