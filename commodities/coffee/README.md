# Coffee Commodity Risk & Opportunity Platform
### Phase 1 module of the Global Commodity Platform (R Shiny)

## Purpose

Identify opportunities and risks in global coffee (Arabica + Robusta) pricing
1–12 months in advance by combining:

- **Weather/climate signal** (ENSO state, rainfall anomalies, temperature,
  drought/frost risk in growing regions) — the core analytical edge
- **Supply chain & logistics** (freight rates, chokepoint risk, port congestion)
- **Input costs** (fertilizer, fuel/bunker costs)
- **Macro/FX** (USD/BRL, USD/VND, USD/COP — since Brazil, Vietnam, and
  Colombia are the dominant Arabica/Robusta exporters)
- **Fundamentals** (USDA PSD production/stocks, ICO trade statistics, CFTC
  positioning)

This mirrors the recent real-world pattern: Brazil's 2024 drought/heat drove
Arabica to a 1977-era high, only to reverse in 2026 on a record Brazilian
harvest and Real weakness — while a Strait of Hormuz closure simultaneously
pushed up shipping, insurance, fertilizer, and fuel costs, creating a
"stacked risk" scenario exactly like the Space instructions describe.

## Why coffee first

- Two distinct growing regions/varietals (Brazil/Colombia Arabica vs.
  Vietnam/Indonesia Robusta) with different weather sensitivities — a good
  test of whether the framework generalizes across sub-markets.
- Strong, well-documented weather-to-price transmission (frost, drought,
  ENSO) with decades of historical analogs.
- Exposed to FX (BRL, VND, COP), shipping (long Brazil→Asia and
  Brazil/Vietnam→US/EU routes), and a concentrated input cost (fertilizer,
  ~15–25% of production cost) — touches every layer in the Space instructions.
- Liquid, transparent futures market (ICE Arabica "KC", ICE Robusta) for
  backtesting price response.

## Repository layout

```
coffee_platform/
├── R/
│   ├── ingest/       # one function per data source, returns tidy df
│   ├── features/     # transforms raw series into model-ready features
│   ├── models/        # split-sample training, evaluation, uncertainty
│   └── utils/         # shared helpers (dates, caching, API keys)
├── data/
│   ├── raw/            # untouched downloads, organized by domain
│   │   ├── price/       # ICE futures, ICO indicator prices
│   │   ├── weather/      # ENSO/ONI, CHIRPS rainfall, station temps
│   │   ├── fx/           # USD/BRL, USD/VND, USD/COP
│   │   ├── shipping/     # Baltic indices, freight quotes
│   │   ├── fertilizer/    # urea/potash/NPK prices
│   │   └── production/    # USDA PSD, ICO production/stocks
│   ├── processed/       # cleaned, joined, feature-engineered panels
│   └── static/          # rarely-changing reference data (growing region
│                         # boundaries, station lists, port lists)
├── scripts/            # top-level run scripts (e.g. run_ingest_all.R)
├── models/             # saved model objects (.rds) and backtest results
├── app/                 # Shiny app (ui.R / server.R / global.R)
├── docs/               # data source registry, methodology notes
└── tests/              # testthat unit tests for ingest/feature functions
```

## Build sequence (per your outline)

1. **Ingest** — download static (growing region boundaries, port/station
   lists) and transient (prices, weather, FX, freight, fertilizer) datasets.
   See `docs/data_sources.md` for the full registry and `R/ingest/`.
2. **Model** — build core relationships between predictors and coffee price
   using a **split-sample methodology**: train on an earlier window, hold
   out a later window to test robustness and generate error/uncertainty
   bounds. See `docs/methodology.md` and `R/models/`.
3. **Interface** — R Shiny app with a growing-region map (weather/risk
   overlay) plus time series charts showing predicted price impact by
   driver, confidence bands, and a scenario/stacked-risk view. See `app/`.

## Status

This is the Phase 1 skeleton: folder structure, data source registry,
ingestion function stubs (working code where sources are free/keyless,
clearly marked TODO where an API key or paid source is needed), a
split-sample modeling template, and a Shiny UI wireframe. Next steps for you:

1. Register for free API keys where needed (NOAA CDO token, FRED,
   Copernicus CDS) — see `docs/data_sources.md` for links.
2. Run `scripts/run_ingest_all.R` to pull the first data snapshot.
3. Review `R/models/model_template.R` and adjust feature set once you've
   inspected the joined panel in `data/processed/`.
4. Run `app/app.R` to see the wireframe and iterate on layout.

For the full step-by-step sequence (what to run, in what order, and what
each object should look like) starting from a clean R session — e.g. after
`rm(list = ls())` or a fresh RStudio restart — see `docs/RUNBOOK.md`.

## Working with two AI assistants on this project

This project is developed using two AI tools with different strengths —
use each for what it's good at rather than treating them as redundant:

**Perplexity (this conversation / Space)** — the architecture and research
layer. Use it for:
- Designing or restructuring the data pipeline and repo layout
- Researching new data sources, APIs, or methodology approaches
- Writing new modules end-to-end, or debugging logic that spans multiple
  files
- Keeping `docs/data_sources.md`, `docs/methodology.md`, and the Space
  instructions in sync with what's actually been built
- git operations (staging, committing, pushing) if you want a walkthrough
  rather than doing it solo

**Posit Assistant / Claude Sonnet (in RStudio)** — the in-editor tactical
layer. Use it for:
- "Why is this line erroring" and quick debugging while heads-down in a
  script
- Inline completions, small refactors, syntax questions
- Fast iteration on a single function without leaving the editor

**How they stay in sync:** there's no live link between the two — the
repo itself (via git) is the shared source of truth. When Posit
Assistant/Claude helps you solve something nontrivial (a bug fix, a
design change, a new feature), commit it with a clear message and,
when convenient, mention it back in the Perplexity conversation so the
architecture-level docs and Space instructions can be updated to match.
When asking Posit Assistant/Claude for help on a specific script, point
it at the relevant doc above (`docs/data_sources.md` for ingestion
questions, `docs/methodology.md` for modeling questions) so it starts
with the same context this conversation already has.
