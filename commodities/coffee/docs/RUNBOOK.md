# Runbook — Clean Session Restart

Use this when you've run `rm(list = ls())` (or restarted R / started a fresh
RStudio session) and want to go from an empty environment to a running app
with the fewest surprises. This assumes one-time setup (package install, API
keys) from `docs/QUICKSTART.md` steps 1–3 is already done — this runbook
covers steps 4 onward, spelled out in full so nothing is assumed to still be
in memory.

## 0. Confirm you're in the right place

```r
getwd()
# should end in .../commodities/coffee
# if not: open coffee_platform.Rproj first (File > Open Project)
```

## 1. Source config + all ingestion scripts

Order matters — later scripts assume objects/paths set up by `config.R`.

```r
source("R/utils/config.R")
source("R/ingest/ingest_weather_enso.R")
source("R/ingest/ingest_weather_chirps.R")
source("R/ingest/ingest_fx.R")
source("R/ingest/ingest_production_usda.R")
source("R/ingest/ingest_price_ico.R")
source("R/ingest/ingest_fertilizer.R")
source("R/ingest/ingest_shipping.R")
```

Or, equivalently, run the orchestration script — it sources everything above
in the right order AND executes each fetch call wrapped in `tryCatch`, so one
source failing (e.g. a missing API key) doesn't stop the rest:

```r
source("scripts/run_ingest_all.R")
```

After this step you should have these objects in your environment (some may
be `NULL` if that source failed — check the console messages):

| Object | From | Notes |
|---|---|---|
| `oni` | `fetch_oni()` | ENSO/ONI monthly series, no key needed |
| `chirps_raw` | `fetch_chirps_for_regions()` | Rainfall by region; end_date auto-lags 75 days |
| `fx` | `fetch_fx_series()` | Requires `FRED_API_KEY` in `.Renviron` |
| `psd` | `fetch_usda_psd_coffee()` | Annual production/exports/stocks |
| `ice_futures` | `fetch_ice_futures()` | Daily KC/RM futures via Yahoo (tidyquant) |
| `coffee_spot` | `fetch_worldbank_coffee_spot()` | Monthly World Bank spot prices |
| `ico_prices` | `load_ico_prices_from_local()` | Only populates if you've manually placed the CSV — see `docs/data_sources.md` |
| `fert` | `fetch_worldbank_fertilizer_prices()` | Urea/DAP/potassium monthly |
| `chokepoints` | `init_chokepoint_log()` | Template on first run — edit manually with real events |

## 2. Compute derived features

```r
chirps_anom <- compute_rainfall_anomaly(chirps_raw)
```

## 3. Pick your price series and build the panel

**Decision point not yet automated:** `build_monthly_panel()` expects a single
`price_df` with columns `date, price`. You currently have two candidate price
sources with different shapes — pick one (or reconcile both) before proceeding:

- `coffee_spot` — has separate `arabica`/`robusta` columns, monthly. Reshape
  to `date, price` by selecting one varietal, e.g.:
  ```r
  price_df <- coffee_spot %>% dplyr::transmute(date, price = arabica)
  ```
- `ice_futures` — has a `contract` column (`"Arabica"`/`"Robusta"`), daily.
  Filter to one contract and let `build_monthly_panel()`'s internal monthly
  aggregation handle the daily-to-monthly step:
  ```r
  price_df <- ice_futures %>% dplyr::filter(contract == "Arabica") %>%
    dplyr::select(date, price)
  ```

Then build the panel:

```r
source("R/features/build_panel.R")
panel <- build_monthly_panel(
  price_df       = price_df,
  oni_df         = oni,
  chirps_df      = chirps_anom,
  fx_df          = fx,
  fert_df        = fert,
  chokepoints_df = chokepoints
)
readr::write_csv(panel, file.path(PROCESSED_DIR, "coffee_monthly_panel.csv"))
```

**Sanity-check before moving on:** `View(panel)` or `summary(panel)` — check
date range, look for unexpected `NA` columns (usually means a join upstream
silently failed to match), and confirm `rain_z_*` columns look reasonable
(z-scores should mostly fall in the -3 to +3 range).

## 4. Train and backtest models (one per horizon)

```r
source("R/models/model_template.R")

predictor_cols <- c(
  "oni_anom_lag1", "oni_anom_lag3",
  "rain_z_avg_lag1", "rain_z_avg_lag3",
  "fx_BRL",
  "chokepoint_severity_max"
  # add fertilizer column(s) once confirmed present in panel
)

results_by_horizon <- purrr::map(
  c(1, 3, 6, 9, 12),
  ~ run_horizon_model(panel, .x, predictor_cols)
)
names(results_by_horizon) <- paste0(c(1, 3, 6, 9, 12), "mo")

saveRDS(results_by_horizon, file.path(MODELS_DIR, "coffee_horizon_models.rds"))
```

Console output per horizon shows MAPE, 80% interval coverage, and directional
accuracy — see `docs/methodology.md` for how to interpret these.

## 5. Launch the app

```r
shiny::runApp("app")
```

`app/global.R` checks whether `data/processed/coffee_monthly_panel.csv` and
`models/coffee_horizon_models.rds` both exist. If yes, it loads your real
panel/models; if either is missing, it silently falls back to synthetic demo
data so the UI still runs. If you expected real data and the app looks like
placeholder charts, re-check that both files were written in steps 3 and 4.

## Known gaps as of Phase 1 (not runbook bugs, just unfinished wiring)

- `price_df` reconciliation (step 3) is a manual decision, not automatic.
- `app/server.R` still has several `# DEMO:` blocks (signal direction,
  confidence, dominant driver, backtest metrics, historical analog table)
  that need to be wired to `results_by_horizon` / `panel` output — see the
  comments in that file for exactly what each one expects.
- `ico_prices` and freight rate CSVs require a one-time manual download —
  see `docs/data_sources.md` for links. Ingestion will run fine without
  them (they're excluded from `predictor_cols` above) but are useful
  cross-checks.
