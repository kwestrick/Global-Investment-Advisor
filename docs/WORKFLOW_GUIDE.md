# Global Investment Advisor — Workflow Guide

## Overview

This document describes the workflow for conducting systematic global market analysis and generating investment memos in the Global Investment Advisor project.

---

## Phase 1: Data Collection

### 01_collect_market_data.R

**Purpose:** Download market prices and load macro data from the Global-Insights-Dashboard.

**Inputs:**
- None (uses configured API sources and linked GID data)

**Key Steps:**
1. Build investable universe (country and theme ETFs)
2. Download price history for all tickers (from 2015 forward)
3. Calculate daily and monthly returns
4. Load macro indicators from Global-Insights-Dashboard
5. Validate data completeness and quality

**Outputs:**
- `data/processed/market_prices_[DATE].csv` — Daily OHLCV data for all tickers
- `data/processed/daily_returns_[DATE].csv` — Calculated daily returns
- `data/processed/monthly_returns_[DATE].csv` — Calculated monthly returns
- `data/processed/macro_data_gid_[DATE].csv` — Macro indicators (growth, inflation, policy, commodities)
- `data/external/country_etf_universe_[DATE].csv` — Universe definitions (for reference)
- `data/external/theme_etf_universe_[DATE].csv` — Universe definitions (for reference)

**Run Instructions:**
```r
source("scripts/01_collect_market_data.R")
```

**Typical Duration:** 2–5 minutes (depending on download speeds)

**Data Quality Checks Built In:**
- ✓ Price observation counts per ticker
- ✓ Missing value detection
- ✓ Date range validation
- ✓ Return summary statistics

---

## Phase 2: Global Opportunity Screening

### 02_screen_global_assets.R

**Purpose:** Rank countries and thematic opportunities using a structured conviction framework.

**Inputs:**
- `data/processed/market_prices_*.csv`
- `data/processed/daily_returns_*.csv`
- `data/processed/macro_data_gid_*.csv` (optional, for context)

**Key Steps:**
1. Load latest processed data
2. Calculate performance metrics (returns, volatility, drawdowns, relative strength)
3. Build valuation proxy framework (value signals, momentum, risk scoring)
4. Assess macro tailwinds and catalysts for each opportunity
5. Calculate weighted conviction scores
6. Rank opportunities and bucket by conviction level

**Outputs:**
- `data/processed/country_opportunity_screen_[DATE].csv` — Ranked country ETFs with scores
- `data/processed/theme_opportunity_screen_[DATE].csv` — Ranked theme ETFs with scores

**Run Instructions:**
```r
source("scripts/02_screen_global_assets.R")
```

**Typical Duration:** 1–2 minutes

**Conviction Levels:**
- **High conviction:** Score ≥ 4.25 → Candidates for deep dives
- **Attractive, monitor closely:** Score 3.50–4.25 → Watchlist
- **Watchlist or tactical:** Score 2.75–3.50 → Monitor for entry
- **Weak thesis:** Score 2.00–2.75 → Background watch
- **Avoid unless conditions change:** Score < 2.00 → Do not recommend

---

## Phase 3: Deep-Dive Analysis & Investment Memo

### Country Deep-Dive Template

**File:** `notebooks/country_deep_dive_template.qmd`

**Purpose:** Detailed investment memo analyzing a specific country/theme opportunity.

**Structure:**
1. **Executive Summary** — Thesis, vehicle, horizon, conviction rating
2. **Performance Analysis** — Growth of $1, relative strength, drawdowns
3. **Bull Case** — Why this outperforms the U.S. (valuation, macro, currency, catalysts)
4. **Bear Case & Risks** — What could go wrong and reversals to bull case
5. **Falsification Triggers** — Hard stops that would invalidate the thesis
6. **Scenario Analysis** — Base, bull, and bear case return expectations
7. **Implementation & Liquidity** — Execution details, position sizing
8. **Conviction Summary** — Final decision and monitoring plan

**How to Use:**
1. From `notebooks/country_deep_dive_template.qmd`, create a copy:
   ```bash
   cp notebooks/country_deep_dive_template.qmd notebooks/country_deep_dive_[COUNTRY].qmd
   ```

2. Replace all placeholders:
   - `[COUNTRY_NAME]` → e.g., "India"
   - `[ETF_SYMBOL]` → e.g., "INDA"
   - `[COUNTRY_CURRENCY]` → e.g., "INR"

3. Fill in sections with:
   - Research findings from the screening output
   - Qualitative analysis of macro and geopolitical factors
   - Your conviction rationale

4. Render in RStudio:
   ```r
   quarto::quarto_render("notebooks/country_deep_dive_[COUNTRY].qmd")
   ```

5. Save final memo to `reports/investment_memos/`:
   ```bash
   mv notebooks/country_deep_dive_[COUNTRY].html reports/investment_memos/
   ```

---

## Global-Insights-Dashboard Data Integration

The project is designed to leverage pre-computed macro data from the **Global-Insights-Dashboard** project, which maintains:

- **135 global indicators** across 11 categories
- **Real-time snapshots** of key metrics
- **Historical time series** back to 2014

### Available Data Categories:
- **Growth & Output:** Real GDP growth, industrial production, PMI
- **Inflation:** CPI, producer prices, inflation expectations
- **Monetary & Financial:** Policy rates, money supply, credit
- **Commodities & Energy:** Oil, natural gas, metals, agricultural prices
- **Labor:** Unemployment, wage growth, participation
- **Markets:** Stock indices, volatility, credit spreads
- **International & Geopolitical:** Currency movements, trade flows, geopolitical risk

### Key Geographies:
- **Developed:** US, Japan, Germany, France, UK, Switzerland, Netherlands, Canada, Australia
- **Emerging:** China, India, Brazil, Mexico, South Korea, Taiwan, Indonesia, Philippines, Vietnam, Turkey, Saudi Arabia, South Africa, Poland, Greece, Argentina, Chile
- **Regional:** Eurozone (EA19, EA20, EMU)

### Data Location:
```
/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Insights-Dashboard/data/
├── indicators_long.rds          # 227K+ observations, all indicators
├── latest_snapshot.rds          # Current values for all 135 indicators
├── podcast_feed.rds             # Geopolitical commentary (context)
└── newsletter/                  # Article feed (narrative context)
```

---

## Typical Analysis Workflow

### Week 1: Initial Screening
1. Run `01_collect_market_data.R` to refresh all price and macro data
2. Run `02_screen_global_assets.R` to generate ranked opportunities
3. Review top-ranked opportunities in output (CSV)

### Week 2–3: Deep-Dive on Top 3–5
1. Create Quarto memos for high-conviction opportunities
2. Integrate fresh macro data from GID
3. Research geopolitical catalysts and policy developments
4. Draft bull/bear cases and falsification triggers

### Week 4: Review & Adjust
1. Present final memos to decision-makers
2. Implement positions if conviction exceeds threshold
3. Set up monitoring for falsification triggers
4. Document any changes to conviction or thesis

---

## Data Maintenance

### Scheduled Updates
- **Market prices:** Weekly (prices are free/fast via tidyquant)
- **Macro data:** Weekly (synced from Global-Insights-Dashboard)
- **Screening refresh:** Bi-weekly (to track changing opportunities)

### Manual Maintenance
- **Universe definitions:** Update when new ETFs launch or old ones are retired
- **Macro assessment:** Review quarterly as conditions evolve
- **Catalyst list:** Review monthly for new developments

### Data Quality Checks
Before running analysis, always verify:
- No unexpected missing values in price data
- Price observations >= 2000 per ticker (at least ~8 years of data)
- Macro data has recent observations (within last 7 days)
- No extreme outliers in returns or indicators

---

## Architecture Reference

### R Module Responsibilities

| Module | Purpose |
|--------|---------|
| `R/00_setup.R` | Configuration, defaults, project paths, themes |
| `R/data_import.R` | Download/load market, macro, and reference data |
| `R/indicators.R` | Return calculations, drawdowns, rolling metrics, relative strength |
| `R/valuation.R` | Valuation scoring, benchmark comparisons, classifications |
| `R/screening.R` | Universe construction, conviction scoring, ranking |
| `R/portfolio_tools.R` | Portfolio weights, correlation, volatility, risk metrics |
| `R/plotting.R` | Reusable ggplot functions for charts and exports |

### Script Responsibilities

| Script | Input | Output | Purpose |
|--------|-------|--------|---------|
| `01_collect_market_data.R` | Yahoo Finance, GID | Prices, returns, macro | Refresh all raw data |
| `02_screen_global_assets.R` | Processed data | Ranked opportunities | Generate screening results |
| `03_*_deep_dive.R` | Screening results | Analysis output | [Optional] Specific analyses |
| `04_generate_reports.R` | All processed | HTML/PDF memos | [Optional] Batch generation |

---

## Troubleshooting

### Issue: Tickers fail to download
**Diagnosis:** Check Yahoo Finance status or internet connection
**Solution:** 
- Re-run `01_collect_market_data.R` later
- Check `tidyquant` configuration
- Verify tickers are valid (use `TTM` instead of `TIMESERIES`, for example)

### Issue: Macro data not found or very old
**Diagnosis:** Global-Insights-Dashboard data may not have refreshed
**Solution:**
- Check GID's data refresh schedule
- Verify path is correct: `/Users/kwestrick/.../Global-Insights-Dashboard/data/`
- Comment out macro loading if GID is unavailable; screening still works without it

### Issue: Screening output shows all zeros or NAs
**Diagnosis:** Likely missing data in returns or prices
**Solution:**
- Check `02_screen_global_assets.R` output for data validation warnings
- Re-run `01_collect_market_data.R` with fresh data
- Inspect specific tickers manually in R console

### Issue: Quarto render fails
**Diagnosis:** Missing packages or placeholder text not replaced
**Solution:**
- Run `quarto::quarto_render()` with verbose = TRUE
- Ensure all placeholders `[LIKE_THIS]` are replaced
- Check that referenced R code is syntactically valid

---

## Best Practices

### Investment Analysis
1. Always start with screening output; don't bias toward pre-favored countries
2. Test your thesis: What would prove you wrong? Set falsification triggers first
3. Include both bull and bear cases with explicit probability weights
4. Benchmark every investment against SPY (or relevant U.S. proxy)
5. Document the date and data sources for every memo

### Code Maintenance
1. Never edit raw data files in `data/raw/`; regenerate from scripts
2. Use relative paths; never hardcode absolute paths
3. Keep functions in `R/`; keep workflows in `scripts/`
4. Run scripts from project root: `source("scripts/01_...")`
5. Test data import functions for missing columns and NULL returns

### Reproducibility
1. Commit `renv.lock` to version control to freeze package versions
2. Use `set.seed()` if incorporating randomized models
3. Include session info (R version, package versions) in memos
4. Document data refresh dates in analysis outputs
5. Store final memos in Git; don't store large data files (use `.gitignore`)

---

## Next Steps

### Immediate (This Week)
- [ ] Run `01_collect_market_data.R` to populate `data/processed/`
- [ ] Run `02_screen_global_assets.R` to generate opportunity rankings
- [ ] Review top-ranked opportunities and pick 1–2 for deep-dive

### Short-Term (Next 2 Weeks)
- [ ] Create first `country_deep_dive_[COUNTRY].qmd` memo
- [ ] Integrate macro data and geopolitical context
- [ ] Draft bull/bear cases and falsification triggers
- [ ] Solicit feedback on memo structure and conviction level

### Medium-Term (Next Month)
- [ ] Develop 3–5 detailed investment memos
- [ ] Build portfolio construction workflow (`scripts/03_build_portfolio.R`)
- [ ] Create dashboard for ongoing monitoring (`notebooks/global_market_dashboard.qmd`)
- [ ] Implement automated alert system for falsification triggers

---

---

## Phase 4: Personal Wealth Monitoring (Quarterly)

### 04_quarterly_wealth_dashboard.R

**Purpose:** Generate a full quarterly personal wealth report from Banktivity account data.

**Inputs:**
- Banktivity QIF export (path configured at top of script)

**Key Steps:**
1. Import QIF file using `import_qif_accounts()` (header-section-only parser)
2. Calculate net worth and categorize accounts
3. Compare current allocation to 7-class target
4. Assess estate goal progress
5. Project 5-year net worth under 3 scenarios
6. Print 10-section dashboard to console
7. Export 3 CSV files (accounts, projection, summary)

**Outputs:**
- `data/processed/[DATE]_quarterly_accounts.csv`
- `data/processed/[DATE]_quarterly_projection.csv`
- `data/processed/[DATE]_quarterly_summary.csv`

**Run Instructions:**
```r
source("scripts/04_quarterly_wealth_dashboard.R")
```

**Recommended Schedule:** January, April, July, October (export QIF from Banktivity first)

**Typical Duration:** ~10 seconds

---

## Phase 5: Colombia Investment Analysis

### 06_colombia_economic_snapshot.R

**Purpose:** Generate a Colombia-specific economic dashboard: COP/USD exchange rate, inflation, policy rate, TES yield curve, and local savings rates.

**Status:** ✅ Complete (Sep 21, 2026)

**Data Sources:**
- Yahoo Finance — Daily COP/USD (COP=X) and COLCAP index (^COLCAP)
- World Bank WDI — Colombia GDP growth, CPI, unemployment, current account

**Outputs:**
- `data/processed/cop_rate_[DATE].csv`
- `data/processed/colombia_macro_[DATE].csv`
- `data/processed/bond_screen_[DATE].csv`
- `outputs/charts/cop_usd_rate_[DATE].png`
- Console dashboard via `print_colombia_snapshot()`

**Run Instructions:**
```r
source("scripts/06_colombia_economic_snapshot.R")
```

### 07_evaluate_colombia_investments.R

**Purpose:** Rank 14 COP-denominated investment vehicles by real yield (net of Colombian inflation and USD/COP FX movement); generate 5-year income forecast.

**Status:** ✅ Complete (Sep 21, 2026)

**Key Functions Used:**
- `get_colombia_investment_universe()` — 14-vehicle reference tibble
- `calculate_real_yield()` — Fisher equation (nominal – inflation)
- `calculate_fx_adjusted_yield()` — Real yield ± expected COP/USD change
- `screen_colombian_bonds()` — Rank all 14 vehicles across bear/base/bull FX scenarios
- `generate_colombia_income_forecast()` — 5-year COP + USD income projection

**Outputs:**
- Console ranked vehicle table with all yield columns
- 2 ggplot charts: yield comparison + cumulative income scenarios

**Run Instructions:**
```r
source("scripts/07_evaluate_colombia_investments.R")
```

---

## Phase 6: Dual-Currency Quarterly Review

### 08_quarterly_dual_currency_review.R

**Purpose:** Full quarterly review combining USD portfolio and COP assets into a single consolidated balance sheet.

**Status:** ✅ Complete (Sep 21, 2026)

**Key Steps:**
1. Load latest USD account data (from Banktivity QIF)
2. Fetch current COP/USD rate from Yahoo Finance
3. Compute dual-currency balance sheet (8 categories including COP home)
4. Calculate currency exposure vs. 80/20 USD/COP target
5. Generate monthly contribution guidance to close USD/COP gap
6. Run Colombia macro snapshot and bond screen
7. Project dual-currency growth under 3 FX scenarios (bear/base/bull)
8. Export 2 charts and 3 CSVs

**Outputs:**
- `outputs/charts/dual_currency_projection_[DATE].png`
- `outputs/charts/currency_exposure_[DATE].png`
- `data/processed/dual_currency_balance_sheet_[DATE].csv`
- `data/processed/dual_currency_projection_[DATE].csv`
- `data/processed/cop_bond_screen_[DATE].csv`

**Run Instructions:**
```r
source("scripts/08_quarterly_dual_currency_review.R")
```

**Recommended schedule:** January, April, July, October (same as quarterly wealth dashboard)

---

## Phase 7: Indicator-Driven Portfolio Prioritization *(Phase 3 Part 4 — Next)*

### 05_collect_global_indicators.R

**Purpose:** Daily/weekly/monthly collection of 30+ macro, climate, and political risk indicators.

**Data Sources:**
- FRED (expanded) — 40+ U.S. and global series
- World Bank WDI — 200+ country indicators
- IMF World Economic Outlook — GDP, debt, current account
- Banco de la República — Colombia daily rates
- DANE — Colombia monthly inflation
- V-Dem — Democracy and governance indices
- Fragile States Index — Country stability scores
- World Bank Climate — Climate vulnerability indices
- IEA — Energy transition data

**Storage Format:**
```
date | geography | indicator_code | indicator_name | value | unit | source
```

### 09_indicator_driven_portfolio_ranking.R

**Purpose:** Dynamically reweight conviction scores based on current macro/climate/political indicator readings.

**Logic:**
- Pulls latest indicator values from `data/processed/economic_dashboard_[DATE].csv`
- Adjusts country/theme conviction weights based on:
  - Growth momentum (accelerating vs. decelerating)
  - Inflation pressure vs. policy rate trajectory
  - Political stability changes
  - Climate transition risk by sector
- Recommends monthly $5,200 allocation split across USD and COP vehicles

---

## Updated Architecture Reference

### R Module Responsibilities

| Module | Purpose |
|---|---|
| `R/00_setup.R` | Configuration, defaults, project paths, shared theme |
| `R/data_import.R` | Download/load market, macro, and QIF data; `import_qif_accounts()` |
| `R/indicators.R` | Return calcs, drawdowns, rolling metrics, relative strength |
| `R/valuation.R` | Valuation scoring, benchmark comparisons, classifications |
| `R/screening.R` | Universe construction, conviction scoring, ranking |
| `R/portfolio_tools.R` | Portfolio weights, correlation, volatility, risk metrics |
| `R/plotting.R` | Reusable ggplot functions for charts and exports |
| `R/personal_wealth_monitoring.R` | Net worth, allocation, goal tracking, projections; dual-currency monitoring (4 functions) |
| `R/economic_indicators.R` | ✅ [Phase 3] FRED (33 series), WDI (16 indicators, 27 countries), FX (19 pairs) |
| `R/colombia_indicators.R` | ✅ [Phase 3] COP/USD, 14-vehicle bond screener, income forecaster, yield analytics |

### Script Responsibilities

| Script | Status | Purpose |
|---|---|---|
| `01_collect_market_data.R` | ✅ Complete | Download prices for 48 ETFs + GID macro data |
| `02_screen_global_assets.R` | ✅ Complete | Rank ETFs by conviction score |
| `04_quarterly_wealth_dashboard.R` | ✅ Complete | Quarterly personal wealth report |
| `05_collect_global_indicators.R` | ✅ Complete | Pull FRED, WDI, FX indicators; 5 CSV outputs |
| `06_colombia_economic_snapshot.R` | ✅ Complete | Colombia dashboard: FX, macro, TES, bond screen |
| `07_evaluate_colombia_investments.R` | ✅ Complete | Rank 14 COP vehicles by real + FX-adjusted yield |
| `08_quarterly_dual_currency_review.R` | ✅ Complete | USD + COP consolidated quarterly review |
| `09_indicator_driven_portfolio_ranking.R` | 🔲 Next | Dynamic conviction reweighting by live indicators |

---

## Questions?

Refer to the project `AGENTS.md` for conventions, philosophy, and coding standards.

For macro data questions, see `docs/DATA_INVENTORY_AND_LINKAGE.md` (135 indicators, 17 geographies).

For personal wealth plan details, see `data/external/personal_wealth_plan_complete.md`.

---

**Last Updated:** September 21, 2026 (Phase 3 Parts 1–3 complete; Part 4 next)
