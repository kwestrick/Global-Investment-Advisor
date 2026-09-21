library(dplyr)
library(lubridate)
library(tidyr)
library(purrr)

build_monthly_panel <- function(price_df, oni_df, chirps_df, fx_df,
                                fert_df = NULL, chokepoints_df = NULL) {

  sanitize_regions <- function(df) {
    df %>%
      dplyr::mutate(region = gsub("[^[:alnum:][:space:]/(),]", "", region)) %>%
      dplyr::mutate(region = trimws(region))
  }

  price_monthly <- price_df %>%
    mutate(year = lubridate::year(date), month = lubridate::month(date)) %>%
    group_by(year, month) %>%
    summarize(price = mean(price, na.rm = TRUE), .groups = "drop") %>%
    mutate(date = as.Date(sprintf("%d-%02d-01", year, month))) %>%
    distinct(date, .keep_all = TRUE)

  oni_monthly <- oni_df %>%
    filter(!is.na(season_mid_month)) %>%
    mutate(date = as.Date(sprintf("%d-%02d-01", year, season_mid_month))) %>%
    select(date, oni_anom, enso_phase) %>%
    distinct(date, .keep_all = TRUE)

  chirps_wide <- chirps_df %>%
    sanitize_regions() %>%
    mutate(
      year = lubridate::year(date),
      month = lubridate::month(date),
      date = as.Date(sprintf("%d-%02d-01", year, month))
    ) %>%
    group_by(date, region) %>%
    summarize(z_score = mean(z_score, na.rm = TRUE), .groups = "drop") %>%
    select(date, region, z_score) %>%
    tidyr::pivot_wider(
      names_from = region, values_from = z_score,
      names_prefix = "rain_z_"
    ) %>%
    distinct(date, .keep_all = TRUE)

  chirps_avg <- chirps_df %>%
    sanitize_regions() %>%
    mutate(
      year = lubridate::year(date),
      month = lubridate::month(date),
      date = as.Date(sprintf("%d-%02d-01", year, month))
    ) %>%
    group_by(date) %>%
    summarize(rain_z_avg_all_regions = mean(z_score, na.rm = TRUE), .groups = "drop") %>%
    distinct(date, .keep_all = TRUE)

  fx_wide <- fx_df %>%
    mutate(date = as.Date(format(date, "%Y-%m-01"))) %>%
    group_by(date, currency) %>%
    summarize(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = currency, values_from = value, names_prefix = "fx_") %>%
    distinct(date, .keep_all = TRUE)

  panel <- price_monthly %>%
    select(date, price) %>%
    left_join(oni_monthly, by = "date") %>%
    left_join(chirps_avg, by = "date") %>%
    left_join(chirps_wide, by = "date") %>%
    left_join(fx_wide, by = "date") %>%
    arrange(date)

  if (!is.null(fert_df)) {
    panel <- panel %>% left_join(fert_df, by = "date")
  }

  if (!is.null(chokepoints_df)) {
    chokepoint_monthly <- expand_chokepoints_to_monthly(chokepoints_df, panel$date)
    panel <- panel %>% left_join(chokepoint_monthly, by = "date")
  }

  panel <- panel %>%
    arrange(date) %>%
    mutate(
      oni_anom_lag1 = dplyr::lag(oni_anom, 1),
      oni_anom_lag3 = dplyr::lag(oni_anom, 3),
      rain_z_avg_lag1 = dplyr::lag(rain_z_avg_all_regions, 1),
      rain_z_avg_lag3 = dplyr::lag(rain_z_avg_all_regions, 3)
    )

  panel
}

expand_chokepoints_to_monthly <- function(chokepoints_df, date_seq) {
  purrr::map_dfr(date_seq, function(d) {
    active <- chokepoints_df %>%
      dplyr::filter(start_date <= d & (is.na(end_date) | end_date >= d))
    data.frame(
      date = d,
      chokepoint_severity_max = if (nrow(active) == 0) 0 else max(active$severity)
    )
  })
}
