# ============================================================
# ingest_production_usda.R
# USDA FAS PSD Online — coffee production/exports/stocks by country
# No API key required (direct CSV/ZIP download)
# Pattern adapted from the `tomcopple/coffeestats` R package.
# ============================================================

library(readr)
library(dplyr)

fetch_usda_psd_coffee <- function(
  url = "https://apps.fas.usda.gov/psdonline/downloads/psd_coffee_csv.zip",
  save_raw = TRUE
) {

  tmp <- tempfile(fileext = ".zip")
  utils::download.file(url, destfile = tmp, quiet = TRUE, mode = "wb")

  csv_name <- utils::unzip(tmp, list = TRUE)$Name[1]
  raw <- readr::read_csv(unz(tmp, csv_name), col_types = readr::cols())

  psd <- raw %>%
    dplyr::select(
      country  = Country_Name,
      year     = Market_Year,
      series   = Attribute_Description,
      value    = Value
    ) %>%
    dplyr::filter(
      country %in% c("Brazil", "Vietnam", "Colombia", "Indonesia",
                     "Ethiopia", "Honduras", "India", "Uganda")
    ) %>%
    dplyr::mutate(
      series = dplyr::case_when(
        series == "Bean Exports"        ~ "Green Exports",
        series == "Bean Imports"        ~ "Green Imports",
        series == "Beginning Stocks"    ~ "Opening Stocks",
        series == "Domestic Consumption" ~ "Consumption",
        TRUE ~ series
      )
    )

  if (save_raw) {
    out_path <- file.path(RAW_DIR, "production", "usda_psd_coffee.csv")
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(psd, out_path)
    message("Saved USDA PSD coffee data to: ", out_path)
  }

  unlink(tmp)
  psd
}

# Usage:
#   source("R/utils/config.R")
#   source("R/ingest/ingest_production_usda.R")
#   psd <- fetch_usda_psd_coffee()
#   # Focus columns for modeling: Production, Exports, Ending Stocks,
#   # by country and market year — these are annual, so they act as a
#   # slow-moving fundamental backdrop rather than a monthly predictor.
