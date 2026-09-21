# scripts/10_rebuild_investment_plan_tables.R
# ==============================================================================
# Purpose:  Rebuild key investment plan analytical tables with live market data.
#           Run at each quarterly review or whenever plan assumptions need
#           refreshing after COP/USD or interest rate moves.
#
# Outputs (outputs/tables/):
#   {date}_sources_uses.csv
#   {date}_cop_reserve_targets.csv
#   {date}_cdt_breakeven.csv
#   {date}_balance_sheet_stress.csv
#   {date}_reserve_runway.csv
#
# Usage: source("scripts/10_rebuild_investment_plan_tables.R")
# Prereqs: FRED_API_KEY set in .Renviron for CPI fetch
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(scales)
})

source("R/economic_indicators.R")

today_str  <- format(Sys.Date(), "%Y-%m-%d")
output_dir <- "outputs/tables"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("======================================================\n")
cat("Investment Plan Table Rebuild —", today_str, "\n")
cat("======================================================\n\n")


# ==============================================================================
# 1. LIVE DATA
# ==============================================================================

cat("--- Fetching live data ---\n")

# COP/USD from Yahoo Finance
cop_usd_live <- tryCatch({
  fx <- fetch_yahoo_fx()
  rate <- fx |>
    filter(series_id == "COP=X") |>
    filter(date == max(date)) |>
    pull(value)
  if (length(rate) == 0) stop("No COP/USD data returned")
  round(rate, 0)
}, error = function(e) {
  warning("COP/USD fetch failed (", e$message, "). Using fallback 3,200.")
  3200
})
cat(sprintf("COP/USD (live):       %s\n", format(cop_usd_live, big.mark = ",")))

# U.S. CPI YoY from FRED
us_cpi_yoy_pct <- tryCatch({
  fred <- fetch_fred_indicators()
  pct <- fred |>
    filter(series_id == "CPIAUCSL") |>
    arrange(desc(date)) |>
    slice(1) |>
    pull(value)
  if (length(pct) == 0) stop("empty")
  pct
}, error = function(e) {
  warning("FRED CPI fetch failed. Using fallback 3.4%.")
  3.4
})
cat(sprintf("U.S. CPI YoY:         %.1f%%\n", us_cpi_yoy_pct))

# Colombia CPI — update from DANE each quarter; no live API in base setup
# Source: https://www.dane.gov.co/
col_cpi_pct <- 5.8   # Last confirmed: Sep 2026
cat(sprintf("Colombia CPI:         %.1f%% (manual — update from DANE quarterly)\n\n",
    col_cpi_pct))

# Model parameters — update quarterly
cdt_gross_yield  <- 0.105   # Current BBVA / Bancolombia 360-day CDT rate
col_withholding  <- 0.07    # Colombian withholding on CDT interest
                             # NOTE: 7% = resident rate; non-resident may be higher
                             # Verify with cross-border tax counsel before execution
usd_tbill_yield  <- 0.048   # U.S. 3-month T-bill (update from TreasuryDirect)
us_marginal_rate <- 0.22    # Federal marginal income tax rate — verify annually
col_cpi          <- col_cpi_pct / 100
us_cpi           <- us_cpi_yoy_pct / 100


# ==============================================================================
# 2. BALANCE SHEET INPUTS
# ==============================================================================
# Update these from Banktivity QIF each quarter

usd_liquid       <- 309908   # Checking + savings (all accounts)
usd_investments  <- 39847    # Wealthfront bond ladder + other investments
us_other_assets  <- 218206   # Hawthorne home + aircraft (Banktivity values)
credit_card_liab <- -9967    # Credit card balances
usd_net_worth    <- usd_liquid + usd_investments + us_other_assets + credit_card_liab

home_cop         <- 1.2e9    # Colombia home (COP) — update from annual appraisal
bank_cop         <- 30e6     # Colombia bank accounts (COP) — update from statements

monthly_income   <- 7488     # Social Security $3,100 + VA Disability $4,388
monthly_spend    <- 8315     # 12-month average recurring spend (Sep 2025–Aug 2026)
monthly_net_flow <- monthly_income - monthly_spend    # –$827/month deficit

monthly_invest   <- 5200     # Monthly contribution (from liquid reserve drawdown)
estate_goal      <- 500000
usd_hard_floor   <- 100000
usd_early_warning <- 150000


# ==============================================================================
# 3. COP SPENDING RESERVE TARGETS
# ==============================================================================

cat("--- Table 1: COP Reserve Targets ---\n")

# Fixed monthly COP-linked costs paid regardless of physical presence in Colombia
fixed_monthly_usd   <- 231   # Medicina Prepagada + Prosegur + UNE + Avianca sub
property_monthly_usd <- 209  # Wompi annual HOA/admin (~COP 2.5M/year, amortized)
variable_per_month_usd <- 600  # When physically in Colombia (groceries, dining, Rappi, etc.)
flight_monthly_usd  <- 150   # 2 round trips/year ~$900 each, amortized

scenarios <- tribble(
  ~scenario,           ~months_in_colombia, ~note,
  "Low presence",      2,                   "1–2 short trips/year",
  "Base presence",     4,                   "~1 month per quarter",
  "High presence",     6,                   "Semi-resident (6 months/year)"
)

cop_reserve_targets <- scenarios |>
  mutate(
    fixed_usd         = fixed_monthly_usd,
    property_usd      = property_monthly_usd,
    variable_usd      = variable_per_month_usd * (months_in_colombia / 12),
    flights_usd       = flight_monthly_usd,
    total_monthly_usd = fixed_usd + property_usd + variable_usd + flights_usd
  ) |>
  crossing(coverage_months = c(12, 18, 24, 36)) |>
  mutate(
    reserve_usd          = total_monthly_usd * coverage_months,
    reserve_cop_millions = reserve_usd * cop_usd_live / 1e6,
    fogafin_cap_usd      = 50e6 / cop_usd_live,
    institutions_needed  = ceiling(reserve_cop_millions / 50)  # COP 50M cap per institution
  ) |>
  arrange(scenario, coverage_months)

print(
  cop_reserve_targets |>
    select(scenario, coverage_months, total_monthly_usd, reserve_usd,
           reserve_cop_millions, institutions_needed) |>
    mutate(
      total_monthly_usd    = dollar(round(total_monthly_usd, 0)),
      reserve_usd          = dollar(round(reserve_usd, 0)),
      reserve_cop_millions = paste0(round(reserve_cop_millions, 1), "M COP")
    ),
  n = 20
)
cat(sprintf("\nFogafín cap at current rate: %s per institution\n\n",
    dollar(50e6 / cop_usd_live)))

readr::write_csv(cop_reserve_targets,
  file.path(output_dir, paste0(today_str, "_cop_reserve_targets.csv")))
cat("Saved: cop_reserve_targets.csv\n\n")


# ==============================================================================
# 4. CDT AFTER-TAX BREAKEVEN
# ==============================================================================

cat("--- Table 2: CDT After-Tax Breakeven vs. USD T-Bill ---\n")

# Yield waterfall calculations
col_withholding_amt  <- cdt_gross_yield * col_withholding       # 0.735%
us_tax_gross         <- cdt_gross_yield * us_marginal_rate      # 2.31%
ftc                  <- col_withholding_amt                     # assumed fully creditable
us_tax_net           <- us_tax_gross - ftc                      # 1.575%
after_all_income_tax <- cdt_gross_yield - col_withholding_amt - us_tax_net  # 8.19%

# Fisher real yield in COP after all income taxes
real_cop_yield_after_tax <- (1 + after_all_income_tax) / (1 + col_cpi) - 1

# USD T-bill benchmark
tbill_after_tax      <- usd_tbill_yield * (1 - us_marginal_rate)
real_tbill_after_tax <- (1 + tbill_after_tax) / (1 + us_cpi) - 1

# Yield waterfall table
cdt_waterfall <- tribble(
  ~step,                                                        ~rate,
  "Gross CDT yield (nominal COP)",                              cdt_gross_yield,
  "Less: Colombian withholding",                                -col_withholding_amt,
  "Less: U.S. income tax at 22% (net of foreign tax credit)",   -us_tax_net,
  "After-tax nominal yield (COP)",                              after_all_income_tax,
  "Less: COP inflation adjustment (Fisher)",                    -(after_all_income_tax - real_cop_yield_after_tax),
  "Real COP yield after all taxes",                             real_cop_yield_after_tax,
  "---",                                                        NA_real_,
  "USD T-bill (gross)",                                         usd_tbill_yield,
  "USD T-bill after 22% U.S. tax",                              tbill_after_tax,
  "USD T-bill real yield (after tax + US CPI)",                 real_tbill_after_tax
)

cat("Yield waterfall:\n")
print(cdt_waterfall |>
  mutate(rate = if_else(is.na(rate), "---", percent(rate, accuracy = 0.01))))

# Carry comparison across COP depreciation scenarios
cdt_carry_table <- tibble(
  cop_depreciation = c(0.05, 0.08, 0.10, 0.12, 0.15)
) |>
  mutate(
    label               = percent(cop_depreciation),
    cdt_usd_after_tax   = after_all_income_tax - cop_depreciation,
    tbill_after_tax_ref = tbill_after_tax,
    carry_advantage     = cdt_usd_after_tax - tbill_after_tax_ref
  )

cat("\nCDT USD-equivalent yield vs. T-bill after COP depreciation:\n")
print(cdt_carry_table |>
  select(label, cdt_usd_after_tax, tbill_after_tax_ref, carry_advantage) |>
  mutate(across(where(is.double), ~ percent(., accuracy = 0.01))))

# Export
cdt_waterfall_export <- cdt_waterfall |>
  mutate(rate = as.character(if_else(is.na(rate), NA_real_, rate))) |>
  mutate(table = "waterfall")

cdt_carry_export <- cdt_carry_table |>
  rename(step = label, rate = carry_advantage) |>
  mutate(table = "carry_vs_tbill") |>
  select(step, rate, table)

readr::write_csv(
  bind_rows(
    cdt_waterfall |> mutate(table = "waterfall"),
    cdt_carry_table |> rename(step = label, rate = carry_advantage) |>
      mutate(table = "carry_vs_tbill") |> select(step, rate, table)
  ),
  file.path(output_dir, paste0(today_str, "_cdt_breakeven.csv"))
)
cat("Saved: cdt_breakeven.csv\n\n")


# ==============================================================================
# 5. BALANCE SHEET STRESS SCENARIOS
# ==============================================================================

cat("--- Table 3: Balance Sheet COP/USD Stress Scenarios ---\n")

# Base rate is live; stress scenarios are fixed thresholds
stress_scenarios <- tibble(
  scenario = c(
    paste0("Base (", format(cop_usd_live, big.mark = ","), ")"),
    "Stress 1 (3,600)",
    "Stress 2 (4,500)"
  ),
  cop_usd = c(cop_usd_live, 3600, 4500)
) |>
  mutate(
    home_usd           = home_cop / cop_usd,
    bank_cop_usd       = bank_cop / cop_usd,
    total_cop_usd      = home_usd + bank_cop_usd,
    usd_net_worth_val  = usd_net_worth,
    combined_nw        = usd_net_worth + total_cop_usd,
    # Estate goal check: conservative — USD assets only (COP assets may not be
    # accessible at death without Colombian estate planning)
    usd_vs_estate_goal = usd_net_worth - estate_goal,
    combined_vs_goal   = combined_nw - estate_goal,
    home_delta_vs_base = home_usd - (home_cop / cop_usd_live),
    # COP reserve affordability: base 18-month reserve in USD at each rate
    cop_reserve_18mo_usd = (19603 * cop_usd_live) / cop_usd,
    fogafin_cap_usd    = 50e6 / cop_usd
  )

print(
  stress_scenarios |>
    select(scenario, cop_usd, home_usd, combined_nw,
           usd_vs_estate_goal, home_delta_vs_base, fogafin_cap_usd) |>
    mutate(
      cop_usd             = format(cop_usd, big.mark = ","),
      across(c(home_usd, combined_nw, usd_vs_estate_goal,
               home_delta_vs_base, fogafin_cap_usd),
             ~ dollar(round(., 0)))
    )
)

cat(paste0(
  "\nNote: USD net worth (", dollar(usd_net_worth), ") exceeds estate goal ",
  "(", dollar(estate_goal), ") by ", dollar(usd_net_worth - estate_goal),
  " without any COP assets.\n",
  "Estate goal is not at risk from COP depreciation at any plausible rate.\n"
))

readr::write_csv(stress_scenarios,
  file.path(output_dir, paste0(today_str, "_balance_sheet_stress.csv")))
cat("Saved: balance_sheet_stress.csv\n\n")


# ==============================================================================
# 6. SOURCES AND USES SCHEDULE
# ==============================================================================

cat("--- Table 4: Sources and Uses Schedule ---\n")

# Base 18-month reserve for base presence scenario
base_cop_reserve_usd <- cop_reserve_targets |>
  filter(scenario == "Base presence", coverage_months == 18) |>
  pull(reserve_usd)

available_after_floors <- usd_liquid - usd_hard_floor - base_cop_reserve_usd

sources_uses <- tribble(
  ~item,                                        ~amount,              ~notes,
  "Starting USD cash reserve",                  usd_liquid,           "Banktivity export; update quarterly",
  "Less: USD hard liquidity floor",             -usd_hard_floor,      "Non-investable; always maintained",
  "Less: Early-warning buffer",                 -(usd_early_warning - usd_hard_floor),
                                                                      "Stop contributions below $150K",
  "COP spending reserve (18-mo base)",          -base_cop_reserve_usd,"Fund slowly after tax gate cleared",
  "Strategic USD investable capital",           available_after_floors,"Remaining for ETF portfolio build",
  "---",                                        NA_real_,             "",
  "Monthly income",                             monthly_income,       "SS + VA Disability (guaranteed)",
  "Monthly recurring spend",                    -monthly_spend,       "12-month average, Sep 2025–Aug 2026",
  "Net monthly flow (before contributions)",    monthly_net_flow,     "Deficit; funded by reserve",
  "Monthly investment contribution",            -monthly_invest,      "Funded by reserve drawdown"
) |>
  mutate(amount_fmt = if_else(is.na(amount), "---", dollar(round(amount, 0))))

print(sources_uses |> select(item, amount_fmt, notes))

readr::write_csv(sources_uses,
  file.path(output_dir, paste0(today_str, "_sources_uses.csv")))
cat("Saved: sources_uses.csv\n\n")


# ==============================================================================
# 7. RESERVE RUNWAY
# ==============================================================================

cat("--- Table 5: Reserve Runway to Liquidity Thresholds ---\n")

monthly_total_drawdown <- abs(monthly_net_flow) + monthly_invest  # $827 + $5,200

runway <- tibble(
  threshold       = c("Early-warning ($150K)", "Hard floor ($100K)",
                      "Hard floor — no contributions"),
  threshold_usd   = c(usd_early_warning, usd_hard_floor, usd_hard_floor),
  monthly_draw    = c(monthly_total_drawdown, monthly_total_drawdown,
                      abs(monthly_net_flow)),
  action          = c("Stop contributions immediately",
                      "Emergency review; no discretionary investing",
                      "Reserve-only burn rate if contributions paused")
) |>
  mutate(
    months_to_threshold = (usd_liquid - threshold_usd) / monthly_draw,
    approx_date = format(Sys.Date() %m+% months(round(months_to_threshold)), "%b %Y")
  )

print(runway |>
  select(threshold, months_to_threshold, approx_date, action) |>
  mutate(months_to_threshold = round(months_to_threshold, 1)))

readr::write_csv(runway,
  file.path(output_dir, paste0(today_str, "_reserve_runway.csv")))
cat("Saved: reserve_runway.csv\n\n")


# ==============================================================================
# 8. SUMMARY CONSOLE OUTPUT
# ==============================================================================

combined_nw_live <- usd_net_worth + (home_cop + bank_cop) / cop_usd_live

cat("======================================================\n")
cat("KEY NUMBERS — Investment Plan\n")
cat("======================================================\n")
cat(sprintf("As of:                      %s\n", today_str))
cat(sprintf("COP/USD (live):             %s\n",   format(cop_usd_live, big.mark = ",")))
cat(sprintf("USD net worth:              %s\n",   dollar(usd_net_worth)))
cat(sprintf("Combined net worth:         %s\n",   dollar(combined_nw_live)))
cat(sprintf("Estate goal margin (USD):   %s\n",   dollar(usd_net_worth - estate_goal)))
cat(sprintf("COP reserve (18-mo base):   %s\n",   dollar(base_cop_reserve_usd)))
cat(sprintf("Fogafín cap (live rate):    %s / institution\n", dollar(50e6 / cop_usd_live)))
cat(sprintf("CDT real COP yield (post-tax): %.2f%%\n", real_cop_yield_after_tax * 100))
cat(sprintf("USD T-bill after-tax yield: %.2f%%\n", tbill_after_tax * 100))
cat(sprintf("Reserve runway to $150K:    %.1f months (~%s)\n",
    (usd_liquid - usd_early_warning) / monthly_total_drawdown,
    format(Sys.Date() %m+% months(
      round((usd_liquid - usd_early_warning) / monthly_total_drawdown)
    ), "%b %Y")))
cat(sprintf("\nAll tables saved to: %s/\n", output_dir))
cat("Next scheduled run: January 2027 quarterly review\n")
cat("======================================================\n")
