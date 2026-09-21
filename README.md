# Global Investment Advisor

## Purpose

Global Investment Advisor is an R-first investment research and personal wealth management project. It combines:

1. **Global market research** — Systematic identification and ranking of non-U.S. investment opportunities that may offer better forward risk/reward than comparable U.S. assets.
2. **Personal financial planning** — A reproducible monitoring system for a dual-currency personal wealth plan (USD + COP).
3. **Colombia investment analysis** — Tools for analyzing COP-denominated cash-generating investments, currency hedging, and dual-citizenship financial planning *(Phase 3, in progress)*.

The default benchmark is the United States. Every major opportunity is compared against U.S. equities, bonds, or cash. The goal is not to assume non-U.S. assets will outperform but to systematically identify cases where valuation, macro regime change, policy divergence, capital flows, currency dynamics, or geopolitical catalysts create a superior risk/reward setup.

Commodity-specific research, forecasting, ingestion, Shiny dashboards, and commodity skills now live in the separate **Global Commodity Platform** project at:

```text
/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Commodity-Platform
```

This project may still use commodity cycles as an input to global investment analysis, but commodity platform code should remain in the standalone commodity repository.

---

## Project Status

| Phase | Description | Status | Completed |
|---|---|---|---|
| **Phase 1** | Global investment research infrastructure (screening, memos, data collection) | ✅ Complete | Sep 21, 2026 |
| **Phase 2** | Personal wealth plan with QIF import, monitoring, quarterly dashboard | ✅ Complete | Sep 21, 2026 |
| **Phase 3** | Colombia investment system + global economic/climate indicators | 🔄 Parts 1–3 complete; Part 4 next | Sep 21, 2026 |

**Phase 3 Part Status:**

| Part | Description | Status |
|---|---|---|
| Part 1 | Global Indicators Foundation (FRED/WDI/FX loaders, 30-source registry, script 05) | ✅ Complete |
| Part 2 | Colombia Investment System (14-vehicle COP universe, yield analytics, scripts 06–07, notebook) | ✅ Complete |
| Part 3 | Dual-Currency Monitoring (4 monitoring functions, quarterly review script 08, HTML dashboard) | ✅ Complete |
| Part 4 | Indicator-Driven Portfolio Prioritization (script 09) | 🔲 Next |
| Part 5 | Data Source Management (30-source registry) | ✅ Complete (in Part 1) ||

---

## Core Research Questions

- Which global regions, countries, sectors, currencies, or asset classes offer better forward risk/reward than comparable U.S. assets?
- Where are valuations low relative to history, fundamentals, or U.S. alternatives?
- Which countries benefit from macro regime shifts (inflation, energy transition, defense rearmament, supply-chain realignment, commodity cycles, monetary divergence)?
- Where are risks over-discounted or under-discounted by markets?
- Which opportunities are practically investable through liquid ETFs, ADRs, sovereign bonds, or local securities?

---

## Quick Start

### Global Screening

```r
# 1. Download price data for 48 country + theme ETFs
source("scripts/01_collect_market_data.R")

# 2. Screen and rank by conviction (valuation, macro, catalyst, risk)
source("scripts/02_screen_global_assets.R")

# 3. Review top opportunities
# Output: data/processed/country_opportunity_screen_[DATE].csv
```

### Personal Wealth Dashboard (Quarterly)

```r
# Export QIF from Banktivity, then:
source("scripts/04_quarterly_wealth_dashboard.R")

# Outputs: data/processed/[DATE]_quarterly_*.csv
```

### Colombia & Dual-Currency Review

```r
# Colombia economic snapshot (COP/USD, TES yields, bond screen)
source("scripts/06_colombia_economic_snapshot.R")

# Rank COP investment vehicles by real + FX-adjusted yield
source("scripts/07_evaluate_colombia_investments.R")

# Consolidated USD + COP quarterly review with dual-currency balance sheet
source("scripts/08_quarterly_dual_currency_review.R")
```

---

## Project Structure

```text
global-investment-advisor/
├── AGENTS.md                           # AI assistant instructions, project history, all phase status
├── README.md                           # This file
├── R/                                  # Reusable analysis functions
│   ├── 00_setup.R                      # Config, defaults, project paths, shared theme
│   ├── data_import.R                   # Market, macro, QIF data loading
│   ├── indicators.R                    # Return calcs, drawdowns, rolling metrics, RS
│   ├── valuation.R                     # Valuation scoring, benchmark comparisons
│   ├── screening.R                     # Conviction scoring, ranking logic
│   ├── portfolio_tools.R               # Portfolio weights, correlation, risk metrics
│   ├── plotting.R                      # Reusable ggplot chart functions
│   ├── personal_wealth_monitoring.R    # ✅ Net worth, allocation, goal tracking, dual-currency monitoring
│   ├── economic_indicators.R           # ✅ [Phase 3] 30+ source loaders (FRED, WDI, FX)
│   └── colombia_indicators.R           # ✅ [Phase 3] COP/USD, TES, COLCAP, yield analytics
├── scripts/                            # Numbered workflow scripts
│   ├── 01_collect_market_data.R        # ✅ Download prices for 48 ETFs + GID macro data
│   ├── 02_screen_global_assets.R       # ✅ Rank ETFs by conviction score
│   ├── 04_quarterly_wealth_dashboard.R # ✅ Quarterly personal wealth report
│   ├── 05_collect_global_indicators.R  # ✅ [Phase 3] Daily/weekly indicator collection
│   ├── 06_colombia_economic_snapshot.R # ✅ [Phase 3] Colombia dashboard
│   ├── 07_evaluate_colombia_investments.R # ✅ [Phase 3] Rank COP vehicles by real yield
│   ├── 08_quarterly_dual_currency_review.R # ✅ [Phase 3] USD + COP quarterly review
│   └── 09_indicator_driven_portfolio_ranking.R # 🔲 [Phase 3 Part 4] Dynamic conviction reweighting
├── notebooks/                          # Quarto analytical notebooks
│   ├── country_deep_dive_template.qmd  # ✅ 10-section investment memo template
│   ├── colombia_investment_analysis.qmd # ✅ [Phase 3] Colombia opportunity analysis
│   └── investment_memo_template.qmd    # ✅ General memo template
├── data/
│   ├── raw/                            # Source downloads; never edit manually
│   ├── processed/                      # Generated by scripts (timestamped)
│   └── external/                       # Lookup tables, reference data, wealth plan
│       ├── personal_wealth_plan_complete.md  # ✅ Full 12,000-word personal wealth plan
│       └── data_source_registry.csv    # ✅ [Phase 3] 30 data sources with API metadata
├── reports/
│   ├── investment_memos/               # Final rendered Quarto memos
│   ├── dashboards/
│   └── investment_dashboard_2026-09-21.html  # ✅ [Phase 3] Interactive dual-currency dashboard
├── outputs/
│   ├── charts/                         # Saved PNG/PDF plots
│   └── tables/                         # Saved CSV/HTML tables
└── docs/                               # Project documentation
    ├── WORKFLOW_GUIDE.md               # ✅ Step-by-step workflow guide
    ├── DATA_INVENTORY_AND_LINKAGE.md   # ✅ GID macro data catalog (227K observations)
    ├── PROJECT_COMPLETION_SUMMARY.md   # ✅ Phase-by-phase completion record
    ├── DELIVERABLES.md                 # ✅ Phase 1 deliverables manifest
    ├── methodology.md
    ├── investment_framework.md
    └── risk_framework.md
```

---

## Phase 1: Global Investment Research Infrastructure

**Completed:** September 21, 2026

### What Was Built

**Data collection (`scripts/01_collect_market_data.R`):**
- Downloads price history for 48 ETFs (35 country + 13 theme) via tidyquant/Yahoo Finance
- Loads 227,142 macro observations from Global-Insights-Dashboard (GID)
- Validates data completeness; saves timestamped CSVs

**Global screening (`scripts/02_screen_global_assets.R`):**
- Calculates performance metrics (return, volatility, Sharpe, max drawdown, relative strength)
- Scores every ETF on a 5-factor conviction model:
  - 25% Valuation · 25% Macro tailwind · 20% Catalyst · 15% Risk · 15% Implementation
- Buckets opportunities: High conviction → Attractive → Watchlist → Weak → Avoid

**Investment memo template (`notebooks/country_deep_dive_template.qmd`):**
- 10-section Quarto template: Executive Summary, Performance, Bull/Bear Case, Falsification Triggers, Scenarios, Implementation, Conviction
- Fully executable R code; dynamic data loading; professional HTML/PDF output

**R helper modules:** `indicators.R`, `valuation.R`, `screening.R`, `portfolio_tools.R`, `plotting.R`

**Documentation:** `docs/WORKFLOW_GUIDE.md`, `docs/DATA_INVENTORY_AND_LINKAGE.md`, `docs/PROJECT_COMPLETION_SUMMARY.md`

---

## Phase 2: Personal Wealth Plan

**Completed:** September 21, 2026

### User Financial Profile

| Item | Value |
|---|---|
| Age | 64, wheelchair-bound (MS disability) |
| Guaranteed monthly income | $7,488 (SS $3,100 + VA Disability $4,388) |
| Monthly expenses | ~$2,300 |
| Monthly investment surplus | ~$5,188 |
| **Net worth (Sep 21, 2026)** | **$557,994** |
| Estate goal | $500,000 — **already exceeded** |
| Investment horizon | 20–30+ years |

### Net Worth Breakdown

| Category | Balance |
|---|---|
| Liquid (checking/savings) | $309,908 |
| Investments (bond ladder) | $39,847 |
| Other assets (home + aircraft loan) | $218,206 |
| Credit cards | ($9,967) |
| **Net Worth** | **$557,994** |

### Target Allocation (7 Asset Classes)

| Asset Class | % | $ Amount | Vehicle |
|---|---|---|---|
| U.S. Large Cap | 20% | $111,599 | SPY or VTSAX |
| International Developed | 15% | $83,699 | VEA |
| Emerging Markets | 15% | $83,699 | VWO or INDA |
| Bonds (Core/Ladder) | 25% | $139,498 | VBTLX or ladder |
| Infrastructure | 10% | $55,799 | GRID |
| Commodities/Transition | 5% | $27,900 | COPX or URA |
| Cash Reserve | 10% | $55,799 | HYSA or Money Market |

### 5-Year Net Worth Projections ($5,200/month contributions)

| Scenario | Return | Year 1 | Year 3 | Year 5 |
|---|---|---|---|---|
| Conservative | 5.0% | $652k | $830k | $1.03M |
| Base Case | 7.5% | $665k | $898k | $1.17M |
| Optimistic | 9.0% | $678k | $967k | $1.25M |

### What Was Built

- `R/data_import.R::import_qif_accounts()` — Parses Banktivity QIF exports (header-section-only parser; bug fixed)
- `R/personal_wealth_monitoring.R` — Full monitoring suite:
  - `calculate_net_worth()`, `calculate_allocation()`, `assess_goal_progress()`
  - `project_net_worth()`, `rebalance_guidance()`, `assess_drawdown_risk()`
  - `generate_quarterly_dashboard()`
- `scripts/04_quarterly_wealth_dashboard.R` — Automated quarterly reporting; runs in ~10 seconds
- `data/external/personal_wealth_plan_complete.md` — 12,000-word financial plan
- `PERSONAL_WEALTH_PLAN_SUMMARY.md`, `ACTION_ITEMS_NEXT_30_DAYS.md`, `DELIVERABLES_INDEX.md`

---

## Phase 3: Colombia Investment System + Global Economic Indicators

**Approved:** September 21, 2026 | **Parts 1–3 complete; Part 4 (script 09) next**

### Context

- Home in Colombia (~1.2 billion COP / ~$375k USD at 3,193 COP/USD)
- Colombian bank accounts: BBVA + Bancolombia (~30 million COP / ~$9,400 USD)
- Pursuing dual U.S.–Colombian citizenship (wife Anna is Colombian citizen)
- Goal: Generate COP cash flow to hedge USD/COP currency risk; integrate comprehensive global indicators into portfolio prioritization

**Combined net worth (USD + COP assets): ~$943k USD equivalent** (as of Sep 21, 2026)

### Dual-Currency Snapshot (Sep 21, 2026)

| Metric | Value |
|---|---|
| COP/USD rate | 3,193 (COP strengthened 7.3% YTD) |
| Annualized COP/USD volatility | 13.7% |
| Current USD exposure (investable) | 97.4% |
| Target USD exposure | 80% |
| Current COP exposure (investable) | 2.6% |
| Target COP exposure | 20% |
| Action | Redirect contributions to COP for ~11 months |

### Colombia Investment Universe (14 COP Vehicles)

| Vehicle | Nominal Yield | Risk | Fogafin |
|---|---|---|---|
| Ecopetrol Corporate Bond | 13.0% | Moderate | No |
| Bancolombia Senior Bond | 12.5% | Moderate | No |
| TES 30Y | 12.0% | Low | No |
| TES 10Y | 11.5% | Low | No |
| TES 5Y | 11.2% | Low | No |
| BBVA CDT 360d | 10.5% | Minimal | Yes |
| TES 1Y | 10.5% | Low | No |
| Bancolombia CDT 360d | 10.2% | Minimal | Yes |
| BBVA CDT 180d | 10.0% | Minimal | Yes |
| BBVA CDT 90d | 9.5% | Minimal | Yes |
| Ecopetrol equity | 5.0% div | High | No |
| BBVA Savings | 4.0% | Minimal | Yes |
| Bancolombia Savings | 3.8% | Minimal | Yes |
| COLCAP ETF | 2.5% div | High | No |

TES 5Y real yield: ~5.7% FX-adjusted (base case). Beats USD risk-free rate.

### R Modules Built (Phase 3)

| File | Status | Purpose |
|---|---|---|
| `R/economic_indicators.R` | ✅ Complete | 30+ source loaders (FRED 33 series, WDI 16 indicators, 19 FX pairs) |
| `R/colombia_indicators.R` | ✅ Complete | COP/USD, TES, COLCAP, 14-vehicle bond screener, income forecaster |
| `R/personal_wealth_monitoring.R` | ✅ Extended | +4 dual-currency functions: net worth, exposure, projection, rebalancing |

### Scripts Built (Phase 3)

| Script | Status | Purpose |
|---|---|---|
| `05_collect_global_indicators.R` | ✅ Complete | Pull FRED, WDI, FX data; save 5 timestamped CSVs |
| `06_colombia_economic_snapshot.R` | ✅ Complete | Colombia dashboard: FX, macro, TES, bond screen |
| `07_evaluate_colombia_investments.R` | ✅ Complete | Rank COP vehicles; 5-year income forecast; 2 charts |
| `08_quarterly_dual_currency_review.R` | ✅ Complete | USD + COP quarterly review; 2 charts; 3 CSV exports |
| `09_indicator_driven_portfolio_ranking.R` | 🔲 Next | Dynamic conviction reweighting by live indicators |

### Phase 3 Key Outputs

| Output | Description |
|---|---|
| `reports/investment_dashboard_2026-09-21.html` | Interactive dual-currency dashboard (Chart.js, 25KB) |
| `data/external/data_source_registry.csv` | 30 data sources with API metadata |
| `data/processed/colombia_snapshot_[DATE].csv` | Live Colombia macro snapshot |
| `data/processed/bond_screen_[DATE].csv` | 14-vehicle COP bond screen |
| `data/processed/global_indicators_[DATE].csv` | Combined FRED + WDI + FX indicators |

---

## Suggested R Packages

```r
install.packages(c(
  "tidyverse", "tidyquant", "quantmod", "PerformanceAnalytics",
  "xts", "zoo", "slider", "lubridate", "janitor",
  "arrow", "readxl", "httr2", "jsonlite",
  "countrycode", "WDI", "fredr",
  "ggplot2", "patchwork", "scales", "gt", "DT", "quarto"
))
```

---

## Benchmarking Standards

| Benchmark | Symbol | When Used |
|---|---|---|
| Broad U.S. equities | SPY / VTI | Default benchmark for all global comparisons |
| U.S. growth | QQQ | Growth-tilted opportunity comparison |
| U.S. small caps | IWM | Small-cap screening |
| U.S. bonds | IEF / TLT / AGG | Fixed income comparison |
| U.S. cash | BIL | Opportunity cost of cash |
| Developed ex-U.S. | VEA | International developed baseline |
| Emerging markets | VWO | EM baseline |

---

## Key Documentation

| Need | File |
|---|---|
| Project history, phases, coding standards | `AGENTS.md` |
| Step-by-step workflow guide | `docs/WORKFLOW_GUIDE.md` |
| GID macro data catalog (135 indicators) | `docs/DATA_INVENTORY_AND_LINKAGE.md` |
| Phase-by-phase completion record | `docs/PROJECT_COMPLETION_SUMMARY.md` |
| Personal wealth plan (full) | `data/external/personal_wealth_plan_complete.md` |
| Wealth plan summary | `PERSONAL_WEALTH_PLAN_SUMMARY.md` |
| 30-day action items | `ACTION_ITEMS_NEXT_30_DAYS.md` |
| Country memo template | `notebooks/country_deep_dive_template.qmd` |
| Colombia investment analysis | `notebooks/colombia_investment_analysis.qmd` |
| Interactive dual-currency dashboard | `reports/investment_dashboard_2026-09-21.html` |

---

## Disclaimer

This project is for research and analysis only, not personalized financial advice. Consult a qualified financial advisor before making investment decisions.
