# plotting.R
# Charting functions for Global Investment Advisor

plot_growth_of_1 <- function(cumulative_returns,
                             title = "Growth of $1",
                             subtitle = NULL) {
  cumulative_returns %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = date,
        y = growth_of_1,
        color = symbol
      )
    ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::scale_y_continuous(labels = scales::dollar_format()) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = "Growth of $1",
      color = NULL
    ) +
    theme_gia()
}

plot_drawdowns <- function(drawdowns,
                           title = "Drawdown Comparison",
                           subtitle = NULL) {
  drawdowns %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = date,
        y = drawdown,
        color = symbol
      )
    ) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = "Drawdown",
      color = NULL
    ) +
    theme_gia()
}

plot_relative_strength <- function(relative_strength,
                                   benchmark_symbol = analysis_defaults$equity_benchmark,
                                   title = "Relative Strength",
                                   subtitle = NULL) {
  relative_strength %>%
    dplyr::filter(symbol != benchmark_symbol) %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = date,
        y = relative_strength,
        color = symbol
      )
    ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = paste("Price relative to", benchmark_symbol),
      color = NULL
    ) +
    theme_gia()
}

plot_scorecard <- function(scorecard,
                           label_col = symbol,
                           score_col = weighted_score,
                           title = "Opportunity Scorecard") {
  label_col <- rlang::enquo(label_col)
  score_col <- rlang::enquo(score_col)

  scorecard %>%
    dplyr::arrange(!!score_col) %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = reorder(!!label_col, !!score_col),
        y = !!score_col
      )
    ) +
    ggplot2::geom_col(fill = "#2C7FB8") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = title,
      x = NULL,
      y = "Weighted score"
    ) +
    theme_gia()
}

save_chart <- function(plot,
                       file_name,
                       width = 10,
                       height = 6,
                       dpi = 300) {
  file_path <- file.path("outputs/charts", file_name)

  ggplot2::ggsave(
    filename = file_path,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi
  )

  file_path
}
