# ============================================================
# server.R
# NOTE: Chart/table logic below runs against the demo data defined in
# global.R until you've run the real ingest + modeling pipeline. Swap in
# real model objects (from R/models/model_template.R output) once ready --
# look for "DEMO:" comments marking placeholder logic to replace.
# ============================================================

server <- function(input, output, session) {

  # --- Signal Summary tab ----------------------------------------------
  output$signal_direction <- renderText({
    # DEMO: replace with models$`6mo`$test_results latest point_pred vs actual trend
    "Bullish"
  })

  output$signal_confidence <- renderText({
    "Medium"  # DEMO: derive from quantile band width relative to price level
  })

  output$dominant_driver <- renderText({
    "Brazil rainfall deficit"  # DEMO: derive from feature importance / coefficient magnitude
  })

  output$horizon_outlook_chart <- renderPlotly({
    # DEMO chart structure -- replace point_pred/q10/q90 with real model output
    horizons <- c(1, 3, 6, 9, 12)
    last_price <- tail(panel$price, 1)
    demo_outlook <- data.frame(
      horizon = horizons,
      point_pred = last_price * (1 + c(0.01, 0.03, 0.05, 0.04, 0.02)),
      q10 = last_price * (1 + c(-0.02, -0.03, -0.05, -0.08, -0.12)),
      q90 = last_price * (1 + c(0.04, 0.09, 0.15, 0.18, 0.22))
    )

    plot_ly(demo_outlook, x = ~horizon) %>%
      add_ribbons(ymin = ~q10, ymax = ~q90, name = "80% interval",
                  fillcolor = "rgba(52,152,219,0.2)", line = list(color = "transparent")) %>%
      add_lines(y = ~point_pred, name = "Point forecast", line = list(color = "#2c3e50")) %>%
      add_markers(y = ~point_pred, showlegend = FALSE) %>%
      layout(xaxis = list(title = "Months ahead"), yaxis = list(title = "Price (cents/lb)"))
  })

  output$stacked_risk_table <- renderDT({
    # DEMO: replace with real detection of overlapping adverse driver readings
    data.frame(
      Period = c("Jul-Sep 2026 (projected)", "Feb-Apr 2024 (historical)"),
      Weather = c("Rainfall deficit (Minas Gerais)", "Frost + drought (Brazil)"),
      FX = c("BRL stable", "BRL weak"),
      `Supply Chain` = c("Hormuz disruption active", "Normal"),
      `Conviction` = c("High (3 factors aligned)", "High (realized: +80% YoY)"),
      check.names = FALSE
    )
  }, options = list(dom = "t", ordering = FALSE))

  # --- Region Map tab -----------------------------------------------------
  output$region_map <- renderLeaflet({
    leaflet(GROWING_REGIONS_MAP) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        lng = ~lon, lat = ~lat,
        radius = 10,
        color = ~case_when(
          varietal == "Arabica" ~ "#8B4513",
          varietal == "Robusta" ~ "#2E8B57",
          TRUE ~ "#DAA520"
        ),
        fillOpacity = 0.7,
        popup = ~paste0("<b>", region, "</b><br>", country, " — ", varietal,
                        "<br>", share_note)
      ) %>%
      setView(lng = -50, lat = -5, zoom = 2)
  })

  output$region_driver_chart <- renderPlotly({
    plot_ly(panel, x = ~date, y = ~rain_z_avg_all_regions, type = "scatter", mode = "lines",
            name = "Rainfall anomaly (z-score, avg across regions)") %>%
      layout(yaxis = list(title = "Z-score"), xaxis = list(title = ""))
  })

  # --- Driver Drill-Down tab ----------------------------------------------
  output$driver_overlay_chart <- renderPlotly({
    driver_col <- input$driver_select

    plot_ly(panel, x = ~date) %>%
      add_lines(y = ~price, name = "Coffee price", yaxis = "y1", line = list(color = "#2c3e50")) %>%
      add_lines(y = as.formula(paste0("~", driver_col)), name = driver_col, yaxis = "y2",
                line = list(color = "#e67e22", dash = "dot")) %>%
      layout(
        yaxis  = list(title = "Price (cents/lb)"),
        yaxis2 = list(title = driver_col, overlaying = "y", side = "right"),
        legend = list(orientation = "h")
      )
  })

  output$analog_table <- renderDT({
    # DEMO: replace with real nearest-neighbor search over historical
    # driver readings (e.g. using distance on standardized driver vector)
    data.frame(
      Date = c("2014-03", "2021-07", "2024-04"),
      `Similarity` = c("0.91", "0.87", "0.83"),
      `Driver Reading` = c("El Nino + BRL weak", "Frost risk elevated", "Drought + record heat"),
      `Price Move (next 6mo)` = c("+18%", "+24%", "+62%"),
      check.names = FALSE
    )
  }, options = list(dom = "t", ordering = FALSE))

  # --- Backtest tab --------------------------------------------------------
  output$bt_mape <- renderText({ "8.4%" })          # DEMO
  output$bt_coverage <- renderText({ "77%" })       # DEMO
  output$bt_directional <- renderText({ "68%" })    # DEMO

  output$backtest_chart <- renderPlotly({
    # DEMO: replace with models[[paste0(input$backtest_horizon, "mo")]]$test_results
    n <- 30
    demo_bt <- data.frame(
      date = tail(panel$date, n),
      actual = tail(panel$price, n),
      point_pred = tail(panel$price, n) + rnorm(n, 0, 5),
      q10 = tail(panel$price, n) - 10,
      q90 = tail(panel$price, n) + 10
    )
    plot_ly(demo_bt, x = ~date) %>%
      add_ribbons(ymin = ~q10, ymax = ~q90, name = "80% interval",
                  fillcolor = "rgba(52,152,219,0.15)", line = list(color = "transparent")) %>%
      add_lines(y = ~actual, name = "Actual", line = list(color = "#2c3e50")) %>%
      add_lines(y = ~point_pred, name = "Predicted", line = list(color = "#e74c3c", dash = "dash"))
  })
}
