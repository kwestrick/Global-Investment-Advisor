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

## Phase 3 Status: Complete (Global Economic Indicators + Colombia Investment System)

**Approved on:** September 21, 2026  
**Completed on:** September 21, 2026  
**Plan file:** `.posit/assistant/plans/2026-09-21-1337-global-economic-indicators-colombia-investment-system.md`

### Quarterly Workflow

Run `source("scripts/00_quarterly_refresh.R")` at the start of each quarterly review (January, April, July, October). This script:
1. Sources `scripts/01_collect_market_data.R` — refreshes ETF price data
2. Sources `scripts/02_screen_global_assets.R` — regenerates conviction scores
3. Sources `scripts/09_indicator_driven_portfolio_ranking.R` — live allocation recommendation
4. Renders `reports/monthly_allocation_brief.qmd` — self-contained HTML report
5. Prints a manual-steps checklist (Banktivity QIF export, Colombia snapshots, allocation decision, git commit)

**Before running:** export latest Banktivity accounts as QIF to `data/raw/`, and confirm `FRED_API_KEY` is set in `.Renviron`.

### Phase 3 Part 1: Global Indicators Foundation — Complete

**Files delivered:**
- `data/external/data_source_registry.csv` — 30 sources; 13 metadata columns (source_id, r_package, api_key_required, api_key_env_var, update_frequency, coverage, cost, loader_function, url, notes)
- `R/economic_indicators.R` — Core module: standard 9-column schema; `FRED_SERIES` (33), `WDI_INDICATORS` (16), `YAHOO_FX_TICKERS` (19); live loaders `fetch_fred_indicators()`, `fetch_wdi_indicators()`, `fetch_yahoo_fx()`; stubs for OECD, V-Dem, climate, Fragile States, Colombia rates; `bind_indicators()`, `validate_indicator_schema()`, `load_source_registry()`, `load_indicator_source()`, `summarize_indicators()`, `report_indicator_coverage()`
- `scripts/05_collect_global_indicators.R` — Orchestration: FRED key check, all loaders, combined output, 5 timestamped CSVs, COP/USD spotlight

**Live-tested (Sep 21, 2026):** WDI schema correct; FX returning COP=3,198, BRL=5.11, INR=95.8; `bind_indicators()` combining correctly; registry loads 30 rows.

### User Context Added

- **Colombian Assets:** Home in Colombia (~1.2 billion COP), two bank accounts (BBVA + Bancolombia, combined ~30 million COP). **The Colombia home is a legacy asset designated for son Anton — it is not expected to be sold and should not be treated as investable or deployable capital in any financial model.** Its USD-equivalent value is tracked for net worth reporting and FX sensitivity monitoring only.
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

**Part 4: Indicator-Driven Portfolio Prioritization — Complete (Sep 21, 2026)**
- `scripts/09_indicator_driven_portfolio_ranking.R` — 8-section live indicator pipeline:
  - Live FX (COP/USD, DXY) + benchmark ETF prices (Yahoo Finance)
  - FRED CPI with graceful fallback; 7 indicator signals
  - Indicator modifiers applied to global ETF conviction scores
  - COP vehicle ranking by real yield (Fisher) + momentum bonus
  - Currency allocation decision vs indicator-adjusted 80/20 target
  - Monthly $ allocation recommendation per vehicle/ETF
  - Exports to `outputs/tables/`
- Live results (Sep 21, 2026): US CPI 3.4% (moderate); all momentum signals neutral; Colombia TES 10Y real yield 5.7% (attractive); recommendation: redirect all $5,200/mo to COP for ~13 months (USD 17.4pp overweight)

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

## Analytical Findings — Sep 21, 2026 (Post-Model Council Review)

Three key analytical findings were derived after the Model Council review of `investment_plan_full.md`. These findings supersede earlier Phase 1 assumptions and are reflected in the updated `reports/investment_plan_full.md` and `scripts/10_rebuild_investment_plan_tables.R`.

### 1. COP Reserve Sizing: Spending-Based, Not Percentage-Based

The prior 80/20 USD/COP target (implying ~$62K in COP assets) is replaced by a spending-needs approach. Based on 85 Colombia-linked transactions over 12 months:

**Monthly COP-linked spending by scenario:**

| Scenario | Monthly (USD) | 18-Month Reserve | Institutions Needed |
|---|---:|---:|---:|
| Low (1–2 trips/year) | $839 | $15,106 | 1 |
| Base (~1 month/quarter) | $1,089 | **$19,603** | 2 |
| High (6 months/year) | $1,339 | $24,099 | 2–3 |

**Fixed monthly costs (regardless of physical presence): ~$231/month**
- Medicina Prepagada: ~$200–300/month
- Prosegur (building security): ~$50/month
- UNE Telco (internet): ~$60/month
- Avianca LifeMiles subscription: $12/month

**Fogafín cap:** COP 50M per institution ≈ **$15,625 USD**. The 18-month base reserve (62.7M COP) requires 2 institutions. Do not concentrate more than COP 50M at any single bank.

**Key implication:** The COP reserve is approximately $15,000–$25,000 USD — far smaller than the previous $62K target. Phase 1 timeline shortens from ~13 months to ~3–5 months at $5,200/month.

**Script:** `scripts/10_rebuild_investment_plan_tables.R` calculates this live with current COP/USD.

### 2. CDT Reframing: Liability Hedge, Not Yield Play

After Colombian withholding, U.S. income tax (§988 ordinary income treatment), and even mild COP depreciation, the CDT carry advantage disappears in USD terms:

| Step | Rate |
|---|---:|
| Gross CDT yield (nominal COP) | 10.50% |
| Less: Colombian withholding (7%) | –0.74% |
| Less: U.S. income tax at 22% (net of FTC) | –1.58% |
| After-tax nominal yield (COP) | 8.19% |
| Less: COP inflation (Fisher) | –5.93% |
| **Real COP yield after all taxes** | **2.26%** |

**vs. USD T-bill at 4.8% after 22% U.S. tax = 3.74%**

| COP Depreciation | CDT After-Tax (USD) | T-Bill After-Tax | Carry Advantage |
|---|---:|---:|---:|
| 5% (mild) | 3.19% | 3.74% | **–0.55%** |
| 8% (moderate) | 0.19% | 3.74% | **–3.55%** |
| 10% (severe) | –1.81% | 3.74% | **–5.55%** |

**Correct frame:** CDTs fund COP obligations without USD conversion. The value is spending-coverage certainty, not excess yield. Size by spending need, not by yield opportunity.

**§988 note:** FX gains/losses on Colombian CDTs are ordinary income/loss for U.S. tax purposes, not capital gains. Verify the applicable withholding rate (7% is the resident rate; non-resident rates may be higher).

### 3. Wealthfront Platform Decision

**Account status (Sep 21, 2026):**
- Wealthfront Individual Cash Account: **$153,492** → Keep as USD liquidity reserve
- Wealthfront Joint Automated Investing Account: **$151** → Effectively unused

**Decision:** Redirect all investment contributions to a self-directed brokerage (Fidelity or Schwab). Wealthfront's robo-advisor cannot implement specific sleeve targets and would conflict with manual ETF allocation.

| Account | Purpose | Action |
|---|---|---|
| Wealthfront Cash ($153K) | USD liquidity reserve | Keep, no change |
| Fidelity or Schwab (new) | Strategic ETF portfolio (4 sleeves) | Open; redirect $5,200/month here |
| BBVA / Bancolombia | COP spending reserve (CDTs) | Fund slowly after tax gate cleared |

### 4. Balance Sheet Stress Scenarios (COP/USD)

*Updated Sep 23, 2026 to reflect new Banktivity export (USD NW $700,715).*

| Scenario | COP/USD | Colombia Home (USD) | USD NW | Combined NW | vs. Estate Goal |
|---|---:|---:|---:|---:|---:|
| Base | 3,200 | $375,000 | $700,715 | $1,075,715 | +$575,715 |
| Stress 1 | 3,600 | $333,333 | $700,715 | $1,034,048 | +$534,048 |
| Stress 2 | 4,500 | $266,667 | $700,715 | $967,382 | +$467,382 |

**Key finding:** USD net worth ($700,715) exceeds the $500K estate goal by $200,715 (140% of target) without any COP assets. The estate goal is not at risk from COP depreciation at any plausible exchange rate. However, the Colombia home's USD value declines by ~$108K under the 4,500 scenario — a meaningful wealth effect to monitor annually.

---

## Phase 2 Status: Complete (Personal Wealth Plan with Full Implementation)

**Completed on:** September 21, 2026

**User Financial Profile (updated from Banktivity export 2026-09-23):**
- **Age:** 64, in wheelchair, MS disability
- **Guaranteed Income:** $7,488/month (Social Security $3,100 + VA Disability $4,388)
- **Current Net Worth:** $700,715 ✓ EXCEEDS $500k goal (140% of target, +$200,715 surplus)
- **Liquid Assets:** $310,013 (checking/savings; essentially unchanged from Sep 21)
- **Investments:** $184,217 (bond ladder $103,287; Wealthfront Joint $80,619 ⚠️; other $311)
- **Other Assets:** $218,206 (Hawthorne home, Aircraft loan)
- **Liabilities:** $11,720 (credit cards — up from $9,967; normal spend)

> ✅ **Wealthfront Joint account ($80,619):** DECIDED Sep 23, 2026 — Transfer to Fidelity Joint taxable brokerage via in-kind ACATS immediately. No tax event on the transfer; modest LTCG (~$1,200–$2,400) expected at reallocation. Advances ETF portfolio crossover point from month 15 → month 7 and adds ~$117K to 5-year ETF value. Step-by-step ACATS instructions now in `reports/investment_plan_full.md` Section 6.
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

**5-Year Net Worth Projections (from updated baseline $700,715 — Sep 23, 2026):**
| Scenario | Return | Year 1 | Year 3 | Year 5 |
|---|---|---|---|---|
| Conservative | 5.0% | $798.2k | $1.01M | $1.24M |
| Base Case | 7.5% | $815.7k | $1.07M | $1.37M |
| Optimistic | 9.0% | $826.2k | $1.11M | $1.45M |

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

---

## Phase 4 Status: Complete (USD/COP FOREX Decision-Support Module)

**Approved on:** September 21, 2026
**Completed on:** September 22, 2026

### Design Rationale

Exchange rate point forecasting is unreliable (Meese-Rogoff 1983: random walk beats structural models out-of-sample). COP/USD is especially noisy — driven by Brent crude prices, Colombia fiscal situation, global EM risk appetite, and Fed policy. Rather than a false-precision point forecast, the module answers a more tractable question:

> **"Is now a relatively good time to convert USD to COP?"**

### Module: `R/fx_forecasting.R`

Two primary analytical layers:

1. **Historical percentile context** — where does the current COP/USD rate sit relative to history (1Y, 3Y, 5Y lookbacks)? A rate in the 70th+ percentile means the peso is historically weak — COP assets are cheaper in USD terms.
2. **GARCH(1,1) volatility bands** — realistic uncertainty intervals over a forward horizon (30/60/90 days). Uses `rugarch`. Does NOT claim to predict direction; shows the plausible range given current volatility regime.

Supporting functions:
- `prepare_cop_series(fx)` — extract clean date/rate from standard `fx` tibble schema
- `cop_historical_percentile(series, lookback_years)` — percentile rank + label
- `cop_garch_bands(series, horizon_days)` — fit GARCH(1,1), simulate forward paths, return quantile bands
- `cop_macro_signals()` — pull Brent crude, DXY, VIX as contextual macro signals
- `cop_conversion_signal(series, bands)` — synthesize into Favorable / Neutral / Unfavorable
- `plot_cop_bands(series, bands)` — ggplot: historical rate + GARCH uncertainty cone
- `print_cop_brief(series)` — console summary for quarterly workflow

### Package Dependencies (Phase 4)

| Package | Purpose | CRAN |
|---|---|---|
| `rugarch` | GARCH model fitting and simulation | Yes |
| `tidyquant` | Already in use for FX data | Yes |
| `ggplot2` | Already in use for charts | Yes |

### Integration Points

- Feeds from `fetch_cop_exchange_rate()` in `R/colombia_indicators.R`
- Accepts the `fx` tibble already in session (columns: date, geography, indicator_code, indicator_name, category, value, unit, source, frequency)
- `print_cop_brief()` should be called from `scripts/00_quarterly_refresh.R`
- `plot_cop_bands()` output saved to `outputs/charts/cop_usd_forecast_bands_YYYY-MM-DD.png`

### Decision Framework

| Percentile (5Y lookback) | GARCH Regime | Conversion Signal |
|---|---|---|
| ≥ 65th (peso historically weak) | Any | Favorable |
| 35th–65th (mid-range) | Low volatility | Neutral |
| 35th–65th (mid-range) | High volatility | Cautious |
| ≤ 35th (peso historically strong) | Any | Unfavorable |

### Files Delivered

| File | Purpose |
|---|---|
| `R/fx_forecasting.R` | Core module — 7 functions: percentile, GARCH, macro signals, conversion signal, plot, brief |
| `scripts/11_cop_usd_forecast.R` | Standalone run script |
| `scripts/12_fx_monitor_alert.R` | Two-channel daily alert (yield-play 80th pct + reserve 35th pct; separate cooldowns and state) |
| `reports/cop_usd_monitor.html` | Dashboard page: signal, GARCH chart, macro drivers, driver analysis, alert status |
| `reports/index.html` | Updated with USD/COP Monitor nav card (orange accent) |
| `scripts/00_quarterly_refresh.R` | Updated — Step 4/5 runs FOREX signal automatically |
| `scripts/auto_weekly_snapshot.R` | Refreshes cop_usd_monitor.html weekly |
| `outputs/charts/cop_usd_forecast_bands_*.png` | Saved GARCH band charts |
| `outputs/fx_monitor_state.rds` | State file — tracks last alert date per channel independently |

### What This Module Does NOT Do

- Does not produce a point forecast ("COP will be X in 90 days")
- Does not recommend a specific conversion amount (that is a personal financial decision)
- Does not incorporate political event prediction
- Does not replace professional FX advice

---

## Analytical Findings — Sep 22, 2026 (COP Reserve Strategy Correction)

### 1. COP Reserve Build: Lump Sum, Not DCA, Not $5,200/Month

The prior framing — pacing the COP reserve build at $5,200/month — was incorrect in two ways:

1. **The $5,200/month is for the USD ETF portfolio only.** It is funded from income + liquid reserve drawdown and should go entirely to Fidelity or Schwab for the 7-class ETF allocation. No portion of it should be redirected to COP reserve building.
2. **Dollar-cost averaging is not appropriate for a cash spending reserve.** DCA is for equity positions where timing uncertainty over a volatile asset matters. A COP reserve is a liability hedge — the right sizing method is the spending need (62.6M COP), and the right transfer method is a one-time lump sum from the liquid reserve ($309K), timed to a better exchange rate.

**Two goals, two separate mechanisms:**

| Goal | Mechanism | Amount | Timing |
|---|---|---|---|
| COP reserve build | One-time lump-sum wire (via Wise) | ~$15,977–$19,602 | When rate ≥ 3,917 COP/USD AND after CPA sign-off |
| USD ETF portfolio | Monthly DCA | $5,200/month | Ongoing — now — independent of COP reserve |

### 2. COP Reserve Rate Trigger: 35th Percentile (~3,917 COP/USD)

Computed from the 5-year daily COP/USD series as of Sep 22, 2026:

- **Current rate:** 3,193 COP/USD (2.6th percentile, 5yr) — peso historically very strong
- **5-year range:** 3,044 – 5,106 COP/USD
- **35th percentile:** 3,917 COP/USD — suggested rate trigger for reserve funding

**Scenario analysis — USD cost of 62.6M COP reserve:**

| Scenario | COP/USD | USD Needed | USD Savings vs. Today |
|---|---:|---:|---:|
| Transfer now (2.6th pct) | 3,193 | $19,602 | — |
| 25th percentile | 3,853 | $16,245 | $3,357 |
| **35th pct — trigger** | **3,917** | **$15,977** | **$3,625** |
| 50th percentile | 4,022 | $15,563 | $4,039 |

**Wait-risk stats:** The 35th-percentile rate has been hit or exceeded in **65% of trading days** over the past 5 years. The longest consecutive stretch without hitting it was **242 trading days (~11.5 months)**. Waiting is likely but not guaranteed. Revisit after 6 months if not triggered.

### 3. Tax Gate Is the Binding Constraint (Not the Rate)

The rate trigger is necessary but not sufficient. Before wiring any funds:

- **FBAR risk is immediate:** Existing Colombian accounts (~30M COP ≈ $9,375 USD) are already near the $10,000 aggregate FBAR threshold. Exchange rate moves alone — without new deposits — could push the USD-equivalent above $10,000 and trigger an unfiled obligation.
- **CPA sign-off required on:** §988 ordinary income treatment, FBAR filing status, Colombian withholding rate by residency status (7% resident rate may not apply — non-resident rate may be higher), and PFIC risk for any non-CDT instruments.
- **Reference document:** `reports/cpa_colombia_tax_checklist.md` — 34-question briefing across 8 sections (§988, FBAR, FATCA, withholding, PFIC, estate/gift, dual citizenship, compliance).

### 4. Two-Channel FX Alert (scripts/12_fx_monitor_alert.R)

The daily FX monitor now fires two independent alert channels:

| Channel | Trigger | Cooldown | Subject Prefix | Purpose |
|---|---|---|---|---|
| Yield-play alert | COP/USD ≥ 80th pct (~4,596) | 14 days | `[GIA ALERT]` | Large USD→COP deployments (TES, CDTs above reserve) |
| Reserve alert | COP/USD ≥ 35th pct (~3,917) | 30 days | `[GIA]` | One-time reserve wire (triggers pre-transfer checklist in email body) |

State file (`outputs/fx_monitor_state.rds`) tracks each channel's last alert date independently. Backward-compatible with the old single-channel format.

### New Files (Sep 22, 2026)

| File | Purpose |
|---|---|
| `reports/cpa_colombia_tax_checklist.md` | 34-question CPA briefing: §988, FBAR, FATCA, Colombian withholding, PFIC, estate, dual citizenship |

### Updated Files (Sep 22, 2026)

| File | Change |
|---|---|
| `scripts/12_fx_monitor_alert.R` | Two independent alert channels with separate cooldowns and state tracking |
| `reports/investment_plan_full.md` | Section 5 rewritten: goal-separation callout, rate-trigger table, one-time transfer plan; Section 6 clarified as parallel/independent |

---

## Analytical Findings — Sep 23, 2026 (Model Council Final Review + GRID/PAVE Verification)

### 1. Model Council Review — Final Assessment

Reviewed `reports/investment_plan_model_council_revised.md` (revised by Claude Opus 5, GPT 5.6 Sol, Gemini 3.1 Pro) against `reports/investment_plan_full.md`. The Council's material corrections are sound and accepted:

1. GRID/PAVE product confusion — plan described GRID using PAVE's name (now corrected).
2. CDT yield compared against zero instead of yield-bearing USD alternatives (T-bills) — overstated carry.
3. Colombian FICs as a TES access route create PFIC exposure (Form 8621).
4. $310K liquid reserve was triple-counted as reserve + contribution engine + investable capital.
5. 80/20 USD/COP target replaced with spending-based COP reserve sizing.
6. Tax gates converted from post-implementation reminders to pre-trade gates.
7. Four-bucket framework (USD operating reserve / COP spending reserve / defensive long-term / global growth) improves on the flat 7-class allocation.
8. $150K early-warning liquidity trigger (stop contributions before hitting the $100K floor).
9. Look-through requirement (India inside VWO, Japan inside VEA) before adding tilts.

- Investable capital base — $310,013 liquid + $184,217 investments = $494,229 total. Bond ladder ($103,287) already covers the 20% bonds target. Wealthfront Joint ($80,619) requires a transfer decision. Roughly $160–210K of liquid reserve remains deployable above the $100–150K floor.
- Bond weight — given the $7,488/mo guaranteed income acting as a bond substitute, 15–20% for drawdown ballast is reasonable rather than the 10–25% range.
- Investable capital base — $309,908 minus a $100–150K floor = roughly $160–210K deployable.

### 2. GRID vs. PAVE Verification (completed)

| Attribute | **GRID** (First Trust) | **PAVE** (Global X) |
|---|---|---|
| Full name | NASDAQ Clean Edge Smart Grid Infrastructure Index Fund | U.S. Infrastructure Development ETF |
| Thesis | Electrification / power-grid buildout | Broad U.S. domestic capex |
| Top holdings | Schneider 9.27%, Eaton 9.26%, Johnson Controls 8.46%, ABB 7.82%, Quanta 7.74% | Deere 3.59%, Nucor 3.43%, Fastenal 3.36%, Emerson 3.27%, Parker-Hannifin 3.08% |
| Holdings / top-10 conc. | 128 / ≈59.8% | 102 / ≈31.7% |
| Geography | Global (European names) | U.S.-only |
| Expense ratio | ~0.56%–0.70% (sources conflict) | 0.47% |
| 12-mo volatility | ~10.6% | ~7.7% |

**Conclusion:** The Council was right that the plan's *label* was wrong, but the *GRID ticker was correct*. GRID fits both the electrification thesis and the project's non-U.S. mandate (holds European industrials); PAVE is 100% U.S. and would work against ex-U.S. diversification. **Decision: keep GRID; correct only its name/description.**

### 3. GRID Look-Through, Expense Ratio, and Tilt-Cap Sizing (finalized Sep 23, 2026)

- **Expense ratio: 0.56%** (locked) — confirmed across Cbonds, Investing.com, Yahoo Finance, MarketXLS. The older ~0.70% figure was a 2010–2013 legacy expense cap, not the current net ratio.
- **Sector:** ~60% Industrials; remainder Utilities + Information Technology. Equipment/capex growth tilt, not a regulated-utility income play.
- **Country:** ~39% U.S. / ~61% ex-U.S. Europe-heavy (Switzerland, France, Germany, Italy, U.K.) plus Canada, South Korea, Brazil. The ex-U.S. weight is what satisfies the project's non-U.S. mandate.
- **Concentration:** ~128–146 holdings, top-10 ≈ 55%–60%, non-diversified.
- **Tilt-cap sizing finalized:** lower half of the 0%–5% band (**~3%–4%**), counted fully as concentrated single-theme equity risk. Supersedes the legacy 10% weight in the plan's Position 5 header.

### 4. Broad Global Infrastructure Alternatives (IGF, NFRA) — Different Role, Not Substitutes

| Fund | Scope | Holdings | Top-10 | U.S. | Expense | Character |
|---|---|---:|---:|---:|---:|---|
| GRID | Smart-grid / electrification | ~128–146 | ~55%–60% | ~39% | 0.56% | Concentrated equipment/capex growth tilt |
| IGF | S&P Global Infrastructure | ~76 | ~38% | ~37% | ~0.42% | Defensive utilities/transport/energy (~40/40/20), ~2.7% yield |
| NFRA | STOXX Global Broad Infrastructure | ~217 | low | ~41% | 0.47% | Broadest; adds communications + rails, ~2.8% yield |

IGF and NFRA are income-oriented core infrastructure (regulated utilities, toll roads, pipelines, rails) that behave defensively — closer to a bond-substitute sleeve. They are **not** substitutes for GRID's electrification growth thesis; use them only if a separate defensive infrastructure sleeve is desired.

### 5. Allocation Table Rebuilt for GRID's 4% Tilt-Cap (finalized Sep 23, 2026)

Position 5's header still carried the legacy 10% weight after the tilt-cap finding above was recorded. Reconciled it across the full Phase 2 allocation:

- **GRID finalized at 4%** (top of the 3%–4% band, chosen so the freed weight redistributes to whole percentage points).
- The **6 percentage points freed from the legacy 10%** were redistributed **proportionally** across the other six sleeves (scale factor 96/90 ≈ 1.067, then rounded to whole points) — no sleeve was arbitrarily favored.

| Asset Class | Old % | New % | New $ (base $349,755) | New Monthly DCA |
|---|---:|---:|---:|---:|
| Bonds / Ladder | 25% | **27%** | $94,434 | $1,404 |
| U.S. Large Cap | 20% | **21%** | $73,449 | $1,092 |
| Emerging Markets | 15% | **16%** | $55,961 | $832 |
| International Developed | 15% | **16%** | $55,961 | $832 |
| Cash Reserve | 10% | **11%** | $38,473 | $572 |
| Commodities / Transition | 5% | 5% (unchanged) | $17,488 | $260 |
| Infrastructure (GRID) | 10% | **4%** | $13,990 | $208 |

Updated in both `reports/investment_plan_full.md` (Section 6 table + all seven Position headers/dollar figures) and `reports/investment_plan.qmd` (the `phase2-allocation-table` code chunk and the "Why GRID" narrative). Re-rendered `reports/investment_plan.html` successfully. The bond weight (27%) remains a working figure, not a resolved figure — the Model Council left the exact bond/TIPS weight open pending a drawdown study.

### 6. IGF/NFRA Defensive-Infrastructure Sleeve — Evaluated, Not Added (Sep 23, 2026)

Evaluated whether a small IGF or NFRA sleeve belongs in the four-bucket framework. **Decision: no, not at this time.** Reasoning:

1. The 0%–10% combined thematic-tilt band is already 9% committed (GRID 4% + Commodities/Transition 5%) — one point of headroom, not enough to justify a new position without displacing an existing thesis.
2. IGF/NFRA's core holdings (regulated utilities, toll roads, pipelines, telecom) substantially overlap with what VEA and VWO already hold — limited marginal diversification.
3. IGF/NFRA are still equity funds with real drawdown risk (both fell materially in 2020 and 2022) — not a genuine substitute for the bond sleeve's defensive role, especially given $7,488/month guaranteed income already substitutes for some bond ballast.
4. No specific income need beyond guaranteed income and the existing bond sleeve has been identified to justify the ~2.7%–2.8% yield pickup.

**Revisit if:** a specific income need emerges, or GRID's concentration/volatility becomes a standalone concern — treat any future addition as a swap within the existing thematic-tilt band, not an addition to it.

### 8. Bond Weight Resolved: 20% (Drawdown Study, Sep 23, 2026)

**Status:** Resolved — no longer a working figure.

**Study parameters:** SPY (equity proxy) + AGG (bond proxy) + 4.8% cash (11% fixed), Jan 2015 – Sep 2026 monthly returns, with a 2008-type stress overlay (SPY −56%, AGG +5%).

**Key findings:**

2. **Liquidity runway:** Monthly deficit ($8,315 spend − $7,488 income) = $827/month. Liquid reserves ($310,013) cover **375 months (31.2 years)** of this deficit with no investment sales — at any portfolio value including zero.d sleeve cannot meaningfully add to an already-vast income cushion. Bonds are not needed as an income source.

2. **Liquidity runway:** Monthly deficit ($8,315 spend − $7,488 income) = $827/month. Liquid reserves ($309,908) cover **375 months (31.2 years)** of this deficit with no investment sales — at any portfolio value including zero.

3. **Marginal drawdown value of bonds is poor:**

| Bond % | Ann Return | Max Drawdown (2015–2026) | Dollar Loss on $349,755 | Total Liquid at Trough |
|---:|---:|---:|---:|---:|
| 0% | 12.9% | −21.1% | −$73,920 | $585,743 |
| 15% | 11.1% | −19.7% | −$68,746 | $590,917 |
| 20% | 10.5% | −19.2% | −$67,030 | $592,633 |
| 27% | 9.7% | −18.5% | −$64,633 | $595,030 |
| 30% | 9.3% | −18.2% | −$63,608 | $596,055 |

   Each 5pp of bonds reduces max drawdown by ~0.5pp but costs ~0.9pp in annual return. The total liquid assets at trough differ by only ~$10K between 0% and 30% bonds — negligible relative to 375-month runway.

4. **2008-type stress (SPY −56%):** At 0% bonds, total liquid at trough = **$485,345** (587 months of deficit). At 20% bonds: **$528,015**. At 27% bonds: **$542,950**. No allocation creates a forced-sale situation.

5. **Correlation caveat:** In 2022, AGG fell ~13% while SPY fell ~18% — the traditional diversification benefit disappears in high-inflation regimes. The bond sleeve provides volatility reduction in normal cycles but not necessarily in inflationary bear markets.

**Decision: Bond weight finalized at 20%** (top of the Model Council's 15–20% recommended range). Rationale: 20% provides meaningful psychological ballast without material opportunity cost; going to 27% recovers only ~$2,400 in additional trough liquidity while costing ~0.8pp/year in expected return over a 20–30 year horizon.

**New allocation (finalized Sep 23, 2026; DCA restructured same day):**

| Asset Class | % | Funding Source | Monthly DCA |
|---|---:|---|---:|
| Bonds / Ladder | 20% | **MassMutual IRA rollover Oct 2027** | **$0** |
| U.S. Large Cap | 24% | Monthly DCA | $1,560 |
| Emerging Markets | 18% | Monthly DCA | $1,170 |
| International Developed | 18% | Monthly DCA | $1,170 |
| Cash Reserve | 11% | Monthly DCA | $715 |
| Commodities / Transition | 5% | Monthly DCA | $325 |
| Infrastructure (GRID) | 4% | Monthly DCA | $260 |
| **Total** | **100%** | | **$5,200** |

**Bond sleeve restructured (Sep 23, 2026):** The MassMutual account ($147,304) was identified as a **Traditional IRA** (American Freedom Liberty 5 MVA fixed deferred annuity, issue date Oct 6, 2022). Key implications:
- **Cannot be DCA source:** Every withdrawal from a Traditional IRA = ordinary income. It cannot fund monthly contributions to a taxable ETF portfolio.
- **Surrender period ends Oct 6, 2027** (12.5 months from today). Do not touch until then.
- **Rollover plan:** On or after Oct 6, 2027, initiate a trustee-to-trustee direct rollover from MassMutual to a Fidelity Traditional IRA. Invest in BND or a Treasury ladder inside the IRA (asset-location optimization: bonds generate ordinary income, best sheltered in tax-deferred wrapper).
- **Bond sleeve pre-funded:** $103,287 (existing bond ladder) + $147,304 (IRA rollover) = $250,591 — exceeds the 20% target. Zero monthly DCA needed for bonds. The $1,040/month previously allocated to bonds is redistributed proportionally to the six remaining positions.
- **RMDs:** Begin at age 73 (~9 years). Estimated annual RMD ~$10,000–$11,000 at that time.

**Corrected non-IRA liquid reserve (Sep 23, 2026):** $162,709 (not $310,013).
- Wealthfront Cash Account: $153,492 — this is the DCA source (ACH to Fidelity/Schwab)
- Chase/BOA checking/savings: ~$9,217 — operational float
- MassMutual $147,304: Traditional IRA — not accessible without tax consequence until rollover
- **Runway at $5,200/mo:** soft floor ($50K) hit at month 19; hard floor ($30K) at month 23
- **Crossover (ETF > liquid):** month 15 without WF Joint transfer; month 7 with WF Joint transferred
- **Wealthfront Joint ($80,619):** transfer to Fidelity/Schwab taxable account — advances crossover from month 15 → month 7 and adds $117K to 5-year ETF value
- **Lump-sum deployment cancelled:** prior plan called for deploying $210K from liquid reserves; corrected plan uses DCA only (non-IRA pool too small for lump-sum without breaching operational floor)

### 7. GRID Reference Data Added to ETF Universe (Sep 23, 2026)

Added `expense_ratio_pct`, `tilt_cap_min_pct`, `tilt_cap_max_pct`, and `tilt_cap_notes` columns to `create_theme_etf_universe()` in `R/screening.R`. Only GRID (0.56%, tilt cap 3–4%) and PAVE (0.47%, comparison-only, not held) are populated; all other tickers carry `NA` until independently verified — do not backfill with memorized figures. Regenerated `data/external/theme_etf_universe_20260923.csv` from the updated function. Prior dated snapshots (`_20260921.csv`, `_20260922.csv`) were left untouched per the project's snapshot convention.

### Updated Files (Sep 23, 2026)

| File | Change |
|---|---|
| `reports/investment_plan_full.md` | Position 5 rewritten with verified GRID holdings, sector/country look-through, locked 0.56% expense ratio, IGF/NFRA comparison table, and finalized 3%–4% tilt sizing; Section 6 allocation table and all seven Position headers/dollar figures rebuilt around GRID's 4% weight; IGF/NFRA "not added" decision recorded |
| `reports/investment_plan_model_council_revised.md` | Product controls marked verified: GRID/PAVE outcome, look-through, locked expense ratio, tilt sizing, IGF/NFRA note; added full IGF/NFRA four-bucket evaluation with "not now" decision and reasoning |
| `reports/investment_plan.qmd` | `phase2-allocation-table` chunk and "Why GRID" narrative rebuilt to match; re-rendered `reports/investment_plan.html` |
| `R/screening.R` | `create_theme_etf_universe()` extended with expense ratio and tilt-cap columns; GRID and PAVE populated |
| `data/external/theme_etf_universe_20260923.csv` | New dated snapshot reflecting the schema change |
| `AGENTS.md` | This findings section added (Council assessment + GRID look-through, expense ratio, tilt sizing, IGF/NFRA, allocation rebuild, bond weight resolved at 20%); updated same day with MassMutual IRA identification, corrected $162,709 non-IRA liquid, bond sleeve DCA restructured to $0, monthly amounts redistributed |
| `reports/investment_plan_full.md` | Section 6 intro corrected (liquid $162,709, lump-sum deployment cancelled); allocation table restructured (bonds $0 DCA, IRA rollover Oct 2027, equity DCA redistributed); Position 1 rewritten with MassMutual product details, rollover instructions, asset-location rationale |
| `outputs/charts/corrected_reserve_projection_2026-09-23.png` | New chart: $162,709 liquid start, $30K/$50K recalibrated floors, Oct 2027 IRA rollover event line, WF Joint crossover scenarios |
| `reports/investment_plan_full.md` | Bond weight resolved: Position 1 header + conviction rationale updated from 27% (working) to 20% (final); allocation table rebuilt; total liquid runway and guaranteed-income bond-equivalent figures added |
| `reports/investment_plan.qmd` | `phase2-allocation-table` chunk updated to 20% bonds, 24% US, 18% Intl Dev, 18% EM |

---

## Future Work

Items queued for future research, development, or implementation. Not yet scoped or scheduled.

---

### FW-01: USD/COP FOREX Forecasting Model (1–12 Month Horizon)

**Status:** Queued — not yet started
**Category:** Quantitative research + model development
**Priority:** Medium (informs CDT sizing and conversion timing; complements existing Phase 4 decision-support module)

#### Problem Statement

The existing Phase 4 module (`R/fx_forecasting.R`) deliberately avoids point forecasting in favor of historical percentile context and GARCH volatility bands. This is intellectually honest but leaves a gap: no directional signal over a 1–12 month horizon. A well-designed forecasting model could help answer:

> "Given current macro conditions, is the peso more likely to be stronger or weaker in 3, 6, or 12 months than it is today?"

This is distinct from the current module's question ("is now a historically cheap rate?"), and would add a forward-looking directional layer to the conversion decision framework.

#### Why This Is Hard

- **Meese-Rogoff result (1983):** Structural FX models underperform a random walk out-of-sample. The result has been largely replicated across currencies and time periods.
- **COP-specific noise:** COP/USD is driven by Brent crude, Colombia fiscal dynamics, global EM risk sentiment (VIX), and Fed policy — four noisy, partly unpredictable series.
- **Structural breaks:** Gustavo Petro's election (2022), oil price shocks, and post-COVID EM capital flow regime shifts make pre-2022 data less reliable as training data.
- **Data scarcity:** At monthly frequency, even 10 years of data = 120 observations — too few for complex models.

#### Candidate Approaches (to research and compare)

| Approach | Horizon | Package | Honest Assessment |
|---|---|---|---|
| VAR / VECM with macro drivers | 1–6 months | `vars` | Theoretically grounded; often fails Meese-Rogoff out-of-sample |
| ARIMA + exogenous regressors (ARIMAX) | 1–3 months | `forecast` / `fable` | Simple baseline; unlikely to beat random walk directionally |
| GARCH-X (GARCH with macro covariates) | Volatility only | `rugarch` | Extends current Phase 4 module; not directional |
| Regime-switching (Markov-switching) | 3–12 months | `MSwM`, `depmixS4` | Captures structural breaks; interpretable; worth exploring |
| STAR / SETAR (nonlinear threshold AR) | 1–6 months | `tsDyn` | Handles asymmetric mean-reversion; reasonable for EM FX |
| Random forest / XGBoost on macro features | 3–12 months | `tidymodels` + `xgboost` | Non-linear; needs careful feature engineering and walk-forward CV |
| Principal components of macro drivers | 6–12 months | base R + `prcomp` | Useful for dimensionality reduction; pairs well with any model |
| Bayesian VAR (BVAR) | 3–12 months | `BVAR` | Shrinkage priors help with short samples; respects uncertainty |

#### Priority Starting Points

Of the eight candidate approaches, two are most likely to yield useful signal given COP's specific characteristics and data constraints — start here before exploring others:

1. **Markov Regime-Switching** (`MSwM`, `depmixS4`) — COP/USD has exhibited at least two distinct regimes since 2020: a high-volatility weakening phase (2022–2024) and a carry-trade-driven strengthening phase (2025–2026). Regime-switching models explicitly capture these structural breaks rather than averaging over them. The Petro election (2022) and the post-VIX-spike recovery (2025) are natural candidate regime boundaries. If regimes are identifiable and persistent, transition probabilities give a probabilistic directional signal without requiring a point forecast.

2. **Bayesian VAR (BVAR)** (`BVAR` package) — At monthly frequency, 10 years of data yields ~120 observations — too few for unrestricted VAR without overfitting. Bayesian shrinkage priors (Minnesota prior) regularize the coefficient estimates, making BVAR substantially more reliable than standard VAR on short samples. Include Brent log-returns, DXY z-score, VIX z-score, and the Banrep–Fed rate differential as covariates. BVAR also naturally produces posterior predictive distributions rather than point forecasts, which aligns with the goal of outputting directional probabilities rather than a single number.

Both approaches are interpretable (critical for understanding *why* a signal fires), handle structural breaks better than purely statistical time-series models, and have been shown to outperform random walks in EM FX contexts more often than linear alternatives.

#### Recommended Research Sequence

1. **Establish a proper baseline:** Fit a random walk (no-change forecast) and an AR(1) on COP/USD log returns. This is the benchmark to beat. If no model consistently beats it, stop there.
2. **Feature engineering:** Build a macro feature set — Brent log-returns, DXY z-score, VIX z-score, Colombia CPI surprise, Banrep rate differential vs. Fed funds, Colombia fiscal balance (annual). Compute rolling correlations with future COP returns at 1, 3, 6, 12-month horizons to identify which features have genuine predictive signal.
3. **Walk-forward cross-validation:** Never use static train/test splits for time series. Use an expanding window with re-estimation at each step. Evaluate directional accuracy (sign of return), RMSE, and MAE — separately.
4. **Directional accuracy is the target metric:** For a conversion-timing decision, being right about the direction (peso weakening vs. strengthening) matters more than minimizing RMSE. Report both but optimize for direction.
5. **Honest benchmark comparison:** If the best model's directional accuracy is not meaningfully above 55% on held-out walk-forward data, do not implement it. Publish the null result.
6. **If a model passes:** Integrate into `R/fx_forecasting.R` as an optional `cop_directional_forecast()` function. Output should be a probability distribution over peso direction (e.g., "60% probability peso weaker in 6 months"), not a point rate.

#### Backtesting Requirements

- Minimum 5 years of out-of-sample walk-forward evaluation
- Re-estimate model parameters at each step (no look-ahead bias)
- Report: directional accuracy, Sharpe-equivalent of a signal-following strategy, maximum drawdown if naively traded
- Compare against: random walk, AR(1), and the current percentile-only signal from Phase 4

#### Implementation Notes (if model passes backtesting)

- New function: `cop_directional_forecast(series, macro_data, horizon_months = c(3, 6, 12))`
- Output schema: `horizon_months`, `prob_weaker`, `prob_stronger`, `prob_neutral`, `model_type`, `confidence`, `last_fit_date`
- Add to `print_cop_brief()` as an optional section
- Add directional probability to `reports/cop_usd_monitor.html`
- Trigger alert email only when both percentile AND directional signal are aligned (reduces false positives)

#### Files to Create (when work begins)

| File | Purpose |
|---|---|
| `notebooks/cop_usd_forecasting_research.qmd` | Research notebook: feature analysis, model comparison, backtest results |
| `R/fx_directional_model.R` | Trained model functions (only if backtesting passes) |
| `scripts/13_cop_usd_directional_model.R` | Standalone run script |
| `data/processed/cop_macro_features.csv` | Cleaned feature matrix for model development |

#### Falsification Criteria

Do not proceed to implementation if:
- No model achieves > 55% directional accuracy on walk-forward out-of-sample evaluation
- The best model does not outperform a simple "buy when > 65th percentile" rule from Phase 4
- Feature importance analysis reveals only spurious correlations with no economic rationale

**Note:** Absence of a useful model is a valid and publishable finding within this research system. The Phase 4 percentile + GARCH approach remains the production signal until/unless this research yields a model that demonstrably improves on it.

---

## FW-01 Status: CLOSED — Null Result Confirmed (Sep 23, 2026)

**Plan file:** N/A (research, not a deliverable phase)
**Notebook:** `notebooks/cop_usd_forecasting_research.qmd`
**Feature matrix:** `data/processed/cop_macro_features.csv` (101 rows, 8 drivers)

### Colombia Macro Driver Fetch Routine (implemented Sep 23, 2026)

Function `fetch_colombia_macro_drivers()` added to `R/colombia_indicators.R`.
Fetches 4 monthly FRED series via `fredr`:

| FRED ID | Description | Latest |
|---|---|---|
| `COLIRSTCI01STM` | Colombia overnight/call money rate (Banrep proxy) | Aug 2026 |
| `COLCPALTT01GYM` | Colombia CPI, all items, YoY % change | Apr 2025 (~5 mo lag) |
| `COLIRLTLT01STM` | Colombia 10Y TES government bond yield | Aug 2026 |
| `FEDFUNDS` | US Federal Funds effective rate | Aug 2026 |

Derived outputs: `rate_differential` (Banrep − Fed Funds), `colombia_cpi_surprise` (MoM Δ in CPI YoY), `tes_10y_yield`.

### Final Results

| Model | RMSE | MAE | Dir Acc | Hold-out months |
|---|---:|---:|---:|---:|
| Random Walk | 0.0338 | 0.0261 | 46.2% | 65 |
| AR(1) | 0.0352 | 0.0267 | 44.6% | 65 |
| ARIMAX (rate diff + TES 10Y) | 0.0366 | 0.0286 | 44.6% | 65 |

**8 drivers × 4 horizons = 32 correlation tests. Significant at p < 0.05: 0.**

ARIMAX (Colombia-specific exogenous regressors) is worse than the random walk on all metrics.

**Verdict:** Both falsification criteria triggered. Do not proceed to Markov or BVAR development. Phase 4 percentile + GARCH is production signal.

**Earliest sensible revisit:** January 2027 — post-2022 subsample analysis (targeting 48+ months of post-Petro data). No other credible path identified until higher-frequency Colombia CPI data becomes available programmatically.

