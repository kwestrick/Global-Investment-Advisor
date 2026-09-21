# ============================================================
# ui.R — Coffee Commodity Risk & Opportunity dashboard
# Layout: (1) signal/watchlist summary, (2) region map + driver drill-down,
# (3) backtest/track-record view — per README build sequence step 3.
# ============================================================

ui <- page_navbar(
  title = "Coffee Commodity Intelligence",
  theme = bs_theme(version = 5, bootswatch = "flatly"),

  nav_panel(
    title = "Signal Summary",
    icon = icon("gauge"),
    layout_columns(
      col_widths = c(4, 4, 4),
      value_box(
        title = "Current Signal (6mo)",
        value = textOutput("signal_direction", inline = TRUE),
        showcase = icon("arrow-trend-up"),
        theme = "primary"
      ),
      value_box(
        title = "Confidence",
        value = textOutput("signal_confidence", inline = TRUE),
        showcase = icon("shield-halved"),
        theme = "secondary"
      ),
      value_box(
        title = "Dominant Driver",
        value = textOutput("dominant_driver", inline = TRUE),
        showcase = icon("cloud-rain"),
        theme = "info"
      )
    ),
    card(
      card_header("Multi-Horizon Outlook"),
      card_body(
        p("Point forecast and 80% uncertainty band by horizon. Widening bands ",
          "at longer horizons are expected -- treat 9-12mo signals as directional, not precise."),
        plotlyOutput("horizon_outlook_chart", height = "380px")
      )
    ),
    card(
      card_header("Stacked Risk Watchlist"),
      card_body(
        p("Periods where weather, FX, and supply chain signals point the same direction ",
          "carry higher conviction (see Space instructions: 'stacked-risk scenario')."),
        DTOutput("stacked_risk_table")
      )
    )
  ),

  nav_panel(
    title = "Region & Driver Map",
    icon = icon("map"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Controls",
        selectInput("region_layer", "Overlay layer",
                    choices = c("Rainfall anomaly (z-score)" = "rain",
                                "ENSO regime" = "enso",
                                "Chokepoint disruption" = "chokepoint")),
        dateRangeInput("map_date_range", "Date range",
                       start = Sys.Date() - 365, end = Sys.Date()),
        hr(),
        p(class = "text-muted small",
          "Map shows representative growing-region centroids, not exhaustive coverage. ",
          "See docs/data_sources.md for source detail.")
      ),
      card(
        full_screen = TRUE,
        card_header("Growing Regions — Current Risk Overlay"),
        leafletOutput("region_map", height = "500px")
      ),
      card(
        card_header("Driver Detail for Selected Region"),
        plotlyOutput("region_driver_chart", height = "300px")
      )
    )
  ),

  nav_panel(
    title = "Driver Drill-Down",
    icon = icon("chart-line"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Select driver",
        radioButtons("driver_select", NULL,
                     choices = c("ENSO / ONI" = "oni_anom",
                                 "Rainfall anomaly" = "rain_z_avg_all_regions",
                                 "USD/BRL" = "fx_BRL",
                                 "Chokepoint severity" = "chokepoint_severity_max"))
      ),
      card(
        card_header("Driver vs. Price (overlay)"),
        plotlyOutput("driver_overlay_chart", height = "450px")
      ),
      card(
        card_header("Historical Analog Finder"),
        card_body(
          p("Nearest historical periods with similar driver readings, and how price moved afterward."),
          DTOutput("analog_table")
        )
      )
    )
  ),

  nav_panel(
    title = "Backtest / Track Record",
    icon = icon("clipboard-check"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Horizon",
        selectInput("backtest_horizon", "Forecast horizon",
                    choices = c("1 month" = 1, "3 months" = 3, "6 months" = 6,
                                "9 months" = 9, "12 months" = 12),
                    selected = 6)
      ),
      layout_columns(
        col_widths = c(4, 4, 4),
        value_box(title = "MAPE (test set)", value = textOutput("bt_mape", inline = TRUE), theme = "warning"),
        value_box(title = "80% Interval Coverage", value = textOutput("bt_coverage", inline = TRUE), theme = "success"),
        value_box(title = "Directional Accuracy", value = textOutput("bt_directional", inline = TRUE), theme = "primary")
      ),
      card(
        card_header("Predicted vs. Actual (held-out test period)"),
        plotlyOutput("backtest_chart", height = "400px")
      )
    )
  ),

  nav_spacer(),
  nav_item(tags$span(icon("book"), " See docs/methodology.md for modeling details", class = "text-muted small"))
)
