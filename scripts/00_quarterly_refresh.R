## =============================================================================
## 00_quarterly_refresh.R
## Global Investment Advisor — Quarterly Workflow Orchestrator
##
## Run at the start of each quarterly review (January, April, July, October).
## This script sequences all data collection, screening, and report rendering.
##
## BEFORE RUNNING:
##   1. Export latest account data from Banktivity as QIF and save to data/raw/
##   2. Confirm FRED_API_KEY is set in .Renviron (run usethis::edit_r_environ())
##   3. Confirm internet connection is active
##
## Usage:
##   source("scripts/00_quarterly_refresh.R")
## =============================================================================

cat("\n========================================\n")
cat("  Global Investment Advisor\n")
cat("  Quarterly Refresh —", format(Sys.Date(), "%B %Y"), "\n")
cat("========================================\n\n")

# ---------------------------------------------------------------------------
# 1. Market data: prices for 48 ETFs (country + theme universe)
# ---------------------------------------------------------------------------
cat("Step 1/4: Collecting market data...\n")
source("scripts/01_collect_market_data.R")
cat("  ✓ Market data collected.\n\n")

# ---------------------------------------------------------------------------
# 2. Global screening: conviction scores for all ETFs
# ---------------------------------------------------------------------------
cat("Step 2/4: Screening global assets...\n")
source("scripts/02_screen_global_assets.R")
cat("  ✓ Global screening complete.\n\n")

# ---------------------------------------------------------------------------
# 3. Live indicator pipeline + monthly allocation recommendation
# ---------------------------------------------------------------------------
cat("Step 3/4: Running indicator-driven portfolio ranking...\n")
source("scripts/09_indicator_driven_portfolio_ranking.R")
cat("  ✓ Portfolio ranking complete.\n\n")

# ---------------------------------------------------------------------------
# 4. Render monthly allocation brief
# ---------------------------------------------------------------------------
cat("Step 4/4: Rendering monthly allocation brief...\n")
if (!requireNamespace("quarto", quietly = TRUE)) {
  stop("Package 'quarto' is required. Install with: install.packages('quarto')")
}
quarto::quarto_render("reports/monthly_allocation_brief.qmd")
cat("  ✓ Report rendered: reports/monthly_allocation_brief.html\n\n")

# ---------------------------------------------------------------------------
# Manual steps checklist
# ---------------------------------------------------------------------------
cat("========================================\n")
cat("  MANUAL STEPS — ACTION REQUIRED\n")
cat("========================================\n\n")

cat("[ ] 1. BANKTIVITY EXPORT\n")
cat("       Export latest accounts as QIF from Banktivity.\n")
cat("       Save to: data/raw/YYYY-MM-DD_fullBanktivity.qif\n")
cat("       Then run: source('scripts/04_quarterly_wealth_dashboard.R')\n\n")

cat("[ ] 2. COLOMBIA SNAPSHOT\n")
cat("       Run: source('scripts/06_colombia_economic_snapshot.R')\n")
cat("       Verify COP/USD rate is current (check Banco de la República).\n\n")

cat("[ ] 3. COLOMBIA INVESTMENTS\n")
cat("       Run: source('scripts/07_evaluate_colombia_investments.R')\n")
cat("       Review CDT rate quotes from BBVA and Bancolombia.\n\n")

cat("[ ] 4. DUAL-CURRENCY REVIEW\n")
cat("       Run: source('scripts/08_quarterly_dual_currency_review.R')\n")
cat("       Update COP home value estimate if needed.\n\n")

cat("[ ] 5. ALLOCATION DECISION\n")
cat("       Review outputs/tables/ for ranked ETF and COP vehicle lists.\n")
cat("       Confirm or adjust monthly Wealthfront allocations.\n\n")

cat("[ ] 6. COMMIT RESULTS\n")
cat("       git add -A && git commit -m 'Quarterly refresh ", format(Sys.Date(), "%Y-%m-%d"), "'\n\n", sep = "")

cat("Next quarterly refresh: ")
next_quarter <- lubridate::floor_date(Sys.Date() %m+% months(3), "month")
# Round to nearest Jan/Apr/Jul/Oct 1
quarter_months <- c(1, 4, 7, 10)
month_diff <- which.min(abs(quarter_months - lubridate::month(next_quarter)))
next_start <- as.Date(paste0(lubridate::year(next_quarter), "-",
                              sprintf("%02d", quarter_months[month_diff]), "-01"))
cat(format(next_start, "%B %d, %Y"), "\n\n")
