---
name: rshiny-dashboard-conventions
description: "Use when helping build, extend, or review the R Shiny commodity intelligence platform itself \u2014 dashboard architecture, package selection, module structure, data pipeline design, or new view proposals. Encodes preferred package stack (shiny, bslib, plotly, DT, quantmod, tidyquant, rnoaa, ecmwfr, forecast/fable, reactable/echarts4r), module pattern (golem or simple modules), reactive data pipeline conventions, and the required three-view dashboard priority (signal/watchlist, commodity drill-down, backtesting). Not for market content/analysis \u2014 use weather-price-signal-memo for that."
metadata:
  author: kwestrick
  version: '1.0'
  space: global-commodity-platform
---

# R Shiny Dashboard Conventions

## When to Use This Skill

Use when the user asks for help with the platform's code/architecture itself: building a
new Shiny module, choosing a package, designing a data pipeline, proposing a new dashboard
view, or reviewing existing R/Shiny code for this project. Do not use this for market
analysis content — that belongs to weather-price-signal-memo.

Always check Kenneth's GitHub repos for existing code/scripts relevant to the request
before proposing a build from scratch (see prior-work-check skill).

## Environment & Package Stack

- Primary environment: R / RStudio.
- Core Shiny stack: `shiny`, `bslib` (theming), `plotly` (interactive charts), `DT`
  (tables), `reactable` or `echarts4r` (advanced interactive visuals — prefer these over
  base `DT`/`plotly` when the view needs richer interactivity like nested rows or linked
  brushing).
- Data/time series: `quantmod`, `tidyquant` for market data pulls and transforms;
  `forecast` or `fable` (tidyverts) for time series modeling — prefer `fable` for new work
  since it integrates with `tsibble`/tidyverse conventions, but match whatever the
  existing codebase already uses if extending prior work.
- Weather/climate data: `rnoaa` for NOAA data access, `ecmwfr` for ECMWF data access.
- Scheduled refresh: `cron` (system-level) or the `targets` package (in-R pipeline
  dependency management) — prefer `targets` for anything with multi-step data dependencies
  (fetch → clean → signal generation), since it tracks what needs re-running.

Recommend free/low-cost APIs first: NOAA, EIA, FRED, Alpha Vantage, Quandl/Nasdaq Data
Link, Baltic Exchange (where accessible). Flag explicitly when paid data (Bloomberg,
Refinitiv, proprietary weather models, AIS vessel tracking) would materially improve
signal quality, rather than silently working around the gap.

## Architecture Pattern

- Favor modular Shiny architecture: either the `golem` framework for a full production
  build, or a simple hand-rolled module pattern (`mod_*_ui()` / `mod_*_server()` pairs) for
  lighter builds. Match whatever pattern already exists in the repo if extending prior
  work — don't introduce a second pattern into an existing codebase without flagging it.
- Maintain clear separation between three layers:
  1. **Data ingestion** — API pulls, raw data caching, scheduled refresh logic.
  2. **Signal generation** — the weather-to-price transmission logic, stacked-risk
     detection, confidence scoring. This layer should be testable independently of the UI.
  3. **UI/presentation** — Shiny modules consuming pre-computed signals, not doing
     inline data transformation.
- Reactive pipelines should pull from cached/pre-computed data where possible rather than
  hitting external APIs directly in reactive expressions, to avoid rate limits and keep
  the UI responsive.

## Required Dashboard View Priorities

When proposing or building dashboard views, prioritize in this order:

1. **Signal/watchlist summary view** — a single screen showing all tracked commodities
   with current signal direction, confidence level, and horizon at a glance (table or
   card-based, using `reactable` or `DT`).
2. **Commodity-specific drill-down** — per-commodity view with weather AND supply chain
   overlay charts (e.g. price chart with ENSO phase shading, freight index overlay),
   matching the weather-price-signal-memo causal chain structure.
3. **Backtesting/track-record view** — validates past calls against actual price outcomes;
   should surface hit rate, magnitude accuracy, and false positives/negatives by commodity
   and horizon bucket (tactical/seasonal/strategic).

Don't build view 2 or 3 features ahead of view 1 unless the user explicitly asks —
the watchlist summary is the entry point and should stay functional first.

## Before Proposing New Code

1. Search GitHub repos for existing modules, scripts, or data pipeline code relevant to
   the request (per prior-work-check skill).
2. If prior code exists, propose extending/refactoring it rather than a parallel
   implementation, unless there's a clear architectural reason not to (state the reason
   if so).
3. If no prior code exists, say so explicitly before proposing a from-scratch build.
