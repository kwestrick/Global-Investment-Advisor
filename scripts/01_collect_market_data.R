# 01_collect_market_data.R
# Collect market and macro data for Global Investment Advisor
# Integrates price history with Global-Insights-Dashboard macro indicators

# ---- Setup ----
source("R/00_setup.R")
install_missing_packages()
load_required_packages()
create_project_dirs()

source("R/data_import.R")
source("R/screening.R")
source("R/indicators.R")

cat("\n=== MARKET DATA COLLECTION WORKFLOW ===\n")
cat("Started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# ---- Build Investable Universe ----

cat("1. Building investable universe...\n")

country_universe <- create_country_etf_universe()
theme_universe <- create_theme_etf_universe()

all_tickers <- c(
  country_universe$symbol,
  theme_universe$symbol
) |>
  unique()

cat("   Country ETFs:", nrow(country_universe), "\n")
cat("   Theme ETFs:", nrow(theme_universe), "\n")
cat("   Total tickers:", length(all_tickers), "\n\n")

# ---- Collect Market Price Data ----

cat("2. Downloading market price data...\n")
cat("   From:", analysis_defaults$start_date, "to", Sys.Date(), "\n")

prices <- get_market_prices(
  tickers = all_tickers,
  from = analysis_defaults$start_date,
  to = Sys.Date()
)

cat("   Downloaded:", nrow(prices), "observations\n")
cat("   Coverage:", n_distinct(prices$symbol), "unique tickers\n")
cat("   Date range:", min(prices$date), "to", max(prices$date), "\n\n")

# ---- Calculate Returns ----

cat("3. Calculating return metrics...\n")

returns <- get_adjusted_returns(prices)
monthly_returns <- get_monthly_returns(prices)

cat("   Daily returns calculated\n")
cat("   Monthly returns calculated\n\n")

# ---- Load Macro Data from GID ----

cat("4. Loading macro data from Global-Insights-Dashboard...\n")

gid_path <- "/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Insights-Dashboard"
indicators_long <- readRDS(file.path(gid_path, "data/indicators_long.rds"))
latest_snapshot <- readRDS(file.path(gid_path, "data/latest_snapshot.rds"))

# Focus on key countries and macro categories
key_geos <- c("US", "JP", "GB", "DE", "BR", "CN", "IN", "EA19", "WORLD")
key_categories <- c(
  "growth_output",
  "inflation",
  "monetary_financial",
  "commodities_energy",
  "labor",
  "markets",
  "international_geopolitical"
)

macro_data <- indicators_long |>
  dplyr::filter(
    geography %in% key_geos,
    category %in% key_categories
  ) |>
  dplyr::arrange(geography, category, id, date)

cat("   Indicators loaded:", nrow(indicators_long), "total observations\n")
cat("   Filtered to key geographies:", nrow(macro_data), "observations\n")
cat("   Geographies:", paste(sort(unique(macro_data$geography)), collapse = ", "), "\n")
cat("   Categories:", length(unique(macro_data$category)), "categories\n\n")

# ---- Save Universe Definitions ----

cat("5. Saving universe definitions...\n")

readr::write_csv(
  country_universe,
  file.path("data/external", paste0("country_etf_universe_", today_stamp(), ".csv"))
)

readr::write_csv(
  theme_universe,
  file.path("data/external", paste0("theme_etf_universe_", today_stamp(), ".csv"))
)

cat("   Saved country ETF universe\n")
cat("   Saved theme ETF universe\n\n")

# ---- Save Market Data ----

cat("6. Saving market data...\n")

write_processed_csv(prices, "market_prices")
write_processed_csv(returns, "daily_returns")
write_processed_csv(monthly_returns, "monthly_returns")

cat("   Saved market prices\n")
cat("   Saved daily returns\n")
cat("   Saved monthly returns\n\n")

# ---- Save Macro Data ----

cat("7. Saving macro data...\n")

write_processed_csv(macro_data, "macro_data_gid")

cat("   Saved macro indicators (GID)\n\n")

# ---- Data Quality Checks ----

cat("8. Data quality checks...\n\n")

# Price completeness by ticker
price_health <- prices |>
  dplyr::group_by(symbol) |>
  dplyr::summarise(
    n_obs = n(),
    first_date = min(date),
    last_date = max(date),
    n_missing = sum(is.na(adjusted)),
    .groups = "drop"
  ) |>
  dplyr::arrange(n_obs)

incomplete_tickers <- price_health |>
  dplyr::filter(n_obs < 2000)

if (nrow(incomplete_tickers) > 0) {
  cat("   WARNING: Tickers with < 2000 observations:\n")
  print(incomplete_tickers)
  cat("\n")
} else {
  cat("   ✓ All tickers have >= 2000 observations\n")
}

missing_tickers <- price_health |>
  dplyr::filter(n_missing > 0)

if (nrow(missing_tickers) > 0) {
  cat("   WARNING: Tickers with missing values:\n")
  print(missing_tickers)
  cat("\n")
} else {
  cat("   ✓ No missing price values\n")
}

# Return summary
return_summary <- calculate_return_summary(returns)
cat("\n   Return statistics (annual, all tickers):\n")
cat("   Median annual return:", 
    round(median(return_summary$annualized_return, na.rm = TRUE) * 100, 2), "%\n")
cat("   Median annual volatility:", 
    round(median(return_summary$annualized_volatility, na.rm = TRUE) * 100, 2), "%\n\n")

# ---- Session Summary ----

cat("=== WORKFLOW SUMMARY ===\n")
cat("Market data:", nrow(prices), "price observations,", 
    n_distinct(prices$symbol), "tickers\n")
cat("Macro data:", nrow(macro_data), "indicator observations,", 
    n_distinct(macro_data$id), "unique indicators\n")
cat("Coverage:", min(prices$date), "to", max(prices$date), "\n\n")

cat("Next steps:\n")
cat("• Run: 02_screen_global_assets.R\n")
cat("• Notebook: notebooks/global_market_dashboard.qmd\n\n")

cat("Completed:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
