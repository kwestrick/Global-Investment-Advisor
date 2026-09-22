#!/usr/bin/env Rscript
# scripts/12_fx_monitor_alert.R
# USD/COP FOREX threshold monitor with email alert.
#
# Checks whether the current COP/USD rate has crossed a favorable conversion
# threshold (default: 80th percentile of 5-year history) and sends an email
# if so. Designed to be run daily or weekly via crontab.
#
# Usage (interactive):
#   source("scripts/12_fx_monitor_alert.R")
#
# Suggested crontab (daily at 8:00 AM):
#   0 8 * * * /usr/local/bin/Rscript /path/to/scripts/12_fx_monitor_alert.R >> logs/fx_monitor.log 2>&1
#
# Environment variables required (in ~/.Renviron):
#   GMAIL_PERSONAL_APP_PASSWORD — Gmail app password for blastula
#   GMAIL_PERSONAL_FROM        — Sender/recipient address (kwestrick@gmail.com)
#
# Alert logic:
#   ALERT triggers when COP/USD percentile (5-year lookback) >= THRESHOLD_PCT.
#   A high percentile = peso is historically weak = favorable for USD→COP conversion.
#   Default threshold: 80th percentile (peso in the top quintile of historical weakness).
#
# State file:
#   outputs/fx_monitor_state.rds — stores last alert date to prevent duplicate alerts.
#   An alert is sent at most once every COOLDOWN_DAYS (default 14) even if threshold stays crossed.

# ── 0. Configuration ─────────────────────────────────────────────────────────

THRESHOLD_PCT  <- 80     # percentile (5-year) that triggers a favorable alert
LOOKBACK_YEARS <- 5      # years of history for percentile calculation
COOLDOWN_DAYS  <- 14     # minimum days between alert emails
STATE_FILE     <- "outputs/fx_monitor_state.rds"
LOG_PREFIX     <- "[FX Monitor]"

# ── 1. Environment setup ─────────────────────────────────────────────────────

renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
if (file.exists(renviron_path)) readRenviron(renviron_path)

proj_root <- "/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Investment-Advisor"
setwd(proj_root)

log_ts <- function(msg) cat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S]"), LOG_PREFIX, msg, "\n")

log_ts("=== COP/USD FOREX Monitor Started ===")

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(glue)
})

source("R/fx_forecasting.R")
source("R/colombia_indicators.R")

# ── 2. Fetch data ─────────────────────────────────────────────────────────────

log_ts("Fetching COP/USD data...")
raw_fx <- tryCatch(
  fetch_cop_exchange_rate(
    start_date = Sys.Date() - LOOKBACK_YEARS * 365,
    end_date   = Sys.Date()
  ),
  error = function(e) {
    log_ts(paste("ERROR: Data fetch failed:", conditionMessage(e)))
    NULL
  }
)

if (is.null(raw_fx) || nrow(raw_fx) == 0) {
  log_ts("ERROR: No COP/USD data returned. Exiting.")
  quit(status = 1)
}

cop_series <- prepare_cop_series(raw_fx)
current_rate <- dplyr::last(cop_series$cop_per_usd)
log_ts(glue("Current COP/USD: {format(round(current_rate), big.mark=',')}"))

# ── 3. Compute percentile ─────────────────────────────────────────────────────

pct_tbl  <- cop_historical_percentile(cop_series, lookback_years = LOOKBACK_YEARS)
pct_val  <- pct_tbl$percentile[pct_tbl$lookback_years == LOOKBACK_YEARS]
pct_label <- pct_tbl$label[pct_tbl$lookback_years == LOOKBACK_YEARS]

log_ts(glue("{LOOKBACK_YEARS}-year percentile: {pct_val}th — {pct_label}"))

# ── 4. Check threshold ────────────────────────────────────────────────────────

is_favorable <- pct_val >= THRESHOLD_PCT

if (!is_favorable) {
  log_ts(glue("Percentile {pct_val} < threshold {THRESHOLD_PCT}. No alert needed."))
  log_ts("=== Monitor complete. No alert sent. ===")
  quit(status = 0)
}

log_ts(glue("THRESHOLD CROSSED: {pct_val}th percentile >= {THRESHOLD_PCT}. Checking cooldown..."))

# ── 5. Cooldown check ─────────────────────────────────────────────────────────

dir.create("outputs", showWarnings = FALSE, recursive = TRUE)
last_alert_date <- NULL

if (file.exists(STATE_FILE)) {
  state <- readRDS(STATE_FILE)
  last_alert_date <- state$last_alert_date
  log_ts(glue("Last alert sent: {last_alert_date}"))
}

if (!is.null(last_alert_date) && (Sys.Date() - last_alert_date) < COOLDOWN_DAYS) {
  days_since <- as.integer(Sys.Date() - last_alert_date)
  log_ts(glue("Cooldown active: {days_since} days since last alert (minimum: {COOLDOWN_DAYS}). No alert sent."))
  log_ts("=== Monitor complete. Cooldown active. ===")
  quit(status = 0)
}

# ── 6. Fetch macro signals for email body ─────────────────────────────────────

log_ts("Fetching macro signals...")
macro <- tryCatch(cop_macro_signals(), error = function(e) NULL)

# Also get GARCH bands briefly (fast fit for 30-day horizon)
log_ts("Fitting GARCH(1,1) for alert context...")
garch_out <- tryCatch(
  cop_garch_bands(cop_series, horizon_days = 30, n_sim = 2000),
  error = function(e) NULL
)

# ── 7. Compose and send alert email ──────────────────────────────────────────

log_ts("Sending alert email...")

if (!requireNamespace("blastula", quietly = TRUE)) {
  log_ts("WARNING: blastula not installed. Cannot send email.")
  quit(status = 0)
}

from_addr <- Sys.getenv("GMAIL_PERSONAL_FROM", unset = "kwestrick@gmail.com")
if (nchar(Sys.getenv("GMAIL_PERSONAL_APP_PASSWORD")) == 0) {
  log_ts("WARNING: GMAIL_PERSONAL_APP_PASSWORD not set. Cannot send email.")
  quit(status = 0)
}

# Build macro signal rows for email table
macro_rows_html <- if (!is.null(macro)) {
  macro |>
    mutate(
      row_color   = dplyr::row_number() %% 2 == 0,
      bg_style    = ifelse(row_color, "background:#f8f9fa;", ""),
      signal_color = case_when(
        grepl("tailwind", signal_label) ~ "color:#28a745;",
        grepl("headwind", signal_label) ~ "color:#dc3545;",
        TRUE ~ "color:#6c757d;"
      )
    ) |>
    rowwise() |>
    mutate(html = glue(
      '<tr style="{bg_style}">',
      '<td style="padding:7px 12px;font-size:12px;color:#555;">{name}</td>',
      '<td style="padding:7px 12px;font-size:12px;text-align:right;">{round(current_value,1)}</td>',
      '<td style="padding:7px 12px;font-size:12px;text-align:right;">{sprintf("%+.2f", z_20d)}</td>',
      '<td style="padding:7px 12px;font-size:12px;{signal_color}">{signal_label}</td>',
      '</tr>'
    )) |>
    pull(html) |>
    paste(collapse = "\n")
} else {
  '<tr><td colspan="4" style="padding:8px;color:#aaa;font-size:12px;">Macro signals unavailable</td></tr>'
}

garch_band_line <- if (!is.null(garch_out)) {
  end_row <- garch_out$bands[nrow(garch_out$bands), ]
  glue("30-day uncertainty band (80%): {format(round(end_row$p10), big.mark=',')} – {format(round(end_row$p90), big.mark=',')} COP/USD")
} else {
  "GARCH bands unavailable"
}

# 1Y percentile for extra context
pct_1y <- cop_historical_percentile(cop_series, lookback_years = 1)$percentile

email_subject <- glue("[GIA ALERT] USD/COP Favorable Conversion Window — {format(Sys.Date(), '%b %d, %Y')}")

email_body <- glue('
<div style="font-family:Arial,sans-serif;max-width:560px;">

<div style="background:#1e3a5f;padding:16px 20px;border-radius:6px 6px 0 0;">
  <h2 style="color:#fff;margin:0;font-size:18px;">USD/COP Favorable Conversion Signal</h2>
  <p style="color:#90caf9;margin:4px 0 0;font-size:13px;">Global Investment Advisor — FX Monitor Alert</p>
</div>

<div style="background:#fff;padding:20px;border:1px solid #dee2e6;border-top:none;border-radius:0 0 6px 6px;">

  <p style="font-size:14px;color:#333;margin-top:0;">
    The COP/USD rate has moved into a <strong style="color:#28a745;">historically favorable</strong>
    range for converting USD to Colombian pesos.
  </p>

  <table style="width:100%;border-collapse:collapse;margin-bottom:16px;background:#f8fff8;border:1px solid #c3e6cb;border-radius:4px;">
    <tr>
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">Current COP/USD</td>
      <td style="padding:10px 16px;font-size:20px;font-weight:bold;color:#1e3a5f;">{format(round(current_rate), big.mark=",")} COP</td>
    </tr>
    <tr style="background:#e8f5e9;">
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">5-Year Percentile</td>
      <td style="padding:10px 16px;font-size:18px;font-weight:bold;color:#28a745;">{pct_val}th percentile</td>
    </tr>
    <tr>
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">1-Year Percentile</td>
      <td style="padding:10px 16px;font-size:14px;color:#333;">{pct_1y}th percentile</td>
    </tr>
    <tr style="background:#e8f5e9;">
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">Signal</td>
      <td style="padding:10px 16px;font-size:14px;font-weight:bold;color:#28a745;">Favorable for USD→COP conversion</td>
    </tr>
    <tr>
      <td style="padding:10px 16px;font-size:12px;color:#777;">{garch_band_line}</td>
      <td></td>
    </tr>
  </table>

  <h4 style="color:#1e3a5f;font-size:13px;margin-bottom:6px;text-transform:uppercase;letter-spacing:0.5px;">Macro Driver Context</h4>
  <table style="width:100%;border-collapse:collapse;font-family:Arial,sans-serif;margin-bottom:16px;">
    <thead>
      <tr style="background:#1e3a5f;color:#fff;font-size:11px;text-transform:uppercase;">
        <th style="padding:7px 12px;text-align:left;">Driver</th>
        <th style="padding:7px 12px;text-align:right;">Level</th>
        <th style="padding:7px 12px;text-align:right;">Z-Score (20d)</th>
        <th style="padding:7px 12px;text-align:left;">Signal</th>
      </tr>
    </thead>
    <tbody>
      {macro_rows_html}
    </tbody>
  </table>

  <div style="background:#fff8e1;border-left:4px solid #ffc107;padding:12px 16px;font-size:12px;color:#555;margin-bottom:16px;">
    <strong>What to consider:</strong><br>
    A rate at the {pct_val}th percentile means the peso is weaker than {pct_val}% of historical observations
    over the past {LOOKBACK_YEARS} years — more COP per dollar than usual. This may represent a favorable
    window to fund the COP spending reserve (BBVA/Bancolombia CDTs).<br><br>
    Suggested action: review COP reserve level vs. 18-month target (~$19,600). If below target,
    consider redirecting a portion of this month\'s $5,200 contribution to COP.
  </div>

  <p style="font-size:11px;color:#adb5bd;border-top:1px solid #dee2e6;padding-top:12px;margin-bottom:0;">
    This is automated research output, not personalized financial advice. Verify rates before executing
    any conversion. Consult a qualified advisor for currency decisions.<br>
    Alert threshold: {THRESHOLD_PCT}th percentile | Cooldown: {COOLDOWN_DAYS} days |
    Generated: {format(Sys.time(), "%Y-%m-%d %H:%M %Z")}
  </p>

</div>
</div>
')

tryCatch({
  email <- blastula::compose_email(body = blastula::html(email_body))
  blastula::smtp_send(
    email,
    to      = from_addr,
    from    = from_addr,
    subject = email_subject,
    credentials = blastula::creds_envvar(
      user        = from_addr,
      pass_envvar = "GMAIL_PERSONAL_APP_PASSWORD",
      host        = "smtp.gmail.com",
      port        = 465,
      use_ssl     = TRUE
    )
  )
  log_ts(glue("  ✓ Alert email sent to {from_addr}"))

  # Save state
  saveRDS(list(last_alert_date = Sys.Date(), last_pct = pct_val), STATE_FILE)
  log_ts("  ✓ State file updated.")

}, error = function(e) {
  log_ts(paste("  ✗ Email failed:", conditionMessage(e)))
})

log_ts("=== COP/USD FOREX Monitor Complete ===")
