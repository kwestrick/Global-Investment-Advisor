# valuation.R
# Valuation helper functions

score_percentile_value <- function(x, higher_is_better = FALSE) {
  if (higher_is_better) {
    dplyr::percent_rank(x)
  } else {
    1 - dplyr::percent_rank(x)
  }
}

create_valuation_scorecard <- function(data,
                                       pe_col = pe_ratio,
                                       pb_col = price_to_book,
                                       dividend_yield_col = dividend_yield,
                                       earnings_growth_col = earnings_growth) {
  pe_col <- rlang::enquo(pe_col)
  pb_col <- rlang::enquo(pb_col)
  dividend_yield_col <- rlang::enquo(dividend_yield_col)
  earnings_growth_col <- rlang::enquo(earnings_growth_col)

  data %>%
    dplyr::mutate(
      pe_score = score_percentile_value(!!pe_col, higher_is_better = FALSE),
      pb_score = score_percentile_value(!!pb_col, higher_is_better = FALSE),
      yield_score = score_percentile_value(!!dividend_yield_col, higher_is_better = TRUE),
      growth_score = score_percentile_value(!!earnings_growth_col, higher_is_better = TRUE),
      valuation_composite = rowMeans(
        dplyr::pick(pe_score, pb_score, yield_score, growth_score),
        na.rm = TRUE
      )
    )
}

compare_to_benchmark <- function(data,
                                 benchmark_symbol,
                                 metric_cols) {
  benchmark_row <- data %>%
    dplyr::filter(symbol == benchmark_symbol) %>%
    dplyr::slice(1)

  if (nrow(benchmark_row) == 0) {
    stop("Benchmark not found: ", benchmark_symbol)
  }

  data %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(metric_cols),
        ~ .x / benchmark_row[[dplyr::cur_column()]],
        .names = "{.col}_vs_benchmark"
      )
    )
}

classify_valuation_signal <- function(score) {
  dplyr::case_when(
    score >= 0.80 ~ "Very attractive",
    score >= 0.60 ~ "Attractive",
    score >= 0.40 ~ "Neutral",
    score >= 0.20 ~ "Expensive",
    TRUE ~ "Very expensive"
  )
}
