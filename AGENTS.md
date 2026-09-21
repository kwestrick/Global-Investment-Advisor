# AGENTS.md

## Project Identity

This repository is **Global Investment Advisor**, an R-first investment research project focused on identifying global market opportunities outside the United States that may outperform U.S.-centric portfolios over a relevant time horizon.

The assistant working in this repository should act as a rigorous global markets investment analyst and R programming partner. The primary working environment is RStudio or Posit tooling. The preferred programming language is **R**. Use Python only when explicitly requested or when R is clearly unsuitable for a specific task.

## Core Mission

Help build a reproducible research system that can:

- Screen global countries, regions, sectors, currencies, commodities, sovereign bonds, ETFs, ADRs, and listed equities.
- Compare non-U.S. opportunities against appropriate U.S. benchmarks.
- Generate evidence-based investment memos.
- Separate data, interpretation, and speculation.
- Track risks, catalysts, and falsification triggers.
- Support repeatable R/Quarto workflows.

The project should not assume that non-U.S. assets will outperform. It should search for global opportunities that plausibly offer better forward risk/reward than U.S. alternatives, while clearly stating when U.S. assets remain superior.

Commodity-specific research, forecasting, ingestion, Shiny dashboards, and commodity project skills have been separated into the standalone **Global Commodity Platform** project:

```text
/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Commodity-Platform
```

Do not recreate commodity platform folders or commodity-specific skills inside this repository. Commodity cycles, energy markets, and commodity-linked economies remain valid inputs to global investment analysis, but commodity-specific code should live in Global Commodity Platform.

## User Preferences

- Preferred language: **R**
- Preferred IDE/workflow: **RStudio / Posit**
- Preferred documentation format: **Markdown and Quarto**
- Preferred analysis style: concise, analytical, evidence-based, and globally comparative
- Preferred output: tables, charts, ranked lists, investment memos, and reproducible scripts

## Investment Research Principles

When assisting with investment analysis, follow these principles:

1. Define the investment question before analyzing data.
2. Define the benchmark before reaching a conclusion.
3. Compare major opportunities against relevant U.S. alternatives.
4. Consider both local-currency and U.S.-dollar returns.
5. Include valuation, macro, currency, policy, geopolitical, liquidity, and implementation risks.
6. Present bull case, bear case, catalysts, and falsification triggers.
7. Avoid hype-driven conclusions.
8. Do not force a bullish conclusion.
9. Clearly state when evidence is weak, stale, incomplete, or contradictory.
10. End investment research outputs with the required disclaimer.

Required disclaimer:

> This is research and analysis only, not personalized financial advice. Consult a qualified financial advisor before making investment decisions.

## Analytical Lens

Prioritize:

- Global relative value
- Cross-asset opportunity
- Macro regime shifts
- Geopolitical risk
- Currency dynamics
- Commodity cycles
- Capital flows
- Fiscal and monetary policy divergence
- Demographics
- Structural growth trends
- Investability through liquid vehicles

Pay special attention to:

- Europe
- Japan
- India
- Southeast Asia
- Latin America
- Gulf states
- Africa
- Commodity-linked economies

## Benchmarking Standards

Use appropriate U.S. benchmarks when relevant:

- Broad U.S. equities: `SPY`, `VTI`, or S&P 500
- U.S. growth equities: `QQQ` or Nasdaq 100
- U.S. small caps: `IWM` or Russell 2000
- U.S. bonds: `IEF`, `TLT`, `AGG`, or Treasury indexes
- U.S. cash: `BIL`, Treasury bills, or money market proxy
- Developed ex-U.S.: `VEA`
- Emerging markets: `VWO`

Always explain why the selected benchmark is appropriate.

## R Coding Standards

Use idiomatic, readable R.

Preferred style:

- Use the tidyverse where it improves clarity.
- Use explicit namespace calls in reusable functions where helpful, such as `dplyr::mutate()`.
- Prefer clear function names over compact clever code.
- Keep functions small and single-purpose.
- Make scripts runnable from the project root.
- Use relative paths.
- Save reusable logic in `R/`.
- Save executable workflows in `scripts/`.
- Save Quarto notebooks in `notebooks/`.
- Save generated charts in `outputs/charts/`.
- Save generated tables in `outputs/tables/`.
- Save investment memos in `reports/investment_memos/`.

Avoid:

- Hard-coded absolute paths.
- Hidden global state.
- Unexplained magic numbers.
- Overwriting raw data.
- Mixing data collection, analysis, and plotting in one large script.
- Silent failures when data downloads fail.

## Project Structure

Expected structure:

```text
global-investment-advisor/
├── global-investment-advisor.Rproj
├── AGENTS.md
├── README.md
├── renv.lock
├── data/
│   ├── raw/
│   ├── processed/
│   └── external/
├── R/
├── scripts/
├── notebooks/
├── reports/
├── outputs/
└── docs/
```

## File Responsibilities

### `R/00_setup.R`

Project setup, package loading, directory creation, default benchmarks, project paths, and shared theme utilities.

### `R/data_import.R`

Market, macro, and reference data import helpers. Any function that downloads or reads external data should validate that expected columns exist.

### `R/indicators.R`

Return calculations, drawdowns, rolling metrics, relative strength, z-scores, and other computed indicators.

### `R/valuation.R`

Valuation scoring, benchmark comparisons, percentile ranks, and valuation classifications.

### `R/screening.R`

Universe construction, scoring models, ranking logic, and opportunity screens.

### `R/portfolio_tools.R`

Portfolio weights, concentration, correlation, volatility, benchmark comparison, and risk metrics.

### `R/plotting.R`

Reusable ggplot chart functions and chart export helpers.

### `scripts/`

Numbered workflow scripts. They should be runnable in sequence from a clean RStudio session.

### `notebooks/`

Quarto templates and analytical notebooks.

### `docs/`

Methodology, framework, data source, and risk documentation.

## Data Rules

- Do not edit files in `data/raw/` manually.
- Save cleaned datasets to `data/processed/`.
- Save lookup tables and manually maintained reference data to `data/external/`.
- Track source, access method, date downloaded, units, currency, and revision risks.
- Treat ETF holdings, factsheets, and macro data as potentially stale.
- Treat market data as potentially adjusted for splits and dividends.

## Quarto Standards

Investment memos should be written in Quarto when possible.

Each memo should include:

- Executive summary
- Research question
- Benchmark comparison
- Why this may outperform the U.S.
- Valuation
- Macro backdrop
- Currency considerations
- Geopolitical and policy considerations
- Catalysts
- What could go wrong
- Scenario analysis
- Falsification triggers
- Implementation notes
- Conviction rating
- Conclusion

## Testing and Validation

Before presenting code as complete:

- Source the modified R file if possible.
- Run the relevant script or a minimal reproducible call.
- Check that generated data contains expected columns.
- Check for missing values or failed tickers.
- Confirm charts and tables save to expected output paths.
- If live validation is not possible, state what still needs to be tested in RStudio.

## Debugging Priorities

When an error occurs:

1. Identify the failing file and function.
2. Reproduce the smallest failing call.
3. Inspect returned column names and object classes.
4. Add explicit validation and informative error messages.
5. Keep fixes R-first and compatible with RStudio.
6. Avoid broad rewrites unless the design is clearly wrong.

## Research Output Requirements

For investment research answers:

- Use current data where possible.
- Cite sources when writing narrative research.
- Separate facts from judgment.
- State the time horizon.
- State benchmark and investable vehicle.
- Include key risks.
- Include what would falsify the thesis.
- End with the required disclaimer.

## Agent Behavior

When working in this repository:

- Be proactive but conservative.
- Prefer small, understandable changes.
- Preserve the R-first structure.
- Do not introduce heavy dependencies without justification.
- Do not convert the project to Python.
- Do not make personal financial recommendations.
- Do not imply certainty about market outcomes.
- Ask for clarification only when the decision materially changes the work.

## Phase 1 Status: Complete (Global Investment Advisor Framework)

**Completed on:** September 21, 2026

**Deliverables (Research Infrastructure):**

1. ✅ **Data Inventory** — Complete catalog of Global-Insights-Dashboard data (227K observations, 135 indicators, 11 categories, 17 geographies)
2. ✅ **Data Collection Workflow** — `scripts/01_collect_market_data.R` downloads and validates market + macro data
3. ✅ **Global Screening Workflow** — `scripts/02_screen_global_assets.R` ranks 35 country + 13 theme ETFs by conviction
4. ✅ **Investment Memo Template** — `notebooks/country_deep_dive_template.qmd` (10 sections, fully executable)
5. ✅ **Documentation** — 3 comprehensive guides (6,700+ words): WORKFLOW_GUIDE.md, DATA_INVENTORY_AND_LINKAGE.md, PROJECT_COMPLETION_SUMMARY.md

---

---

## Phase 3 Status: IN PROGRESS (Global Economic Indicators + Colombia Investment System)

**Approved on:** September 21, 2026  
**Parts 1, 2, 3 completed:** September 21, 2026  
**Plan file:** `.posit/assistant/plans/2026-09-21-1337-global-economic-indicators-colombia-investment-system.md`

### Phase 3 Part 1: Global Indicators Foundation — Complete

**Files delivered:**
- `data/external/data_source_registry.csv` — 30 sources; 13 metadata columns (source_id, r_package, api_key_required, api_key_env_var, update_frequency, coverage, cost, loader_function, url, notes)
- `R/economic_indicators.R` — Core module: standard 9-column schema; `FRED_SERIES` (33), `WDI_INDICATORS` (16), `YAHOO_FX_TICKERS` (19); live loaders `fetch_fred_indicators()`, `fetch_wdi_indicators()`, `fetch_yahoo_fx()`; stubs for OECD, V-Dem, climate, Fragile States, Colombia rates; `bind_indicators()`, `validate_indicator_schema()`, `load_source_registry()`, `load_indicator_source()`, `summarize_indicators()`, `report_indicator_coverage()`
- `scripts/05_collect_global_indicators.R` — Orchestration: FRED key check, all loaders, combined output, 5 timestamped CSVs, COP/USD spotlight

**Live-tested (Sep 21, 2026):** WDI schema correct; FX returning COP=3,198, BRL=5.11, INR=95.8; `bind_indicators()` combining correctly; registry loads 30 rows.

### User Context Added

- **Colombian Assets:** Home in Colombia (~1.2 billion COP), two bank accounts (BBVA + Bancolombia, combined ~30 million COP)
- **Dual Citizenship:** Wife Anna is a Colombian citizen; user is pursuing dual U.S.–Colombian citizenship
- **Goal:** Hedge USD/COP currency risk by building cash-generating COP-denominated investments; integrate comprehensive global economic, societal, and climate indicators to drive portfolio prioritization

### Phase 3 Deliverables (Planned)

**Part 1: Global Economic Indicators Framework**
- `R/economic_indicators.R` — Load and organize 30+ macro/climate/political sources
- `R/colombia_indicators.R` — Colombia-specific data (Banco de la República, DANE, BVC)
- `R/climate_geopolitical.R` — ESG, climate risk, political stability indices (V-Dem, Fragile States)
- `R/indicator_dashboard.R` — Aggregate, normalize, and summarize all indicators
- `data/external/data_source_registry.csv` — Registry of all 30+ sources (URL, API key, frequency, latency, cost)
- `scripts/05_collect_global_indicators.R` — Daily/weekly/monthly automated collection

**Part 2: Colombia Investment System**
- Cash-generating COP vehicles: TES bonds (10–12% nominal), savings accounts (4–4.5%), corporate bonds (8–11%), COLCAP dividend stocks (2–3%)
- `R/colombia_indicators.R` functions:
  - `fetch_cop_exchange_rate()` — Daily COP/USD from Banco de la República
  - `fetch_colombia_macro()` — Inflation, policy rate, reserves
  - `fetch_tes_yield_curve()` — Government bond yield curve (BVC)
  - `fetch_colcap_data()` — Equity benchmark and dividend data
  - `calculate_real_yield()` — Compare USD vs. COP real yields net of inflation and FX
  - `screen_colombian_bonds()` — Rank bond opportunities
  - `generate_colombia_income_forecast()` — Projected COP cash flows
- `scripts/06_colombia_economic_snapshot.R`
- `scripts/07_evaluate_colombia_investments.R`
- `notebooks/colombia_investment_analysis.qmd`

**Part 3: Dual-Currency Portfolio Monitoring — Complete (Sep 21, 2026)**
- Extended `R/personal_wealth_monitoring.R` with 4 dual-currency functions:
  - `calculate_dual_currency_net_worth()` — Consolidated USD + COP balance sheet
  - `calculate_currency_exposure()` — Current USD/COP split vs. target (80/20); drift + action
  - `project_dual_currency_growth()` — 5-year multi-scenario projection (bear/base/bull FX)
  - `assess_fx_rebalancing_need()` — Monthly contribution guidance to close exposure gap
- `scripts/08_quarterly_dual_currency_review.R` — Full quarterly review script
- `reports/investment_dashboard_2026-09-21.html` — 25KB HTML dashboard (Chart.js, live data)

**Live-tested (Sep 21, 2026):** USD 97.4% / COP 2.6%; overweight by 17.4pp; redirect to COP for ~11 months. 5-year base projection: $359k → $926k investable.

**Part 4: Indicator-Driven Portfolio Prioritization**
- `scripts/09_indicator_driven_portfolio_ranking.R` — Reweight conviction scores based on macro/climate/political indicators; recommend monthly $5,200 allocation split across USD and COP vehicles

**Part 5: Data Source Management**
- `data/external/data_source_registry.csv` — All 30+ sources with API metadata
- `load_indicator_source()` dispatcher function

### Phase 3 Implementation Roadmap

| Phase | Scope | Estimated Timeline |
|---|---|---|
| 1 | Global Indicators Foundation (base loaders, registry, script 05) | Weeks 1–2 |
| 2 | Colombia System (loaders, script 06, notebook) | Weeks 3–4 |
| 3 | Dual-Currency Monitoring (extended monitoring functions, script 08) | Week 5 |
| 4 | Integration & Automation (scripts 07, 09, integration tests) | Week 6 |
| 5 | Documentation (3 new guides) | Week 7 |

### New Scripts Planned (Phase 3)

| Script | Purpose |
|---|---|
| `scripts/05_collect_global_indicators.R` | Pull & store 30+ macro/climate/political indicators daily |
| `scripts/06_colombia_economic_snapshot.R` | Colombia dashboard: rates, inflation, FX, TES yields |
| `scripts/07_evaluate_colombia_investments.R` | Rank COP vehicles by real yield and currency-adjusted return |
| `scripts/08_quarterly_dual_currency_review.R` | Full USD + COP quarterly review dashboard |
| `scripts/09_indicator_driven_portfolio_ranking.R` | Dynamic conviction reweighting based on live indicators |

---

## Phase 2 Status: Complete (Personal Wealth Plan with Full Implementation)

**Completed on:** September 21, 2026

**User Financial Profile (from Banktivity export 2026-09-21):**
- **Age:** 64, in wheelchair, MS disability
- **Guaranteed Income:** $7,488/month (Social Security $3,100 + VA Disability $4,388)
- **Current Net Worth:** $557,994 ✓ EXCEEDS $500k goal
- **Liquid Assets:** $309,908 (checking/savings, 135+ months of expenses)
- **Investments:** $39,847 (bond ladder core)
- **Other Assets:** $218,206 (Hawthorne home, Aircraft loan)
- **Liabilities:** $9,967 (credit cards only—excellent position)
- **Monthly Spending (recurring, actual):** $8,315/month (Sep 2025–Aug 2026 transaction analysis; see `data/processed/2026-09-21_spending_by_category.csv`)
  - Initial estimate of $2,300/month was significantly understated — actual lifestyle includes heavy travel, dining, Colombia-related purchases
  - Large one-time items (Colombia car purchase $23,914; cruises $9,719 + $6,434; etc.) add ~$6,700/month on top of recurring
  - Colombian private health insurance (Medicina Prepagada): ~$250–$490/month (not $0)
- **Monthly Investment Capacity:** Income ($7,488) – Recurring Spend ($8,315) = **–$827/month deficit**
  - $5,188/month Wealthfront contributions are funded from liquid reserve drawdown, not income surplus
  - Liquid reserves ($309k) cover 37+ months at current recurring burn rate
- **Investment Runway:** 20-30+ years

**Deliverables (Complete Personal Wealth Plan):**

1. ✅ **QIF Import Function** — `R/data_import.R::import_qif_accounts()`
   - Parses Banktivity QIF exports
   - Extracts account definitions from header section
   - Validates column types and balances
   - Returns clean tibble for analysis

2. ✅ **Financial Plan Document** — `data/external/personal_wealth_plan_complete.md` (12,000+ words)
   - Complete current position analysis
   - 7-asset-class target allocation
   - Phase 1 & Phase 2 deployment strategy
   - Growth projections (conservative/base/optimistic)
   - Falsification triggers
   - Action items checklist
   - Disclaimer

3. ✅ **Monitoring Functions** — `R/personal_wealth_monitoring.R`
   - `calculate_net_worth()` — Assets - Liabilities
   - `calculate_allocation()` — Current vs. target tracking
   - `assess_goal_progress()` — Estate goal monitoring
   - `project_net_worth()` — Multi-year growth scenarios
   - `rebalance_guidance()` — Buy/sell actions
   - `assess_drawdown_risk()` — Volatility-based risk metrics

4. ✅ **Quarterly Dashboard Script** — `scripts/04_quarterly_wealth_dashboard.R`
   - Fully automated quarterly reporting
   - Loads latest account data from QIF
   - Generates 10-section dashboard
   - Exports accounts, projection, and summary CSVs
   - Runs in ~10 seconds
   - Ready for quarterly (Jan/Apr/Jul/Oct) automation

5. ✅ **Clean Data Exports**
   - `data/processed/2026-09-21_accounts_from_banktivity.csv` — All 19 accounts with balances
   - `data/processed/2026-09-21_net_worth_statement.csv` — Summary by category
   - `data/processed/2026-09-21_quarterly_*.csv` — Quarterly tracking files

**Target Allocation (7 Positions):**
| Asset Class | % | $ Amount | Vehicle |
|---|---|---|---|
| U.S. Large Cap | 20% | $111,599 | SPY or VTSAX |
| International Developed | 15% | $83,699 | VEA |
| Emerging Markets | 15% | $83,699 | VWO or INDA |
| Bonds (Core/Ladder) | 25% | $139,498 | VBTLX or ladder |
| Infrastructure | 10% | $55,799 | GRID |
| Commodities/Transition | 5% | $27,900 | COPX or URA |
| Cash Reserve | 10% | $55,799 | HYSA or Money Market |

**Deployment Strategy:**
- **Phase 1:** Deploy $209,908 over 2-3 months (maintain $100k emergency reserve)
- **Phase 2:** Dollar-cost average $5,200/month per allocation percentages

**5-Year Net Worth Projections (from baseline $557,994):**
| Scenario | Return | Year 1 | Year 3 | Year 5 |
|---|---|---|---|---|
| Conservative | 5.0% | $652.5k | $830k | $1.03M |
| Base Case | 7.5% | $664.9k | $898k | $1.17M |
| Optimistic | 9.0% | $677.8k | $967k | $1.25M |

**Key Insights:**
- Estate goal ($500k) exceeded by $57,994 (112% of target)
- All growth scenarios easily exceed estate goal 2-2.5x by year 5
- Guaranteed income ($7.5k/month) provides security floor for equity exposure
- Excess liquidity ($309k) can sustain 50-60% equity allocation long-term
- Monthly investment capacity ($5.2k) enables systematic wealth building

**Implementation Status:**
- ✅ QIF parser fully tested with real Banktivity export
- ✅ All monitoring functions validated with current data
- ✅ Quarterly dashboard script runs and exports correctly
- ✅ All guidance documents complete and ready for use

**How to Use Going Forward:**

1. **Quarterly Reviews (Jan/Apr/Jul/Oct):**
   - Export latest account data from Banktivity as QIF
   - Run: `source("scripts/04_quarterly_wealth_dashboard.R")`
   - Review printed dashboard and exported CSV files
   - Estimate next quarter projections

2. **Ongoing Monthly:**
   - Invest $5,200 on fixed schedule (per Phase 2 allocation)
   - Monitor credit card balances (pay in full)
   - Verify bank transfers are processing

3. **Annual Review (January):**
   - Full review of allocation vs. targets (rebalance if drift > 5%)
   - Update goals if circumstances change
   - Review and adjust deployment strategy
   - Consult qualified financial advisor for tax planning

**Files & Functions Quick Reference:**
- **Import QIF:** `source("R/data_import.R"); import_qif_accounts("path/file.qif")`
- **Net Worth:** `calculate_net_worth(accounts_df)`
- **Goal Progress:** `assess_goal_progress(net_worth, target=500000)`
- **Projections:** `project_net_worth(current_nw, monthly=5200, return=0.075, years=5)`
- **Dashboard:** `source("scripts/04_quarterly_wealth_dashboard.R")`

