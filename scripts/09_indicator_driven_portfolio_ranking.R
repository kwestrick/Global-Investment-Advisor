# scripts/09_indicator_driven_portfolio_ranking.R
# Phase 3, Part 4: Indicator-Driven Portfolio Prioritization
#
# PURPOSE:
#   Integrates live macro, FX, and momentum indicators with the global ETF
#   screening universe to produce a monthly allocation recommendation.
#   Accounts for actual USD/COP currency exposure vs. target (80/20) and
#   suggests specific $ amounts to deploy into each asset class.
#
# HOW IT WORKS:
#   1. Fetch live indicators (FX rates, ETF momentum, CPI, Colombia macro)
#   2. Score each signal as positive / neutral / negative
#   3. Apply conviction modifiers (+0.25 to +0.75 per signal) to base ETF scores
#   4. Recalculate currency split recommendation (USD vs COP)
#   5. Rank top opportunities within each currency bucket
#   6. Output ranked table + narrative with dollar amounts
#
# INPUTS (auto-loaded):
#   - Live Yahoo Finance prices (via tidyquant)
#   - FRED CPI (if FRED_API_KEY is set; otherwise uses cached/manual fallback)
#   - R/screening.R  — base ETF universe and conviction score framework
#   - R/colombia_indicators.R — COP investment universe and analytics
#   - R/personal_wealth_monitoring.R — currency exposure functions
#
# OUTPUTS:
#   - outputs/tables/<date>_indicator_signal_dashboard.csv
#   - outputs/tables/<date>_ranked_allocation_recommendation.csv
#   - Printed narrative to console

# ---- Setup ----------------------------------------------------------------

source("R/00_setup.R")
suppressWarnings(install_missing_packages())
suppressWarnings(load_required_packages())
create_project_dirs()

source("R/data_import.R")
source("R/screening.R")
source("R/indicators.R")
source("R/economic_indicators.R")
source("R/colombia_indicators.R")
source("R/personal_wealth_monitoring.R")

library(tidyquant)
library(scales)

today_str <- format(Sys.Date(), "%Y-%m-%d")

cat("\n")
cat(strrep("=", 65), "\n")
cat("INDICATOR-DRIVEN PORTFOLIO RANKING\n")
cat("Date:", today_str, "\n")
cat(strrep("=", 65), "\n\n")

# ---- Section 1: Live Indicator Fetch --------------------------------------

cat("1. Fetching live indicators...\n")

# --- 1a. FX rates: COP/USD, EUR/USD, and DXY proxy ---

fx_tickers <- c(
  "COP=X",    # COP per 1 USD
  "DX-Y.NYB"  # US Dollar Index (DXY)
)

fx_raw <- tryCatch(
  tq_get(fx_tickers, from = Sys.Date() - 100, to = Sys.Date()),
  error = function(e) { cat("  WARNING: FX fetch failed:", conditionMessage(e), "\n"); NULL }
)

if (!is.null(fx_raw)) {
  cat("  FX data loaded:", nrow(fx_raw), "rows\n")
} else {
  cat("  FX fetch failed. Using fallback values.\n")
}

# --- 1b. Benchmark ETF prices for momentum ---

momentum_tickers <- c("SPY", "VEA", "VWO", "IEF", "GLD")

etf_raw <- tryCatch(
  tq_get(momentum_tickers, from = Sys.Date() - 100, to = Sys.Date()),
  error = function(e) { cat("  WARNING: ETF fetch failed:", conditionMessage(e), "\n"); NULL }
)

if (!is.null(etf_raw)) {
  cat("  Benchmark ETF data loaded:", n_distinct(etf_raw$symbol), "tickers\n")
}

# --- 1c. FRED CPI (optional, requires API key) ---

us_cpi_yoy <- tryCatch({
  if (!nzchar(Sys.getenv("FRED_API_KEY"))) stop("No FRED key set")
  fredr::fredr_set_key(Sys.getenv("FRED_API_KEY"))
  cpi <- fredr::fredr("CPIAUCSL", observation_start = Sys.Date() - 400)
  # Compute YoY from monthly index
  cpi |>
    dplyr::arrange(date) |>
    dplyr::mutate(yoy = value / dplyr::lag(value, 12) - 1) |>
    dplyr::filter(!is.na(yoy)) |>
    dplyr::slice_tail(n = 1) |>
    dplyr::pull(yoy) * 100
}, error = function(e) {
  cat("  FRED CPI not available. Using manual estimate (5.1%).\n")
  NA_real_
})

if (is.na(us_cpi_yoy)) us_cpi_yoy <- 5.1  # fallback: approximate per AGENTS.md context

cat("  US CPI YoY (latest):", round(us_cpi_yoy, 2), "%\n")

cat("\n")

# ---- Section 2: Compute Indicator Signals ---------------------------------

cat("2. Computing indicator signals...\n\n")

# Helper: compute n-day return for a ticker from tq_get output
get_return_nday <- function(df, ticker, n_days) {
  if (is.null(df)) return(NA_real_)
  sub <- df |>
    dplyr::filter(symbol == ticker) |>
    dplyr::arrange(date) |>
    dplyr::filter(!is.na(adjusted)) |>
    dplyr::slice_tail(n = n_days + 1)
  if (nrow(sub) < 2) return(NA_real_)
  (dplyr::last(sub$adjusted) / dplyr::first(sub$adjusted)) - 1
}

# Helper: compute latest value for a ticker
get_latest <- function(df, ticker) {
  if (is.null(df)) return(NA_real_)
  df |>
    dplyr::filter(symbol == ticker, !is.na(adjusted)) |>
    dplyr::slice_max(date, n = 1) |>
    dplyr::pull(adjusted) |>
    dplyr::first()
}

# --- COP/USD signals ---
cop_usd_latest  <- get_latest(fx_raw, "COP=X")
cop_30d_return  <- get_return_nday(fx_raw, "COP=X", 30)   # pos = COP weakening
cop_90d_return  <- get_return_nday(fx_raw, "COP=X", 90)

# Invert: COP strength = NEGATIVE cop/usd return (fewer COP per dollar)
cop_30d_strength <- if (!is.na(cop_30d_return)) -cop_30d_return else 0
cop_90d_strength <- if (!is.na(cop_90d_return)) -cop_90d_return else 0

cop_signal <- dplyr::case_when(
  cop_30d_strength >  0.02 ~ "bullish",   # COP strengthened >2% in 30d
  cop_30d_strength < -0.02 ~ "bearish",
  TRUE                     ~ "neutral"
)

# --- DXY signal (dollar strength) ---
dxy_30d <- get_return_nday(fx_raw, "DX-Y.NYB", 30)
dxy_signal <- dplyr::case_when(
  !is.na(dxy_30d) & dxy_30d >  0.015 ~ "strong_usd",
  !is.na(dxy_30d) & dxy_30d < -0.015 ~ "weak_usd",
  TRUE                                 ~ "neutral_usd"
)

# --- US inflation regime ---
inflation_regime <- dplyr::case_when(
  us_cpi_yoy >= 4.5 ~ "high",
  us_cpi_yoy >= 2.5 ~ "moderate",
  TRUE              ~ "low"
)

# --- Equity momentum (SPY vs VEA vs VWO, 60-day) ---
spy_60d  <- get_return_nday(etf_raw, "SPY",  60)
vea_60d  <- get_return_nday(etf_raw, "VEA",  60)
vwo_60d  <- get_return_nday(etf_raw, "VWO",  60)
gld_60d  <- get_return_nday(etf_raw, "GLD",  60)
ief_60d  <- get_return_nday(etf_raw, "IEF",  60)

us_vs_intl_signal <- dplyr::case_when(
  !is.na(spy_60d) & !is.na(vea_60d) & (spy_60d - vea_60d) >  0.05 ~ "us_leading",
  !is.na(spy_60d) & !is.na(vea_60d) & (spy_60d - vea_60d) < -0.05 ~ "intl_leading",
  TRUE                                                               ~ "neutral"
)

em_vs_us_signal <- dplyr::case_when(
  !is.na(vwo_60d) & !is.na(spy_60d) & (vwo_60d - spy_60d) >  0.04 ~ "em_leading",
  !is.na(vwo_60d) & !is.na(spy_60d) & (vwo_60d - spy_60d) < -0.04 ~ "us_leading_em",
  TRUE                                                               ~ "neutral"
)

# --- Colombia real yield (from reference data in colombia_indicators.R) ---
# TES 10Y nominal: ~11.5%, Colombia CPI: ~5.5% → real yield ~5.7% (Fisher)
# Classify as attractive if real yield > 4%
colombia_cpi_est   <- 5.5   # approximate (see AGENTS.md)
tes_10y_nominal    <- 11.5
colombia_real_yield <- ((1 + tes_10y_nominal/100) / (1 + colombia_cpi_est/100) - 1) * 100
cop_yield_signal   <- dplyr::case_when(
  colombia_real_yield >= 6.0 ~ "very_attractive",
  colombia_real_yield >= 4.0 ~ "attractive",
  TRUE                       ~ "neutral"
)

# --- Summarise signals ---
signal_dashboard <- tibble::tibble(
  indicator         = c(
    "COP/USD 30-day trend",
    "COP/USD 90-day trend",
    "US Dollar Index (DXY) 30-day",
    "US CPI YoY",
    "SPY vs VEA 60-day momentum",
    "VWO vs SPY 60-day momentum",
    "Colombia TES 10Y real yield"
  ),
  raw_value         = c(
    ifelse(!is.na(cop_30d_return), paste0(round(cop_30d_strength*100,1),"% COP gain"), "N/A"),
    ifelse(!is.na(cop_90d_return), paste0(round(cop_90d_strength*100,1),"% COP gain"), "N/A"),
    ifelse(!is.na(dxy_30d),        paste0(round(dxy_30d*100,1),"% USD index change"), "N/A"),
    paste0(round(us_cpi_yoy,1),"%"),
    ifelse(!is.na(spy_60d) & !is.na(vea_60d),
           paste0("SPY ",round(spy_60d*100,1),"% vs VEA ",round(vea_60d*100,1),"%"), "N/A"),
    ifelse(!is.na(vwo_60d) & !is.na(spy_60d),
           paste0("VWO ",round(vwo_60d*100,1),"% vs SPY ",round(spy_60d*100,1),"%"), "N/A"),
    paste0(round(colombia_real_yield,1),"% (Fisher)")
  ),
  signal            = c(
    cop_signal, cop_signal, dxy_signal,
    inflation_regime, us_vs_intl_signal,
    em_vs_us_signal, cop_yield_signal
  ),
  implication       = c(
    "COP allocation attractiveness",
    "COP trend confirmation",
    "USD vs international positioning",
    "Inflation regime: bond/equity/commodity mix",
    "US vs developed-market relative weight",
    "EM vs US relative weight",
    "Colombia fixed-income attractiveness"
  )
)

cat("SIGNAL DASHBOARD\n")
cat(strrep("-", 65), "\n")
signal_dashboard |>
  dplyr::select(indicator, raw_value, signal) |>
  print(n = 10)
cat("\n")

# ---- Section 3: Build Conviction Modifier Table ---------------------------

cat("3. Applying indicator modifiers to ETF conviction scores...\n\n")

# Base modifiers keyed to asset class
# Positive = conviction boost; negative = conviction headwind
build_modifier <- function(category) {
  mod <- 0

  # Dollar signal
  if (dxy_signal == "weak_usd" && category %in% c("Country ETF", "Emerging Market")) mod <- mod + 0.50
  if (dxy_signal == "strong_usd" && category %in% c("Country ETF", "Emerging Market")) mod <- mod - 0.50
  if (dxy_signal == "weak_usd" && category == "Commodity/Transition") mod <- mod + 0.25
  if (dxy_signal == "strong_usd" && category == "Benchmark" &&
      grepl("US", category)) mod <- mod - 0.25

  # US vs international momentum
  if (us_vs_intl_signal == "intl_leading" && category %in% c("Country ETF", "Benchmark")) mod <- mod + 0.50
  if (us_vs_intl_signal == "us_leading"   && category == "Country ETF") mod <- mod - 0.25

  # EM momentum
  if (em_vs_us_signal == "em_leading"    && category == "Emerging Market") mod <- mod + 0.50
  if (em_vs_us_signal == "us_leading_em" && category == "Emerging Market") mod <- mod - 0.25

  # Inflation regime
  if (inflation_regime == "high" && category == "US Bond") mod <- mod - 0.50
  if (inflation_regime == "high" && category == "Commodity/Transition") mod <- mod + 0.50
  if (inflation_regime == "low"  && category == "US Bond") mod <- mod + 0.25

  round(mod, 2)
}

# Load or recompute the global ETF screening scores from script 02 output
# Script 02 saves two files: country_opportunity_screen_<date>.csv
#                            theme_opportunity_screen_<date>.csv
latest_country <- list.files(
  "data/processed", pattern = "^country_opportunity_screen_",
  full.names = TRUE
) |> sort(decreasing = TRUE) |> head(1)

latest_theme <- list.files(
  "data/processed", pattern = "^theme_opportunity_screen_",
  full.names = TRUE
) |> sort(decreasing = TRUE) |> head(1)

if (length(latest_country) > 0 && length(latest_theme) > 0) {
  country_screen <- readr::read_csv(latest_country, show_col_types = FALSE) |>
    dplyr::mutate(screen_type = "country")
  theme_screen   <- readr::read_csv(latest_theme, show_col_types = FALSE) |>
    dplyr::rename(country_or_region = dplyr::any_of("theme")) |>
    dplyr::mutate(screen_type = "theme")
  base_scores <- dplyr::bind_rows(country_screen, theme_screen)
  cat("  Loaded", nrow(country_screen), "country scores from:", basename(latest_country), "\n")
  cat("  Loaded", nrow(theme_screen),   "theme scores from:",   basename(latest_theme), "\n")
} else {
  # Fallback: use the country/theme universe with neutral base scores
  cat("  No screening file found — using ETF universe with neutral base scores.\n")
  country_u <- create_country_etf_universe() |>
    dplyr::mutate(weighted_score = 3.0, conviction_bucket = "Watchlist or tactical")
  theme_u <- create_theme_etf_universe() |>
    dplyr::mutate(weighted_score = 3.0, conviction_bucket = "Watchlist or tactical")
  base_scores <- dplyr::bind_rows(country_u, theme_u)
}

# Standardize required columns (handle both possible schemas)
if (!"category" %in% names(base_scores) && "sector" %in% names(base_scores)) {
  base_scores <- dplyr::rename(base_scores, category = sector)
}
if (!"category" %in% names(base_scores)) {
  base_scores <- dplyr::mutate(base_scores, category = "Country ETF")
}
if (!"weighted_score" %in% names(base_scores)) {
  base_scores <- dplyr::mutate(base_scores, weighted_score = 3.0)
}

# Apply modifiers
ranked <- base_scores |>
  dplyr::mutate(
    indicator_modifier = purrr::map_dbl(category, build_modifier),
    adjusted_score = round(weighted_score + indicator_modifier, 2),
    adjusted_conviction = dplyr::case_when(
      adjusted_score >= 4.25 ~ "High conviction",
      adjusted_score >= 3.50 ~ "Attractive",
      adjusted_score >= 2.75 ~ "Watchlist",
      adjusted_score >= 2.00 ~ "Weak thesis",
      TRUE                    ~ "Avoid"
    )
  ) |>
  dplyr::arrange(dplyr::desc(adjusted_score))

cat("  Indicator modifiers applied to", nrow(ranked), "securities.\n\n")

# ---- Section 4: COP Vehicle Ranking ---------------------------------------

cat("4. Ranking COP investment vehicles...\n\n")

cop_universe <- get_colombia_investment_universe()

# Score COP vehicles using real yield and risk-adjusted attractiveness
cop_ranked <- cop_universe |>
  dplyr::mutate(
    # Real yield using Fisher equation
    real_yield_pct = ((1 + nominal_yield_pct / 100) / (1 + colombia_cpi_est / 100) - 1) * 100,

    # COP momentum bonus: if COP is strengthening, COP assets are more attractive in USD terms
    cop_momentum_bonus = dplyr::case_when(
      cop_signal == "bullish"  ~ 1.0,
      cop_signal == "neutral"  ~ 0.5,
      cop_signal == "bearish"  ~ 0.0
    ),

    # Risk-adjusted score: high risk vehicles need higher yield to compensate
    risk_penalty = dplyr::case_when(
      risk_level == "minimal" ~ 0.0,
      risk_level == "low"     ~ 0.2,
      risk_level == "moderate"~ 0.6,
      risk_level == "high"    ~ 1.2,
      TRUE                    ~ 0.5
    ),

    # Liquidity bonus
    liquidity_bonus = dplyr::case_when(
      liquidity == "high"   ~ 0.3,
      liquidity == "medium" ~ 0.1,
      liquidity == "low"    ~ 0.0
    ),

    # Final score out of 10 (coalesce sub-terms to 0 to prevent NA propagation)
    cop_score = round(
      dplyr::coalesce(real_yield_pct / 10 * 4, 0) +
      dplyr::coalesce(cop_momentum_bonus, 0) +
      dplyr::if_else(is.na(fogafin_guaranteed) | !fogafin_guaranteed, 0, 0.5) +
      dplyr::coalesce(liquidity_bonus, 0) -
      dplyr::coalesce(risk_penalty, 0.5),
      2
    )
  ) |>
  dplyr::arrange(dplyr::desc(cop_score))

cat("  COP vehicles ranked:", nrow(cop_ranked), "\n")
cop_ranked |>
  dplyr::select(vehicle_name, vehicle_type, nominal_yield_pct, real_yield_pct,
                risk_level, fogafin_guaranteed, cop_score) |>
  print(n = 14)
cat("\n")

# ---- Section 5: Currency Allocation Decision ------------------------------

cat("5. Computing currency allocation recommendation...\n\n")

# Current exposure (hard-coded from Phase 3 Part 3 analysis; update quarterly)
# As of Sep 2026: investable = $359,149 USD; USD 97.4%, COP 2.6%
# Target: 80% USD / 20% COP
# Corrected monthly cash flow: -$827/month deficit

current_usd_pct  <- 97.4
current_cop_pct  <- 2.6
target_usd_pct   <- 80.0
target_cop_pct   <- 20.0
total_investable <- 359149

# Indicator-adjusted target: if COP signals bullish, tighten to 75/25
# If COP signals bearish, loosen to 85/15
adj_cop_target <- dplyr::case_when(
  cop_signal == "bullish" & cop_yield_signal %in% c("attractive", "very_attractive") ~ 25,
  cop_signal == "bearish" ~ 15,
  TRUE ~ target_cop_pct
)
adj_usd_target <- 100 - adj_cop_target

usd_drift <- current_usd_pct - adj_usd_target  # positive = USD overweight
gap_usd   <- (usd_drift / 100) * total_investable

# Monthly investable amount: Wealthfront contribution drawn from liquid reserves
# Even with a -$827/month income deficit, the Wealthfront auto-deposit plan
# continues at $5,200/month funded from the $309k liquid reserve.
monthly_investable_usd <- 5200

# If USD overweight: direct all new contributions to COP
# If balanced: split proportionally to targets
if (usd_drift > 5) {
  cop_per_usd <- if (!is.na(cop_usd_latest)) cop_usd_latest else 3200
  monthly_usd_deploy <- 0
  monthly_cop_deploy_usd <- monthly_investable_usd
  months_to_close <- ceiling(gap_usd / monthly_investable_usd)
  rebal_action <- paste0(
    "REDIRECT to COP: direct $", format(round(monthly_investable_usd), big.mark = ","),
    "/mo entirely to COP assets for ~", months_to_close, " months."
  )
} else if (usd_drift < -5) {
  monthly_usd_deploy <- monthly_investable_usd
  monthly_cop_deploy_usd <- 0
  rebal_action <- paste0("Increase USD: current COP allocation above target.")
} else {
  monthly_usd_deploy     <- round(monthly_investable_usd * adj_usd_target / 100)
  monthly_cop_deploy_usd <- monthly_investable_usd - monthly_usd_deploy
  rebal_action <- "Portfolio near target. Split contributions proportionally."
}

cat("  Current exposure:     USD", current_usd_pct, "% / COP", current_cop_pct, "%\n")
cat("  Indicator-adj target: USD", adj_usd_target,  "% / COP", adj_cop_target, "%\n")
cat("  USD drift:            ", sprintf("%+.1f", usd_drift), "pp\n")
cat("  Gap to close:        $", format(round(abs(gap_usd)), big.mark = ","), " USD\n")
cat("  Monthly investable:  $", format(monthly_investable_usd, big.mark = ","), " (from liquid reserve)\n")
cat("  Recommendation:       ", rebal_action, "\n\n")

# ---- Section 6: USD Allocation — Top ETF Recommendations -----------------

cat("6. USD allocation — top ETF opportunities (indicator-adjusted)...\n\n")

# Exclude benchmarks from ranked recommendations (keep country/theme ETFs)
top_usd <- ranked |>
  dplyr::filter(category != "Benchmark",
                adjusted_score >= 2.75) |>
  dplyr::mutate(
    # Coalesce whichever name column exists into one
    label = dplyr::coalesce(
      if ("country_or_region" %in% names(ranked)) country_or_region else NA_character_,
      if ("theme"             %in% names(ranked)) theme             else NA_character_,
      symbol
    )
  ) |>
  dplyr::slice_head(n = 8) |>
  dplyr::select(
    symbol, label, category,
    base_score = weighted_score,
    indicator_modifier,
    adjusted_score,
    adjusted_conviction
  )

# Fallback: if schema differs, just use symbol
if (ncol(top_usd) < 4) {
  top_usd <- ranked |> dplyr::slice_head(n = 8) |>
    dplyr::select(symbol, adjusted_score, adjusted_conviction)
}

print(top_usd, n = 10)
cat("\n")

# ---- Section 7: Final Allocation Recommendation --------------------------

cat(strrep("=", 65), "\n")
cat("MONTHLY ALLOCATION RECOMMENDATION —", today_str, "\n")
cat(strrep("=", 65), "\n\n")

cat("CASH FLOW CONTEXT\n")
cat("  Monthly income:         $7,488\n")
cat("  Monthly recurring spend: $8,315 (actual; Sep 2025–Aug 2026)\n")
cat("  Net monthly cash flow:  -$827 (deficit; funded from liquid reserve)\n")
cat("  Liquid reserve:         $309,908 (37+ months runway)\n")
cat("  Monthly Wealthfront:    $5,200 (from liquid reserve drawdown)\n\n")

cat("CURRENCY SPLIT\n")
cat("  →", sprintf("USD: $%-6s", format(monthly_usd_deploy, big.mark=",")),
    sprintf("(%.0f%%)", monthly_usd_deploy/monthly_investable_usd*100), "\n")
cat("  →", sprintf("COP: $%-6s", format(monthly_cop_deploy_usd, big.mark=",")),
    sprintf("(%.0f%%)", monthly_cop_deploy_usd/monthly_investable_usd*100), "\n\n")

if (monthly_usd_deploy > 0 && nrow(top_usd) > 0) {
  n_top   <- min(nrow(top_usd), 5)
  per_etf <- round(monthly_usd_deploy / n_top)
  cat("USD ALLOCATIONS (top", n_top, "ETFs, ~$", format(per_etf, big.mark=","), "/each)\n")
  top_usd |> dplyr::slice_head(n = n_top) |>
    dplyr::mutate(
      monthly_usd = format(per_etf, big.mark = ","),
      line = paste0("  → ", symbol, " (", adjusted_conviction, ", score ", adjusted_score, ")  $", monthly_usd)
    ) |>
    dplyr::pull(line) |>
    cat(sep = "\n")
  cat("\n\n")
}

if (monthly_cop_deploy_usd > 0) {
  cop_per_usd_rate <- if (!is.na(cop_usd_latest)) cop_usd_latest else 3200
  monthly_cop_cop  <- round(monthly_cop_deploy_usd * cop_per_usd_rate / 1e6, 1)
  cat("COP ALLOCATIONS (~$", format(monthly_cop_deploy_usd, big.mark=","),
      " USD /", monthly_cop_cop, "M COP)\n")
  cop_ranked |>
    dplyr::filter(cop_score > 0) |>
    dplyr::slice_head(n = 3) |>
    dplyr::mutate(
      line = paste0(
        "  → ", vehicle_name,
        " (", nominal_yield_pct, "% nominal / ",
        round(real_yield_pct, 1), "% real, ",
        risk_level, " risk)"
      )
    ) |>
    dplyr::pull(line) |>
    cat(sep = "\n")
  cat("\n\n")
}

# Key indicator signals
cat("KEY SIGNALS DRIVING THIS RECOMMENDATION\n")
signal_dashboard |>
  dplyr::mutate(
    emoji = dplyr::case_when(
      stringr::str_detect(signal, "bullish|attractive|weak_usd|intl_leading|em_leading|low") ~ "[+]",
      stringr::str_detect(signal, "bearish|strong_usd|us_leading|high")                      ~ "[-]",
      TRUE                                                                                     ~ "[ ]"
    ),
    row = paste0("  ", emoji, " ", indicator, ": ", signal, " (", raw_value, ")")
  ) |>
  dplyr::pull(row) |>
  cat(sep = "\n")

cat("\n\n")
cat("FALSIFICATION TRIGGERS\n")
cat("  • Abandon COP buildup if COP/USD breaks above 4,500 (>15% depreciation)\n")
cat("  • Reduce EM if VWO drawdown exceeds 15% without macro catalyst\n")
cat("  • Revisit USD allocation if Fed restarts aggressive hiking cycle\n")
cat("  • Reassess Colombia TES if Banrep cuts policy rate below 7%\n\n")

cat("Disclaimer: This is research and analysis only, not personalized financial\n")
cat("advice. Consult a qualified financial advisor before making investment decisions.\n\n")

cat(strrep("=", 65), "\n\n")

# ---- Section 8: Export outputs --------------------------------------------

cat("8. Saving outputs...\n")

readr::write_csv(
  signal_dashboard,
  paste0("outputs/tables/", today_str, "_indicator_signal_dashboard.csv")
)

readr::write_csv(
  ranked |> dplyr::slice_head(n = 20),
  paste0("outputs/tables/", today_str, "_ranked_allocation_recommendation.csv")
)

readr::write_csv(
  cop_ranked |> dplyr::select(vehicle_id, vehicle_name, vehicle_type,
                               nominal_yield_pct, real_yield_pct,
                               risk_level, fogafin_guaranteed, cop_score),
  paste0("outputs/tables/", today_str, "_cop_vehicle_ranking.csv")
)

cat("  outputs/tables/", today_str, "_indicator_signal_dashboard.csv\n", sep = "")
cat("  outputs/tables/", today_str, "_ranked_allocation_recommendation.csv\n", sep = "")
cat("  outputs/tables/", today_str, "_cop_vehicle_ranking.csv\n", sep = "")
cat("\nScript 09 complete:", format(Sys.time(), "%H:%M:%S"), "\n")
