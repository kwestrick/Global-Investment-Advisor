# Global Investment Advisor

## Purpose

Global Investment Advisor is an R-first investment research and personal wealth management project. It combines:

1. **Global market research** — Systematic identification and ranking of non-U.S. investment opportunities that may offer better forward risk/reward than comparable U.S. assets.
2. **Personal financial planning** — A reproducible monitoring system for a dual-currency personal wealth plan (USD + COP).
3. **Colombia investment analysis** — Tools for analyzing COP-denominated cash-generating investments, currency hedging, and dual-citizenship financial planning *(Phase 3, in progress)*.

The default benchmark is the United States. Every major opportunity is compared against U.S. equities, bonds, or cash. The goal is not to assume non-U.S. assets will outperform but to systematically identify cases where valuation, macro regime change, policy divergence, capital flows, currency dynamics, or geopolitical catalysts create a superior risk/reward setup.

---

## Project Status

| Phase | Description | Status | Completed |
|---|---|---|---|
| **Phase 1** | Global investment research infrastructure (screening, memos, data collection) | ✅ Complete | Sep 21, 2026 |
| **Phase 2** | Personal wealth plan with QIF import, monitoring, quarterly dashboard | ✅ Complete | Sep 21, 2026 |
| **Phase 3** | Colombia investment system + global economic/climate indicators | 🔄 Approved, implementing | Sep 21, 2026 |

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

### Colombia Snapshot *(Phase 3 — Coming)*

```r
source("scripts/06_colombia_economic_snapshot.R")
source("scripts/07_evaluate_colombia_investments.R")
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
│   ├── personal_wealth_monitoring.R    # Net worth, allocation, goal tracking, projections
│   ├── economic_indicators.R           # [Phase 3] 30+ macro/climate source loaders
│   ├── colombia_indicators.R           # [Phase 3] COP/USD, TES, COLCAP, DANE
│   ├── climate_geopolitical.R          # [Phase 3] ESG, political risk, climate data
│   └── indicator_dashboard.R           # [Phase 3] Aggregate & normalize all indicators
├── scripts/                            # Numbered workflow scripts
│   ├── 01_collect_market_data.R        # ✅ Download prices for 48 ETFs + GID macro data
│   ├── 02_screen_global_assets.R       # ✅ Rank ETFs by conviction score
│   ├── 04_quarterly_wealth_dashboard.R # ✅ Quarterly personal wealth report
│   ├── 05_collect_global_indicators.R  # [Phase 3] Daily/weekly indicator collection
│   ├── 06_colombia_economic_snapshot.R # [Phase 3] Colombia dashboard
│   ├── 07_evaluate_colombia_investments.R # [Phase 3] Rank COP vehicles
│   ├── 08_quarterly_dual_currency_review.R # [Phase 3] USD + COP quarterly review
│   └── 09_indicator_driven_portfolio_ranking.R # [Phase 3] Dynamic conviction reweighting
├── notebooks/                          # Quarto analytical notebooks
│   ├── country_deep_dive_template.qmd  # ✅ 10-section investment memo template
│   └── colombia_investment_analysis.qmd # [Phase 3] Colombia opportunity analysis
├── data/
│   ├── raw/                            # Source downloads; never edit manually
│   ├── processed/                      # Generated by scripts (timestamped)
│   └── external/                       # Lookup tables, reference data, wealth plan
│       ├── personal_wealth_plan_complete.md  # ✅ Full 12,000-word personal wealth plan
│       └── data_source_registry.csv    # [Phase 3] All 30+ data sources with API metadata
├── reports/
│   ├── investment_memos/               # Final rendered Quarto memos
│   └── dashboards/
├── outputs/
│   ├── charts/                         # Saved PNG/PDF plots
│   └── tables/                         # Saved CSV/HTML tables
└── docs/                               # Project documentation
    ├── WORKFLOW_GUIDE.md               # ✅ Step-by-step workflow guide
    ├── DATA_INVENTORY_AND_LINKAGE.md   # ✅ GID macro data catalog (227K observations)
    ├── PROJECT_COMPLETION_SUMMARY.md   # ✅ Phase-by-phase completion record
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

**Approved:** September 21, 2026 | **Status:** Implementation beginning

### Context

- Home in Colombia (~1.2 billion COP / ~$300k USD)
- Colombian bank accounts: BBVA + Bancolombia (~30 million COP / ~$7,500 USD)
- Pursuing dual U.S.–Colombian citizenship (wife Anna is Colombian citizen)
- Goal: Generate COP cash flow to hedge USD/COP currency risk; integrate comprehensive global indicators into portfolio prioritization

### Colombia Investment Universe

| Vehicle | Yield (nominal) | Risk |
|---|---|---|
| COP savings accounts (BBVA/Bancolombia) | 4.0–4.5% | Minimal |
| Colombian government bonds (TES) | 10–12% | Moderate |
| Corporate bonds (local) | 8–11% | Moderate–High |
| COLCAP dividend stocks | 2–3% dividend | Moderate–High |
| Real estate rental income | 5–7% net | Moderate |

### New R Modules Planned

| File | Purpose |
|---|---|
| `R/economic_indicators.R` | 30+ macro/climate/political source loaders |
| `R/colombia_indicators.R` | COP/USD, TES yield curve, COLCAP, DANE inflation, Banco de la República rates |
| `R/climate_geopolitical.R` | V-Dem democracy index, Fragile States, IEA, World Bank climate |
| `R/indicator_dashboard.R` | Normalize and aggregate all indicators to a standard long format |

### New Scripts Planned

| Script | Purpose |
|---|---|
| `05_collect_global_indicators.R` | Pull 30+ macro/climate/political indicators on schedule |
| `06_colombia_economic_snapshot.R` | Colombia dashboard: FX, inflation, TES, bank rates |
| `07_evaluate_colombia_investments.R` | Rank COP vehicles by real yield (net of inflation + FX) |
| `08_quarterly_dual_currency_review.R` | Consolidated USD + COP quarterly review |
| `09_indicator_driven_portfolio_ranking.R` | Dynamic conviction reweighting by live indicators |

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

---

## Disclaimer

This project is for research and analysis only, not personalized financial advice. Consult a qualified financial advisor before making investment decisions.
