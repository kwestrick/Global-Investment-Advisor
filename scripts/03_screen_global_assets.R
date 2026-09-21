# 03_screen_global_assets.R
# Starter global asset screen using return, volatility, drawdown, and relative strength

source("R/00_setup.R")
load_required_packages()

source("R/data_import.R")
source("R/indicators.R")
source("R/screening.R")
source("R/plotting.R")

create_project_dirs()

country_universe <- create_country_etf_universe()

prices <- get_market_prices(
  tickers = country_universe$symbol,
  from = analysis_defaults$start_date,
  to = Sys.Date()
)

returns <- get_adjusted_returns(prices)

return_summary <- calculate_return_summary(returns)
drawdowns <- calculate_drawdowns(returns)
max_drawdowns <- drawdowns %>%
  dplyr::group_by(symbol) %>%
  dplyr::summarise(
    max_drawdown = min(drawdown, na.rm = TRUE),
    .groups = "drop"
  )

relative_strength <- calculate_relative_strength(
  prices,
  benchmark_symbol = analysis_defaults$equity_benchmark
)

latest_relative_strength <- relative_strength %>%
  dplyr::group_by(symbol) %>%
  dplyr::filter(date == max(date, na.rm = TRUE)) %>%
  dplyr::ungroup() %>%
  dplyr::select(symbol, latest_relative_strength = relative_strength)

screen <- return_summary %>%
  dplyr::left_join(max_drawdowns, by = "symbol") %>%
  dplyr::left_join(latest_relative_strength, by = "symbol") %>%
  dplyr::left_join(country_universe, by = "symbol") %>%
  dplyr::mutate(
    return_score = dplyr::percent_rank(annualized_return) * 5,
    volatility_score = (1 - dplyr::percent_rank(annualized_volatility)) * 5,
    drawdown_score = dplyr::percent_rank(max_drawdown) * 5,
    relative_strength_score = dplyr::percent_rank(latest_relative_strength) * 5,
    weighted_score =
      return_score * 0.30 +
      volatility_score * 0.20 +
      drawdown_score * 0.20 +
      relative_strength_score * 0.30
  ) %>%
  dplyr::arrange(dplyr::desc(weighted_score))

top_screen <- screen %>%
  dplyr::slice_head(n = 15)

write_output_table(screen, "global_asset_screen")

screen_chart <- plot_scorecard(
  top_screen,
  label_col = symbol,
  score_col = weighted_score,
  title = "Top Global ETF Opportunities by Starter Quant Screen"
)

save_chart(
  screen_chart,
  paste0("global_asset_screen_", today_stamp(), ".png")
)

message("Global asset screen complete.")
