# ============================================================
# model_template.R
# Split-sample training + walk-forward backtest + uncertainty bounds
# for a single forecast horizon. Run once per horizon (1, 3, 6, 9, 12 mo).
# ============================================================

library(dplyr)
library(glmnet)
library(quantreg)

#' Prepare horizon-specific supervised learning frame
#'
#' Shifts price forward by `horizon` months to create the target, keeping
#' predictors as of time t (no lookahead).
make_horizon_frame <- function(panel, horizon_months, predictor_cols) {
  panel %>%
    arrange(date) %>%
    mutate(target = dplyr::lead(price, horizon_months)) %>%
    select(date, target, all_of(predictor_cols)) %>%
    filter(!is.na(target)) %>%
    tidyr::drop_na()   # simple approach; consider imputation instead for
                        # production if this drops too many rows
}

#' Chronological train/validation/test split
#'
#' @param frame data.frame ordered by date
#' @param train_frac, val_frac fractions of rows (test gets the remainder)
split_chronological <- function(frame, train_frac = 0.70, val_frac = 0.15) {
  n <- nrow(frame)
  train_end <- floor(n * train_frac)
  val_end   <- floor(n * (train_frac + val_frac))

  list(
    train = frame[1:train_end, ],
    val   = frame[(train_end + 1):val_end, ],
    test  = frame[(val_end + 1):n, ]
  )
}

#' Fit elastic net + quantile regression, evaluate on test set
fit_and_evaluate <- function(splits, predictor_cols) {
  x_train <- as.matrix(splits$train[, predictor_cols])
  y_train <- splits$train$target
  x_test  <- as.matrix(splits$test[, predictor_cols])
  y_test  <- splits$test$target

  # Elastic net (point forecast), alpha tuned via cross-validation on train
  cv_fit <- glmnet::cv.glmnet(x_train, y_train, alpha = 0.5)
  point_pred <- predict(cv_fit, newx = x_test, s = "lambda.min")[, 1]

  # Quantile regression (10th/50th/90th) for uncertainty bounds
  train_df <- splits$train
  q_formula <- as.formula(paste("target ~", paste(predictor_cols, collapse = " + ")))
  q10 <- quantreg::rq(q_formula, data = train_df, tau = 0.10)
  q50 <- quantreg::rq(q_formula, data = train_df, tau = 0.50)
  q90 <- quantreg::rq(q_formula, data = train_df, tau = 0.90)

  test_df <- splits$test
  pred_q10 <- predict(q10, newdata = test_df)
  pred_q50 <- predict(q50, newdata = test_df)
  pred_q90 <- predict(q90, newdata = test_df)

  results <- data.frame(
    date        = splits$test$date,
    actual      = y_test,
    point_pred  = point_pred,
    q10         = pred_q10,
    q50         = pred_q50,
    q90         = pred_q90
  ) %>%
    mutate(
      within_band = actual >= q10 & actual <= q90,
      abs_error   = abs(actual - point_pred),
      pct_error   = 100 * abs_error / actual
    )

  metrics <- list(
    mape           = mean(results$pct_error, na.rm = TRUE),
    coverage_80pct = mean(results$within_band, na.rm = TRUE),  # target ~0.80
    directional_accuracy = mean(
      sign(diff(results$actual)) == sign(diff(results$point_pred)),
      na.rm = TRUE
    )
  )

  list(
    elastic_net_fit = cv_fit,
    quantile_fits   = list(q10 = q10, q50 = q50, q90 = q90),
    test_results    = results,
    metrics         = metrics
  )
}

#' Full pipeline for one horizon
run_horizon_model <- function(panel, horizon_months, predictor_cols) {
  frame  <- make_horizon_frame(panel, horizon_months, predictor_cols)
  splits <- split_chronological(frame)
  result <- fit_and_evaluate(splits, predictor_cols)

  message(sprintf(
    "Horizon %d mo | MAPE: %.1f%% | 80%% interval coverage: %.0f%% | Directional acc: %.0f%%",
    horizon_months, result$metrics$mape, result$metrics$coverage_80pct * 100,
    result$metrics$directional_accuracy * 100
  ))

  result
}

# ------------------------------------------------------------
# Example usage (run after building data/processed/coffee_monthly_panel.csv):
#
#   panel <- readr::read_csv(file.path(PROCESSED_DIR, "coffee_monthly_panel.csv"))
#
#   predictor_cols <- c(
#     "oni_anom_lag1", "oni_anom_lag3",
#     "rain_z_avg_lag1", "rain_z_avg_lag3",
#     "fx_BRL", "fx_VND",
#     "chokepoint_severity_max"
#     # add fertilizer price column(s) once confirmed from World Bank pull
#   )
#
#   results_by_horizon <- purrr::map(
#     c(1, 3, 6, 9, 12),
#     ~ run_horizon_model(panel, .x, predictor_cols)
#   )
#   names(results_by_horizon) <- paste0(c(1,3,6,9,12), "mo")
#
#   saveRDS(results_by_horizon, file.path(MODELS_DIR, "coffee_horizon_models.rds"))
# ------------------------------------------------------------
