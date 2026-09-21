# economic_indicators.R
# Load, normalize, and combine global economic indicators from multiple sources.
#
# All public functions return a tibble in the standard long format:
#   date | geography | indicator_code | indicator_name | category | value | unit | source | frequency
#
# Usage:
#   source("R/00_setup.R")
#   source("R/economic_indicators.R")
#   fred_data  <- fetch_fred_indicators()
#   wdi_data   <- fetch_wdi_indicators()
#   fx_data    <- fetch_yahoo_fx()
#   indicators <- bind_indicators(fred_data, wdi_data, fx_data)

# ---- Standard schema ----------------------------------------------------------

# All indicator loaders must return a tibble with exactly these columns:
INDICATOR_SCHEMA <- c(
  "date",           # Date
  "geography",      # ISO 2-letter country/region code (e.g. "US", "CO", "WORLD")
  "indicator_code", # Unique short identifier (e.g. "UNRATE", "NY.GDP.MKTP.KD.ZG")
  "indicator_name", # Human-readable name
  "category",       # One of: growth_output, inflation, monetary_financial, labor,
                    #   commodities_energy, international_trade, fiscal,
                    #   demographics, climate_environment, geopolitical_political, colombia_specific
  "value",          # Numeric observation
  "unit",           # Units as a string (e.g. "Percent", "USD per barrel")
  "source",         # Short source identifier (e.g. "FRED", "WDI", "Yahoo Finance")
  "frequency"       # "daily", "weekly", "monthly", "quarterly", "annual"
)

#' Validate that a tibble conforms to the standard indicator schema.
#' Stops with an informative message if required columns are missing.
validate_indicator_schema <- function(data, caller = "Unknown function") {
  missing <- setdiff(INDICATOR_SCHEMA, names(data))
  if (length(missing) > 0) {
    stop(
      caller, " returned a tibble missing required columns: ",
      paste(missing, collapse = ", "), ".\n",
      "All indicator loaders must return columns: ",
      paste(INDICATOR_SCHEMA, collapse = ", ")
    )
  }
  invisible(data)
}

#' Combine multiple indicator tibbles, validate schema, and de-duplicate.
#' @param ... One or more tibbles conforming to INDICATOR_SCHEMA.
#' @return A single combined tibble sorted by geography, indicator_code, date.
bind_indicators <- function(...) {
  dfs <- list(...)
  # Drop NULLs (from failed fetches that return NULL)
  dfs <- Filter(Negate(is.null), dfs)

  if (length(dfs) == 0) {
    stop("bind_indicators: all inputs are NULL. No data to combine.")
  }

  purrr::walk(seq_along(dfs), function(i) {
    validate_indicator_schema(dfs[[i]], caller = paste0("Input ", i, " to bind_indicators"))
  })

  dplyr::bind_rows(dfs) |>
    dplyr::distinct(date, geography, indicator_code, .keep_all = TRUE) |>
    dplyr::arrange(geography, indicator_code, date)
}

# ---- FRED indicators ----------------------------------------------------------

# Curated FRED series for systematic global investment analysis.
# Format: named character vector (name = human-readable label, value = FRED series ID)
FRED_SERIES <- c(
  # U.S. Growth & Output
  "US Real GDP Growth (QoQ, SAAR)"    = "A191RL1Q225SBEA",
  "US Industrial Production Index"    = "INDPRO",
  "US ISM Manufacturing PMI"          = "MANEMP",     # Proxy; actual PMI not in FRED

  # U.S. Inflation
  "US CPI All Items (YoY)"            = "CPIAUCSL",
  "US Core CPI ex Food & Energy"      = "CPILFESL",
  "US PCE Price Index"                = "PCEPI",
  "US Core PCE (Fed preferred)"       = "PCEPILFE",
  "US 5-Year Breakeven Inflation"     = "T5YIE",
  "US 10-Year Breakeven Inflation"    = "T10YIE",
  "US PPI Final Demand"               = "PPIACO",

  # U.S. Labor
  "US Unemployment Rate"              = "UNRATE",
  "US Nonfarm Payrolls (Monthly Chg)" = "PAYEMS",
  "US Prime-Age Labor Participation"  = "LNS11300060",
  "US Initial Jobless Claims"         = "ICSA",

  # U.S. Monetary & Financial Conditions
  "US Federal Funds Rate (Target)"    = "FEDFUNDS",
  "US 2-Year Treasury Yield"          = "DGS2",
  "US 10-Year Treasury Yield"         = "DGS10",
  "US 30-Year Treasury Yield"         = "DGS30",
  "US Yield Curve (10Y minus 2Y)"     = "T10Y2Y",
  "US Yield Curve (10Y minus 3M)"     = "T10Y3M",
  "US High Yield OAS Spread"          = "BAMLH0A0HYM2",
  "US Investment Grade OAS Spread"    = "BAMLC0A0CM",
  "US TED Spread"                     = "TEDRATE",
  "US 30-Year Mortgage Rate"          = "MORTGAGE30US",
  "USD Broad Trade-Weighted Index"    = "DTWEXBGS",

  # U.S. Housing & Credit
  "US Existing Home Sales"            = "EXHOSLUSM495S",
  "US Credit Card Delinquency Rate"   = "DRCCLACBS",

  # Global Commodities
  "WTI Crude Oil Price (USD/bbl)"     = "DCOILWTICO",
  "Brent Crude Oil Price (USD/bbl)"   = "DCOILBRENTEU",
  "Gold Price (USD/troy oz)"          = "GOLDAMGBD228NLBM",
  "Copper Price (USD/lb)"             = "PCOPPUSDM",
  "Henry Hub Natural Gas Price"       = "DHHNGSP",
  "Global Commodity Price Index"      = "PALLFNFINDEXQ"
)

# Map FRED series IDs to metadata (category, unit, frequency)
FRED_META <- tibble::tribble(
  ~series_id,           ~category,              ~unit,                    ~frequency,
  "A191RL1Q225SBEA",   "growth_output",         "Percent SAAR",           "quarterly",
  "INDPRO",            "growth_output",         "Index (2017=100)",        "monthly",
  "MANEMP",            "labor",                 "Thousands of Persons",    "monthly",
  "CPIAUCSL",          "inflation",             "Index (1982-84=100)",     "monthly",
  "CPILFESL",          "inflation",             "Index (1982-84=100)",     "monthly",
  "PCEPI",             "inflation",             "Index (2017=100)",        "monthly",
  "PCEPILFE",          "inflation",             "Index (2012=100)",        "monthly",
  "T5YIE",             "inflation",             "Percent",                 "daily",
  "T10YIE",            "inflation",             "Percent",                 "daily",
  "PPIACO",            "inflation",             "Index (1982=100)",        "monthly",
  "UNRATE",            "labor",                 "Percent",                 "monthly",
  "PAYEMS",            "labor",                 "Thousands of Persons",    "monthly",
  "LNS11300060",       "labor",                 "Percent",                 "monthly",
  "ICSA",              "labor",                 "Number",                  "weekly",
  "FEDFUNDS",          "monetary_financial",    "Percent",                 "monthly",
  "DGS2",              "monetary_financial",    "Percent",                 "daily",
  "DGS10",             "monetary_financial",    "Percent",                 "daily",
  "DGS30",             "monetary_financial",    "Percent",                 "daily",
  "T10Y2Y",            "monetary_financial",    "Percent",                 "daily",
  "T10Y3M",            "monetary_financial",    "Percent",                 "daily",
  "BAMLH0A0HYM2",      "monetary_financial",    "Percent",                 "daily",
  "BAMLC0A0CM",        "monetary_financial",    "Percent",                 "daily",
  "TEDRATE",           "monetary_financial",    "Percent",                 "daily",
  "MORTGAGE30US",      "monetary_financial",    "Percent",                 "weekly",
  "DTWEXBGS",          "monetary_financial",    "Index (Jan 2006=100)",    "daily",
  "EXHOSLUSM495S",     "growth_output",         "Thousands of Units SAAR", "monthly",
  "DRCCLACBS",         "monetary_financial",    "Percent",                 "quarterly",
  "DCOILWTICO",        "commodities_energy",    "USD per Barrel",          "daily",
  "DCOILBRENTEU",      "commodities_energy",    "USD per Barrel",          "daily",
  "GOLDAMGBD228NLBM",  "commodities_energy",    "USD per Troy Oz",         "daily",
  "PCOPPUSDM",         "commodities_energy",    "USD per Pound",           "monthly",
  "DHHNGSP",           "commodities_energy",    "USD per MMBtu",           "daily",
  "PALLFNFINDEXQ",     "commodities_energy",    "Index (2016=100)",        "quarterly"
)

#' Fetch the curated FRED indicator series.
#'
#' Requires the FRED API key to be set: fredr::fredr_set_key(Sys.getenv("FRED_API_KEY"))
#'
#' @param series_ids Named character vector of FRED series IDs. Defaults to FRED_SERIES.
#' @param start_date Date or character. Defaults to analysis_defaults$start_date if available.
#' @param end_date Date or character. Defaults to today.
#' @param geography Character. Geography code to attach to all FRED series. Defaults to "US"
#'   (most series are U.S.-specific; commodity series are global but priced in USD).
#' @return Tibble in standard indicator long format.
fetch_fred_indicators <- function(series_ids = FRED_SERIES,
                                  start_date = NULL,
                                  end_date = Sys.Date(),
                                  geography = "US") {
  if (!requireNamespace("fredr", quietly = TRUE)) {
    stop("Package 'fredr' is required. Install with install.packages('fredr').")
  }

  # Check for API key
  key <- fredr::fredr_get_key()
  if (is.null(key) || nchar(key) == 0) {
    stop(
      "No FRED API key found. Set one with:\n",
      "  fredr::fredr_set_key(Sys.getenv('FRED_API_KEY'))\n",
      "Get a free key at: https://fred.stlouisfed.org/docs/api/api_key.html"
    )
  }

  if (is.null(start_date)) {
    start_date <- if (exists("analysis_defaults")) {
      as.Date(analysis_defaults$start_date)
    } else {
      as.Date("2015-01-01")
    }
  }
  start_date <- as.Date(start_date)
  end_date   <- as.Date(end_date)

  # Fetch each series; skip failures with a warning
  results <- purrr::map(
    names(series_ids),
    function(name) {
      series_id <- series_ids[[name]]
      tryCatch(
        {
          fredr::fredr(
            series_id          = series_id,
            observation_start  = start_date,
            observation_end    = end_date
          ) |>
            dplyr::select(date, value) |>
            dplyr::mutate(
              indicator_name = name,
              indicator_code = series_id
            )
        },
        error = function(e) {
          warning("FRED series '", series_id, "' (", name, ") failed: ", conditionMessage(e))
          NULL
        }
      )
    }
  )

  raw <- dplyr::bind_rows(Filter(Negate(is.null), results))

  if (nrow(raw) == 0) {
    warning("fetch_fred_indicators: no series downloaded successfully.")
    return(NULL)
  }

  # Attach metadata
  raw |>
    dplyr::left_join(FRED_META, by = c("indicator_code" = "series_id")) |>
    dplyr::mutate(
      geography = dplyr::case_when(
        indicator_code %in% c(
          "DCOILWTICO", "DCOILBRENTEU", "GOLDAMGBD228NLBM",
          "PCOPPUSDM", "DHHNGSP", "PALLFNFINDEXQ"
        ) ~ "WORLD",
        TRUE ~ geography
      ),
      source    = "FRED",
      category  = dplyr::coalesce(category, "monetary_financial"),
      unit      = dplyr::coalesce(unit, ""),
      frequency = dplyr::coalesce(frequency, "monthly")
    ) |>
    dplyr::select(dplyr::all_of(INDICATOR_SCHEMA)) |>
    dplyr::filter(!is.na(value))
}

# ---- World Bank WDI indicators ------------------------------------------------

# Curated WDI indicator codes for global investment analysis.
WDI_INDICATORS <- c(
  # Growth
  "NY.GDP.MKTP.KD.ZG",   # GDP growth (annual %)
  "NY.GDP.PCAP.KD",       # GDP per capita (constant 2015 USD)
  "NE.EXP.GNFS.ZS",      # Exports of goods and services (% of GDP)
  "NE.IMP.GNFS.ZS",      # Imports of goods and services (% of GDP)

  # Inflation
  "FP.CPI.TOTL.ZG",      # CPI inflation (annual %)

  # Labor
  "SL.UEM.TOTL.ZS",      # Unemployment rate (% of total labor force, modeled ILO)
  "SL.TLF.CACT.ZS",      # Labor force participation rate (% of population 15+)

  # International & External Balances
  "BN.CAB.XOKA.GD.ZS",   # Current account balance (% of GDP)
  "FI.RES.TOTL.MO",      # Total reserves in months of imports
  "FI.RES.TOTL.CD",      # Total reserves (includes gold, current USD)

  # Fiscal
  "GC.DOD.TOTL.GD.ZS",   # Central government debt (% of GDP)
  "GC.BAL.CASH.GD.ZS",   # Cash surplus/deficit (% of GDP)

  # Financial Development
  "FS.AST.PRVT.GD.ZS",   # Domestic credit to private sector (% of GDP)

  # Demographics
  "SP.POP.TOTL",          # Total population
  "SP.POP.GROW",          # Population growth (annual %)
  "SP.DYN.IMRT.IN"        # Infant mortality rate
)

# Map WDI codes to human-readable names, category, unit
WDI_META <- tibble::tribble(
  ~indicator_code,          ~indicator_name,                                      ~category,               ~unit,
  "NY.GDP.MKTP.KD.ZG",     "GDP Growth (Annual %)",                              "growth_output",         "Percent",
  "NY.GDP.PCAP.KD",         "GDP Per Capita (Constant 2015 USD)",                 "growth_output",         "USD",
  "NE.EXP.GNFS.ZS",        "Exports of Goods and Services (% of GDP)",           "international_trade",   "Percent of GDP",
  "NE.IMP.GNFS.ZS",        "Imports of Goods and Services (% of GDP)",           "international_trade",   "Percent of GDP",
  "FP.CPI.TOTL.ZG",        "CPI Inflation (Annual %)",                           "inflation",             "Percent",
  "SL.UEM.TOTL.ZS",        "Unemployment Rate (ILO Modeled, % Labor Force)",     "labor",                 "Percent",
  "SL.TLF.CACT.ZS",        "Labor Force Participation Rate (% Population 15+)", "labor",                 "Percent",
  "BN.CAB.XOKA.GD.ZS",     "Current Account Balance (% of GDP)",                 "international_trade",   "Percent of GDP",
  "FI.RES.TOTL.MO",        "Foreign Reserves (Months of Imports)",               "monetary_financial",    "Months",
  "FI.RES.TOTL.CD",        "Foreign Reserves Including Gold (Current USD)",      "monetary_financial",    "Current USD",
  "GC.DOD.TOTL.GD.ZS",     "Central Government Debt (% of GDP)",                 "fiscal",                "Percent of GDP",
  "GC.BAL.CASH.GD.ZS",     "Government Cash Surplus/Deficit (% of GDP)",         "fiscal",                "Percent of GDP",
  "FS.AST.PRVT.GD.ZS",     "Domestic Credit to Private Sector (% of GDP)",      "monetary_financial",    "Percent of GDP",
  "SP.POP.TOTL",            "Total Population",                                   "demographics",          "Persons",
  "SP.POP.GROW",            "Population Growth Rate (Annual %)",                  "demographics",          "Percent",
  "SP.DYN.IMRT.IN",        "Infant Mortality Rate (per 1,000 live births)",      "demographics",          "Per 1,000 live births"
)

# Key geographies to pull (ISO 2-letter codes that WDI understands)
WDI_COUNTRIES <- c(
  "US", "CO", "BR", "IN", "CN", "DE", "JP", "GB", "FR",
  "KR", "MX", "ID", "ZA", "SA", "AU", "CA", "CL", "PE",
  "AR", "VN", "PH", "TH", "PL", "TR", "NG", "EG", "KE"
)

#' Fetch curated World Bank WDI indicators for key geographies.
#'
#' No API key required. Data is annual with approximately a 1-year lag.
#'
#' @param countries Character vector of ISO 2-letter country codes. Defaults to WDI_COUNTRIES.
#' @param indicators Character vector of WDI indicator codes. Defaults to WDI_INDICATORS.
#' @param start_year Integer. Defaults to 2000.
#' @param end_year Integer. Defaults to current year.
#' @return Tibble in standard indicator long format.
fetch_wdi_indicators <- function(countries = WDI_COUNTRIES,
                                 indicators = WDI_INDICATORS,
                                 start_year = 2000,
                                 end_year = as.integer(format(Sys.Date(), "%Y"))) {
  if (!requireNamespace("WDI", quietly = TRUE)) {
    stop("Package 'WDI' is required. Install with install.packages('WDI').")
  }

  message("Fetching WDI data for ", length(countries), " countries and ",
          length(indicators), " indicators...")

  raw <- tryCatch(
    WDI::WDI(
      country   = countries,
      indicator = indicators,
      start     = start_year,
      end       = end_year,
      extra     = FALSE
    ),
    error = function(e) {
      warning("WDI fetch failed: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(raw) || nrow(raw) == 0) {
    warning("fetch_wdi_indicators: no data returned from World Bank API.")
    return(NULL)
  }

  # WDI returns wide format; pivot to long
  raw |>
    janitor::clean_names() |>
    dplyr::rename(geography = iso2c) |>
    tidyr::pivot_longer(
      cols      = dplyr::all_of(tolower(gsub("\\.", "_", indicators))),
      names_to  = "indicator_code_clean",
      values_to = "value"
    ) |>
    dplyr::mutate(
      # Restore original WDI code format (WDI package lowercases and replaces . with _)
      indicator_code = indicators[match(indicator_code_clean,
                                        tolower(gsub("\\.", "_", indicators)))],
      date      = as.Date(paste0(year, "-01-01")),
      frequency = "annual"
    ) |>
    dplyr::left_join(WDI_META, by = "indicator_code") |>
    dplyr::mutate(
      source    = "World Bank WDI",
      indicator_name = dplyr::coalesce(indicator_name, indicator_code),
      category  = dplyr::coalesce(category, "growth_output"),
      unit      = dplyr::coalesce(unit, "")
    ) |>
    dplyr::filter(!is.na(value), !is.na(geography), geography != "") |>
    dplyr::select(dplyr::all_of(INDICATOR_SCHEMA))
}

# ---- Yahoo Finance FX rates ---------------------------------------------------

# Key FX pairs to track (Yahoo Finance ticker format)
YAHOO_FX_TICKERS <- c(
  "COP=X",   # Colombian Peso / USD
  "BRL=X",   # Brazilian Real / USD
  "INR=X",   # Indian Rupee / USD
  "MXN=X",   # Mexican Peso / USD
  "IDR=X",   # Indonesian Rupiah / USD
  "ZAR=X",   # South African Rand / USD
  "TRY=X",   # Turkish Lira / USD
  "PHP=X",   # Philippine Peso / USD
  "VND=X",   # Vietnamese Dong / USD
  "JPY=X",   # Japanese Yen / USD
  "KRW=X",   # South Korean Won / USD
  "CNY=X",   # Chinese Yuan / USD
  "EUR=X",   # Euro / USD
  "GBP=X",   # British Pound / USD
  "AUD=X",   # Australian Dollar / USD
  "CAD=X",   # Canadian Dollar / USD
  "CLP=X",   # Chilean Peso / USD
  "PEN=X",   # Peruvian Sol / USD
  "ARS=X"    # Argentine Peso / USD
)

# Map tickers to geography codes and readable names
YAHOO_FX_META <- tibble::tribble(
  ~ticker,   ~geography,  ~indicator_name,
  "COP=X",   "CO",        "COP/USD Exchange Rate (USD per 1 COP — inverse: lower = stronger COP)",
  "BRL=X",   "BR",        "BRL/USD Exchange Rate",
  "INR=X",   "IN",        "INR/USD Exchange Rate",
  "MXN=X",   "MX",        "MXN/USD Exchange Rate",
  "IDR=X",   "ID",        "IDR/USD Exchange Rate",
  "ZAR=X",   "ZA",        "ZAR/USD Exchange Rate",
  "TRY=X",   "TR",        "TRY/USD Exchange Rate",
  "PHP=X",   "PH",        "PHP/USD Exchange Rate",
  "VND=X",   "VN",        "VND/USD Exchange Rate",
  "JPY=X",   "JP",        "JPY/USD Exchange Rate",
  "KRW=X",   "KR",        "KRW/USD Exchange Rate",
  "CNY=X",   "CN",        "CNY/USD Exchange Rate",
  "EUR=X",   "DE",        "EUR/USD Exchange Rate",
  "GBP=X",   "GB",        "GBP/USD Exchange Rate",
  "AUD=X",   "AU",        "AUD/USD Exchange Rate",
  "CAD=X",   "CA",        "CAD/USD Exchange Rate",
  "CLP=X",   "CL",        "CLP/USD Exchange Rate",
  "PEN=X",   "PE",        "PEN/USD Exchange Rate",
  "ARS=X",   "AR",        "ARS/USD Exchange Rate"
)

#' Fetch daily FX exchange rates (local currency per USD) via Yahoo Finance.
#'
#' Rates are expressed as units of local currency per 1 USD.
#' A rising value means the local currency is weakening against the USD.
#'
#' @param tickers Character vector of Yahoo Finance FX tickers. Defaults to YAHOO_FX_TICKERS.
#' @param start_date Date or character. Defaults to analysis_defaults$start_date if available.
#' @param end_date Date or character. Defaults to today.
#' @return Tibble in standard indicator long format.
fetch_yahoo_fx <- function(tickers = YAHOO_FX_TICKERS,
                           start_date = NULL,
                           end_date = Sys.Date()) {
  if (!requireNamespace("tidyquant", quietly = TRUE)) {
    stop("Package 'tidyquant' is required. Install with install.packages('tidyquant').")
  }

  if (is.null(start_date)) {
    start_date <- if (exists("analysis_defaults")) {
      as.Date(analysis_defaults$start_date)
    } else {
      as.Date("2015-01-01")
    }
  }
  start_date <- as.Date(start_date)
  end_date   <- as.Date(end_date)

  message("Fetching FX rates for ", length(tickers), " currency pairs from Yahoo Finance...")

  raw <- tryCatch(
    tidyquant::tq_get(
      tickers,
      from = start_date,
      to   = end_date,
      get  = "stock.prices"
    ),
    error = function(e) {
      warning("Yahoo Finance FX fetch failed: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(raw) || nrow(raw) == 0) {
    warning("fetch_yahoo_fx: no FX data returned from Yahoo Finance.")
    return(NULL)
  }

  raw |>
    janitor::clean_names() |>
    dplyr::select(ticker = symbol, date, value = adjusted) |>
    dplyr::left_join(YAHOO_FX_META, by = "ticker") |>
    dplyr::mutate(
      indicator_code = ticker,
      category       = "monetary_financial",
      unit           = "Local Currency per 1 USD",
      source         = "Yahoo Finance",
      frequency      = "daily"
    ) |>
    dplyr::filter(!is.na(value), !is.na(geography)) |>
    dplyr::select(dplyr::all_of(INDICATOR_SCHEMA))
}

# ---- Stub loaders for Phase 3 Parts 2+ ----------------------------------------
# These functions are defined but not yet implemented.
# Each returns NULL with a message explaining what will be built.

#' [STUB] Fetch Colombia-specific macro data from Banco de la República.
#' Implementation planned for Phase 3 Part 2 (R/colombia_indicators.R).
fetch_colombia_rates <- function(...) {
  message("[STUB] fetch_colombia_rates: to be implemented in R/colombia_indicators.R (Phase 3 Part 2)")
  message("  Will fetch: policy rate, CPI, reserve levels via Banco de la República REST API")
  NULL
}

#' [STUB] Fetch V-Dem democracy and political freedom indices.
#' Implementation planned for Phase 3 Part 1 (R/climate_geopolitical.R).
fetch_vdem_indicators <- function(...) {
  message("[STUB] fetch_vdem_indicators: to be implemented in R/climate_geopolitical.R")
  message("  Will use: vdemdata R package (install from GitHub: xmarquez/vdemdata)")
  message("  Indicators: v2x_libdem, v2x_polyarchy, v2x_corr, v2x_rule")
  NULL
}

#' [STUB] Fetch World Bank climate vulnerability indicators.
#' Implementation planned for Phase 3 Part 1 (R/climate_geopolitical.R).
fetch_wb_climate <- function(...) {
  message("[STUB] fetch_wb_climate: to be implemented in R/climate_geopolitical.R")
  message("  Will use: World Bank Climate Change Knowledge Portal API (free)")
  message("  Indicators: temperature anomaly, precipitation, heat days")
  NULL
}

#' [STUB] Fetch OECD Composite Leading Indicators.
#' Implementation planned for Phase 3 Part 1.
fetch_oecd_indicators <- function(...) {
  message("[STUB] fetch_oecd_indicators: to be implemented using OECD R package")
  message("  Dataset: MEI_CLI — monthly composite leading indicators for OECD countries")
  NULL
}

#' [STUB] Fetch Fragile States Index from Fund for Peace.
#' Implementation planned for Phase 3 Part 1 (R/climate_geopolitical.R).
fetch_fragile_states <- function(...) {
  message("[STUB] fetch_fragile_states: CSV downloaded annually from fragilestatesindex.org")
  message("  File saved to: data/external/fragile_states_index_[YEAR].csv")
  NULL
}

# ---- Data source registry -----------------------------------------------------

#' Load the data source registry from data/external/data_source_registry.csv.
#' @return Tibble with one row per data source and metadata columns.
load_source_registry <- function() {
  registry_path <- file.path("data", "external", "data_source_registry.csv")
  if (!file.exists(registry_path)) {
    stop("Source registry not found: ", registry_path,
         "\nExpected at: data/external/data_source_registry.csv")
  }
  readr::read_csv(registry_path, show_col_types = FALSE)
}

#' Dispatcher: load data for a given source_id from the registry.
#'
#' Routes to the correct fetch function based on the loader_function column.
#' @param source_id Character. Must match a source_id in data_source_registry.csv.
#' @param ... Additional arguments passed to the loader function.
#' @return Tibble in standard indicator long format, or NULL if source is a stub.
load_indicator_source <- function(source_id, ...) {
  registry <- load_source_registry()

  row <- registry[registry$source_id == source_id, ]
  if (nrow(row) == 0) {
    stop("source_id '", source_id, "' not found in data_source_registry.csv.")
  }

  loader <- row$loader_function
  if (!is.character(loader) || is.na(loader)) {
    stop("No loader_function defined for source_id '", source_id, "'.")
  }

  fn <- tryCatch(
    get(loader, envir = globalenv()),
    error = function(e) NULL
  )

  if (is.null(fn)) {
    fn <- tryCatch(
      match.fun(loader),
      error = function(e) {
        stop("Loader function '", loader, "' not found.",
             " Source '", source_id, "' from data_source_registry.csv.")
      }
    )
  }

  fn(...)
}

# ---- Summary helpers ----------------------------------------------------------

#' Summarize available indicators: count, date range, and geography coverage.
#' @param indicators Tibble in standard long format returned by bind_indicators().
#' @return Summary tibble.
summarize_indicators <- function(indicators) {
  indicators |>
    dplyr::group_by(source, category, indicator_code, indicator_name, geography) |>
    dplyr::summarise(
      n_obs    = dplyr::n(),
      date_min = min(date),
      date_max = max(date),
      pct_na   = mean(is.na(value)),
      .groups  = "drop"
    ) |>
    dplyr::arrange(source, category, indicator_code, geography)
}

#' Print a compact coverage report for a combined indicators tibble.
#' @param indicators Tibble in standard long format.
report_indicator_coverage <- function(indicators) {
  cat("=== Global Indicators Coverage Report ===\n\n")

  cat("Total observations:", format(nrow(indicators), big.mark = ","), "\n")
  cat("Unique indicators: ", dplyr::n_distinct(indicators$indicator_code), "\n")
  cat("Unique geographies:", dplyr::n_distinct(indicators$geography), "\n")
  cat("Date range:        ", format(min(indicators$date)), "to",
      format(max(indicators$date)), "\n\n")

  cat("By source:\n")
  indicators |>
    dplyr::count(source, name = "n_obs") |>
    dplyr::arrange(dplyr::desc(n_obs)) |>
    dplyr::mutate(label = paste0("  ", source, ": ", format(n_obs, big.mark = ","))) |>
    dplyr::pull(label) |>
    cat(sep = "\n")

  cat("\n\nBy category:\n")
  indicators |>
    dplyr::count(category, name = "n_obs") |>
    dplyr::arrange(dplyr::desc(n_obs)) |>
    dplyr::mutate(label = paste0("  ", category, ": ", format(n_obs, big.mark = ","))) |>
    dplyr::pull(label) |>
    cat(sep = "\n")

  invisible(indicators)
}
