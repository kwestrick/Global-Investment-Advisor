# 07_evaluate_colombia_investments.R
# Detailed Colombia investment evaluation and allocation recommendation.
#
# Builds on 06_colombia_economic_snapshot.R by:
#   - Proposing a specific COP allocation across vetted vehicles
#   - Projecting 5-year income under bear / base / bull FX scenarios
#   - Comparing COP vehicles to the USD portfolio on a risk-adjusted basis
#   - Generating a ranked recommendation table
#
# Run from the project root:
#   source("scripts/07_evaluate_colombia_investments.R")
#
# Outputs:
#   data/processed/colombia_allocation_[DATE].csv      — proposed allocation
#   data/processed/colombia_income_forecast_[DATE].csv — 5-year income projection
#   outputs/charts/colombia_income_scenarios_[DATE].png
#   outputs/charts/colombia_yield_comparison_[DATE].png

cat("============================================================\n")
cat(" Colombia Investment Evaluation\n")
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
library(scales)

create_project_dirs()

today <- Sys.Date()
stamp <- format(today, "%Y-%m-%d")

# ---- Key assumptions (review and update quarterly) ---------------------------

ASSUMPTIONS <- list(
  # Current COP/USD (will be overridden by live fetch if available)
  cop_per_usd_fallback = 4000,

  # Colombia CPI inflation (annual %, from WDI or DANE)
  # Will be overridden by live fetch if available
  colombia_cpi_fallback = 5.5,

  # U.S. risk-free rate (approximate 6-month T-bill yield)
  usd_risk_free_pct = 5.3,

  # FX scenarios: annual COP appreciation vs USD (positive = COP strengthens)
  # Bear: COP depreciates 5%/yr (historical average trend is mild depreciation)
  # Base: COP roughly stable (Banrep inflation targeting improving credibility)
  # Bull: COP appreciates 3%/yr (commodity boom + capital inflows scenario)
  fx_scenarios = c(bear = -5, base = 0, bull = 3),

  # Total COP available for investment (bank accounts only; home is illiquid)
  # Start conservative: invest 2/3 of bank accounts now; keep 1/3 liquid
  total_cop_investable = 20000000,  # 20M COP (~$5,000 USD at 4000)

  # Monthly COP inflow (from peso-denominated income or transfers)
  # Adjust when USD flows are converted and deposited in COP accounts
  monthly_cop_inflow = 2000000  # 2M COP/month (~$500 USD)
)

# ---- 1. Get current market data ----------------------------------------------

cat("[ 1/4 ] Fetching current market data...\n")

cop_data <- tryCatch(
  fetch_cop_exchange_rate(start_date = today - 365, end_date = today),
  error = function(e) NULL
)

current_cop_usd <- if (!is.null(cop_data) && nrow(cop_data) > 0) {
  cat("  COP/USD (live):", round(dplyr::last(cop_data$cop_per_usd), 0), "\n")
  dplyr::last(cop_data$cop_per_usd)
} else {
  cat("  COP/USD (fallback):", ASSUMPTIONS$cop_per_usd_fallback, "\n")
  ASSUMPTIONS$cop_per_usd_fallback
}

macro_data <- tryCatch(
  fetch_colombia_macro(start_year = 2020, end_year = as.integer(format(today, "%Y"))),
  error = function(e) NULL
)

colombia_inflation <- if (!is.null(macro_data) && nrow(macro_data) > 0) {
  cpi <- macro_data |>
    dplyr::filter(grepl("CPI|Inflation", indicator_name)) |>
    dplyr::slice_max(date, n = 1) |>
    dplyr::pull(value)
  if (length(cpi) > 0) {
    cat("  Colombia CPI (WDI, latest):", round(cpi, 1), "%\n")
    cpi
  } else {
    cat("  Colombia CPI (fallback):", ASSUMPTIONS$colombia_cpi_fallback, "%\n")
    ASSUMPTIONS$colombia_cpi_fallback
  }
} else {
  cat("  Colombia CPI (fallback):", ASSUMPTIONS$colombia_cpi_fallback, "%\n")
  ASSUMPTIONS$colombia_cpi_fallback
}

cat("\n")

# ---- 2. Screen all vehicles --------------------------------------------------

cat("[ 2/4 ] Screening COP investment vehicles...\n\n")

screen <- screen_colombian_bonds(
  colombia_inflation_pct = colombia_inflation,
  usd_risk_free_pct      = ASSUMPTIONS$usd_risk_free_pct,
  fx_scenarios           = ASSUMPTIONS$fx_scenarios
)

# Print ranked table
cat("Vehicle ranking (base-case FX-adjusted real yield):\n\n")
print(
  screen |>
    dplyr::select(
      rank, vehicle_name, vehicle_type,
      nominal_yield_pct, real_yield_cop_pct,
      fx_adj_bear_pct, fx_adj_base_pct, fx_adj_bull_pct,
      beats_cop_inflation, beats_usd_risk_free,
      risk_level, liquidity
    ) |>
    dplyr::mutate(dplyr::across(where(is.numeric), ~ round(., 1))),
  n = Inf, width = 140
)
cat("\n")

# ---- 3. Proposed COP allocation ----------------------------------------------

cat("[ 3/4 ] Building proposed COP allocation...\n\n")

# Allocation philosophy:
#   - Prioritize government-guaranteed (CDT/savings) for low risk
#   - Include TES for higher yield with sovereign backing
#   - Keep 20% liquid in savings for emergencies / opportunities
#   - Avoid equity until COP bank accounts grow substantially

total_investable <- ASSUMPTIONS$total_cop_investable

proposed_allocation <- tibble::tribble(
  ~vehicle_id,      ~allocation_pct, ~rationale,
  "bbva_savings",   20,             "Emergency / opportunity liquidity; instant access",
  "bbva_cdt_360",   30,             "Best CDT rate; Fogafin insured; BBVA existing relationship",
  "bcol_cdt_360",   20,             "Diversify across two banks; both Fogafin insured",
  "tes_5y",         20,             "Sovereign bond; higher yield; liquid secondary market",
  "tes_10y",        10,             "Long-term hold for maximum yield; suits 20-30yr horizon"
) |>
  dplyr::left_join(
    screen |> dplyr::select(vehicle_id, vehicle_name, nominal_yield_pct,
                             real_yield_cop_pct, fx_adj_base_pct, risk_level, liquidity),
    by = "vehicle_id"
  ) |>
  dplyr::mutate(
    cop_amount    = round(total_investable * allocation_pct / 100, -4),
    usd_equivalent = round(cop_amount / current_cop_usd, 0),
    annual_income_cop = round(cop_amount * nominal_yield_pct / 100, 0),
    annual_income_usd = round(annual_income_cop / current_cop_usd, 0)
  )

cat("Proposed allocation of", format(total_investable, big.mark = ","), "COP:\n\n")
print(
  proposed_allocation |>
    dplyr::select(vehicle_name, allocation_pct, cop_amount, usd_equivalent,
                  nominal_yield_pct, annual_income_cop, annual_income_usd,
                  risk_level, rationale),
  n = Inf, width = 140
)

# Portfolio summary
cat("\nPortfolio summary:\n")
cat(sprintf("  Total invested (COP):      %s\n", format(sum(proposed_allocation$cop_amount), big.mark = ",")))
cat(sprintf("  Total invested (USD):      $%s\n", format(sum(proposed_allocation$usd_equivalent), big.mark = ",")))
cat(sprintf("  Blended nominal yield:     %.1f%%\n",
            weighted.mean(proposed_allocation$nominal_yield_pct, proposed_allocation$cop_amount)))
cat(sprintf("  Annual income (COP):       %s\n", format(sum(proposed_allocation$annual_income_cop), big.mark = ",")))
cat(sprintf("  Annual income (USD):       $%s\n", format(sum(proposed_allocation$annual_income_usd), big.mark = ",")))
cat("\n")

# Save allocation
alloc_path <- file.path("data/processed", paste0("colombia_allocation_", stamp, ".csv"))
readr::write_csv(proposed_allocation, alloc_path)
cat("  Saved:", alloc_path, "\n\n")

# ---- 4. 5-year income forecast -----------------------------------------------

cat("[ 4/4 ] Projecting 5-year income forecast...\n\n")

forecast <- generate_colombia_income_forecast(
  vehicle_ids            = proposed_allocation$vehicle_id,
  cop_amounts            = proposed_allocation$cop_amount,
  years                  = 5,
  current_cop_usd        = current_cop_usd,
  colombia_inflation_pct = colombia_inflation,
  fx_scenarios           = ASSUMPTIONS$fx_scenarios
)

# Annual totals by scenario
annual_totals <- forecast |>
  dplyr::group_by(scenario, year) |>
  dplyr::summarise(
    total_income_cop = sum(annual_income_cop),
    total_income_usd = sum(annual_income_usd),
    total_balance_cop = sum(balance_end_cop),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    cumulative_income_cop = ave(total_income_cop, scenario, FUN = cumsum),
    cumulative_income_usd = ave(total_income_usd, scenario, FUN = cumsum)
  )

cat("Annual income projection by scenario (USD equivalent):\n\n")
print(
  annual_totals |>
    dplyr::select(scenario, year, total_income_cop, total_income_usd,
                  cumulative_income_usd, total_balance_cop) |>
    dplyr::mutate(
      total_income_cop     = format(total_income_cop, big.mark = ","),
      total_income_usd     = paste0("$", format(total_income_usd, big.mark = ",")),
      cumulative_income_usd = paste0("$", format(cumulative_income_usd, big.mark = ",")),
      total_balance_cop    = format(total_balance_cop, big.mark = ",")
    ),
  n = Inf
)

# Save forecast
forecast_path <- file.path("data/processed", paste0("colombia_income_forecast_", stamp, ".csv"))
readr::write_csv(forecast, forecast_path)
cat("\n  Saved:", forecast_path, "\n\n")

# ---- 5. Charts ---------------------------------------------------------------

# Yield comparison chart
yield_chart <- screen |>
  dplyr::filter(vehicle_type %in% c("savings", "cdt", "government_bond")) |>
  tidyr::pivot_longer(
    cols      = c(nominal_yield_pct, real_yield_cop_pct, fx_adj_base_pct),
    names_to  = "yield_type",
    values_to = "yield_pct"
  ) |>
  dplyr::mutate(
    yield_label = dplyr::case_when(
      yield_type == "nominal_yield_pct"    ~ "Nominal Yield",
      yield_type == "real_yield_cop_pct"   ~ "Real Yield (net of CPI)",
      yield_type == "fx_adj_base_pct"      ~ "FX-Adjusted Real Yield (USD, base)"
    ),
    vehicle_short = stringr::str_remove(vehicle_name, " Colombia| 360 Days| Account| Days| Bond| -.*")
  ) |>
  ggplot(aes(x = forcats::fct_reorder(vehicle_short, yield_pct), y = yield_pct, fill = yield_label)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = ASSUMPTIONS$usd_risk_free_pct, linetype = "dashed",
             color = "gray40", linewidth = 0.6) +
  annotate("text", x = 1.5, y = ASSUMPTIONS$usd_risk_free_pct + 0.3,
           label = paste0("USD Risk-Free (", ASSUMPTIONS$usd_risk_free_pct, "%)"),
           size = 3, color = "gray40", hjust = 0) +
  scale_fill_manual(values = c(
    "Nominal Yield"                      = "#2c5f8a",
    "Real Yield (net of CPI)"            = "#4a9e7a",
    "FX-Adjusted Real Yield (USD, base)" = "#e8541c"
  )) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  coord_flip() +
  labs(
    title    = "COP Investment Vehicle Yields",
    subtitle = paste0("Colombia CPI: ", round(colombia_inflation, 1),
                      "% | USD risk-free: ", ASSUMPTIONS$usd_risk_free_pct,
                      "% | COP/USD: ", round(current_cop_usd, 0)),
    x        = NULL, y = "Annual Yield (%)",
    fill     = NULL,
    caption  = "Source: BVC, bank websites (approximate). Verify before investing."
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title   = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

yield_path <- file.path("outputs/charts", paste0("colombia_yield_comparison_", stamp, ".png"))
ggsave(yield_path, yield_chart, width = 10, height = 6, dpi = 150)
cat("  Chart saved:", yield_path, "\n")

# Income scenario chart
income_chart <- annual_totals |>
  dplyr::mutate(scenario = stringr::str_to_title(scenario)) |>
  ggplot(aes(x = year, y = cumulative_income_usd, color = scenario, group = scenario)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::dollar) +
  scale_color_manual(values = c(Bear = "#cc3333", Base = "#2c5f8a", Bull = "#4a9e7a")) +
  labs(
    title    = "Cumulative COP Investment Income (USD Equivalent)",
    subtitle = paste0("Starting investment: ", format(total_investable, big.mark = ","),
                      " COP (~$", format(round(total_investable / current_cop_usd), big.mark = ","),
                      " USD) | 5-Year projection"),
    x        = "Year",
    y        = "Cumulative Income (USD)",
    color    = "FX Scenario",
    caption  = "Bear: COP -5%/yr | Base: COP flat | Bull: COP +3%/yr vs USD"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title   = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

income_path <- file.path("outputs/charts", paste0("colombia_income_scenarios_", stamp, ".png"))
ggsave(income_path, income_chart, width = 10, height = 5, dpi = 150)
cat("  Chart saved:", income_path, "\n\n")

# ---- Final summary -----------------------------------------------------------

cat("============================================================\n")
cat(" COLOMBIA INVESTMENT RECOMMENDATION SUMMARY\n")
cat("============================================================\n\n")

blended_yield <- weighted.mean(proposed_allocation$nominal_yield_pct, proposed_allocation$cop_amount)
blended_real  <- weighted.mean(proposed_allocation$real_yield_cop_pct, proposed_allocation$cop_amount, na.rm = TRUE)

cat(sprintf("  Investable COP: %s (~$%s USD)\n",
            format(total_investable, big.mark = ","),
            format(round(total_investable / current_cop_usd), big.mark = ",")))
cat(sprintf("  Blended nominal yield: %.1f%%\n", blended_yield))
cat(sprintf("  Blended real yield (net of %.1f%% CPI): %.1f%%\n",
            colombia_inflation, blended_real))
cat(sprintf("  Estimated annual income: %s COP / $%s USD\n",
            format(sum(proposed_allocation$annual_income_cop), big.mark = ","),
            format(sum(proposed_allocation$annual_income_usd), big.mark = ",")))

cat("\n  5-Year cumulative income projections:\n")
purrr::walk(c("bear", "base", "bull"), function(s) {
  yr5 <- annual_totals |>
    dplyr::filter(scenario == s, year == 5) |>
    dplyr::pull(cumulative_income_usd)
  cat(sprintf("    %-5s scenario: $%s USD\n", stringr::str_to_title(s),
              format(yr5, big.mark = ",")))
})

cat("\n  Key investment thesis:\n")
cat("  + COP vehicles yield 10-11.5% nominal vs ~5.3% USD risk-free\n")
cat("  + Real yields (net of Colombian CPI) are 5-6% — strong positive\n")
cat("  + CDTs are Fogafin-insured (equivalent to FDIC) up to 50M COP\n")
cat("  + TES bonds provide government-backed yield with BVC liquidity\n")
cat("  + FX risk is real: COP has historically depreciated vs USD\n")
cat("  + Hedge rationale: as Colombian resident, COP income offsets\n")
cat("    daily living expenses without USD/COP conversion friction\n")

cat("\n  What to watch (falsification triggers):\n")
cat("  - Colombia sovereign downgrade below BB (Moody's/S&P)\n")
cat("  - Banrep policy rate cut below 7% (compresses CDT/TES yields)\n")
cat("  - COP depreciates >10% in a single year (increases real FX cost)\n")
cat("  - Colombia CPI re-accelerates above 8% (erodes real yields)\n")
cat("  - Political risk spike (Fragile States Index deterioration)\n")

cat("\n============================================================\n")
cat("NOTE: Rates are approximate. Verify current rates before investing.\n")
cat("CDT rates: BBVA / Bancolombia websites or branch.\n")
cat("TES yields: bvc.com.co or broker (Valores Bancolombia, Corficolombiana).\n")
cat("Disclaimer: Research only. Not personalized financial advice.\n")
cat("============================================================\n")
