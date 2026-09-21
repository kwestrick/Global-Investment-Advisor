# indicators.R
# Indicator calculations for global market analysis

calculate_cumulative_returns <- function(returns,
                                         return_col = daily_return,
                                         group_col = symbol) {
  return_col <- rlang::enquo(return_col)
  group_col <- rlang::enquo(group_col)

  returns %>%
    dplyr::group_by(!!group_col) %>%
    dplyr::arrange(date, .by_group = TRUE) %>%
    dplyr::mutate(
      cumulative_return = cumprod(1 + tidyr::replace_na(!!return_col, 0)) - 1,
      growth_of_1 = 1 + cumulative_return
    ) %>%
    dplyr::ungroup()
}

calculate_return_summary <- function(returns,
                                     return_col = daily_return,
                                     periods_per_year = 252) {
  return_col <- rlang::enquo(return_col)

  returns %>%
    dplyr::group_by(symbol) %>%
    dplyr::summarise(
      observations = sum(!is.na(!!return_col)),
      annualized_return = mean(!!return_col, na.rm = TRUE) * periods_per_year,
      annualized_volatility = sd(!!return_col, na.rm = TRUE) * sqrt(periods_per_year),
      sharpe_proxy = annualized_return / annualized_volatility,
      best_period = max(!!return_col, na.rm = TRUE),
      worst_period = min(!!return_col, na.rm = TRUE),
      .groups = "drop"
    )
}

calculate_drawdowns <- function(returns,
                                return_col = daily_return) {
  return_col <- rlang::enquo(return_col)

  returns %>%
    dplyr::group_by(symbol) %>%
    dplyr::arrange(date, .by_group = TRUE) %>%
    dplyr::mutate(
      wealth_index = cumprod(1 + tidyr::replace_na(!!return_col, 0)),
      prior_peak = cummax(wealth_index),
      drawdown = wealth_index / prior_peak - 1
    ) %>%
    dplyr::ungroup()
}

calculate_relative_strength <- function(prices,
                                        benchmark_symbol = analysis_defaults$equity_benchmark) {
  price_wide <- prices %>%
    dplyr::select(date, symbol, adjusted) %>%
    tidyr::pivot_wider(names_from = symbol, values_from = adjusted)

  if (!benchmark_symbol %in% names(price_wide)) {
    stop("Benchmark symbol not found in price data: ", benchmark_symbol)
  }

  price_wide %>%
    tidyr::pivot_longer(
      cols = -date,
      names_to = "symbol",
      values_to = "adjusted"
    ) %>%
    dplyr::left_join(
      price_wide %>%
        dplyr::select(date, benchmark_adjusted = dplyr::all_of(benchmark_symbol)),
      by = "date"
    ) %>%
    dplyr::mutate(relative_strength = adjusted / benchmark_adjusted)
}

z_score <- function(x) {
  (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
}

calculate_rolling_return <- function(returns,
                                     window = 252,
                                     return_col = daily_return) {
  return_col <- rlang::enquo(return_col)

  returns %>%
    dplyr::group_by(symbol) %>%
    dplyr::arrange(date, .by_group = TRUE) %>%
    dplyr::mutate(
      rolling_return = slider::slide_dbl(
        !!return_col,
        ~ prod(1 + tidyr::replace_na(.x, 0)) - 1,
        .before = window - 1,
        .complete = TRUE
      )
    ) %>%
    dplyr::ungroup()
}
