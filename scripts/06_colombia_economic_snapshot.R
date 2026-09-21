# 06_colombia_economic_snapshot.R
# Colombia economic and investment snapshot dashboard.
#
# Produces a concise current-state view of:
#   - COP/USD exchange rate (trend, volatility, YTD change)
#   - Colombia macro fundamentals (GDP growth, CPI, unemployment, current account)
#   - COP investment vehicle ranking by real and FX-adjusted yield
#   - User's Colombian asset summary in USD equivalent
#
# Run from the project root:
#   source("scripts/06_colombia_economic_snapshot.R")
#
# Outputs:
#   data/processed/colombia_snapshot_[DATE].csv   — macro indicators
#   data/processed/colombia_cop_rate_[DATE].csv   — COP/USD daily series
#   data/processed/colombia_bond_screen_[DATE].csv — vehicle ranking
#   outputs/charts/colombia_cop_usd_[DATE].png    — COP/USD chart

cat("============================================================\n")
cat(" Colombia Economic Snapshot\n")
cat(" Run date:", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "\n")
cat("============================================================\n\n")

# ---- 0. Setup ----------------------------------------------------------------

source("R/00_setup.R")
source("R/economic_indicators.R")
source("R/colombia_indicators.R")

library(tidyverse)
library(tidyquant)
library(WDI)
library(janitor)
library(ggplot2)

create_project_dirs()

today <- Sys.Date()
stamp <- format(today, "%Y-%m-%d")

# ---- User's Colombian assets (update these values manually) ------------------
# These are approximate current values based on user context.
# Update with actual account balances before each quarterly review.

USER_COP_ASSETS <- list(
  home_cop         = 1200000000,  # ~1.2 billion COP (home in Colombia)
  bbva_cop         = 15000000,    # ~15 million COP (BBVA account)
  bancolombia_cop  = 15000000,    # ~15 million COP (Bancolombia account)
  total_bank_cop   = 30000000     # Total bank accounts
)

# ---- 1. COP/USD Exchange Rate ------------------------------------------------

cat("[ 1/5 ] Fetching COP/USD exchange rate...\n")

cop_data <- fetch_cop_exchange_rate(
  start_date = today - 5 * 365,
  end_date   = today
)

if (!is.null(cop_data)) {
  current_cop_usd <- dplyr::last(cop_data$cop_per_usd)
  risk_metrics    <- assess_currency_risk(cop_data)

  cat("  Current rate: ", round(current_cop_usd, 0), " COP per 1 USD\n")
  cat("  YTD change:  ", round(risk_metrics$ytd_change_pct, 1), "%",
      ifelse(risk_metrics$cop_weakened_ytd, " (COP weakened)\n", " (COP strengthened)\n"))
  cat("  1-year change:", round(risk_metrics$one_year_change_pct, 1), "%\n")
  cat("  Annualized volatility:", risk_metrics$annualized_vol_pct, "%\n\n")

  # Save COP/USD data
  cop_path <- file.path("data/processed", paste0("colombia_cop_rate_", stamp, ".csv"))
  readr::write_csv(cop_data, cop_path)
  cat("  Saved:", cop_path, "\n\n")
} else {
  cat("  WARNING: COP/USD data unavailable. Using fallback rate of 4,000.\n\n")
  current_cop_usd <- 4000
}

# ---- 2. User's Colombian assets in USD ---------------------------------------

cat("[ 2/5 ] User's Colombian assets at current COP/USD rate...\n")

cop_assets_usd <- tibble::tibble(
  asset           = c("Home (Colombia)", "BBVA Bank Account", "Bancolombia Bank Account", "Total Bank Accounts", "Total Colombian Assets"),
  value_cop       = c(
    USER_COP_ASSETS$home_cop,
    USER_COP_ASSETS$bbva_cop,
    USER_COP_ASSETS$bancolombia_cop,
    USER_COP_ASSETS$total_bank_cop,
    USER_COP_ASSETS$home_cop + USER_COP_ASSETS$total_bank_cop
  ),
  value_usd       = round(value_cop / current_cop_usd, 0),
  cop_per_usd     = current_cop_usd,
  as_of_date      = today
)

cat("  COP/USD rate used:", round(current_cop_usd, 0), "\n")
print(cop_assets_usd |> dplyr::select(asset, value_cop, value_usd))
cat("\n")

# ---- 3. Colombia macro indicators --------------------------------------------

cat("[ 3/5 ] Fetching Colombia macro data from World Bank WDI...\n")

macro_data <- fetch_colombia_macro(start_year = 2015, end_year = as.integer(format(today, "%Y")))

if (!is.null(macro_data)) {
  latest_macro <- macro_data |>
    dplyr::group_by(indicator_name) |>
    dplyr::slice_max(date, n = 1) |>
    dplyr::ungroup()

  cat("  Latest available Colombia macro indicators:\n\n")
  print(
    latest_macro |>
      dplyr::select(indicator_name, value, unit, date) |>
      dplyr::mutate(value = round(value, 2)),
    n = Inf
  )
  cat("\n")

  # Extract key rates for downstream calculations
  latest_cpi <- latest_macro |>
    dplyr::filter(grepl("CPI|Inflation", indicator_name)) |>
    dplyr::pull(value)

  colombia_inflation <- if (length(latest_cpi) > 0) {
    cat("  Using Colombia CPI for real yield calculation:", round(latest_cpi, 1), "%\n")
    latest_cpi
  } else {
    cat("  WARNING: CPI not available from WDI. Using default: 5.5%\n")
    5.5
  }

  macro_path <- file.path("data/processed", paste0("colombia_snapshot_", stamp, ".csv"))
  readr::write_csv(macro_data, macro_path)
  cat("  Saved:", macro_path, "\n\n")
} else {
  cat("  WARNING: Macro data unavailable. Using default Colombia CPI: 5.5%\n\n")
  colombia_inflation <- 5.5
}

# ---- 4. COLCAP index ---------------------------------------------------------

cat("[ 4/5 ] Fetching COLCAP index...\n")

colcap_data <- fetch_colcap_data(start_date = today - 5 * 365, end_date = today)

if (!is.null(colcap_data) && nrow(colcap_data) > 0) {
  current_colcap <- dplyr::last(colcap_data$colcap_close)
  colcap_1yr_ago <- colcap_data |>
    dplyr::filter(date <= today - 365) |>
    dplyr::arrange(dplyr::desc(date)) |>
    dplyr::slice_head(n = 1) |>
    dplyr::pull(colcap_close)

  colcap_1yr_return <- if (length(colcap_1yr_ago) > 0) {
    (current_colcap / colcap_1yr_ago - 1) * 100
  } else NA_real_

  cat("  Current COLCAP:", round(current_colcap, 0), "\n")
  cat("  1-Year return (COP terms):", round(colcap_1yr_return, 1), "%\n\n")
} else {
  cat("  WARNING: COLCAP data unavailable.\n\n")
}

# ---- 5. Investment vehicle screening -----------------------------------------

cat("[ 5/5 ] Screening COP investment vehicles...\n\n")

# Current U.S. risk-free rate (update manually or fetch from FRED)
# Using approximate 6-month T-bill yield as of Sep 2026
usd_risk_free <- 5.3

screen_results <- screen_colombian_bonds(
  colombia_inflation_pct = colombia_inflation,
  usd_risk_free_pct      = usd_risk_free,
  fx_scenarios           = c(bear = -5, base = 0, bull = 3)
)

# Save screen results
screen_path <- file.path("data/processed", paste0("colombia_bond_screen_", stamp, ".csv"))
readr::write_csv(screen_results, screen_path)
cat("  Saved:", screen_path, "\n\n")

# Print full snapshot
print_colombia_snapshot(
  cop_data       = cop_data,
  macro_data     = macro_data,
  screen_results = screen_results
)

# ---- 6. COP/USD chart --------------------------------------------------------

if (!is.null(cop_data) && nrow(cop_data) > 0) {
  cop_chart <- cop_data |>
    dplyr::filter(date >= today - 3 * 365) |>
    ggplot(aes(x = date, y = cop_per_usd)) +
    geom_line(color = "#2c5f8a", linewidth = 0.7) +
    geom_smooth(method = "loess", span = 0.3, se = FALSE,
                color = "#e8541c", linewidth = 0.5, linetype = "dashed") +
    scale_y_continuous(labels = scales::comma) +
    labs(
      title    = "COP/USD Exchange Rate (3-Year History)",
      subtitle = paste0("As of ", today, " — higher = more COP per USD = weaker peso"),
      x        = NULL,
      y        = "COP per 1 USD",
      caption  = "Source: Yahoo Finance (COP=X)"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title    = element_text(face = "bold"),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank()
    )

  chart_path <- file.path("outputs/charts", paste0("colombia_cop_usd_", stamp, ".png"))
  ggsave(chart_path, cop_chart, width = 10, height = 5, dpi = 150)
  cat("Chart saved:", chart_path, "\n")
}

# ---- 7. User asset summary in context ----------------------------------------

cat("\n--- User's Colombian Assets (summary) ---\n")
total_cop <- USER_COP_ASSETS$home_cop + USER_COP_ASSETS$total_bank_cop
total_usd <- round(total_cop / current_cop_usd, 0)
bank_usd  <- round(USER_COP_ASSETS$total_bank_cop / current_cop_usd, 0)

cat(sprintf("  Total Colombian assets: %s COP (~$%s USD at %s COP/USD)\n",
            format(total_cop, big.mark = ","),
            format(total_usd, big.mark = ","),
            format(round(current_cop_usd, 0), big.mark = ",")))
cat(sprintf("  Bank accounts (investable): %s COP (~$%s USD)\n",
            format(USER_COP_ASSETS$total_bank_cop, big.mark = ","),
            format(bank_usd, big.mark = ",")))

cat("\nNext step: source('scripts/07_evaluate_colombia_investments.R')\n")
cat("           to generate a detailed investment allocation recommendation.\n")
