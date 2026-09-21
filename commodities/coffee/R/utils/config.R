# ============================================================
# config.R — paths, growing-region reference points, API key loading
# ============================================================

# --- Project paths -------------------------------------------------------
PROJ_ROOT     <- rprojroot::find_root(rprojroot::has_file("coffee_platform.Rproj"))
RAW_DIR       <- file.path(PROJ_ROOT, "data", "raw")
PROCESSED_DIR <- file.path(PROJ_ROOT, "data", "processed")
STATIC_DIR    <- file.path(PROJ_ROOT, "data", "static")
MODELS_DIR    <- file.path(PROJ_ROOT, "models")

# --- API keys --------------------------------------------------------------
# Store real keys in a .Renviron file (never commit it). Add lines like:
#   FRED_API_KEY=xxxxxxxxxxxxxxxx
#   NOAA_NCEI_TOKEN=xxxxxxxxxxxxxxxx
#   CDS_API_KEY=xxxxxxxxxxxxxxxx
# Then restart R. usethis::edit_r_environ() opens the file for you.
get_key <- function(name) {
  val <- Sys.getenv(name)
  if (identical(val, "")) {
    warning(sprintf(
      "%s is not set. Add it to .Renviron (see R/utils/config.R header).",
      name
    ))
    return(NA_character_)
  }
  val
}

# --- Growing region reference points --------------------------------------
# Representative coordinates used for weather/climate pulls (station lookup,
# CHIRPS grid extraction, ERA5 point extraction). Expand as needed — these
# are centroids of the dominant producing sub-regions, not exhaustive.
GROWING_REGIONS <- data.frame(
  region     = c(
    "Minas Gerais (BR, Arabica)",
    "Sao Paulo / Mogiana (BR, Arabica)",
    "Espirito Santo (BR, Robusta/Conilon)",
    "Huila (CO, Arabica)",
    "Narino (CO, Arabica)",
    "Central Highlands - Dak Lak (VN, Robusta)",
    "Central Highlands - Lam Dong (VN, Arabica/Robusta)"
  ),
  country    = c("Brazil", "Brazil", "Brazil", "Colombia", "Colombia",
                 "Vietnam", "Vietnam"),
  varietal   = c("Arabica", "Arabica", "Robusta", "Arabica", "Arabica",
                 "Robusta", "Mixed"),
  lat        = c(-18.9, -21.0, -19.6, 2.5, 1.2, 12.7, 11.6),
  lon        = c(-45.0, -47.5, -40.9, -76.0, -77.3, 108.2, 108.1),
  share_note = c(
    "Largest Arabica region in Brazil",
    "Traditional high-altitude Arabica belt",
    "Brazil's main Robusta/Conilon area",
    "Largest Arabica department in Colombia",
    "High-altitude specialty Arabica",
    "~30% of global Robusta production",
    "Mixed Arabica/Robusta, high elevation"
  ),
  stringsAsFactors = FALSE
)

# --- FX pairs relevant to coffee export economics ---------------------------
FX_SERIES <- c(
  BRL = "DEXBZUS",         # FRED H.10: Brazilian Real per USD (daily)
  COP = "COLCCUSMA02STM"   # FRED/OECD: Colombian Peso per USD (monthly avg)
  # VND: FRED has no Vietnamese Dong series. DEXVZUS is Venezuelan Bolivares
  # (wrong currency). For VND, use the State Bank of Vietnam API or a manual
  # CSV until a suitable FRED series is identified.
)
