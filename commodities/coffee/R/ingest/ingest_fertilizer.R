# ============================================================
# ingest_fertilizer.R
# World Bank Commodity Markets Outlook ("Pink Sheet") — fertilizer prices
# No API key required (direct Excel download)
# ============================================================

library(readxl)
library(dplyr)

fetch_worldbank_fertilizer_prices <- function(
  url = "https://thedocs.worldbank.org/en/doc/18675f1d1639c7a34d463f59263ba0a2-0050012025/related/CMO-Historical-Data-Monthly.xlsx",
  save_raw = TRUE
) {
  # NOTE: World Bank periodically changes this filename/path when they
  # refresh the Pink Sheet. If the download fails, get the current link from
  # https://www.worldbank.org/en/research/commodity-markets ("Monthly Data").

  tmp <- tempfile(fileext = ".xlsx")
  utils::download.file(url, destfile = tmp, quiet = TRUE, mode = "wb")

  # The Pink Sheet workbook has a "Monthly Prices" sheet with commodities as
  # columns and months as rows, several header rows deep. Inspect once
  # downloaded and adjust skip/range as needed.
  raw <- readxl::read_excel(tmp, sheet = "Monthly Prices", skip = 4)

  fert <- raw %>%
    filter(!is.na(...1), !grepl("\\$", ...1)) %>%
    rename(
      date_str = 1,
      urea = `Urea`,
      dap = `DAP`,
      potassium = `Potassium chloride **`
    ) %>%
    mutate(
      date = as.Date(paste0(gsub("M.*", "", date_str), "-", gsub(".*M", "", date_str), "-01"), format = "%Y-%m-%d"),
      across(c(urea, dap, potassium), ~as.numeric(gsub("[\\$,]", "", .)))
    ) %>%
    select(date, urea, dap, potassium)

  if (save_raw) {
    out_path <- file.path(RAW_DIR, "fertilizer", "worldbank_fertilizer_prices.csv")
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(fert, out_path)
    message("Saved fertilizer price series to: ", out_path)
  }

  unlink(tmp)
  fert
}

# Usage:
#   source("R/utils/config.R")
#   source("R/ingest/ingest_fertilizer.R")
#   fert <- fetch_worldbank_fertilizer_prices()
