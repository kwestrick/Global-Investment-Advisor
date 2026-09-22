# fx_forecasting.R
# USD/COP FOREX decision-support module.
#
# Answers the question: "Is now a relatively good time to convert USD to COP?"
#
# Does NOT attempt point forecasts (Meese-Rogoff result still holds for COP/USD).
# Instead provides:
#   1. Historical percentile context — where does the current rate sit vs. history?
#   2. GARCH(1,1) volatility bands — realistic uncertainty intervals, not direction calls
#   3. Macro driver signals — Brent crude, DXY, VIX as context
#   4. A synthesized conversion signal: Favorable / Neutral / Unfavorable
#
# Usage:
#   source("R/00_setup.R")
#   source("R/colombia_indicators.R")   # for fetch_cop_exchange_rate()
#   source("R/fx_forecasting.R")
#
#   # Option A: use existing fx tibble from session
#   series <- prepare_cop_series(fx)
#
#   # Option B: fetch fresh data
#   series <- fetch_cop_exchange_rate(start_date = Sys.Date() - 10 * 365)
#
#   # Run full analysis
#   print_cop_brief(series)
#   bands <- cop_garch_bands(series, horizon_days = 90)
#   plot_cop_bands(series, bands)
#
# Key context:
#   COP/USD is expressed as COP per 1 USD. Higher = weaker peso.
#   A rate in the 70th+ percentile (5Y lookback) means the peso is historically
#   cheap in USD terms — COP assets cost fewer dollars to acquire.
#
# Required packages: rugarch, tidyquant, dplyr, ggplot2, lubridate
# Optional:          tidyquant (for macro signals)


# ---- Data preparation --------------------------------------------------------

#' Prepare a clean COP/USD time series from the standard fx tibble schema.
#'
#' Accepts the `fx` tibble produced by `fetch_yahoo_fx()` in economic_indicators.R,
#' which uses the 9-column standard schema:
#'   date, geography, indicator_code, indicator_name, category,
#'   value, unit, source, frequency
#'
#' Also accepts output from `fetch_cop_exchange_rate()` (columns: date, cop_per_usd).
#'
#' @param fx Tibble. Either standard fx schema or fetch_cop_exchange_rate() output.
#' @return Tibble with columns: date (Date), cop_per_usd (numeric).
prepare_cop_series <- function(fx) {
  stopifnot(is.data.frame(fx))

  # Handle standard 9-column schema (from fetch_yahoo_fx / economic_indicators.R)
  if ("indicator_code" %in% names(fx)) {
    series <- fx |>
      dplyr::filter(indicator_code == "COP=X", !is.na(value)) |>
      dplyr::select(date, cop_per_usd = value) |>
      dplyr::arrange(date)

    if (nrow(series) == 0) {
      stop("No COP=X rows found in fx tibble. Check indicator_code values.")
    }
    return(series)
  }

  # Handle fetch_cop_exchange_rate() output (columns: date, cop_per_usd)
  if ("cop_per_usd" %in% names(fx)) {
    return(fx |> dplyr::select(date, cop_per_usd) |> dplyr::arrange(date))
  }

  stop(
    "fx must be either the standard 9-column schema (with indicator_code) ",
    "or the output of fetch_cop_exchange_rate() (with cop_per_usd)."
  )
}


# ---- Historical percentile context -------------------------------------------

#' Compute historical percentile rank of the current COP/USD rate.
#'
#' A high percentile (e.g., 75th) means the peso is historically weak —
#' COP assets are cheaper to acquire in USD terms.
#'
#' @param series Tibble from prepare_cop_series(). Columns: date, cop_per_usd.
#' @param lookback_years Numeric. Years of history to use for percentile calculation.
#'   Defaults to 5. Pass c(1, 3, 5) to get multiple lookbacks.
#' @return Tibble with one row per lookback_years value:
#'   lookback_years, n_obs, min_rate, max_rate, median_rate,
#'   current_rate, percentile, label
cop_historical_percentile <- function(series, lookback_years = 5) {
  stopifnot(is.data.frame(series), "cop_per_usd" %in% names(series))

  current_rate <- dplyr::last(series$cop_per_usd)
  current_date <- dplyr::last(series$date)

  purrr::map_dfr(lookback_years, function(yrs) {
    cutoff <- current_date - lubridate::years(yrs)
    window <- series |> dplyr::filter(date >= cutoff)

    if (nrow(window) < 30) {
      warning("Only ", nrow(window), " observations in ", yrs, "-year window.")
    }

    pct <- mean(window$cop_per_usd <= current_rate, na.rm = TRUE) * 100

    label <- dplyr::case_when(
      pct >= 75 ~ "Historically Weak Peso (Favorable for USD→COP conversion)",
      pct >= 55 ~ "Somewhat Weak Peso (Neutral-to-Favorable)",
      pct >= 35 ~ "Mid-Range (Neutral)",
      pct >= 20 ~ "Somewhat Strong Peso (Neutral-to-Unfavorable)",
      TRUE       ~ "Historically Strong Peso (Unfavorable for USD→COP conversion)"
    )

    tibble::tibble(
      lookback_years = yrs,
      n_obs          = nrow(window),
      min_rate       = min(window$cop_per_usd, na.rm = TRUE),
      max_rate       = max(window$cop_per_usd, na.rm = TRUE),
      median_rate    = median(window$cop_per_usd, na.rm = TRUE),
      current_rate   = current_rate,
      percentile     = round(pct, 1),
      label          = label
    )
  })
}


# ---- GARCH(1,1) volatility bands --------------------------------------------

#' Fit a GARCH(1,1) model on COP/USD log returns and simulate forward paths.
#'
#' Returns quantile bands (10th/25th/50th/75th/90th percentiles) over the
#' forecast horizon. The median path is NOT a directional forecast — it is the
#' model's best guess absent new information, which is approximately flat.
#' The bands show the plausible range given current volatility regime.
#'
#' Requires the `rugarch` package.
#'
#' @param series Tibble from prepare_cop_series().
#' @param horizon_days Integer. Days ahead to simulate. Default 90.
#' @param n_sim Integer. Number of Monte Carlo paths. Default 5000.
#' @param train_years Numeric. Years of history to use for fitting. Default 5.
#' @return List with elements:
#'   $bands  — Tibble: day (1:horizon), p10, p25, p50, p75, p90, level_label
#'   $fit    — rugarch ugarchfit object
#'   $spec   — rugarch ugarchspec object
#'   $current_rate — numeric, last observed rate
#'   $annualized_vol — numeric, annualized conditional volatility at last observation
#'   $vol_regime — character, "Low" / "Moderate" / "Elevated" / "High"
cop_garch_bands <- function(series,
                            horizon_days = 90,
                            n_sim        = 5000,
                            train_years  = 5) {

  if (!requireNamespace("rugarch", quietly = TRUE)) {
    stop("Package 'rugarch' is required. Install with: install.packages('rugarch')")
  }

  # Training window
  cutoff   <- dplyr::last(series$date) - lubridate::years(train_years)
  train    <- series |> dplyr::filter(date >= cutoff, !is.na(cop_per_usd))
  log_ret  <- diff(log(train$cop_per_usd))

  if (length(log_ret) < 200) {
    stop("Fewer than 200 log-return observations in training window. ",
         "Increase train_years or provide more history.")
  }

  # Specify and fit GARCH(1,1) with normal innovations
  spec <- rugarch::ugarchspec(
    variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
    mean.model     = list(armaOrder = c(0, 0), include.mean = TRUE),
    distribution.model = "norm"
  )

  fit <- tryCatch(
    rugarch::ugarchfit(spec = spec, data = log_ret, solver = "hybrid"),
    error = function(e) {
      stop("GARCH fitting failed: ", conditionMessage(e))
    }
  )

  # Current volatility regime
  last_sigma    <- as.numeric(rugarch::sigma(fit)[length(log_ret)])
  ann_vol       <- last_sigma * sqrt(252) * 100  # annualized %
  vol_regime    <- dplyr::case_when(
    ann_vol < 8  ~ "Low",
    ann_vol < 14 ~ "Moderate",
    ann_vol < 20 ~ "Elevated",
    TRUE          ~ "High"
  )

  # Simulate forward paths
  set.seed(7391)
  sim <- rugarch::ugarchsim(
    fit,
    n.sim    = horizon_days,
    n.start  = 0,
    m.sim    = n_sim,
    rseed    = 7391
  )

  # sim@simulation$seriesSim is (horizon_days × n_sim) log-return matrix
  log_ret_paths <- sim@simulation$seriesSim

  # Convert to price levels: current_rate × exp(cumsum of log returns)
  current_rate <- dplyr::last(series$cop_per_usd)

  level_paths <- apply(log_ret_paths, 2, function(path) {
    current_rate * exp(cumsum(path))
  })  # (horizon_days × n_sim)

  # Compute quantile bands at each horizon day
  qs <- c(0.10, 0.25, 0.50, 0.75, 0.90)
  band_matrix <- apply(level_paths, 1, quantile, probs = qs, na.rm = TRUE)
  # band_matrix is (5 × horizon_days); transpose
  band_df <- as.data.frame(t(band_matrix))
  names(band_df) <- c("p10", "p25", "p50", "p75", "p90")

  bands <- tibble::tibble(
    day   = seq_len(horizon_days),
    date  = dplyr::last(series$date) + day
  ) |>
    dplyr::bind_cols(band_df) |>
    dplyr::mutate(
      level_label = dplyr::case_when(
        p50 > current_rate * 1.03  ~ "Median path: Peso weakening",
        p50 < current_rate * 0.97  ~ "Median path: Peso strengthening",
        TRUE                        ~ "Median path: Roughly stable"
      )
    )

  list(
    bands           = bands,
    fit             = fit,
    spec            = spec,
    current_rate    = current_rate,
    annualized_vol  = round(ann_vol, 1),
    vol_regime      = vol_regime
  )
}


# ---- Macro driver signals ----------------------------------------------------

#' Fetch contextual macro signals relevant to COP/USD.
#'
#' Signals: Brent crude (BZ=F), DXY dollar index (DX-Y.NYB), VIX (^VIX).
#' These are the three primary drivers of short-term COP moves.
#'
#' Returns 20-day and 60-day z-scores so you can see whether drivers are
#' pushing the peso toward weakness or strength.
#'
#' @param lookback_days Integer. Days of history to fetch. Default 180.
#' @return Tibble: symbol, name, current_value, z_20d, z_60d, signal_label
cop_macro_signals <- function(lookback_days = 180) {
  if (!requireNamespace("tidyquant", quietly = TRUE)) {
    stop("Package 'tidyquant' is required.")
  }

  tickers <- c("BZ=F", "DX-Y.NYB", "^VIX")
  names_map <- c(
    "BZ=F"      = "Brent Crude (USD/bbl)",
    "DX-Y.NYB"  = "US Dollar Index (DXY)",
    "^VIX"      = "VIX (Equity Volatility)"
  )

  raw <- tryCatch(
    tidyquant::tq_get(tickers, from = Sys.Date() - lookback_days, get = "stock.prices"),
    error = function(e) {
      warning("Macro signal fetch failed: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(raw) || nrow(raw) == 0) {
    warning("cop_macro_signals: no data returned.")
    return(NULL)
  }

  raw |>
    janitor::clean_names() |>
    dplyr::group_by(symbol) |>
    dplyr::arrange(date, .by_group = TRUE) |>
    dplyr::mutate(
      roll_mean_20 = zoo::rollmean(adjusted, k = 20, fill = NA, align = "right"),
      roll_sd_20   = zoo::rollapply(adjusted, width = 20, FUN = sd, fill = NA, align = "right"),
      roll_mean_60 = zoo::rollmean(adjusted, k = 60, fill = NA, align = "right"),
      roll_sd_60   = zoo::rollapply(adjusted, width = 60, FUN = sd, fill = NA, align = "right"),
      z_20d        = (adjusted - roll_mean_20) / roll_sd_20,
      z_60d        = (adjusted - roll_mean_60) / roll_sd_60
    ) |>
    dplyr::filter(date == max(date)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      name = names_map[symbol],
      # For COP: Brent up → peso strengthens; DXY up → peso weakens; VIX up → peso weakens
      cop_impact_direction = dplyr::case_when(
        symbol == "BZ=F"     ~ "positive",  # Brent↑ → COP strengthens
        symbol == "DX-Y.NYB" ~ "negative",  # DXY↑ → COP weakens
        symbol == "^VIX"     ~ "negative"   # VIX↑ → COP weakens
      ),
      signal_label = dplyr::case_when(
        # Brent: high z = high oil = bullish for COP
        symbol == "BZ=F" & z_20d >  1.0 ~ "Brent elevated — COP tailwind",
        symbol == "BZ=F" & z_20d < -1.0 ~ "Brent depressed — COP headwind",
        # DXY: high z = strong dollar = bearish for COP
        symbol == "DX-Y.NYB" & z_20d >  1.0 ~ "DXY elevated — USD strong, COP headwind",
        symbol == "DX-Y.NYB" & z_20d < -1.0 ~ "DXY depressed — USD weak, COP tailwind",
        # VIX: high z = risk-off = bearish for EM/COP
        symbol == "^VIX" & z_20d >  1.0 ~ "VIX elevated — risk-off, COP headwind",
        symbol == "^VIX" & z_20d < -1.0 ~ "VIX depressed — risk-on, COP tailwind",
        TRUE ~ "Neutral"
      )
    ) |>
    dplyr::select(symbol, name, current_value = adjusted, z_20d, z_60d, signal_label)
}


# ---- Conversion signal synthesis ---------------------------------------------

#' Synthesize a conversion signal from percentiles, GARCH regime, and macro signals.
#'
#' This is a decision-support heuristic, not a statistical forecast.
#' It combines three inputs:
#'   - Historical percentile (is the peso cheap or expensive vs. history?)
#'   - GARCH volatility regime (is now a low-turbulence window to act?)
#'   - Macro signals (are drivers aligned with further weakening or strengthening?)
#'
#' @param percentiles Tibble from cop_historical_percentile().
#' @param garch_result List from cop_garch_bands().
#' @param macro Tibble from cop_macro_signals(). Can be NULL.
#' @param primary_lookback Numeric. Which lookback_year from percentiles to use. Default 5.
#' @return List:
#'   $signal     — "Favorable" / "Neutral" / "Unfavorable"
#'   $confidence — "High" / "Moderate" / "Low"
#'   $rationale  — character vector of 1-sentence reasons
#'   $caution    — character vector of risks / contradictory signals
cop_conversion_signal <- function(percentiles,
                                  garch_result,
                                  macro           = NULL,
                                  primary_lookback = 5) {
  # Extract primary percentile
  pct_row <- percentiles |> dplyr::filter(lookback_years == primary_lookback)
  if (nrow(pct_row) == 0) pct_row <- percentiles[nrow(percentiles), ]
  pct_val <- pct_row$percentile

  vol_regime   <- garch_result$vol_regime
  ann_vol      <- garch_result$annualized_vol
  current_rate <- garch_result$current_rate

  rationale <- character(0)
  caution   <- character(0)
  score     <- 0  # positive = Favorable, negative = Unfavorable

  # -- Percentile component (range -2 to +2)
  if (pct_val >= 75) {
    score <- score + 2
    rationale <- c(rationale, glue::glue(
      "COP/USD at {pct_row$percentile}th percentile ({primary_lookback}-yr lookback): ",
      "peso is historically weak, making COP assets cheaper in USD terms."
    ))
  } else if (pct_val >= 55) {
    score <- score + 1
    rationale <- c(rationale, glue::glue(
      "COP/USD at {pct_row$percentile}th percentile ({primary_lookback}-yr lookback): ",
      "peso is somewhat weak vs. history."
    ))
  } else if (pct_val >= 35) {
    rationale <- c(rationale, glue::glue(
      "COP/USD at {pct_row$percentile}th percentile ({primary_lookback}-yr lookback): ",
      "peso is near its historical midpoint — no strong valuation signal."
    ))
  } else if (pct_val >= 20) {
    score <- score - 1
    caution <- c(caution, glue::glue(
      "COP/USD at {pct_row$percentile}th percentile ({primary_lookback}-yr lookback): ",
      "peso is somewhat strong vs. history — consider waiting."
    ))
  } else {
    score <- score - 2
    caution <- c(caution, glue::glue(
      "COP/USD at {pct_row$percentile}th percentile ({primary_lookback}-yr lookback): ",
      "peso is historically strong — USD→COP conversion is expensive right now."
    ))
  }

  # -- Volatility component: prefer low/moderate volatility for planned conversions
  if (vol_regime %in% c("Low", "Moderate")) {
    score <- score + 0.5
    rationale <- c(rationale, glue::glue(
      "GARCH volatility regime: {vol_regime} ({ann_vol}% annualized). ",
      "Relatively calm market — timing execution is more predictable."
    ))
  } else {
    caution <- c(caution, glue::glue(
      "GARCH volatility regime: {vol_regime} ({ann_vol}% annualized). ",
      "Elevated turbulence — rate may move significantly before or during execution."
    ))
  }

  # -- Macro signal component
  if (!is.null(macro) && nrow(macro) > 0) {
    headwinds  <- sum(grepl("headwind", macro$signal_label))
    tailwinds  <- sum(grepl("tailwind", macro$signal_label))
    net_signal <- tailwinds - headwinds

    if (net_signal > 0) {
      score <- score + 0.5
      rationale <- c(rationale, glue::glue(
        "{tailwinds} of 3 macro drivers (Brent/DXY/VIX) are currently ",
        "supportive of COP strength."
      ))
    } else if (net_signal < 0) {
      caution <- c(caution, glue::glue(
        "{headwinds} of 3 macro drivers (Brent/DXY/VIX) are currently ",
        "acting as COP headwinds — peso may weaken further before stabilizing."
      ))
    }
  }

  # -- Synthesize
  signal <- dplyr::case_when(
    score >= 2   ~ "Favorable",
    score >= 0.5 ~ "Neutral-to-Favorable",
    score >= -0.5 ~ "Neutral",
    score >= -1.5 ~ "Neutral-to-Unfavorable",
    TRUE          ~ "Unfavorable"
  )

  confidence <- dplyr::case_when(
    abs(score) >= 2   ~ "Moderate",   # never "High" — FX forecasting is inherently uncertain
    abs(score) >= 1   ~ "Low",
    TRUE               ~ "Very Low"
  )

  list(
    signal     = signal,
    confidence = confidence,
    score      = round(score, 2),
    rationale  = rationale,
    caution    = caution
  )
}


# ---- Visualization -----------------------------------------------------------

#' Plot historical COP/USD rate with GARCH uncertainty cone.
#'
#' Shows the last `history_days` of actual rates plus the forward simulation
#' bands (10th/25th/75th/90th percentiles and median).
#'
#' @param series Tibble from prepare_cop_series().
#' @param garch_result List from cop_garch_bands().
#' @param history_days Integer. Days of history to show. Default 365.
#' @param save_path Character or NULL. If provided, saves to this path.
#' @return ggplot object.
plot_cop_bands <- function(series,
                           garch_result,
                           history_days = 365,
                           save_path    = NULL) {
  bands        <- garch_result$bands
  current_rate <- garch_result$current_rate
  vol_regime   <- garch_result$vol_regime
  ann_vol      <- garch_result$annualized_vol

  # Historical window
  hist_start <- dplyr::last(series$date) - history_days
  hist_data  <- series |> dplyr::filter(date >= hist_start)

  # Anchor row — connect history to forecast at current date
  anchor <- tibble::tibble(
    day   = 0L,
    date  = dplyr::last(series$date),
    p10   = current_rate, p25 = current_rate,
    p50   = current_rate, p75 = current_rate,
    p90   = current_rate,
    level_label = "Anchor"
  )
  bands_full <- dplyr::bind_rows(anchor, bands)

  p <- ggplot2::ggplot() +
    # 80% band (lightest)
    ggplot2::geom_ribbon(
      data    = bands_full,
      mapping = ggplot2::aes(x = date, ymin = p10, ymax = p90),
      fill    = "#2196F3", alpha = 0.12
    ) +
    # 50% band (medium)
    ggplot2::geom_ribbon(
      data    = bands_full,
      mapping = ggplot2::aes(x = date, ymin = p25, ymax = p75),
      fill    = "#2196F3", alpha = 0.22
    ) +
    # Median path
    ggplot2::geom_line(
      data    = bands_full,
      mapping = ggplot2::aes(x = date, y = p50),
      color   = "#1565C0", linewidth = 0.8, linetype = "dashed"
    ) +
    # Historical rate
    ggplot2::geom_line(
      data    = hist_data,
      mapping = ggplot2::aes(x = date, y = cop_per_usd),
      color   = "#212121", linewidth = 0.9
    ) +
    # Current rate marker
    ggplot2::geom_point(
      data    = dplyr::filter(series, date == max(date)),
      mapping = ggplot2::aes(x = date, y = cop_per_usd),
      color   = "#E53935", size = 3
    ) +
    # Vertical divider at forecast start
    ggplot2::geom_vline(
      xintercept = dplyr::last(series$date),
      linetype   = "dotted", color = "grey50", linewidth = 0.6
    ) +
    ggplot2::labs(
      title    = "USD/COP Rate: Historical + GARCH(1,1) Uncertainty Bands",
      subtitle = glue::glue(
        "Current: {format(round(current_rate), big.mark=',')} COP/USD | ",
        "Volatility regime: {vol_regime} ({ann_vol}% annualized) | ",
        "Bands: 10th/25th/75th/90th percentiles of simulated paths"
      ),
      x        = NULL,
      y        = "COP per 1 USD",
      caption  = paste0(
        "Bands are Monte Carlo simulation from GARCH(1,1) — they reflect ",
        "uncertainty, not a directional forecast.\n",
        "Higher COP/USD = weaker peso. Source: Yahoo Finance (COP=X). ",
        "Generated: ", Sys.Date()
      )
    ) +
    ggplot2::scale_y_continuous(labels = scales::comma) +
    ggplot2::scale_x_date(date_breaks = "3 months", date_labels = "%b '%y") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey40", size = 10),
      plot.caption  = ggplot2::element_text(color = "grey50", size = 8),
      axis.text.x   = ggplot2::element_text(angle = 30, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    ) +
    ggplot2::annotate(
      "text", x = dplyr::last(series$date) + 5, y = current_rate,
      label = "← Forecast", hjust = 0, size = 3.5, color = "grey50"
    )

  if (!is.null(save_path)) {
    ggplot2::ggsave(save_path, plot = p, width = 12, height = 6, dpi = 150)
    message("Chart saved: ", save_path)
  }

  p
}


# ---- Console brief -----------------------------------------------------------

#' Print a concise COP/USD decision-support brief to the console.
#'
#' Suitable for embedding in quarterly workflow (scripts/00_quarterly_refresh.R).
#'
#' @param series Tibble from prepare_cop_series().
#' @param run_garch Logical. If TRUE, fits GARCH and prints vol regime. Default TRUE.
#'   Set FALSE to get a quick percentile-only summary without the ~10-sec GARCH fit.
#' @param horizon_days Integer. GARCH forecast horizon. Default 90.
#' @return Invisibly returns a list with percentiles, garch_result (if run), signal.
print_cop_brief <- function(series, run_garch = TRUE, horizon_days = 90) {

  cat("\n", strrep("=", 60), "\n", sep = "")
  cat("  USD/COP CONVERSION SIGNAL\n")
  cat("  Generated:", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "\n")
  cat(strrep("=", 60), "\n\n")

  current_rate <- dplyr::last(series$cop_per_usd)
  current_date <- dplyr::last(series$date)
  cat(sprintf("  Current COP/USD:  %s  (as of %s)\n",
              format(round(current_rate), big.mark = ","),
              format(current_date)))
  cat("\n")

  # Historical percentiles
  pcts <- cop_historical_percentile(series, lookback_years = c(1, 3, 5))
  cat("  Historical Percentile Context:\n")
  for (i in seq_len(nrow(pcts))) {
    row <- pcts[i, ]
    cat(sprintf("    %d-year: %4.1f%%ile  (range %s – %s COP/USD)  |  %s\n",
                row$lookback_years,
                row$percentile,
                format(round(row$min_rate), big.mark = ","),
                format(round(row$max_rate), big.mark = ","),
                row$label))
  }
  cat("\n")

  # GARCH
  garch_result <- NULL
  if (run_garch) {
    cat("  Fitting GARCH(1,1) volatility model...\n")
    garch_result <- tryCatch(
      cop_garch_bands(series, horizon_days = horizon_days),
      error = function(e) {
        cat("  GARCH fitting failed:", conditionMessage(e), "\n")
        NULL
      }
    )
    if (!is.null(garch_result)) {
      bands <- garch_result$bands
      cat(sprintf("  Volatility regime:  %s (%s%% annualized)\n",
                  garch_result$vol_regime, garch_result$annualized_vol))
      end_row <- bands[nrow(bands), ]
      cat(sprintf("  %d-day range (80%%): %s – %s COP/USD\n",
                  horizon_days,
                  format(round(end_row$p10), big.mark = ","),
                  format(round(end_row$p90), big.mark = ",")))
      cat(sprintf("  %d-day range (50%%): %s – %s COP/USD\n",
                  horizon_days,
                  format(round(end_row$p25), big.mark = ","),
                  format(round(end_row$p75), big.mark = ",")))
      cat("\n")
    }
  }

  # Macro signals
  cat("  Fetching macro signals (Brent / DXY / VIX)...\n")
  macro <- tryCatch(cop_macro_signals(), warning = function(w) NULL, error = function(e) NULL)
  if (!is.null(macro)) {
    cat("  Macro Driver Signals:\n")
    for (i in seq_len(nrow(macro))) {
      cat(sprintf("    %-28s z-score(20d): %+.2f  |  %s\n",
                  macro$name[i], macro$z_20d[i], macro$signal_label[i]))
    }
    cat("\n")
  }

  # Conversion signal
  signal_obj <- cop_conversion_signal(pcts, garch_result %||% list(
    vol_regime = "Unknown", annualized_vol = NA, current_rate = current_rate
  ), macro)

  cat(strrep("-", 60), "\n")
  cat(sprintf("  SIGNAL:     %s\n", signal_obj$signal))
  cat(sprintf("  CONFIDENCE: %s\n", signal_obj$confidence))
  cat("\n  Rationale:\n")
  for (r in signal_obj$rationale) cat("    +", r, "\n")
  if (length(signal_obj$caution) > 0) {
    cat("\n  Cautions:\n")
    for (c in signal_obj$caution) cat("    !", c, "\n")
  }
  cat(strrep("-", 60), "\n")
  cat("\n  NOTE: This is a decision-support heuristic, not a financial forecast.\n")
  cat("  Consult a qualified advisor before executing currency conversions.\n\n")

  invisible(list(percentiles = pcts, garch_result = garch_result, signal = signal_obj))
}

# Null coalescing helper (base R ≥ 4.4 has |>, but not %||%; define locally)
`%||%` <- function(x, y) if (!is.null(x)) x else y
