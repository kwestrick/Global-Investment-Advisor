#!/usr/bin/env Rscript
# scripts/12_fx_monitor_alert.R
# USD/COP FOREX threshold monitor — two independent alert channels.
#
# ALERT 1 — Yield-Play Favorable:
#   Fires when COP/USD is at or above the 80th percentile of 5-year history.
#   High percentile = peso historically very weak = favorable for large USD→COP
#   deployments (TES bonds, large CDT purchases).
#
# ALERT 2 — COP Reserve Funding Window:
#   Fires when COP/USD is at or above the 35th percentile of 5-year history.
#   This is the lower bar set for cost-effective reserve funding. At the 35th
#   percentile (~3,917 COP/USD as of Sep 2026), the same 62.6M COP reserve
#   costs ~$15,977 vs. ~$19,602 at today's rate — a savings of ~$3,625 (18.5%).
#   Pre-conditions (not enforced here — must be verified manually):
#     1. Tax gate: CPA sign-off on §988, FBAR, and Colombian withholding rate.
#        See: reports/cpa_colombia_tax_checklist.md
#     2. Rate gate: this alert fires automatically when the rate is met.
#
# Usage (interactive):
#   source("scripts/12_fx_monitor_alert.R")
#
# Suggested crontab (daily at 8:30 AM):
#   30 8 * * * /usr/local/bin/Rscript /path/to/scripts/12_fx_monitor_alert.R >> logs/fx_monitor.log 2>&1
#
# Environment variables required (in ~/.Renviron):
#   GMAIL_PERSONAL_APP_PASSWORD — Gmail app password for blastula
#   GMAIL_PERSONAL_FROM        — Sender/recipient address
#
# State file: outputs/fx_monitor_state.rds
#   Tracks last alert date for each channel independently.
#   Backward-compatible: old files used last_alert_date (treated as yield alert).

# ── 0. Configuration ─────────────────────────────────────────────────────────

# Yield-play alert — peso historically very weak; favorable for large deployments
YIELD_THRESHOLD_PCT  <- 80   # percentile trigger (5-year lookback)
YIELD_COOLDOWN_DAYS  <- 14   # minimum days between yield-play emails

# COP reserve alert — peso has weakened enough to fund reserve at a better rate
RESERVE_TRIGGER_PCT   <- 35  # percentile trigger (~3,917 COP/USD as of Sep 2026)
RESERVE_COOLDOWN_DAYS <- 30  # minimum days between reserve emails (less urgent)

# Shared
LOOKBACK_YEARS <- 5
STATE_FILE     <- "outputs/fx_monitor_state.rds"
LOG_PREFIX     <- "[FX Monitor]"

# COP reserve sizing (base scenario, 18-month reserve)
COP_RESERVE_TARGET <- 62.6e6  # COP — 62.6 million pesos

# ── 1. Environment setup ─────────────────────────────────────────────────────

renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
if (file.exists(renviron_path)) readRenviron(renviron_path)

proj_root <- "/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Investment-Advisor"
setwd(proj_root)

log_ts <- function(msg) cat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S]"), LOG_PREFIX, msg, "\n")

# null-coalescing operator (base R)
`%||%` <- function(a, b) if (!is.null(a)) a else b

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

cop_series   <- prepare_cop_series(raw_fx)
current_rate <- dplyr::last(cop_series$cop_per_usd)
log_ts(glue("Current COP/USD: {format(round(current_rate), big.mark=',')}"))

# ── 3. Compute percentile and dynamic threshold rates ─────────────────────────

pct_tbl   <- cop_historical_percentile(cop_series, lookback_years = LOOKBACK_YEARS)
pct_val   <- pct_tbl$percentile[pct_tbl$lookback_years == LOOKBACK_YEARS]
pct_label <- pct_tbl$label[pct_tbl$lookback_years == LOOKBACK_YEARS]

lookback_series      <- cop_series |> filter(date >= Sys.Date() - LOOKBACK_YEARS * 365)
reserve_trigger_rate <- quantile(lookback_series$cop_per_usd, RESERVE_TRIGGER_PCT / 100, na.rm = TRUE)
yield_trigger_rate   <- quantile(lookback_series$cop_per_usd, YIELD_THRESHOLD_PCT  / 100, na.rm = TRUE)

log_ts(glue("{LOOKBACK_YEARS}-year percentile: {pct_val}th — {pct_label}"))
log_ts(glue("Reserve trigger ({RESERVE_TRIGGER_PCT}th pct): {format(round(reserve_trigger_rate), big.mark=',')} COP/USD"))
log_ts(glue("Yield trigger   ({YIELD_THRESHOLD_PCT}th pct): {format(round(yield_trigger_rate),   big.mark=',')} COP/USD"))

# ── 4. Determine which alerts are triggered ───────────────────────────────────

is_yield_triggered   <- pct_val >= YIELD_THRESHOLD_PCT
is_reserve_triggered <- pct_val >= RESERVE_TRIGGER_PCT

log_ts(glue("Yield-play alert triggered:  {is_yield_triggered}"))
log_ts(glue("Reserve alert triggered:     {is_reserve_triggered}"))

if (!is_yield_triggered && !is_reserve_triggered) {
  log_ts("Neither threshold reached. No action needed.")
  log_ts("=== Monitor complete. No alerts sent. ===")
  quit(status = 0)
}

# ── 5. Load state file and apply cooldowns ────────────────────────────────────

dir.create("outputs", showWarnings = FALSE, recursive = TRUE)

last_yield_alert_date   <- NULL
last_reserve_alert_date <- NULL

if (file.exists(STATE_FILE)) {
  state <- readRDS(STATE_FILE)
  # Backward-compatible: old state files used last_alert_date (yield only)
  last_yield_alert_date   <- state$last_yield_alert_date   %||% state$last_alert_date
  last_reserve_alert_date <- state$last_reserve_alert_date
  log_ts(glue("Last yield-play alert:  {last_yield_alert_date   %||% 'never'}"))
  log_ts(glue("Last reserve alert:     {last_reserve_alert_date %||% 'never'}"))
}

yield_cooldown_active <- !is.null(last_yield_alert_date) &&
  as.integer(Sys.Date() - last_yield_alert_date) < YIELD_COOLDOWN_DAYS

reserve_cooldown_active <- !is.null(last_reserve_alert_date) &&
  as.integer(Sys.Date() - last_reserve_alert_date) < RESERVE_COOLDOWN_DAYS

if (yield_cooldown_active) {
  days_since <- as.integer(Sys.Date() - last_yield_alert_date)
  log_ts(glue("Yield-play cooldown active: {days_since}/{YIELD_COOLDOWN_DAYS} days. Skipping."))
}
if (reserve_cooldown_active) {
  days_since <- as.integer(Sys.Date() - last_reserve_alert_date)
  log_ts(glue("Reserve cooldown active: {days_since}/{RESERVE_COOLDOWN_DAYS} days. Skipping."))
}

send_yield_alert   <- is_yield_triggered   && !yield_cooldown_active
send_reserve_alert <- is_reserve_triggered && !reserve_cooldown_active

if (!send_yield_alert && !send_reserve_alert) {
  log_ts("All triggered alerts are in cooldown. No emails sent.")
  log_ts("=== Monitor complete. Cooldown active. ===")
  quit(status = 0)
}

# ── 6. Shared email infrastructure ───────────────────────────────────────────

if (!requireNamespace("blastula", quietly = TRUE)) {
  log_ts("WARNING: blastula not installed. Cannot send email.")
  quit(status = 0)
}

from_addr <- Sys.getenv("GMAIL_PERSONAL_FROM", unset = "kwestrick@gmail.com")
if (nchar(Sys.getenv("GMAIL_PERSONAL_APP_PASSWORD")) == 0) {
  log_ts("WARNING: GMAIL_PERSONAL_APP_PASSWORD not set. Cannot send email.")
  quit(status = 0)
}

smtp_creds <- blastula::creds_envvar(
  user        = from_addr,
  pass_envvar = "GMAIL_PERSONAL_APP_PASSWORD",
  host        = "smtp.gmail.com",
  port        = 465,
  use_ssl     = TRUE
)

log_ts("Fetching macro signals...")
macro <- tryCatch(cop_macro_signals(), error = function(e) NULL)

log_ts("Fitting GARCH(1,1) for alert context...")
garch_out <- tryCatch(
  cop_garch_bands(cop_series, horizon_days = 30, n_sim = 2000),
  error = function(e) NULL
)

pct_1y <- cop_historical_percentile(cop_series, lookback_years = 1)$percentile

macro_rows_html <- if (!is.null(macro)) {
  macro |>
    mutate(
      row_color    = dplyr::row_number() %% 2 == 0,
      bg_style     = ifelse(row_color, "background:#f8f9fa;", ""),
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
  glue("30-day uncertainty band (80%): {format(round(end_row$p10), big.mark=',')} \u2013 {format(round(end_row$p90), big.mark=',')} COP/USD")
} else {
  "GARCH bands unavailable"
}

# ── 7. Yield-play alert ───────────────────────────────────────────────────────

if (send_yield_alert) {
  log_ts("Composing yield-play alert email...")

  email_subject <- glue(
    "[GIA ALERT] USD/COP Favorable Conversion Window \u2014 {format(Sys.Date(), '%b %d, %Y')}"
  )

  email_body <- glue('
<div style="font-family:Arial,sans-serif;max-width:560px;">

<div style="background:#1e3a5f;padding:16px 20px;border-radius:6px 6px 0 0;">
  <h2 style="color:#fff;margin:0;font-size:18px;">USD/COP Favorable Conversion Signal</h2>
  <p style="color:#90caf9;margin:4px 0 0;font-size:13px;">Global Investment Advisor \u2014 FX Monitor (Yield-Play Alert)</p>
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
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">Yield trigger rate</td>
      <td style="padding:10px 16px;font-size:14px;color:#333;">{format(round(yield_trigger_rate), big.mark=",")} COP/USD ({YIELD_THRESHOLD_PCT}th pct)</td>
    </tr>
    <tr>
      <td colspan="2" style="padding:10px 16px;font-size:12px;color:#777;">{garch_band_line}</td>
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
    <tbody>{macro_rows_html}</tbody>
  </table>

  <div style="background:#fff8e1;border-left:4px solid #ffc107;padding:12px 16px;font-size:12px;color:#555;margin-bottom:16px;">
    <strong>What to consider:</strong><br>
    The peso is weaker than {pct_val}% of all observations over the past {LOOKBACK_YEARS} years \u2014
    more COP per dollar than usual. This is a yield-play signal: review whether any planned large
    USD\u2192COP deployment (TES bonds, large CDT purchases) benefits from executing at this rate.
    <br><br>
    <strong>Note:</strong> This is a separate signal from the COP reserve funding alert.
    The reserve is funded by a one-time lump-sum wire (not from the $5,200/month USD portfolio budget)
    and has its own lower rate trigger ({RESERVE_TRIGGER_PCT}th percentile \u2248 {format(round(reserve_trigger_rate), big.mark=",")} COP/USD).
  </div>

  <p style="font-size:11px;color:#adb5bd;border-top:1px solid #dee2e6;padding-top:12px;margin-bottom:0;">
    Automated research output \u2014 not personalized financial advice. Verify rates before executing
    any conversion. Consult a qualified advisor for currency decisions.<br>
    Alert: Yield-play ({YIELD_THRESHOLD_PCT}th pct) | Cooldown: {YIELD_COOLDOWN_DAYS} days |
    Generated: {format(Sys.time(), "%Y-%m-%d %H:%M %Z")}
  </p>

</div></div>
')

  tryCatch({
    email <- blastula::compose_email(body = blastula::html(email_body))
    blastula::smtp_send(email, to = from_addr, from = from_addr,
                        subject = email_subject, credentials = smtp_creds)
    log_ts(glue("  \u2713 Yield-play alert sent to {from_addr}"))
    last_yield_alert_date <- Sys.Date()
  }, error = function(e) {
    log_ts(paste("  \u2717 Yield-play email failed:", conditionMessage(e)))
  })
}

# ── 8. COP reserve funding alert ──────────────────────────────────────────────

if (send_reserve_alert) {
  log_ts("Composing COP reserve funding alert email...")

  usd_at_today    <- round(COP_RESERVE_TARGET / current_rate, 0)
  # Savings vs. Sep 2026 baseline (2.6th pct, historically strong peso)
  usd_baseline    <- round(COP_RESERVE_TARGET / 3193, 0)
  usd_saved       <- usd_baseline - usd_at_today       # positive: paying less than baseline
  pct_saved       <- round(usd_saved / usd_baseline * 100, 1)
  per_inst_usd   <- round(COP_RESERVE_TARGET / 2 / current_rate, 0)
  per_inst_cop_m <- round(COP_RESERVE_TARGET / 2 / 1e6, 1)

  email_subject_r <- glue(
    "[GIA] COP Reserve Funding Window \u2014 {format(Sys.Date(), '%b %d, %Y')}"
  )

  email_body_r <- glue('
<div style="font-family:Arial,sans-serif;max-width:560px;">

<div style="background:#92400e;padding:16px 20px;border-radius:6px 6px 0 0;">
  <h2 style="color:#fff;margin:0;font-size:18px;">COP Reserve Funding Window Open</h2>
  <p style="color:#fde68a;margin:4px 0 0;font-size:13px;">Global Investment Advisor \u2014 COP Reserve Alert</p>
</div>

<div style="background:#fff;padding:20px;border:1px solid #dee2e6;border-top:none;border-radius:0 0 6px 6px;">

  <p style="font-size:14px;color:#333;margin-top:0;">
    The COP/USD rate has reached the <strong>{RESERVE_TRIGGER_PCT}th percentile</strong> of its
    5-year history \u2014 the threshold set for cost-effective reserve funding. Funding the 62.6M COP
    reserve now costs <strong>${format(usd_at_today, big.mark=",")}</strong> \u2014
    <strong>${format(usd_saved, big.mark=",")} ({pct_saved}%) less</strong> than the Sep 2026 baseline
    of ${format(usd_baseline, big.mark=",")} (when the peso was near its strongest, 2.6th percentile).
  </p>

  <table style="width:100%;border-collapse:collapse;margin-bottom:16px;background:#fffbeb;border:1px solid #fcd34d;border-radius:4px;">
    <tr>
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">Current COP/USD</td>
      <td style="padding:10px 16px;font-size:20px;font-weight:bold;color:#92400e;">{format(round(current_rate), big.mark=",")} COP</td>
    </tr>
    <tr style="background:#fef3c7;">
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">5-Year Percentile</td>
      <td style="padding:10px 16px;font-size:18px;font-weight:bold;color:#92400e;">{pct_val}th percentile</td>
    </tr>
    <tr>
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">Reserve trigger ({RESERVE_TRIGGER_PCT}th pct)</td>
      <td style="padding:10px 16px;font-size:14px;color:#333;">{format(round(reserve_trigger_rate), big.mark=",")} COP/USD</td>
    </tr>
    <tr style="background:#fef3c7;">
      <td style="padding:10px 16px;font-size:13px;color:#555;font-weight:bold;">62.6M COP \u2014 USD cost today</td>
      <td style="padding:10px 16px;font-size:16px;font-weight:bold;color:#92400e;">${format(usd_at_today, big.mark=",")}</td>
    </tr>
    <tr>
      <td colspan="2" style="padding:10px 16px;font-size:12px;color:#777;">{garch_band_line}</td>
    </tr>
  </table>

  <h4 style="color:#92400e;font-size:13px;margin-bottom:8px;text-transform:uppercase;letter-spacing:0.5px;">
    Pre-Transfer Checklist
  </h4>
  <div style="background:#f8f9fa;border:1px solid #dee2e6;border-radius:4px;padding:14px 16px;font-size:13px;color:#333;margin-bottom:16px;line-height:2.0;">
    Before wiring \u2014 both gates must be cleared:<br>
    &#9744;&nbsp; <strong>Tax gate:</strong> Written CPA sign-off on \u00a7988, FBAR filing status,
    and Colombian withholding rate for your residency status.<br>
    &nbsp;&nbsp;&nbsp;&nbsp;\u2192 See <em>reports/cpa_colombia_tax_checklist.md</em><br>
    &#9744;&nbsp; <strong>FBAR check:</strong> Existing Colombian accounts (~30M COP \u2248 $9,375) may
    already be near the $10,000 aggregate threshold. Confirm prior-year filing status before adding funds.<br><br>
    Wire structure (split across 2 institutions to stay under Fog\u00e1f\u00edn 50M COP cap):<br>
    &nbsp;&nbsp;\u2022 Wire 1 \u2192 BBVA Colombia: ~{per_inst_cop_m}M COP (~${format(per_inst_usd, big.mark=",")} USD via Wise)<br>
    &nbsp;&nbsp;\u2022 Wire 2 \u2192 Bancolombia: &nbsp;~{per_inst_cop_m}M COP (~${format(per_inst_usd, big.mark=",")} USD via Wise)<br>
    &nbsp;&nbsp;\u2022 Use <strong>Wise</strong> (not bank wire) to avoid 1\u20132% FX spread<br>
    &nbsp;&nbsp;\u2022 Convert both wires on the same day to lock a consistent rate<br>
    &nbsp;&nbsp;\u2022 After funds clear, purchase 360-day CDTs in each bank\u2019s app
  </div>

  <div style="background:#fef2f2;border-left:4px solid #dc2626;padding:12px 16px;font-size:12px;color:#555;margin-bottom:16px;">
    <strong>Do not wire until the tax gate is cleared.</strong> Adding funds above the $10,000
    aggregate FBAR threshold without a filed FinCEN 114 creates a compliance risk that is
    independent of the exchange rate. The rate trigger is necessary but not sufficient.
  </div>

  <p style="font-size:11px;color:#adb5bd;border-top:1px solid #dee2e6;padding-top:12px;margin-bottom:0;">
    Automated research output \u2014 not personalized financial advice. Consult a qualified CPA
    with U.S.\u2013Colombia cross-border experience before executing any transfer.<br>
    Alert: COP Reserve ({RESERVE_TRIGGER_PCT}th pct) | Cooldown: {RESERVE_COOLDOWN_DAYS} days |
    Generated: {format(Sys.time(), "%Y-%m-%d %H:%M %Z")}
  </p>

</div></div>
')

  tryCatch({
    email_r <- blastula::compose_email(body = blastula::html(email_body_r))
    blastula::smtp_send(email_r, to = from_addr, from = from_addr,
                        subject = email_subject_r, credentials = smtp_creds)
    log_ts(glue("  \u2713 Reserve alert sent to {from_addr}"))
    last_reserve_alert_date <- Sys.Date()
  }, error = function(e) {
    log_ts(paste("  \u2717 Reserve email failed:", conditionMessage(e)))
  })
}

# ── 9. Save updated state ─────────────────────────────────────────────────────

saveRDS(
  list(
    last_yield_alert_date   = last_yield_alert_date,
    last_reserve_alert_date = last_reserve_alert_date,
    last_pct                = pct_val,
    last_run                = Sys.time()
  ),
  STATE_FILE
)
log_ts("  \u2713 State file updated.")
log_ts("=== COP/USD FOREX Monitor Complete ===")
