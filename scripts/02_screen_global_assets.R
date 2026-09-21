# 02_screen_global_assets.R
# Screen global assets by valuation, macro tailwind, catalyst strength, and risk

# ---- Setup ----
source("R/00_setup.R")
install_missing_packages()
load_required_packages()
create_project_dirs()

source("R/data_import.R")
source("R/screening.R")
source("R/indicators.R")
source("R/valuation.R")

cat("\n=== GLOBAL ASSET SCREENING WORKFLOW ===\n")
cat("Started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# ---- Load Data ----

cat("1. Loading processed market and macro data...\n")

# Find the most recent processed files
latest_prices <- list.files(
  "data/processed",
  pattern = "^market_prices_",
  full.names = TRUE
) |>
  sort(decreasing = TRUE) |>
  head(1)

latest_returns <- list.files(
  "data/processed",
  pattern = "^daily_returns_",
  full.names = TRUE
) |>
  sort(decreasing = TRUE) |>
  head(1)

latest_macro <- list.files(
  "data/processed",
  pattern = "^macro_data_gid_",
  full.names = TRUE
) |>
  sort(decreasing = TRUE) |>
  head(1)

if (length(latest_prices) == 0 || length(latest_returns) == 0) {
  stop("Required data files not found. Run 01_collect_market_data.R first.")
}

prices <- readr::read_csv(latest_prices, show_col_types = FALSE)
returns <- readr::read_csv(latest_returns, show_col_types = FALSE)

cat("   Loaded:", nrow(prices), "price observations\n")
cat("   Loaded:", nrow(returns), "return observations\n")

if (length(latest_macro) > 0) {
  macro_data <- readr::read_csv(latest_macro, show_col_types = FALSE)
  cat("   Loaded:", nrow(macro_data), "macro observations\n")
} else {
  cat("   WARNING: Macro data file not found\n")
  macro_data <- NULL
}

cat("\n")

# Load universe definitions
country_universe <- create_country_etf_universe()
theme_universe <- create_theme_etf_universe()

cat("   Country universe:", nrow(country_universe), "ETFs\n")
cat("   Theme universe:", nrow(theme_universe), "ETFs\n\n")

# ---- Calculate Performance Metrics ----

cat("2. Calculating performance metrics...\n")

# Get latest prices for each ticker
latest_prices_tbl <- prices |>
  dplyr::group_by(symbol) |>
  dplyr::slice_max(date, n = 1) |>
  dplyr::ungroup() |>
  dplyr::select(symbol, date, adjusted) |>
  dplyr::rename(current_price = adjusted, price_date = date)

# Return summary statistics
return_summary <- calculate_return_summary(returns)

# Calculate drawdowns
drawdowns <- calculate_drawdowns(returns)
max_drawdown <- drawdowns |>
  dplyr::group_by(symbol) |>
  dplyr::summarise(
    max_drawdown = min(drawdown, na.rm = TRUE),
    .groups = "drop"
  )

# Relative strength to SPY
relative_strength <- calculate_relative_strength(prices, benchmark_symbol = "SPY")
recent_rs <- relative_strength |>
  dplyr::filter(symbol != "SPY") |>
  dplyr::group_by(symbol) |>
  dplyr::slice_max(date, n = 1) |>
  dplyr::ungroup() |>
  dplyr::select(symbol, relative_strength_to_spy = relative_strength)

cat("   ✓ Return summary metrics calculated\n")
cat("   ✓ Drawdown analysis completed\n")
cat("   ✓ Relative strength computed\n\n")

# ---- Build Valuation Scores ----

cat("3. Building valuation framework...\n")

# Create a valuation DataFrame with estimated relative value metrics
# Note: Using relative performance as a proxy for relative valuation
# In production, would incorporate actual P/E, P/B, dividend yields

valuation_proxy <- return_summary |>
  dplyr::left_join(max_drawdown, by = "symbol") |>
  dplyr::left_join(recent_rs, by = "symbol") |>
  dplyr::mutate(
    # Valuation proxy: lower recent return, lower volatility = potentially better value
    # (contrarian signal)
    value_signal = dplyr::case_when(
      annualized_return < median(annualized_return, na.rm = TRUE) &
        annualized_volatility < median(annualized_volatility, na.rm = TRUE) ~ 1.0,
      annualized_return < median(annualized_return, na.rm = TRUE) ~ 0.7,
      annualized_volatility > median(annualized_volatility, na.rm = TRUE) ~ 0.4,
      TRUE ~ 0.5
    ),
    # Momentum signal: relative strength trend
    momentum_signal = dplyr::case_when(
      is.na(relative_strength_to_spy) ~ 0.5,
      relative_strength_to_spy > 1.05 ~ 1.0,
      relative_strength_to_spy > 0.95 ~ 0.6,
      relative_strength_to_spy < 0.90 ~ 0.3,
      TRUE ~ 0.5
    ),
    # Risk signal: drawdown severity
    risk_score = dplyr::case_when(
      max_drawdown > -0.40 ~ 1.0,  # Shallow drawdowns = better risk profile
      max_drawdown > -0.50 ~ 0.7,
      max_drawdown > -0.60 ~ 0.4,
      TRUE ~ 0.2
    ),
    valuation_composite = (value_signal * 0.4 + momentum_signal * 0.3 + risk_score * 0.3)
  ) |>
  dplyr::select(
    symbol,
    annualized_return,
    annualized_volatility,
    sharpe_proxy,
    max_drawdown,
    relative_strength_to_spy,
    value_signal,
    momentum_signal,
    risk_score,
    valuation_composite
  )

cat("   ✓ Valuation framework created\n")
cat("   ✓ Value signals calculated\n")
cat("   ✓ Risk scores assigned\n\n")

# ---- Macro and Catalyst Assessment ----

cat("4. Assessing macro tailwinds and catalysts...\n")

# Macro tailwind assessment (simulated for now)
# In production, this would be data-driven from macro_data and qualitative research
macro_assessment <- country_universe |>
  dplyr::mutate(
    macro_tailwind = dplyr::case_when(
      country_or_region == "Emerging markets" ~ 3.5,  # EM recovery theme
      country_or_region == "Japan" ~ 3.2,             # Yen weakness, inflation
      country_or_region == "India" ~ 3.8,             # Growth leader
      country_or_region == "Brazil" ~ 3.0,            # Commodity exposure
      country_or_region == "United States" ~ 2.5,     # Baseline
      TRUE ~ 2.8
    ),
    catalyst_strength = dplyr::case_when(
      country_or_region == "India" ~ 4.0,             # Strong structural tailwinds
      country_or_region == "Japan" ~ 3.5,             # BoJ policy, wage growth
      country_or_region == "Emerging markets" ~ 3.3,  # Multiple re-rating
      country_or_region == "Brazil" ~ 3.2,            # Rate cycle, agri exports
      country_or_region == "United Kingdom" ~ 2.8,    # Brexit normalization
      TRUE ~ 2.5
    ),
    implementation_quality = dplyr::case_when(
      symbol %in% c("INDA", "EWJ", "VWO", "EZA", "EWZ") ~ 4.0,  # Liquid ETFs
      symbol %in% c("SPY", "VEA") ~ 4.2,                          # Core benchmarks
      TRUE ~ 3.8
    ),
    risk_control = dplyr::case_when(
      category == "Benchmark" ~ 4.0,
      TRUE ~ 3.5
    )
  )

theme_assessment <- theme_universe |>
  dplyr::mutate(
    macro_tailwind = dplyr::case_when(
      theme == "Uranium and nuclear fuel" ~ 4.2,      # Energy security
      theme == "Copper miners" ~ 3.8,                 # China recovery, energy transition
      theme == "Electric grid infrastructure" ~ 4.0,  # Grid modernization
      theme == "Wind energy" ~ 3.5,                   # Structural growth
      theme == "Solar energy" ~ 3.5,                  # Structural growth
      theme == "U.S. aerospace and defense benchmark" ~ 3.7,
      TRUE ~ 2.8
    ),
    catalyst_strength = dplyr::case_when(
      theme == "Uranium and nuclear fuel" ~ 4.0,
      theme == "Electric grid infrastructure" ~ 3.8,
      theme == "Copper miners" ~ 3.6,
      theme == "U.S. aerospace and defense benchmark" ~ 3.5,
      TRUE ~ 3.0
    ),
    implementation_quality = 4.0,  # ETFs are liquid
    risk_control = 3.5
  )

cat("   ✓ Macro tailwinds assessed (country universe)\n")
cat("   ✓ Catalyst strength ranked (theme universe)\n\n")

# ---- Screen Countries ----

cat("5. Screening country ETFs...\n")

country_scores <- country_universe |>
  dplyr::left_join(valuation_proxy, by = "symbol") |>
  dplyr::left_join(
    macro_assessment |> dplyr::select(symbol, macro_tailwind, catalyst_strength, 
                                       implementation_quality, risk_control),
    by = "symbol"
  ) |>
  dplyr::mutate(
    valuation_score = valuation_composite * 5,  # Scale to 0-5
    macro_score = macro_tailwind,
    catalyst_score = catalyst_strength,
    impl_score = implementation_quality,
    risk_score_adj = risk_control
  ) |>
  calculate_conviction_score(
    valuation = valuation_score,
    macro_tailwind = macro_score,
    catalyst_strength = catalyst_score,
    risk_control = risk_score_adj,
    implementation_quality = impl_score
  ) |>
  dplyr::arrange(dplyr::desc(weighted_score))

cat("   Screened:", nrow(country_scores), "country ETFs\n")
cat("   Top conviction score:", round(max(country_scores$weighted_score, na.rm = TRUE), 2), "\n\n")

# ---- Screen Themes ----

cat("6. Screening theme ETFs...\n")

theme_scores <- theme_universe |>
  dplyr::left_join(valuation_proxy, by = "symbol") |>
  dplyr::left_join(
    theme_assessment |> dplyr::select(symbol, macro_tailwind, catalyst_strength,
                                       implementation_quality, risk_control),
    by = "symbol"
  ) |>
  dplyr::mutate(
    valuation_score = valuation_composite * 5,
    macro_score = macro_tailwind,
    catalyst_score = catalyst_strength,
    impl_score = implementation_quality,
    risk_score_adj = risk_control
  ) |>
  calculate_conviction_score(
    valuation = valuation_score,
    macro_tailwind = macro_score,
    catalyst_strength = catalyst_score,
    risk_control = risk_score_adj,
    implementation_quality = impl_score
  ) |>
  dplyr::arrange(dplyr::desc(weighted_score))

cat("   Screened:", nrow(theme_scores), "theme ETFs\n")
cat("   Top conviction score:", round(max(theme_scores$weighted_score, na.rm = TRUE), 2), "\n\n")

# ---- Generate Rankings ----

cat("7. Generating final rankings...\n")

top_countries <- rank_opportunities(country_scores, top_n = 15)
top_themes <- rank_opportunities(theme_scores, top_n = 10)

cat("   Top countries:\n")
print(top_countries |> dplyr::select(symbol, country_or_region, weighted_score, conviction_bucket))

cat("\n   Top themes:\n")
print(top_themes |> dplyr::select(symbol, theme, weighted_score, conviction_bucket))

cat("\n\n")

# ---- Save Results ----

cat("8. Saving screening results...\n")

write_processed_csv(country_scores, "country_opportunity_screen")
write_processed_csv(theme_scores, "theme_opportunity_screen")

cat("   ✓ Country screening results saved\n")
cat("   ✓ Theme screening results saved\n\n")

# ---- Conviction Breakdown ----

cat("9. Conviction distribution...\n")

country_conviction_dist <- country_scores |>
  dplyr::count(conviction_bucket) |>
  dplyr::arrange(dplyr::desc(n))

theme_conviction_dist <- theme_scores |>
  dplyr::count(conviction_bucket) |>
  dplyr::arrange(dplyr::desc(n))

cat("\n   Countries by conviction:\n")
print(country_conviction_dist)

cat("\n   Themes by conviction:\n")
print(theme_conviction_dist)

cat("\n")

# ---- Summary ----

cat("=== SCREENING COMPLETE ===\n")
cat("Country opportunities ranked:", nrow(country_scores), "\n")
cat("Theme opportunities ranked:", nrow(theme_scores), "\n")
cat("High/Attractive conviction countries:", 
    nrow(country_scores |> dplyr::filter(weighted_score >= 3.5)), "\n")
cat("High/Attractive conviction themes:", 
    nrow(theme_scores |> dplyr::filter(weighted_score >= 3.5)), "\n\n")

cat("Next steps:\n")
cat("• notebooks/global_market_dashboard.qmd (visualization)\n")
cat("• notebooks/country_deep_dive_template.qmd (detailed analysis)\n\n")

cat("Completed:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
