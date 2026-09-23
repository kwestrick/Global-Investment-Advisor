# colombia_indicators.R
# Colombia-specific investment analysis functions.
#
# Provides data loaders, analytics, and screening tools for COP-denominated
# investment vehicles. Part of Phase 3, Part 2 of Global Investment Advisor.
#
# Usage:
#   source("R/00_setup.R")
#   source("R/economic_indicators.R")   # for INDICATOR_SCHEMA
#   source("R/colombia_indicators.R")
#
# Data sources:
#   Live (no key required):
#     - Yahoo Finance COP=X       — daily COP/USD rate
#     - Yahoo Finance ^COLCAP     — daily COLCAP equity index
#     - World Bank WDI (CO)       — annual macro (CPI, GDP growth, unemployment, etc.)
#   Live (FRED API key required):
#     - CPALTT01COM659N           — Colombia CPI (OECD monthly series in FRED)
#   Manual reference tables (update quarterly):
#     - TES yield curve           — from BVC.com.co
#     - Bank CDT / savings rates  — from BBVA and Bancolombia websites
#
# Key context:
#   User holds Colombian assets: home ~1.2B COP, bank accounts ~30M COP.
#   Goal: generate COP income to hedge USD/COP currency risk.
#   Dual citizenship in progress; wife Anna is Colombian citizen.

# ---- Reference data: Colombia investment universe ----------------------------
#
# Update this tibble quarterly with current rates from:
#   TES yields: https://www.bvc.com.co/pps/tibco/portalbvc/Home/Mercados/descripcionmercado/mercadodeuda
#   CDT rates:  https://www.bbva.com.co and https://www.bancolombia.com
#   Banrep policy rate: https://www.banrep.gov.co/es/estadisticas/tasas-politica-monetaria
#
# LAST UPDATED: 2026-09-21 (rates are approximate; verify before investing)
# Policy rate: approximately 8.25% as of late 2026 (Banrep cutting cycle)
# Colombia CPI (annual): approximately 5.5% as of mid-2026
# Source for TES yields: BVC secondary market; adjusted yields, not coupon rates

get_colombia_investment_universe <- function() {
  tibble::tribble(
    ~vehicle_id,           ~vehicle_name,                              ~vehicle_type,
    ~institution,          ~nominal_yield_pct,  ~term_days,           ~min_investment_cop,
    ~risk_level,           ~liquidity,          ~fogafin_guaranteed,  ~notes,

    "bbva_savings",        "BBVA Savings Account",                     "savings",
    "BBVA Colombia",       4.0,                  NA_real_,             0,
    "minimal",             "high",               TRUE,                  "Cuentas de ahorro; rate floats with policy rate; very liquid; Fogafin-insured up to 50M COP",

    "bcol_savings",        "Bancolombia Savings Account",              "savings",
    "Bancolombia",         3.8,                  NA_real_,             0,
    "minimal",             "high",               TRUE,                  "Similar to BBVA; rate floats; widely available ATMs across Colombia",

    "bbva_cdt_90",         "BBVA CDT 90 Days",                        "cdt",
    "BBVA Colombia",       9.5,                  90,                   500000,
    "minimal",             "low",                TRUE,                  "Certificate of Term Deposit; early withdrawal usually permitted with penalty; Fogafin-insured",

    "bbva_cdt_180",        "BBVA CDT 180 Days",                       "cdt",
    "BBVA Colombia",       10.0,                 180,                  500000,
    "minimal",             "low",                TRUE,                  "Higher rate for longer term; ask about automatic renewal option",

    "bbva_cdt_360",        "BBVA CDT 360 Days",                       "cdt",
    "BBVA Colombia",       10.5,                 360,                  500000,
    "minimal",             "low",                TRUE,                  "Best CDT rate at BBVA for 1-year term; compare with Bancolombia",

    "bcol_cdt_360",        "Bancolombia CDT 360 Days",                "cdt",
    "Bancolombia",         10.2,                 360,                  1000000,
    "minimal",             "low",                TRUE,                  "Minimum 1M COP; Bancolombia has strong digital banking for COP management",

    "tes_1y",              "TES Colombia 1-Year Government Bond",      "government_bond",
    "Ministerio de Hacienda", 10.5,              365,                  1000000,
    "low",                 "high",               FALSE,                 "Colombian peso-denominated sovereign bond; liquid secondary market on BVC; buy via Valores Bancolombia or similar broker",

    "tes_5y",              "TES Colombia 5-Year Government Bond",      "government_bond",
    "Ministerio de Hacienda", 11.2,              1825,                 1000000,
    "low",                 "high",               FALSE,                 "Duration risk; yields move inversely with rates; favored if Banrep cuts continue",

    "tes_10y",             "TES Colombia 10-Year Government Bond",     "government_bond",
    "Ministerio de Hacienda", 11.5,              3650,                 1000000,
    "low",                 "moderate",           FALSE,                 "Benchmark bond; most liquid TES tenor; subject to inflation and credit risk",

    "tes_30y",             "TES Colombia 30-Year Government Bond",     "government_bond",
    "Ministerio de Hacienda", 12.0,              10950,                1000000,
    "low",                 "low",                FALSE,                 "Long duration; higher yield but significant interest rate sensitivity; less liquid",

    "ecopetrol_bond",      "Ecopetrol Corporate Bond (COP)",          "corporate_bond",
    "Ecopetrol S.A.",      13.0,                 1825,                 5000000,
    "moderate",            "low",                FALSE,                 "State-controlled oil company; investment-grade locally; oil price risk; ask broker for current issuances",

    "bcol_bond",           "Bancolombia Senior Bond",                  "corporate_bond",
    "Bancolombia",         12.5,                 1095,                 5000000,
    "moderate",            "low",                FALSE,                 "Largest Colombian bank; Baa2/BBB- rated; buy through secondary market or new issuances",

    "colcap_etf",          "COLCAP Index Fund (via local broker)",     "equity",
    "BVC Listed Stocks",   2.5,                  NA_real_,             500000,
    "high",                "high",               FALSE,                 "Dividend yield only; 2-3% typical; total return includes capital gains; top holdings: Bancolombia, Ecopetrol, ISA, Grupo Sura",

    "ecopetrol_equity",    "Ecopetrol S.A. Common Shares (EC / BVC)", "equity",
    "Ecopetrol S.A.",      5.0,                  NA_real_,             500000,
    "high",                "high",               FALSE,                 "Highest dividend yield in COLCAP (~4-6%); trades as EC on NYSE ADR; oil price correlated; government owns 88%"
  )
}

# ---- Live data: COP/USD exchange rate ----------------------------------------

#' Fetch daily COP/USD exchange rate from Yahoo Finance.
#'
#' Rate is expressed as Colombian Pesos (COP) per 1 USD.
#' A higher number means more COP are needed per dollar — a weaker peso.
#'
#' @param start_date Date. Defaults to 5 years ago.
#' @param end_date Date. Defaults to today.
#' @return Tibble with columns: date, cop_per_usd, source.
fetch_cop_exchange_rate <- function(start_date = Sys.Date() - 5 * 365,
                                   end_date = Sys.Date()) {
  if (!requireNamespace("tidyquant", quietly = TRUE)) {
    stop("Package 'tidyquant' is required.")
  }

  raw <- tryCatch(
    tidyquant::tq_get("COP=X", from = start_date, to = end_date, get = "stock.prices"),
    error = function(e) {
      warning("COP/USD fetch failed: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(raw) || nrow(raw) == 0) {
    warning("fetch_cop_exchange_rate: no data returned.")
    return(NULL)
  }

  raw |>
    janitor::clean_names() |>
    dplyr::select(date, cop_per_usd = adjusted) |>
    dplyr::filter(!is.na(cop_per_usd)) |>
    dplyr::mutate(source = "Yahoo Finance (COP=X)")
}

# ---- Live data: COLCAP index --------------------------------------------------

#' Fetch daily COLCAP Colombia equity index from Yahoo Finance.
#'
#' COLCAP is the benchmark equity index for the Bolsa de Valores de Colombia (BVC).
#' It tracks the 20 most liquid stocks. Yahoo Finance ticker: ^COLCAP
#'
#' @param start_date Date. Defaults to 5 years ago.
#' @param end_date Date. Defaults to today.
#' @return Tibble with columns: date, colcap_close, colcap_return, source.
fetch_colcap_data <- function(start_date = Sys.Date() - 5 * 365,
                              end_date = Sys.Date()) {
  if (!requireNamespace("tidyquant", quietly = TRUE)) {
    stop("Package 'tidyquant' is required.")
  }

  raw <- tryCatch(
    tidyquant::tq_get("^COLCAP", from = start_date, to = end_date, get = "stock.prices"),
    error = function(e) {
      warning("COLCAP fetch failed: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(raw) || nrow(raw) == 0) {
    warning("fetch_colcap_data: no data returned for ^COLCAP.")
    return(NULL)
  }

  raw |>
    janitor::clean_names() |>
    dplyr::select(date, colcap_close = adjusted) |>
    dplyr::filter(!is.na(colcap_close)) |>
    dplyr::arrange(date) |>
    dplyr::mutate(
      colcap_return = colcap_close / dplyr::lag(colcap_close) - 1,
      source = "Yahoo Finance (^COLCAP)"
    )
}

# ---- Live data: Colombia macro from WDI --------------------------------------

#' Fetch Colombia annual macro indicators from World Bank WDI.
#'
#' Returns: GDP growth, CPI inflation, unemployment, current account,
#'   government debt, foreign reserves.
#'
#' @param start_year Integer. Defaults to 2010.
#' @param end_year Integer. Defaults to current year.
#' @return Tibble in standard long indicator format.
fetch_colombia_macro <- function(start_year = 2010,
                                 end_year = as.integer(format(Sys.Date(), "%Y"))) {
  if (!requireNamespace("WDI", quietly = TRUE)) {
    stop("Package 'WDI' is required.")
  }

  colombia_indicators <- c(
    "NY.GDP.MKTP.KD.ZG",   # GDP growth (annual %)
    "FP.CPI.TOTL.ZG",      # CPI inflation (annual %)
    "SL.UEM.TOTL.ZS",      # Unemployment rate (%)
    "BN.CAB.XOKA.GD.ZS",   # Current account (% GDP)
    "GC.DOD.TOTL.GD.ZS",   # Government debt (% GDP)
    "FI.RES.TOTL.MO",      # Foreign reserves (months of imports)
    "NY.GDP.PCAP.KD"        # GDP per capita (constant 2015 USD)
  )

  indicator_names <- c(
    "NY.GDP.MKTP.KD.ZG" = "GDP Growth (Annual %)",
    "FP.CPI.TOTL.ZG"    = "CPI Inflation (Annual %)",
    "SL.UEM.TOTL.ZS"    = "Unemployment Rate (%)",
    "BN.CAB.XOKA.GD.ZS" = "Current Account Balance (% of GDP)",
    "GC.DOD.TOTL.GD.ZS" = "Government Debt (% of GDP)",
    "FI.RES.TOTL.MO"    = "Foreign Reserves (Months of Imports)",
    "NY.GDP.PCAP.KD"    = "GDP Per Capita (Constant 2015 USD)"
  )

  raw <- tryCatch(
    WDI::WDI(
      country   = "CO",
      indicator = colombia_indicators,
      start     = start_year,
      end       = end_year,
      extra     = FALSE
    ),
    error = function(e) {
      warning("Colombia WDI fetch failed: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(raw) || nrow(raw) == 0) {
    warning("fetch_colombia_macro: no data returned.")
    return(NULL)
  }

  raw |>
    janitor::clean_names() |>
    tidyr::pivot_longer(
      cols      = dplyr::any_of(tolower(gsub("\\.", "_", colombia_indicators))),
      names_to  = "indicator_code_clean",
      values_to = "value"
    ) |>
    dplyr::mutate(
      indicator_code = colombia_indicators[match(
        indicator_code_clean,
        tolower(gsub("\\.", "_", colombia_indicators))
      )],
      indicator_name = indicator_names[indicator_code],
      date           = as.Date(paste0(year, "-01-01")),
      geography      = "CO",
      category       = "colombia_specific",
      unit           = dplyr::case_when(
        grepl("Percent|%|Rate|Growth|Inflation|Account|Debt|Unemployment",
              indicator_names[indicator_code]) ~ "Percent",
        grepl("Months", indicator_names[indicator_code]) ~ "Months",
        TRUE ~ "USD"
      ),
      source         = "World Bank WDI",
      frequency      = "annual"
    ) |>
    dplyr::filter(!is.na(value)) |>
    dplyr::select(date, geography, indicator_code, indicator_name,
                  category, value, unit, source, frequency)
}

# ---- Analytics: yield calculations -------------------------------------------

#' Calculate real yield (net of local inflation).
#'
#' Uses the Fisher equation: real = (1 + nominal) / (1 + inflation) - 1
#' For small rates, this approximates to nominal - inflation.
#'
#' @param nominal_yield_pct Numeric. Nominal annual yield in percent (e.g., 11.5).
#' @param inflation_pct Numeric. Annual inflation rate in percent (e.g., 5.5).
#' @return Numeric real yield in percent.
calculate_real_yield <- function(nominal_yield_pct, inflation_pct) {
  nominal <- nominal_yield_pct / 100
  infl    <- inflation_pct / 100
  ((1 + nominal) / (1 + infl) - 1) * 100
}

#' Calculate FX-adjusted yield for a USD-based investor holding COP assets.
#'
#' For a USD investor, the return has two components:
#'   1. The COP real yield
#'   2. The change in COP/USD (positive = COP appreciates = gain for USD investor)
#'
#' Approximate formula: FX-adjusted yield ≈ real_yield_cop + cop_appreciation_pct
#'
#' @param real_yield_cop_pct Numeric. Real yield in COP (net of Colombian inflation).
#' @param cop_appreciation_pct Numeric. Expected annual COP appreciation vs USD in percent.
#'   Positive = COP strengthens (good for USD investor). Negative = COP weakens (bad).
#' @return Numeric FX-adjusted yield in percent.
calculate_fx_adjusted_yield <- function(real_yield_cop_pct, cop_appreciation_pct) {
  r_cop <- real_yield_cop_pct / 100
  fx    <- cop_appreciation_pct / 100
  # Exact Fisher combination
  ((1 + r_cop) * (1 + fx) - 1) * 100
}

#' Calculate carry trade return: borrow in USD, invest in COP.
#'
#' Returns are net of the USD funding cost.
#'
#' @param nominal_yield_cop_pct Numeric. COP nominal yield (e.g., 11.5).
#' @param usd_funding_rate_pct Numeric. USD cost of borrowing (e.g., 5.3 for 5.3%).
#' @param cop_appreciation_pct Numeric. Expected annual COP change vs USD.
#' @return Numeric carry return in percent.
calculate_carry_return <- function(nominal_yield_cop_pct,
                                   usd_funding_rate_pct,
                                   cop_appreciation_pct) {
  cop_return <- (1 + nominal_yield_cop_pct / 100) * (1 + cop_appreciation_pct / 100) - 1
  usd_cost   <- usd_funding_rate_pct / 100
  (cop_return - usd_cost) * 100
}

# ---- Analytics: FX risk assessment -------------------------------------------

#' Assess COP/USD currency risk: volatility, trend, carry, and drawdown.
#'
#' @param cop_data Tibble from fetch_cop_exchange_rate() with columns: date, cop_per_usd.
#' @param window_days Integer. Rolling window for volatility calculation. Defaults to 252 (1 year).
#' @return List with: current_rate, annualized_vol_pct, ytd_change_pct,
#'   one_year_change_pct, five_year_change_pct, max_drawdown_pct, summary.
assess_currency_risk <- function(cop_data, window_days = 252) {
  if (is.null(cop_data) || nrow(cop_data) == 0) {
    stop("assess_currency_risk: cop_data is NULL or empty.")
  }

  cop <- cop_data |>
    dplyr::arrange(date) |>
    dplyr::mutate(
      daily_chg = cop_per_usd / dplyr::lag(cop_per_usd) - 1
    ) |>
    dplyr::filter(!is.na(daily_chg))

  today_rate <- dplyr::last(cop_data$cop_per_usd)
  today_date <- dplyr::last(cop_data$date)

  # YTD change
  ytd_start_rate <- cop_data |>
    dplyr::filter(format(date, "%Y") == format(today_date, "%Y")) |>
    dplyr::arrange(date) |>
    dplyr::slice_head(n = 1) |>
    dplyr::pull(cop_per_usd)

  ytd_change_pct <- if (length(ytd_start_rate) > 0) {
    (today_rate / ytd_start_rate - 1) * 100
  } else NA_real_

  # 1-year change
  one_yr_rate <- cop_data |>
    dplyr::filter(date <= today_date - 365) |>
    dplyr::arrange(dplyr::desc(date)) |>
    dplyr::slice_head(n = 1) |>
    dplyr::pull(cop_per_usd)

  one_year_change_pct <- if (length(one_yr_rate) > 0) {
    (today_rate / one_yr_rate - 1) * 100
  } else NA_real_

  # 5-year change
  five_yr_rate <- cop_data |>
    dplyr::filter(date <= today_date - 5 * 365) |>
    dplyr::arrange(dplyr::desc(date)) |>
    dplyr::slice_head(n = 1) |>
    dplyr::pull(cop_per_usd)

  five_year_change_pct <- if (length(five_yr_rate) > 0) {
    (today_rate / five_yr_rate - 1) * 100
  } else NA_real_

  # Annualized volatility
  ann_vol <- if (nrow(cop) >= 21) {
    sd(cop$daily_chg, na.rm = TRUE) * sqrt(252) * 100
  } else NA_real_

  # Maximum drawdown (from high, in terms of COP depreciation against USD)
  # Drawdown: maximum decline in COP value (i.e., maximum rise in COP_per_USD from trough)
  cummax_rate <- cummax(cop_data$cop_per_usd)
  drawdown_pct <- (cop_data$cop_per_usd / cummax_rate - 1) * 100
  max_dd <- min(drawdown_pct, na.rm = TRUE)  # most negative = worst depreciation

  # Interpretation note: positive ytd_change_pct = COP weakened (more COP per USD)
  cop_weakened_ytd <- ytd_change_pct > 0

  list(
    current_rate          = today_rate,
    as_of_date            = today_date,
    annualized_vol_pct    = round(ann_vol, 2),
    ytd_change_pct        = round(ytd_change_pct, 2),
    one_year_change_pct   = round(one_year_change_pct, 2),
    five_year_change_pct  = round(five_year_change_pct, 2),
    max_cop_depreciation_pct = round(max_dd, 2),
    cop_weakened_ytd      = cop_weakened_ytd,
    summary = paste0(
      "COP/USD: ", round(today_rate, 0), " as of ", today_date, ". ",
      "YTD: ", ifelse(cop_weakened_ytd, "+", ""), round(ytd_change_pct, 1),
      "% (", ifelse(cop_weakened_ytd, "COP weakened", "COP strengthened"), " vs USD). ",
      "Annualized vol: ", round(ann_vol, 1), "%."
    )
  )
}

# ---- Analytics: bond screening -----------------------------------------------

#' Screen and rank all COP investment vehicles by real and FX-adjusted yield.
#'
#' Applies three FX scenarios for a USD-based investor:
#'   Bear (COP depreciates 5%/yr) | Base (flat) | Bull (COP appreciates 3%/yr)
#'
#' @param colombia_inflation_pct Numeric. Current Colombia CPI annual % (default ~5.5).
#' @param usd_risk_free_pct Numeric. USD risk-free rate for carry comparison (default 5.3).
#' @param fx_scenarios Named numeric vector. Expected annual COP appreciation (%).
#'   Negative = COP depreciates. Defaults to bear=-5, base=0, bull=+3.
#' @param vehicles Tibble. From get_colombia_investment_universe() or custom.
#' @return Tibble ranked by base-case FX-adjusted real yield.
screen_colombian_bonds <- function(
  colombia_inflation_pct = 5.5,
  usd_risk_free_pct      = 5.3,
  fx_scenarios           = c(bear = -5, base = 0, bull = 3),
  vehicles               = get_colombia_investment_universe()
) {
  scored <- vehicles |>
    dplyr::mutate(
      # Real yield (net of Colombian inflation, for COP investor)
      real_yield_cop_pct = calculate_real_yield(nominal_yield_pct, colombia_inflation_pct),

      # FX-adjusted real yield (for USD investor) under each scenario
      fx_adj_bear_pct    = calculate_fx_adjusted_yield(real_yield_cop_pct, fx_scenarios["bear"]),
      fx_adj_base_pct    = calculate_fx_adjusted_yield(real_yield_cop_pct, fx_scenarios["base"]),
      fx_adj_bull_pct    = calculate_fx_adjusted_yield(real_yield_cop_pct, fx_scenarios["bull"]),

      # Carry vs USD risk-free (base scenario)
      carry_vs_usd_pct   = fx_adj_base_pct - usd_risk_free_pct,

      # Risk-adjusted score (penalize illiquid and high-risk vehicles)
      risk_penalty = dplyr::case_when(
        risk_level == "minimal" ~ 0,
        risk_level == "low"     ~ 0.5,
        risk_level == "moderate" ~ 1.5,
        risk_level == "high"    ~ 3.0,
        TRUE                    ~ 1.0
      ),
      liquidity_penalty = dplyr::case_when(
        liquidity == "high"     ~ 0,
        liquidity == "moderate" ~ 0.3,
        liquidity == "low"      ~ 0.8,
        TRUE                    ~ 0.5
      ),
      risk_adj_yield_pct = real_yield_cop_pct - risk_penalty - liquidity_penalty,

      # Conviction flag: does this beat COP inflation and USD risk-free?
      beats_cop_inflation = real_yield_cop_pct > 0,
      beats_usd_risk_free = fx_adj_base_pct > usd_risk_free_pct
    ) |>
    dplyr::arrange(dplyr::desc(fx_adj_base_pct))

  # Add rank
  scored |>
    dplyr::mutate(
      rank = dplyr::row_number(),
      .before = vehicle_id
    )
}

# ---- Analytics: income forecasting -------------------------------------------

#' Project COP income over multiple years for a given investment allocation.
#'
#' Assumes principal is reinvested at the same nominal rate each year.
#' FX translation to USD uses the projected COP/USD rate under each scenario.
#'
#' @param vehicle_ids Character vector. IDs from get_colombia_investment_universe().
#' @param cop_amounts Numeric vector. Principal in COP for each vehicle (same length as vehicle_ids).
#' @param years Integer. Projection horizon in years. Defaults to 5.
#' @param current_cop_usd Numeric. Current COP per USD exchange rate.
#' @param colombia_inflation_pct Numeric. Current Colombia CPI for real yield calculation.
#' @param fx_scenarios Named numeric. Annual COP appreciation under each scenario.
#' @return Tibble with annual income projections by vehicle, scenario, and year.
generate_colombia_income_forecast <- function(
  vehicle_ids,
  cop_amounts,
  years = 5,
  current_cop_usd = 4000,
  colombia_inflation_pct = 5.5,
  fx_scenarios = c(bear = -5, base = 0, bull = 3)
) {
  if (length(vehicle_ids) != length(cop_amounts)) {
    stop("vehicle_ids and cop_amounts must be the same length.")
  }

  universe <- get_colombia_investment_universe()

  inputs <- tibble::tibble(
    vehicle_id  = vehicle_ids,
    principal_cop = cop_amounts
  ) |>
    dplyr::left_join(
      universe |> dplyr::select(vehicle_id, vehicle_name, nominal_yield_pct, risk_level),
      by = "vehicle_id"
    )

  missing_vehicles <- dplyr::filter(inputs, is.na(nominal_yield_pct))$vehicle_id
  if (length(missing_vehicles) > 0) {
    warning("Vehicle IDs not found in universe: ", paste(missing_vehicles, collapse = ", "))
  }

  inputs <- dplyr::filter(inputs, !is.na(nominal_yield_pct))

  # Expand to year × scenario × vehicle grid
  purrr::map_dfr(names(fx_scenarios), function(scenario_name) {
    cop_appreciation <- fx_scenarios[[scenario_name]]

    purrr::map_dfr(seq_len(nrow(inputs)), function(i) {
      vehicle  <- inputs[i, ]
      rate     <- vehicle$nominal_yield_pct / 100
      princ    <- vehicle$principal_cop

      purrr::map_dfr(seq_len(years), function(yr) {
        # Compound principal over yr-1 full years, then earn one year of income
        balance_start <- princ * (1 + rate)^(yr - 1)
        annual_income_cop <- balance_start * rate
        balance_end       <- balance_start * (1 + rate)

        # USD conversion: COP/USD changes by cop_appreciation each year
        # If COP appreciates (positive), fewer COP per USD = stronger COP
        cop_usd_rate <- current_cop_usd * (1 - cop_appreciation / 100)^yr

        tibble::tibble(
          year               = yr,
          scenario           = scenario_name,
          vehicle_id         = vehicle$vehicle_id,
          vehicle_name       = vehicle$vehicle_name,
          nominal_yield_pct  = vehicle$nominal_yield_pct,
          principal_cop      = princ,
          balance_start_cop  = round(balance_start),
          annual_income_cop  = round(annual_income_cop),
          balance_end_cop    = round(balance_end),
          cop_usd_rate       = round(cop_usd_rate, 0),
          annual_income_usd  = round(annual_income_cop / cop_usd_rate, 0),
          cumulative_income_cop = round(princ * ((1 + rate)^yr - 1))
        )
      })
    })
  }) |>
    dplyr::arrange(scenario, year, vehicle_id)
}

# ---- Live data: Colombia macro drivers for FX forecasting -------------------

#' Fetch Colombia-specific macro drivers for COP/USD forecasting research.
#'
#' Pulls four monthly FRED series and computes derived features:
#'   - COLIRSTCI01STM  : Colombia overnight/call money rate (%, monthly) — tracks Banrep policy rate
#'   - COLCPALTT01GYM  : Colombia CPI, all items, YoY % change (monthly, ~4-5 month lag)
#'   - COLIRLTLT01STM  : Colombia 10Y TES government bond yield (%, monthly) — risk premium signal
#'   - FEDFUNDS        : US Federal Funds effective rate (%, monthly)
#'
#' Derived columns:
#'   - rate_differential    : Colombia overnight rate - FEDFUNDS (carry spread)
#'   - colombia_cpi_yoy     : Colombia CPI YoY % (direct from FRED series)
#'   - colombia_cpi_surprise: Month-over-month change in CPI YoY (unexpected inflation proxy)
#'   - tes_10y_yield        : Colombia 10Y TES yield (credit/duration risk premium)
#'
#' @param start_date Date or character "YYYY-MM-DD". Defaults to 2015-01-01.
#' @param end_date Date or character "YYYY-MM-DD". Defaults to today.
#' @return Tibble with columns:
#'   date, colombia_rate, fedfunds, rate_differential,
#'   colombia_cpi_yoy, colombia_cpi_surprise, n_missing.
#'   Returns NULL with a warning on full failure.
fetch_colombia_macro_drivers <- function(
  start_date = as.Date("2015-01-01"),
  end_date   = Sys.Date()
) {
  if (!requireNamespace("fredr", quietly = TRUE)) {
    stop("Package 'fredr' is required. Install with install.packages('fredr').")
  }

  key <- tryCatch(fredr::fredr_get_key(), error = function(e) "")
  if (is.null(key) || nchar(key) == 0) {
    stop(
      "FRED API key not set. Add FRED_API_KEY=<your_key> to ~/.Renviron, ",
      "then restart R and run fredr::fredr_set_key(Sys.getenv('FRED_API_KEY'))."
    )
  }

  fetch_one <- function(series_id, col_name) {
    tryCatch(
      fredr::fredr(
        series_id         = series_id,
        observation_start = as.Date(start_date),
        observation_end   = as.Date(end_date),
        frequency         = "m"             # force monthly aggregation
      ) |>
        dplyr::select(date, value) |>
        dplyr::rename(!!col_name := value) |>
        dplyr::filter(!is.na(.data[[col_name]])),
      error = function(e) {
        warning("FRED series '", series_id, "' failed: ", conditionMessage(e))
        NULL
      }
    )
  }

  colombia_rate_raw <- fetch_one("COLIRSTCI01STM", "colombia_rate")
  cpi_raw           <- fetch_one("COLCPALTT01GYM", "colombia_cpi_yoy")
  tes10y_raw        <- fetch_one("COLIRLTLT01STM", "tes_10y_yield")
  fedfunds_raw      <- fetch_one("FEDFUNDS",        "fedfunds")

  if (is.null(colombia_rate_raw) && is.null(cpi_raw)) {
    warning("fetch_colombia_macro_drivers: both Colombia rate series failed.")
    return(NULL)
  }

  # Join on date — outer join so we keep all months present in any series
  combined <- fedfunds_raw |>
    dplyr::full_join(colombia_rate_raw, by = "date") |>
    dplyr::full_join(cpi_raw,           by = "date") |>
    dplyr::full_join(tes10y_raw,        by = "date") |>
    dplyr::arrange(date) |>
    dplyr::mutate(
      # Carry spread: how much more Colombia pays over the Fed
      rate_differential = colombia_rate - fedfunds,

      # CPI surprise: unexpected acceleration/deceleration vs. prior month
      colombia_cpi_surprise = colombia_cpi_yoy - dplyr::lag(colombia_cpi_yoy),

      # Count missing values per row for diagnostics
      n_missing = is.na(colombia_rate) + is.na(fedfunds) +
                  is.na(colombia_cpi_yoy) + is.na(tes_10y_yield)
    ) |>
    dplyr::filter(date >= as.Date(start_date), date <= as.Date(end_date))

  combined
}

# ---- Summary: Colombia snapshot ----------------------------------------------

#' Print a concise Colombia investment snapshot to the console.
#'
#' @param cop_data Tibble from fetch_cop_exchange_rate().
#' @param macro_data Tibble from fetch_colombia_macro().
#' @param screen_results Tibble from screen_colombian_bonds().
print_colombia_snapshot <- function(cop_data = NULL,
                                    macro_data = NULL,
                                    screen_results = NULL) {
  cat("============================================================\n")
  cat(" Colombia Investment Snapshot\n")
  cat(" Generated:", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
  cat("============================================================\n\n")

  # COP/USD
  if (!is.null(cop_data) && nrow(cop_data) > 0) {
    risk <- assess_currency_risk(cop_data)
    cat("--- COP/USD Exchange Rate ---\n")
    cat(risk$summary, "\n\n")
  }

  # Latest macro indicators
  if (!is.null(macro_data) && nrow(macro_data) > 0) {
    cat("--- Colombia Macro (latest available) ---\n")
    latest_macro <- macro_data |>
      dplyr::group_by(indicator_name) |>
      dplyr::slice_max(date, n = 1) |>
      dplyr::ungroup() |>
      dplyr::select(indicator_name, value, unit, date)
    print(latest_macro, n = Inf)
    cat("\n")
  }

  # Bond screen
  if (!is.null(screen_results) && nrow(screen_results) > 0) {
    cat("--- COP Investment Vehicle Ranking (by base-case FX-adjusted real yield) ---\n")
    display <- screen_results |>
      dplyr::select(
        rank, vehicle_name, nominal_yield_pct, real_yield_cop_pct,
        fx_adj_bear_pct, fx_adj_base_pct, fx_adj_bull_pct,
        risk_level, liquidity
      ) |>
      dplyr::mutate(dplyr::across(dplyr::where(is.numeric), ~ round(., 1)))
    print(display, n = Inf)
    cat("\n")

    # Flag best opportunities
    top <- dplyr::filter(screen_results, beats_cop_inflation & fx_adj_base_pct > 0)
    if (nrow(top) > 0) {
      cat("Vehicles beating COP inflation AND providing positive USD-adjusted return:\n")
      cat(paste0("  ", top$vehicle_name, " (", round(top$fx_adj_base_pct, 1), "% base)\n"),
          sep = "")
    }
  }

  cat("\n============================================================\n")
  cat("NOTE: Rates are approximate. Verify before investing.\n")
  cat("TES yields: bvc.com.co | CDT rates: bank websites\n")
  cat("This is research only, not financial advice.\n")
  cat("============================================================\n")

  invisible(NULL)
}
