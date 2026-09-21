# ============================================================
# ingest_weather_chirps.R
# CHIRPS rainfall (satellite + station blend), via ClimateSERV API
# No API key required. Requires the `chirps` R package.
# ============================================================
#
# install.packages("chirps")  # if not already installed

library(chirps)
library(sf)
library(dplyr)
library(purrr)

#' Pull monthly CHIRPS rainfall for each coffee growing region centroid
#'
#' @param regions data.frame with columns region, lat, lon (see GROWING_REGIONS
#'   in R/utils/config.R)
#' @param start_date, end_date character "YYYY-MM-DD"
#' CHIRPS has a publication lag — the most recent ~45-75 days are typically
#' not yet available. Default end_date lags 75 days behind today to avoid
#' a "Subscript out of bounds" / date-range error from get_chirps(). Pass
#' end_date explicitly to override (e.g. a known-good date from a prior
#' error message) if 75 days proves too conservative or not conservative
#' enough on a given day.
CHIRPS_LAG_DAYS <- 75

fetch_chirps_for_regions <- function(regions = GROWING_REGIONS,
                                      start_date = "2000-01-01",
                                      end_date = as.character(Sys.Date() - CHIRPS_LAG_DAYS),
                                      save_raw = TRUE) {

  pts <- sf::st_as_sf(regions, coords = c("lon", "lat"), crs = 4326)

  # get_chirps() expects an sf/SpatVector of points/polygons + a date range.
  # For a long history + many points, ClimateSERV can be slow — consider
  # chunking by year if this times out.
  precip <- chirps::get_chirps(
    pts,
    dates  = c(start_date, end_date),
    server = "ClimateSERV"
  )

  # get_chirps() returns columns id/lon/lat/date/chirps, where `id` is the
  # row index (1-based) of the input `regions`/`pts` data frame — NOT the
  # row order of the output itself. Join on that id rather than assuming a
  # fixed repeating row order (which breaks silently if the API sorts by
  # date first). Build the lookup from `regions` directly so this is robust
  # regardless of how the output happens to be ordered.
  region_lookup <- regions %>%
    dplyr::mutate(id = as.character(dplyr::row_number())) %>%
    dplyr::select(id, region)

  precip <- precip %>%
    dplyr::mutate(id = as.character(id)) %>%
    dplyr::left_join(region_lookup, by = "id")

  if (any(is.na(precip$region))) {
    warning(
      "Some CHIRPS rows failed to match a region via `id` — inspect ",
      "`precip` and confirm the chirps package version still returns an ",
      "`id` column matching input row order before trusting this join."
    )
  }

  if (save_raw) {
    out_path <- file.path(RAW_DIR, "weather", "chirps_rainfall_regions.csv")
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(precip, out_path)
    message("Saved CHIRPS rainfall to: ", out_path)
  }

  precip
}

#' Compute rainfall anomaly (% of climatological mean, and z-score) by region
compute_rainfall_anomaly <- function(chirps_df, baseline_years = 2000:2020) {
  chirps_df %>%
    dplyr::mutate(
      year  = as.integer(format(date, "%Y")),
      month = as.integer(format(date, "%m"))
    ) %>%
    dplyr::group_by(region, month) %>%
    dplyr::mutate(
      clim_mean = mean(chirps[year %in% baseline_years], na.rm = TRUE),
      clim_sd   = sd(chirps[year %in% baseline_years], na.rm = TRUE),
      pct_of_normal = 100 * chirps / clim_mean,
      z_score       = (chirps - clim_mean) / clim_sd
    ) %>%
    dplyr::ungroup()
}

# Usage:
#   source("R/utils/config.R")
#   source("R/ingest/ingest_weather_chirps.R")
#   chirps_raw <- fetch_chirps_for_regions(start_date = "2010-01-01")
#   chirps_anom <- compute_rainfall_anomaly(chirps_raw)
