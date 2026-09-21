# ============================================================
# global.R — loaded once when the Shiny app starts
# ============================================================

library(shiny)
library(bslib)
library(plotly)
library(leaflet)
library(DT)
library(dplyr)

PROJ_ROOT <- rprojroot::find_root(rprojroot::has_file("coffee_platform.Rproj"))
source(file.path(PROJ_ROOT, "R", "utils", "config.R"))

# --- Load processed panel + model results if they exist --------------------
panel_path  <- file.path(PROCESSED_DIR, "coffee_monthly_panel.csv")
models_path <- file.path(MODELS_DIR, "coffee_horizon_models.rds")

has_real_data <- file.exists(panel_path) && file.exists(models_path)

if (has_real_data) {
  panel  <- readr::read_csv(panel_path)
  models <- readRDS(models_path)
} else {
  # --- Demo/placeholder data so the UI is fully interactive before you've
  # run the ingest + model pipeline. Replace by running scripts/run_ingest_all.R
  # and R/models/model_template.R.
  set.seed(42)
  demo_dates <- seq(as.Date("2015-01-01"), as.Date("2026-06-01"), by = "month")
  panel <- data.frame(
    date = demo_dates,
    price = 120 + cumsum(rnorm(length(demo_dates), 0, 4)),
    oni_anom = sin(seq_along(demo_dates) / 12) * 1.2 + rnorm(length(demo_dates), 0, 0.3),
    rain_z_avg_all_regions = rnorm(length(demo_dates), 0, 1),
    fx_BRL = 4.5 + cumsum(rnorm(length(demo_dates), 0, 0.05)),
    chokepoint_severity_max = sample(0:2, length(demo_dates), replace = TRUE, prob = c(0.7, 0.2, 0.1))
  )
  models <- NULL
}

GROWING_REGIONS_MAP <- GROWING_REGIONS
