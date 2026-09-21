# ============================================================
# ingest_shipping.R
# Shipping / logistics / chokepoint risk
# Mixed access: some free, some paid. Structured as a manual-entry +
# scripted-download hybrid since there's no single free API covering all of
# this cleanly.
# ============================================================

library(dplyr)
library(readr)

#' Chokepoint disruption index — manually maintained event log
#'
#' Rather than trying to scrape a live feed (unreliable, inconsistent
#' formats), maintain a simple event log of known chokepoint disruptions
#' (Panama drought restrictions, Red Sea/Houthi activity, Suez closures,
#' Strait of Hormuz tension) with a severity score 0-3. Update this file
#' manually or via periodic news-based review; join it to the price panel
#' as a step/dummy feature.
#'
#' Columns: start_date, end_date (NA if ongoing), chokepoint, severity (0-3),
#' description, source_url
init_chokepoint_log <- function() {
  path <- file.path(RAW_DIR, "shipping", "chokepoint_events.csv")
  if (!file.exists(path)) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    template <- data.frame(
      start_date  = as.Date(c("2023-11-01", "2023-08-01")),
      end_date    = as.Date(c(NA, "2024-06-01")),
      chokepoint  = c("Red Sea / Bab-el-Mandeb", "Panama Canal"),
      severity    = c(2, 2),
      description = c(
        "Houthi attacks on shipping, major carriers reroute via Cape of Good Hope",
        "Drought-driven draft restrictions cut daily transit slots"
      ),
      source_url  = c(
        "https://www.reuters.com/",  # replace with specific article
        "https://pancanal.com/"       # replace with specific bulletin
      ),
      stringsAsFactors = FALSE
    )
    readr::write_csv(template, path)
    message("Initialized chokepoint event log template at: ", path,
            "\nEdit this file directly to add/update events (e.g. the 2026 ",
            "Strait of Hormuz closure) with real dates and source URLs.")
  }
  readr::read_csv(path, col_types = readr::cols())
}

#' Freight rate placeholder — Baltic Dry Index / route-specific rates
#'
#' No free structured API found for BDI or FBX at time of writing. Options,
#' in order of ease:
#'  1. Manually log the weekly headline BDI figure (widely reported in
#'     financial news) into a CSV — lowest effort, coarse signal.
#'  2. Subscribe to Baltic Exchange or Freightos (FBX) API for route-level
#'     Brazil->Asia / Brazil->US/EU rates — better signal, has a cost.
#'  3. Use bunker fuel price (available via EIA/finance tools) as a rough
#'     proxy driver of freight cost trends in the meantime.
load_freight_rates_from_local <- function(path = file.path(RAW_DIR, "shipping", "freight_rates.csv")) {
  if (!file.exists(path)) {
    stop(
      "No local freight rate file found. See comments in this script for ",
      "options. Expected columns: date, route, rate_usd, unit."
    )
  }
  readr::read_csv(path, col_types = readr::cols())
}

# Usage:
#   source("R/utils/config.R")
#   source("R/ingest/ingest_shipping.R")
#   chokepoints <- init_chokepoint_log()
