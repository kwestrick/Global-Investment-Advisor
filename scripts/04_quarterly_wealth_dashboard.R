# scripts/04_quarterly_wealth_dashboard.R
# Quarterly wealth monitoring and dashboard generation
# Run quarterly: January 1, April 1, July 1, October 1

source("R/00_setup.R")
source("R/personal_wealth_monitoring.R")
source("R/data_import.R")

# ---- Configuration ----

qif_file <- "data/raw/2026-09-21_fullBanktivity.qif"  # Update quarterly
target_estate <- 500000
monthly_contribution <- 5200
annual_return_base <- 0.075

target_allocation <- tibble::tibble(
  allocation_type = c("Cash", "Investments"),
  target_pct = c(10, 90)
)

# ---- Import latest account data ----

cat("Loading latest account data from QIF...\n")
accounts_current <- import_qif_accounts(qif_file)

# ---- Calculate key metrics ----

nw <- calculate_net_worth(accounts_current)
goal <- assess_goal_progress(nw$net_worth, target_estate)
projection <- project_net_worth(nw$net_worth, monthly_contribution, annual_return_base, 5)

# ---- Generate dashboard ----

cat("\n")
cat(strrep("=", 80), "\n")
cat("PERSONAL WEALTH QUARTERLY DASHBOARD\n")
cat("Date:", format(Sys.Date(), "%B %d, %Y"), "\n")
cat(strrep("=", 80), "\n\n")

# Section 1: Net Worth
cat("NET WORTH SUMMARY\n")
cat(strrep("-", 80), "\n")
cat(sprintf("Total Assets:        $%s\n", format(round(nw$total_assets), big.mark=",")))
cat(sprintf("Total Liabilities:   $%s\n", format(round(nw$total_liabilities), big.mark=",")))
cat(sprintf("NET WORTH:           $%s\n\n", format(round(nw$net_worth), big.mark=",")))

# Section 2: Goal Progress
cat("ESTATE GOAL TRACKING\n")
cat(strrep("-", 80), "\n")
cat(sprintf("Target:              $%s\n", format(round(goal$target_estate), big.mark=",")))
cat(sprintf("Current:             $%s\n", format(round(goal$current_net_worth), big.mark=",")))
cat(sprintf("Surplus:             $%s\n", format(round(goal$surplus), big.mark=",")))
cat(sprintf("%% of Goal:           %.1f%%\n", goal$pct_of_goal))
status_msg <- if_else(goal$goal_met, "✓ GOAL MET", "✗ GOAL NOT MET")
cat(sprintf("Status:              %s\n\n", status_msg))

# Section 3: Accounts Detail
cat("ACCOUNTS BY CATEGORY\n")
cat(strrep("-", 80), "\n")
accounts_summary <- accounts_current %>%
  group_by(account_category) %>%
  summarise(
    count = n(),
    total_balance = sum(balance),
    .groups = "drop"
  ) %>%
  arrange(desc(abs(total_balance)))

for (i in seq_len(nrow(accounts_summary))) {
  cat(sprintf("%30s: $%13s (%d accounts)\n",
              accounts_summary$account_category[i],
              format(round(accounts_summary$total_balance[i]), big.mark=","),
              accounts_summary$count[i]))
}
cat("\n")

# Section 4: Top Accounts
cat("TOP 10 ACCOUNTS BY BALANCE\n")
cat(strrep("-", 80), "\n")
top_accounts <- accounts_current %>%
  arrange(desc(abs(balance))) %>%
  slice(1:10) %>%
  select(account_name, account_type, balance)

for (i in seq_len(nrow(top_accounts))) {
  cat(sprintf("%40s [%10s] $%13s\n",
              substr(top_accounts$account_name[i], 1, 40),
              top_accounts$account_type[i],
              format(round(top_accounts$balance[i]), big.mark=",")))
}
cat("\n")

# Section 5: Projection
cat("5-YEAR NET WORTH PROJECTION (7.5% return, $5,200/month)\n")
cat(strrep("-", 80), "\n")
proj_display <- projection %>%
  select(year, balance, annual_gain) %>%
  mutate(
    balance = format(round(balance), big.mark=","),
    annual_gain = format(round(annual_gain), big.mark=",")
  )

for (i in seq_len(nrow(proj_display))) {
  cat(sprintf("Year %d: $%15s (annual gain: $%15s)\n",
              projection$year[i],
              proj_display$balance[i],
              proj_display$annual_gain[i]))
}
cat("\n")

# Section 6: Action Items
cat("RECOMMENDED ACTIONS FOR THIS QUARTER\n")
cat(strrep("-", 80), "\n")
cat("□ Review target allocation (current: 10% cash, 90% investments)\n")
cat("□ Check for accounts with drift > 5%\n")
cat("□ Confirm $5,200 monthly contributions are on track\n")
cat("□ Review credit card balances and pay in full\n")
cat("□ Schedule rebalancing if needed (annual)\n\n")

# Footer
cat(strrep("=", 80), "\n")
cat("Report generated:", format(Sys.time(), "%I:%M %p %Z"), "\n")
cat("Next review:     ", format(Sys.Date() + 90, "%B %d, %Y"), "\n")
cat(strrep("=", 80), "\n\n")

# ---- Export summary to CSV ----

cat("Saving summary data...\n")

# Export accounts
readr::write_csv(
  accounts_current,
  sprintf("data/processed/%s_quarterly_accounts.csv", format(Sys.Date(), "%Y-%m-%d"))
)

# Export projection
readr::write_csv(
  projection,
  sprintf("data/processed/%s_quarterly_projection.csv", format(Sys.Date(), "%Y-%m-%d"))
)

# Export summary
summary_data <- tibble::tibble(
  metric = c("Total Assets", "Total Liabilities", "Net Worth", "Estate Goal", 
             "Goal Status", "Monthly Contribution", "Projection Year 5"),
  value = c(
    nw$total_assets,
    nw$total_liabilities,
    nw$net_worth,
    target_estate,
    if_else(goal$goal_met, "MET", "NOT MET"),
    monthly_contribution,
    projection$balance[6]  # Year 5
  )
)

readr::write_csv(
  summary_data,
  sprintf("data/processed/%s_quarterly_summary.csv", format(Sys.Date(), "%Y-%m-%d"))
)

cat("✓ Quarterly files saved to data/processed/\n\n")
