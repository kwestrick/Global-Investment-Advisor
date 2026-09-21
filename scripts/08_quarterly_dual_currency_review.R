# 08_quarterly_dual_currency_review.R
# Quarterly dual-currency portfolio review: USD (Banktivity) + COP (Colombia).
#
# Run this every quarter (January, April, July, October) to review the full
# combined balance sheet, currency exposure vs. target, and contribution guidance.
#
# Prerequisites:
#   - Fresh Banktivity QIF export at data/raw/accounts_*.qif
#   - FRED_API_KEY environment variable (optional; only needed for indicators script)
#
# Usage:
#   source("scripts/08_quarterly_dual_currency_review.R")
#
# Outputs (timestamped, data/processed/ and outputs/charts/):
#   - dual_currency_net_worth.csv
#   - currency_exposure.csv
#   - dual_currency_projection.csv
#   - cop_rate_trend.png (COP/USD 3-year)
#   - dual_currency_projection.png (5-year scenario chart)
#
# Part of Phase 3, Part 3 — Global Investment Advisor
# Author: Global Investment Advisor / Posit Assistant
# Last updated: 2026-09-21

# ==============================================================================
# 0. SETUP
# ==============================================================================

source("R/00_setup.R")
source("R/data_import.R")
source("R/personal_wealth_monitoring.R")
source("R/colombia_indicators.R")

library(tidyverse)
library(tidyquant)

today_stamp <- format(Sys.Date(), "%Y-%m-%d")
cat("\n")
cat("=================================================================\n")
cat(" QUARTERLY DUAL-CURRENCY PORTFOLIO REVIEW\n")
cat(" Date:", today_stamp, "\n")
cat("=================================================================\n\n")


# ==============================================================================
# 1. LOAD USD ACCOUNTS (Banktivity QIF)
# ==============================================================================

cat("--- Step 1: USD Accounts (Banktivity QIF) ---\n")

qif_files <- list.files("data/raw", pattern = "\\.qif$", full.names = TRUE)

if (length(qif_files) == 0) {
  stop(
    "No QIF file found in data/raw/. ",
    "Export your accounts from Banktivity and save to data/raw/."
  )
}

qif_path <- qif_files[length(qif_files)]  # use most recent
cat("Loading QIF:", qif_path, "\n")

accounts_df <- import_qif_accounts(qif_path)
nw          <- calculate_net_worth(accounts_df)

cat("Accounts loaded:", nrow(accounts_df), "accounts\n")
cat("USD Net Worth: $", format(round(nw$net_worth), big.mark = ","), "\n\n", sep = "")


# ==============================================================================
# 2. LIVE COP/USD EXCHANGE RATE
# ==============================================================================

cat("--- Step 2: COP/USD Exchange Rate ---\n")

cop_data <- fetch_cop_exchange_rate(start_date = Sys.Date() - 3 * 365)

if (is.null(cop_data) || nrow(cop_data) == 0) {
  warning("COP/USD data unavailable — using fallback rate of 4,000 COP/USD.")
  cop_per_usd <- 4000
  cop_as_of   <- Sys.Date()
} else {
  cop_per_usd <- dplyr::last(cop_data$cop_per_usd)
  cop_as_of   <- dplyr::last(cop_data$date)
  fx_risk     <- assess_currency_risk(cop_data)

  cat("Current COP/USD:", round(cop_per_usd, 0), "as of", as.character(cop_as_of), "\n")
  cat(fx_risk$summary, "\n\n")
}


# ==============================================================================
# 3. DUAL-CURRENCY BALANCE SHEET
# ==============================================================================

cat("--- Step 3: Dual-Currency Balance Sheet ---\n")

# Inputs: update quarterly if Colombian asset values change
cop_home_value   <- 1200000000   # ~1.2 billion COP (approximate appraisal)
cop_bank_balance <- 30000000     # BBVA ~15M + Bancolombia ~15M COP
cop_investments  <- 0            # COP already deployed into TES/CDTs/COLCAP

dual_nw <- calculate_dual_currency_net_worth(
  usd_accounts_df  = accounts_df,
  cop_home_value   = cop_home_value,
  cop_bank_balance = cop_bank_balance,
  cop_investments  = cop_investments,
  cop_per_usd      = cop_per_usd
)

# Print balance sheet
cat("\nDUAL-CURRENCY BALANCE SHEET (as of", today_stamp, "):\n")
cat(strrep("-", 75), "\n")
display_nw <- dual_nw |>
  dplyr::mutate(
    cop_value_m    = round(cop_value / 1e6, 2),
    usd_value_k    = round(usd_value / 1000, 1)
  ) |>
  dplyr::select(asset_class, currency, cop_value_m, usd_value_k, is_liquid, is_investable)

print(display_nw, n = Inf)
cat("(COP values in millions; USD values in thousands)\n\n")

# Total net worth in USD
combined_net_worth <- dual_nw |>
  dplyr::filter(asset_class == "TOTAL NET WORTH") |>
  dplyr::pull(usd_value)

cat("COMBINED NET WORTH (USD equivalent): $",
    format(round(combined_net_worth), big.mark = ","), "\n\n", sep = "")


# ==============================================================================
# 4. CURRENCY EXPOSURE ANALYSIS
# ==============================================================================

cat("--- Step 4: Currency Exposure vs. Target ---\n")

# Target: 80% USD / 20% COP (investable assets only)
exposure <- calculate_currency_exposure(
  dual_nw_df              = dual_nw,
  target_usd_pct          = 80,
  rebalance_threshold_pct = 5
)

cat("Total investable (USD + COP in USD): $",
    format(exposure$total_investable, big.mark = ","), "\n", sep = "")
cat("  USD investable: $", format(exposure$usd_investable, big.mark = ","),
    " (", exposure$current_usd_pct, "%)\n", sep = "")
cat("  COP investable: $", format(exposure$cop_investable_usd, big.mark = ","),
    " (", exposure$current_cop_pct, "%)\n", sep = "")
cat("  Target: ", exposure$target_usd_pct, "% USD / ",
    exposure$target_cop_pct, "% COP\n", sep = "")
cat("  USD drift: ", exposure$usd_drift_pct, "pp\n", sep = "")
cat("  Action:", exposure$action, "\n\n")


# ==============================================================================
# 5. CONTRIBUTION GUIDANCE
# ==============================================================================

cat("--- Step 5: Monthly Contribution Guidance ---\n")

rebalance <- assess_fx_rebalancing_need(
  exposure                = exposure,
  monthly_usd_surplus     = 5200,
  monthly_cop_surplus_cop = 2000000,  # target: 2M COP/month from COP investments
  cop_per_usd             = cop_per_usd
)

cat(rebalance$narrative, "\n")
cat("  Invest this month:\n")
cat("    USD assets: $", format(rebalance$recommended_usd_invest, big.mark = ","), "\n", sep = "")
cat("    COP assets:", format(round(rebalance$recommended_cop_invest_cop / 1e6, 1), nsmall = 1),
    "M COP\n")
if (rebalance$months_to_target > 0) {
  cat("  Months to reach target:", rebalance$months_to_target, "\n")
}
cat("\n")


# ==============================================================================
# 6. COLOMBIA MACRO + BOND SCREEN
# ==============================================================================

cat("--- Step 6: Colombia Investment Universe ---\n")

colombia_macro <- tryCatch(
  fetch_colombia_macro(start_year = 2018),
  error = function(e) { warning("Colombia WDI fetch failed: ", e$message); NULL }
)

# Extract latest CPI for yield calculations
cop_inflation <- if (!is.null(colombia_macro)) {
  colombia_macro |>
    dplyr::filter(indicator_code == "FP.CPI.TOTL.ZG") |>
    dplyr::slice_max(date, n = 1) |>
    dplyr::pull(value)
} else 5.5

cat("Colombia CPI (latest WDI):", round(cop_inflation, 1), "%\n")

bond_screen <- screen_colombian_bonds(
  colombia_inflation_pct = cop_inflation,
  usd_risk_free_pct      = 5.3,
  fx_scenarios           = c(bear = -5, base = 0, bull = 3)
)

cat("\nTOP 5 COP VEHICLES (by base-case FX-adjusted real yield):\n")
print(
  bond_screen |>
    dplyr::slice_head(n = 5) |>
    dplyr::select(rank, vehicle_name, nominal_yield_pct, real_yield_cop_pct,
                  fx_adj_bear_pct, fx_adj_base_pct, fx_adj_bull_pct,
                  risk_level, beats_usd_risk_free) |>
    dplyr::mutate(dplyr::across(dplyr::where(is.numeric), ~ round(., 1))),
  n = Inf
)
cat("\n")


# ==============================================================================
# 7. 5-YEAR DUAL-CURRENCY PROJECTION
# ==============================================================================

cat("--- Step 7: 5-Year Dual-Currency Growth Projection ---\n")

# COP investable = bank accounts only (home is illiquid)
cop_investable_cop <- cop_bank_balance + cop_investments

projection <- project_dual_currency_growth(
  usd_investable            = exposure$usd_investable,
  cop_investable_cop        = cop_investable_cop,
  usd_monthly_contribution  = 5200,
  cop_monthly_income_cop    = 2000000,
  usd_annual_return         = 0.075,
  cop_nominal_yield         = 0.105,
  years                     = 5,
  current_cop_per_usd       = cop_per_usd,
  fx_scenarios              = c(bear = -5, base = 0, bull = 3)
)

cat("\n5-YEAR COMBINED NET WORTH PROJECTION (USD equivalent, $000s):\n")
print(
  projection |>
    dplyr::select(year, scenario, usd_portfolio, cop_portfolio_usd, combined_net_worth_usd) |>
    dplyr::filter(year %in% c(0, 1, 2, 3, 4, 5)) |>
    dplyr::mutate(dplyr::across(dplyr::where(is.numeric), ~ round(. / 1000, 0))),
  n = Inf
)
cat("(values in $thousands USD)\n\n")


# ==============================================================================
# 8. CHARTS
# ==============================================================================

cat("--- Step 8: Generating Charts ---\n")

# Chart A: COP/USD 3-year trend
if (!is.null(cop_data) && nrow(cop_data) > 0) {
  p_cop <- cop_data |>
    dplyr::filter(date >= Sys.Date() - 3 * 365) |>
    ggplot2::ggplot(ggplot2::aes(x = date, y = cop_per_usd)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_hline(yintercept = cop_per_usd, linetype = "dashed", color = "steelblue") +
    ggplot2::labs(
      title    = "COP/USD Exchange Rate — 3 Years",
      subtitle = paste0("Current: ", round(cop_per_usd, 0), " COP per USD as of ", cop_as_of),
      x        = NULL,
      y        = "COP per 1 USD",
      caption  = "Source: Yahoo Finance (COP=X). Higher = weaker peso."
    ) +
    ggplot2::scale_y_continuous(labels = scales::comma) +
    ggplot2::theme_minimal()

  chart_path_a <- file.path("outputs", "charts",
                             paste0(today_stamp, "_cop_usd_trend.png"))
  ggplot2::ggsave(chart_path_a, p_cop, width = 10, height = 5, dpi = 150)
  cat("  Saved:", chart_path_a, "\n")
}

# Chart B: 5-year dual-currency projection
p_proj <- projection |>
  dplyr::mutate(combined_k = combined_net_worth_usd / 1000) |>
  ggplot2::ggplot(ggplot2::aes(x = year, y = combined_k, color = scenario, group = scenario)) +
  ggplot2::geom_line(linewidth = 1) +
  ggplot2::geom_point(size = 2) +
  ggplot2::scale_color_manual(values = c(bear = "#d62728", base = "#1f77b4", bull = "#2ca02c")) +
  ggplot2::labs(
    title    = "5-Year Dual-Currency Net Worth Projection",
    subtitle = paste0(
      "USD: 7.5% return, $5,200/month | COP: 10.5% yield, 2M COP/month | ",
      "FX scenarios: bear −5%, base flat, bull +3% COP appreciation"
    ),
    x     = "Year",
    y     = "Combined Net Worth (USD $thousands)",
    color = "FX Scenario",
    caption = "Investable assets only. Home (~1.2B COP) excluded from projection."
  ) +
  ggplot2::scale_x_continuous(breaks = 0:5) +
  ggplot2::scale_y_continuous(labels = scales::comma) +
  ggplot2::theme_minimal()

chart_path_b <- file.path("outputs", "charts",
                           paste0(today_stamp, "_dual_currency_projection.png"))
ggplot2::ggsave(chart_path_b, p_proj, width = 10, height = 5, dpi = 150)
cat("  Saved:", chart_path_b, "\n\n")


# ==============================================================================
# 9. EXPORT CSVs
# ==============================================================================

cat("--- Step 9: Exporting Data ---\n")

write_csv_stamped <- function(df, label) {
  path <- file.path("data", "processed",
                    paste0(today_stamp, "_", label, ".csv"))
  readr::write_csv(df, path)
  cat("  Saved:", path, "\n")
  invisible(path)
}

write_csv_stamped(dual_nw, "dual_currency_net_worth")

write_csv_stamped(
  tibble::tibble(
    as_of               = today_stamp,
    usd_investable      = exposure$usd_investable,
    cop_investable_usd  = exposure$cop_investable_usd,
    total_investable    = exposure$total_investable,
    current_usd_pct     = exposure$current_usd_pct,
    current_cop_pct     = exposure$current_cop_pct,
    target_usd_pct      = exposure$target_usd_pct,
    target_cop_pct      = exposure$target_cop_pct,
    usd_drift_pct       = exposure$usd_drift_pct,
    action_needed       = exposure$action_needed,
    action              = exposure$action
  ),
  "currency_exposure"
)

write_csv_stamped(projection, "dual_currency_projection")

cat("\n")


# ==============================================================================
# 10. DASHBOARD SUMMARY
# ==============================================================================

cat("=================================================================\n")
cat(" QUARTERLY DUAL-CURRENCY REVIEW SUMMARY\n")
cat("=================================================================\n")
cat("Date:", today_stamp, "\n\n")

cat("COMBINED NET WORTH:\n")
cat("  USD Portfolio:        $", format(round(exposure$usd_investable), big.mark = ","), " (investable)\n", sep = "")
cat("  COP Portfolio:        $", format(round(exposure$cop_investable_usd), big.mark = ","), " USD-equivalent\n", sep = "")
cat("  COP Home (illiquid):  $", format(round(cop_home_value / cop_per_usd), big.mark = ","), " USD-equivalent\n", sep = "")
cat("  COP/USD rate:         ", round(cop_per_usd, 0), "\n\n", sep = "")

cat("CURRENCY EXPOSURE:\n")
cat("  Current: ", exposure$current_usd_pct, "% USD / ", exposure$current_cop_pct, "% COP\n", sep = "")
cat("  Target:  ", exposure$target_usd_pct, "% USD / ", exposure$target_cop_pct, "% COP\n", sep = "")
cat("  Action:  ", exposure$action, "\n\n", sep = "")

cat("THIS MONTH'S CONTRIBUTIONS:\n")
cat("  USD assets: $", format(rebalance$recommended_usd_invest, big.mark = ","), "\n", sep = "")
cat("  COP assets: ", format(round(rebalance$recommended_cop_invest_cop / 1e6, 1), nsmall = 1),
    "M COP\n\n", sep = "")

cat("TOP COP OPPORTUNITY (base-case FX-adjusted real yield):\n")
top_vehicle <- bond_screen |> dplyr::slice_head(n = 1)
cat("  ", top_vehicle$vehicle_name, ": ",
    round(top_vehicle$nominal_yield_pct, 1), "% nominal → ",
    round(top_vehicle$fx_adj_base_pct, 1), "% FX-adjusted real\n\n", sep = "")

cat("5-YEAR PROJECTION (investable assets, base case):\n")
base_end <- projection |>
  dplyr::filter(scenario == "base", year == 5) |>
  dplyr::pull(combined_net_worth_usd)
cat("  Base case total: $", format(round(base_end), big.mark = ","), " USD\n\n", sep = "")

cat("=================================================================\n")
cat("This is research only, not personalized financial advice.\n")
cat("Consult a qualified financial advisor before investing.\n")
cat("=================================================================\n\n")
