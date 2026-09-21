# ============================================================
# ingest_price_ico.R
# International Coffee Organization (ICO) indicator prices
# No API key required, but no REST API either — ICO publishes CSV/PDF
# downloads that update periodically. This function downloads the current
# file; you'll want to re-run periodically and append to build history,
# or source historical prices from a paid feed (Quandl/Barchart) instead
# for a complete daily backtest panel.
# ============================================================

library(readr)
library(dplyr)
library(tidyquant)

#' Fetch daily ICE Arabica ("KC") and Robusta ("RM") futures via Yahoo Finance
fetch_ice_futures <- function(save_raw = TRUE) {
  symbols <- c("KC=F" = "Arabica", "RM=F" = "Robusta")
  
  futures <- purrr::imap_dfr(symbols, function(sym, name) {
    tq_get(sym, get = "stock.prices", from = "2010-01-01") %>%
      dplyr::transmute(
        date = date,
        contract = name,
        price = adjusted
      )
  })

  if (save_raw) {
    out_path <- file.path(RAW_DIR, "price", "ice_futures_daily.csv")
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(futures, out_path)
    message("Saved ICE futures to: ", out_path)
  }

  futures
}

#' Fetch current ICO composite + group indicator prices (Placeholder)
load_ico_prices_from_local <- function(path = file.path(RAW_DIR, "price", "ico_indicator_prices.csv")) {
  if (!file.exists(path)) {
    stop(
      "No local ICO price file found. Download the current indicator price ",
      "file from https://ico.org/resources/public-market-information/ and ",
      "save it to: ", path
    )
  }
  readr::read_csv(path, col_types = readr::cols())
}

#' Fetch monthly World Bank spot prices (from the Pink Sheet)
fetch_worldbank_coffee_spot <- function(save_raw = TRUE) {
  url <- "https://thedocs.worldbank.org/en/doc/18675f1d1639c7a34d463f59263ba0a2-0050012025/related/CMO-Historical-Data-Monthly.xlsx"
  tmp <- tempfile(fileext = ".xlsx")
  utils::download.file(url, destfile = tmp, quiet = TRUE, mode = "wb")

  raw <- readxl::read_excel(tmp, sheet = "Monthly Prices", skip = 4)

  coffee <- raw %>%
    filter(!is.na(...1), !grepl("\\$", ...1)) %>%
    rename(
      date_str = 1,
      arabica = `Coffee, Arabica`,
      robusta = `Coffee, Robusta`
    ) %>%
    mutate(
      date = as.Date(paste0(gsub("M.*", "", date_str), "-", gsub(".*M", "", date_str), "-01"), format = "%Y-%m-%d"),
      across(c(arabica, robusta), ~as.numeric(gsub("[\\$,]", "", .)))
    ) %>%
    select(date, arabica, robusta)

  if (save_raw) {
    out_path <- file.path(RAW_DIR, "price", "worldbank_coffee_spot_monthly.csv")
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(coffee, out_path)
    message("Saved World Bank coffee spot prices to: ", out_path)
  }

  unlink(tmp)
  coffee
}


# Usage:
#   source("R/utils/config.R")
#   source("R/ingest/ingest_price_ico.R")
#   ico_prices <- load_ico_prices_from_local()
