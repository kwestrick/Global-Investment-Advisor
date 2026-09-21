# ============================================================
# run_ingest_all.R — top-level orchestration script
# Run this after setting up API keys in .Renviron (see R/utils/config.R)
# ============================================================

source(here::here("R", "utils", "config.R"))
source(here::here("R", "ingest", "ingest_weather_enso.R"))
source(here::here("R", "ingest", "ingest_weather_chirps.R"))
source(here::here("R", "ingest", "ingest_fx.R"))
source(here::here("R", "ingest", "ingest_production_usda.R"))
source(here::here("R", "ingest", "ingest_price_ico.R"))
source(here::here("R", "ingest", "ingest_fertilizer.R"))
source(here::here("R", "ingest", "ingest_shipping.R"))

message("=== 1/7: ONI (ENSO) ===")
oni <- tryCatch(fetch_oni(), error = function(e) { message("FAILED: ", e$message); NULL })

message("=== 2/7: CHIRPS rainfall ===")
chirps_raw <- tryCatch(
  # fetch_chirps_for_regions() now defaults end_date to Sys.Date() -
  # CHIRPS_LAG_DAYS on its own (see ingest_weather_chirps.R), so we don't
  # need to pass end_date here — just set the start date for this run.
  fetch_chirps_for_regions(start_date = "2010-01-01"),
  error = function(e) { message("FAILED: ", e$message); NULL }
)

message("=== 3/7: FX rates ===")
fx <- tryCatch(fetch_fx_series(), error = function(e) { message("FAILED (check FRED_API_KEY): ", e$message); NULL })

message("=== 4/7: USDA PSD production ===")
psd <- tryCatch(fetch_usda_psd_coffee(), error = function(e) { message("FAILED: ", e$message); NULL })

message("=== 5/7: Coffee Prices (Daily Futures + Monthly Spot) ===")
ice_futures <- tryCatch(fetch_ice_futures(), error = function(e) { message("FAILED (check tidyquant): ", e$message); NULL })
coffee_spot <- tryCatch(fetch_worldbank_coffee_spot(), error = function(e) { message("FAILED: ", e$message); NULL })
ico_prices <- if (file.exists(file.path(RAW_DIR, "price", "ico_indicator_prices.csv"))) {
  tryCatch(load_ico_prices_from_local(), error = function(e) { message(e$message); NULL })
} else {
  NULL
}

message("=== 6/7: Fertilizer prices (World Bank Pink Sheet) ===")
fert <- tryCatch(fetch_worldbank_fertilizer_prices(), error = function(e) { message("FAILED: ", e$message); NULL })

message("=== 7/7: Chokepoint event log ===")
chokepoints <- tryCatch(init_chokepoint_log(), error = function(e) { message("FAILED: ", e$message); NULL })

message("\n=== Ingest run complete. Check data/raw/ subfolders for output. ===")
message("Sources that FAILED above need either an API key (.Renviron) or a ",
        "manually placed file — see docs/data_sources.md.")
