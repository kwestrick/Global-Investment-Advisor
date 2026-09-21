# Quick Start

> One-time setup only (steps 1–3 below). For the full run sequence to use every time you start a clean R session — e.g. after `rm(list = ls())` — see [`RUNBOOK.md`](RUNBOOK.md), which covers steps 4 onward in full detail with no assumed in-memory state.

1. **Open the project**
   Open `coffee_platform.Rproj` in RStudio (double-click it, or
   `File > Open Project`). This sets your working directory correctly for
   all the `here::here(...)` / relative paths used throughout.

2. **Install R packages**
   ```r
   source("scripts/install_packages.R")
   ```

3. **Set up free API keys** (see `docs/data_sources.md` for registration links)
   Open `.Renviron` (create it in the project root if it doesn't exist —
   `usethis::edit_r_environ(scope = "project")` opens it for you) and add:
   ```
   FRED_API_KEY=your_key_here
   NOAA_NCEI_TOKEN=your_key_here
   ```
   Restart R after saving so the new environment variables load.

4. **Run the first data pull**
   ```r
   source("scripts/run_ingest_all.R")
   ```
   Expect a couple of steps to fail on the first run — the ICO price file
   and freight rate file need to be manually downloaded and placed once
   (see the messages printed; `docs/data_sources.md` has the links).

5. **Inspect the raw pulls**
   Check `data/raw/*/` — open the CSVs and sanity-check date ranges, units,
   and missingness before building the panel. The CHIRPS pull in particular
   is worth checking closely on first run since the `chirps` package's
   output shape varies by version (see the NOTE in
   `R/ingest/ingest_weather_chirps.R`).

6. **Build the modeling panel**
   ```r
   source("R/features/build_panel.R")
   panel <- build_monthly_panel(price_df, oni, chirps_anom, fx, fert, chokepoints)
   readr::write_csv(panel, "data/processed/coffee_monthly_panel.csv")
   ```
   You'll need a `price_df` (date, price) — pull this from ICO or your
   finance connector until a systematic historical futures feed is wired up.

7. **Train and backtest models**
   ```r
   source("R/models/model_template.R")
   # see example usage block at the bottom of that file
   ```

8. **Launch the Shiny app**
   ```r
   shiny::runApp("app")
   ```
   The app runs immediately with demo data even before steps 4–7 are done —
   useful for iterating on layout first. Once `data/processed/coffee_monthly_panel.csv`
   and `models/coffee_horizon_models.rds` exist, `app/global.R` automatically
   switches to real data.

## What to expect vs. what's a stub

**Working out of the box (no key needed):** ONI/ENSO, CHIRPS rainfall,
USDA PSD production, World Bank fertilizer prices, chokepoint event log
(template — you fill in real events).

**Needs a free API key:** FX rates (FRED).

**Manual step required (no clean free API found):** ICO indicator prices
(download CSV periodically), freight rates (log manually or use a paid
Baltic Exchange/Freightos subscription).

**Demo/placeholder logic in the Shiny app** (marked `# DEMO:` in
`app/server.R`): signal direction, confidence, dominant driver, backtest
metrics, and the historical analog finder are all currently populated with
illustrative values or simple heuristics. Wire these to your real model
output as you complete steps 6–7.
