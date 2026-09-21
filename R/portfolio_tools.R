# portfolio_tools.R
# Portfolio and risk analysis tools

calculate_correlation_matrix <- function(returns,
                                         return_col = daily_return) {
  return_col <- rlang::enquo(return_col)

  returns %>%
    dplyr::select(date, symbol, return = !!return_col) %>%
    tidyr::pivot_wider(names_from = symbol, values_from = return) %>%
    dplyr::select(-date) %>%
    stats::cor(use = "pairwise.complete.obs")
}

calculate_portfolio_returns <- function(returns,
                                        weights,
                                        return_col = daily_return) {
  return_col <- rlang::enquo(return_col)

  weight_tbl <- tibble::enframe(weights, name = "symbol", value = "weight")

  returns %>%
    dplyr::left_join(weight_tbl, by = "symbol") %>%
    dplyr::mutate(weighted_return = !!return_col * weight) %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(
      portfolio_return = sum(weighted_return, na.rm = TRUE),
      .groups = "drop"
    )
}

calculate_hhi <- function(weights) {
  sum(weights^2, na.rm = TRUE)
}

calculate_position_flags <- function(weights) {
  tibble::enframe(weights, name = "symbol", value = "weight") %>%
    dplyr::mutate(
      concentration_flag = weight > 0.20,
      flag_text = dplyr::if_else(
        concentration_flag,
        "Position exceeds 20%",
        "Within threshold"
      )
    )
}

calculate_portfolio_summary <- function(portfolio_returns,
                                        benchmark_returns = NULL,
                                        periods_per_year = 252) {
  summary <- portfolio_returns %>%
    dplyr::summarise(
      annualized_return = mean(portfolio_return, na.rm = TRUE) * periods_per_year,
      annualized_volatility = sd(portfolio_return, na.rm = TRUE) * sqrt(periods_per_year),
      sharpe_proxy = annualized_return / annualized_volatility,
      .groups = "drop"
    )

  if (!is.null(benchmark_returns)) {
    comparison <- portfolio_returns %>%
      dplyr::inner_join(benchmark_returns, by = "date") %>%
      dplyr::summarise(
        correlation_to_benchmark = cor(portfolio_return, benchmark_return, use = "complete.obs"),
        excess_annualized_return = mean(portfolio_return - benchmark_return, na.rm = TRUE) * periods_per_year,
        .groups = "drop"
      )

    summary <- dplyr::bind_cols(summary, comparison)
  }

  summary
}
