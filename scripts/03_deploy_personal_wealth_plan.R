# 03_deploy_personal_wealth_plan.R
# Personal wealth plan execution for Kenneth Westrick
# This script helps manage your monthly $5,200 investments

source("R/00_setup.R")
source("R/personal_wealth_monitoring.R")

cat("\n")
cat("╔═════════════════════════════════════════════════════════════════╗\n")
cat("║          KENNETH'S PERSONAL WEALTH PLAN DEPLOYMENT              ║\n")
cat("║                   Monthly Investment Guide                       ║\n")
cat("╚═════════════════════════════════════════════════════════════════╝\n\n")

# ---- Target Allocation ----

cat("TARGET ALLOCATION:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

target_allocation <- create_target_allocation()
print(target_allocation)

# ---- Monthly Deployment Plan ----

cat("\n\nMONTHLY INVESTMENT PLAN ($5,200 available):\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

deployment <- target_allocation %>%
  dplyr::filter(asset_class != "Cash Reserve") %>%  # Don't invest cash reserve
  dplyr::mutate(
    monthly_amount = target_pct * 5200,
    comment = dplyr::case_when(
      grepl("SPY|VTI", asset_class) ~ "Core U.S. holding",
      grepl("VEA", asset_class) ~ "Developed ex-U.S.",
      grepl("VWO|INDA", asset_class) ~ "High-growth emerging markets",
      grepl("GRID", asset_class) ~ "Infrastructure + dividend income",
      grepl("COPX", asset_class) ~ "Inflation hedge + commodity exposure",
      grepl("Bond", asset_class) ~ "Bonds + fixed income (existing ladder)",
      TRUE ~ ""
    )
  ) %>%
  dplyr::select(asset_class, target_pct, monthly_amount, comment)

cat("ETF/Vehicle                         Target  Monthly   Notes\n")
cat("─────────────────────────────────────────────────────────────────\n")
for (i in 1:nrow(deployment)) {
  row <- deployment[i, ]
  cat(sprintf("%-35s %5.0f%%  $%6.0f   %s\n",
              row$asset_class, row$target_pct * 100, row$monthly_amount, row$comment))
}
cat("─────────────────────────────────────────────────────────────────\n")
cat(sprintf("%-35s       $%6.0f   Total invested each month\n",
            "TOTAL", sum(deployment$monthly_amount)))

cat("\n\nDOLLAR-COST AVERAGING SCHEDULE:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("Week 1 of Month (Early in the month, after income deposits):\n")
cat("  • SPY or VTI:           $1,300\n\n")

cat("Week 2 of Month:\n")
cat("  • VEA:                  $975\n\n")

cat("Week 3 of Month:\n")
cat("  • VWO or INDA:          $975\n\n")

cat("Week 4 of Month:\n")
cat("  • GRID or PAVE:         $650\n")
cat("  • COPX or URA:          $260\n")
cat("  • Bonds (VBTLX or add to ladder): $1,040\n\n")

cat("WHY SPREAD OVER 4 WEEKS?\n")
cat("  • Dollar-cost averaging (DCA) reduces timing risk\n")
cat("  • Smooth entry into positions\n")
cat("  • Less stress about \"buying the top\"\n")
cat("  • Historically, DCA outperforms lump-sum 60% of the time\n\n")

# ---- Quarterly Projection ----

cat("QUARTERLY PROJECTION (3 months):\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

quarterly_projection <- tibble::tibble(
  month = c(1, 2, 3),
  investment = c(5200, 5200, 5200),
  cumulative = cumsum(investment),
  current_nw = 557994,
  projected_nw_conservative = current_nw + cumulative,  # Without market gains
  market_gain_est = cumulative * 0.018,  # ~7% annual = ~1.8% per quarter
  projected_nw_realistic = current_nw + cumulative + market_gain_est
)

cat("Month  New Investment  Cumulative  Portfolio Value*\n")
cat("─────────────────────────────────────────────────────\n")
for (i in 1:nrow(quarterly_projection)) {
  row <- quarterly_projection[i, ]
  cat(sprintf("  %d      $%5.0f         $%6.0f       $%9.0f\n",
              row$month, row$investment, row$cumulative, row$projected_nw_realistic))
}
cat("─────────────────────────────────────────────────────\n")
cat("* Assumes ~1.8% market gain per quarter (7% annual average)\n\n")

# ---- Rebalancing Rules ----

cat("REBALANCING RULES:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("When to Rebalance (Quarterly Review):\n")
cat("  • If any position drifts >5% from target: REBALANCE\n")
cat("  • If any position drifts 3-5% from target: MONITOR (rebalance next quarter)\n")
cat("  • If all positions within 3% of target: HOLD (no action needed)\n\n")

cat("How to Rebalance:\n")
cat("  1. Identify overweight positions (above target + 5%)\n")
cat("  2. Identify underweight positions (below target - 5%)\n")
cat("  3. Sell 50% of excess in overweight positions\n")
cat("  4. Buy with proceeds into underweight positions\n")
cat("  5. Document the trades\n\n")

cat("Example Rebalancing:\n")
cat("  Current: SPY at 22% (target 20%)\n")
cat("  Action: Sell $5,000 of SPY, buy $5,000 VEA\n\n")

# ---- Warning Signs ----

cat("FALSIFICATION TRIGGERS (When to Pause/Adjust):\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("RED FLAGS:\n")
cat("  ⚠ Your monthly spending exceeds $3,500\n")
cat("    → Action: Pause investing; review budget\n\n")
cat("  ⚠ Market drops >40% and stays down >1 year\n")
cat("    → Action: Rebalance; consider 50/50 stocks/bonds\n\n")
cat("  ⚠ A position drops >50% (e.g., COPX in commodity bust)\n")
cat("    → Action: Review thesis; hold if conviction strong; exit if not\n\n")
cat("  ⚠ Your guaranteed income is threatened\n")
cat("    → Action: Immediately increase emergency fund to 12 months\n\n")
cat("  ⚠ Unexpected major expense (medical, home repair >$15k)\n")
cat("    → Action: Tap savings; pause new investing for 1-2 months\n\n")

# ---- Next Review ----

cat("NEXT ACTIONS:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("IMMEDIATE (This Week):\n")
cat("  1. Open accounts/verify trading access to Wealthfront, Fidelity, Vanguard\n")
cat("  2. Set up automatic monthly deposits\n")
cat("  3. Make first monthly purchase (aim for this week)\n\n")

cat("MONTHLY (Ongoing):\n")
cat("  1. Invest $5,200 on schedule (Week 1, 2, 3, 4)\n")
cat("  2. Document investments in a simple spreadsheet\n")
cat("  3. No need to monitor daily; ignore day-to-day volatility\n\n")

cat("QUARTERLY (Every 3 Months):\n")
cat("  1. Run quarterly dashboard (see quarterly_dashboard_template())\n")
cat("  2. Check if allocation is in balance\n")
cat("  3. Rebalance if any position drifts >5%\n")
cat("  4. Review cash flow (are you on budget?)\n\n")

cat("ANNUALLY (Every January):\n")
cat("  1. Full financial review\n")
cat("  2. Update net worth projection\n")
cat("  3. Check goal progress\n")
cat("  4. Tax planning with professional\n")
cat("  5. Update will/estate plan if needed\n\n")

# ---- Confidence ----

cat("WHY THIS PLAN WORKS:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("✓ Your income is GUARANTEED\n")
cat("✓ Your income EXCEEDS spending by 3x\n")
cat("✓ You have $310k emergency fund (41 months!)\n")
cat("✓ You can afford market volatility\n")
cat("✓ Your $500k goal is achieved in ~3 years with zero additional effort\n")
cat("✓ You're projecting $1M-5M+ by age 80-84\n\n")

cat("The only way this fails is if you PANIC and sell at market bottoms.\n")
cat("DON'T PANIC. Your income covers everything. Keep investing.\n\n")

cat("═════════════════════════════════════════════════════════════════\n")
cat("Ready to build wealth. Let's go.\n")
cat("═════════════════════════════════════════════════════════════════\n")
