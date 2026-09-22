#!/usr/bin/env Rscript
# scripts/auto_weekly_snapshot.R
# Automated weekly financial snapshot refresh.
# Runs every Monday at 7:00 AM via crontab.
# Refreshes market data + indicators, re-renders index and snapshot pages,
# commits to git, and sends an email summary to kwestrick@gmail.com.

# ── 0. Environment Setup ───────────────────────────────────────────────────────
# Load .Renviron so API keys (FRED_API_KEY) and other vars are available
renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
if (file.exists(renviron_path)) readRenviron(renviron_path)

# Set working directory to project root (required for crontab execution)
proj_root <- "/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Investment-Advisor"
setwd(proj_root)

log_timestamp <- function(msg) {
  cat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S]"), msg, "\n")
}

log_timestamp("=== Weekly Snapshot Refresh Started ===")

# ── 1. Refresh Market Data ─────────────────────────────────────────────────────
log_timestamp("Step 1/4: Refreshing market data...")
tryCatch(
  source("scripts/01_collect_market_data.R"),
  error = function(e) log_timestamp(paste("WARNING: Market data refresh failed:", e$message))
)

# ── 2. Refresh Global Indicators ──────────────────────────────────────────────
log_timestamp("Step 2/4: Refreshing global indicators...")
tryCatch(
  source("scripts/05_collect_global_indicators.R"),
  error = function(e) log_timestamp(paste("WARNING: Indicators refresh failed:", e$message))
)

# ── 3. Re-render Snapshot Pages ───────────────────────────────────────────────
log_timestamp("Step 3/4: Rendering snapshot HTML pages...")
library(quarto)
render_ok <- TRUE

for (qmd in c("reports/index.qmd", "reports/snapshot.qmd")) {
  tryCatch({
    quarto_render(qmd, quiet = TRUE)
    log_timestamp(paste("  ✓ Rendered", qmd))
  }, error = function(e) {
    log_timestamp(paste("  ✗ Failed to render", qmd, ":", e$message))
    render_ok <<- FALSE
  })
}

# ── 4. Git Commit and Push ─────────────────────────────────────────────────────
log_timestamp("Step 4/4: Committing and pushing to git...")
today_str <- format(Sys.Date(), "%Y-%m-%d")
commit_msg <- paste0("Auto weekly snapshot refresh — ", today_str)

system(paste0('cd "', proj_root, '" && git add reports/index.html reports/snapshot.html reports/index_files/ outputs/ data/processed/ 2>/dev/null; git diff --cached --quiet || git commit -m "', commit_msg, '"'))
system(paste0('cd "', proj_root, '" && git push origin main 2>/dev/null'))
log_timestamp("  ✓ Git push complete")

# ── 5. Collect Key Metrics for Email ──────────────────────────────────────────
# Pull a few live numbers for the email body
metrics <- tryCatch({
  library(tidyverse)

  accounts <- read_csv("data/processed/2026-09-21_accounts_from_banktivity.csv",
                       show_col_types = FALSE)
  liquid <- accounts |> filter(grepl("liquid|check|saving|cash", tolower(category))) |>
    pull(balance) |> sum(na.rm = TRUE)

  signals_file <- "outputs/tables/2026-09-21_indicator_signal_dashboard.csv"
  if (file.exists(signals_file)) {
    signals <- read_csv(signals_file, show_col_types = FALSE)
    cop_signal <- signals |> filter(grepl("TES|Colombia", indicator)) |>
      pull(raw_value) |> head(1)
    cop_signal_str <- if (length(cop_signal) > 0) paste0(cop_signal[1]) else "N/A"
  } else {
    cop_signal_str <- "N/A"
  }

  fx_file <- list.files("data/processed", pattern = "fx_rates", full.names = TRUE) |>
    sort() |> tail(1)
  cop_rate_str <- "N/A"
  if (length(fx_file) > 0) {
    fx <- read_csv(fx_file[1], show_col_types = FALSE)
    cop_row <- fx |> filter(grepl("COP", toupper(ticker))) |> tail(1)
    if (nrow(cop_row) > 0) cop_rate_str <- format(round(cop_row$close[1]), big.mark = ",")
  }

  alloc_file <- "outputs/tables/2026-09-21_ranked_allocation_recommendation.csv"
  top_etf_str <- "N/A"
  if (file.exists(alloc_file)) {
    alloc <- read_csv(alloc_file, show_col_types = FALSE)
    top_row <- alloc |> arrange(desc(adjusted_score)) |> head(1)
    if (nrow(top_row) > 0) {
      top_etf_str <- paste0(top_row$symbol[1], " (", top_row$country_or_region[1],
                            ") — score ", round(top_row$adjusted_score[1], 2))
    }
  }

  list(
    liquid          = scales::dollar(liquid, accuracy = 1),
    top_etf         = top_etf_str,
    cop_rate        = cop_rate_str,
    cop_real_yield  = cop_signal_str,
    render_status   = if (render_ok) "✓ All pages rendered successfully" else "⚠ One or more pages failed to render — check logs"
  )
}, error = function(e) {
  list(liquid = "N/A", top_etf = "N/A", cop_rate = "N/A",
       cop_real_yield = "N/A", render_status = "⚠ Metrics unavailable")
})

# ── 6. Send Email ──────────────────────────────────────────────────────────────
log_timestamp("Sending email notification...")

send_snapshot_email <- function(metrics, render_ok) {
  if (!requireNamespace("blastula", quietly = TRUE)) {
    log_timestamp("WARNING: blastula package not installed — skipping email. Run: install.packages('blastula')")
    return(invisible(NULL))
  }
  if (nchar(Sys.getenv("GMAIL_APP_PASSWORD")) == 0) {
    log_timestamp("WARNING: GMAIL_APP_PASSWORD not set in .Renviron — skipping email. Run: source('scripts/setup_email_credentials.R')")
    return(invisible(NULL))
  }

  subject <- paste0(
    if (render_ok) "[GIA] Weekly Snapshot Updated — " else "[GIA] Weekly Snapshot (render errors) — ",
    format(Sys.Date(), "%b %d, %Y")
  )

  body_html <- glue::glue('
<h2 style="font-family:Arial,sans-serif;color:#1e3a5f;">Global Investment Advisor</h2>
<h3 style="font-family:Arial,sans-serif;color:#555;">Weekly Snapshot Refresh — {format(Sys.Date(), "%B %d, %Y")}</h3>

<table style="font-family:Arial,sans-serif;border-collapse:collapse;width:100%;max-width:500px;">
  <tr style="background:#f8f9fa;">
    <td style="padding:8px 12px;font-weight:bold;color:#6c757d;font-size:11px;text-transform:uppercase;">Liquid Reserve</td>
    <td style="padding:8px 12px;font-size:16px;font-weight:bold;color:#1e3a5f;">{metrics$liquid}</td>
  </tr>
  <tr>
    <td style="padding:8px 12px;font-weight:bold;color:#6c757d;font-size:11px;text-transform:uppercase;">Top ETF (Conviction)</td>
    <td style="padding:8px 12px;font-size:13px;color:#333;">{metrics$top_etf}</td>
  </tr>
  <tr style="background:#f8f9fa;">
    <td style="padding:8px 12px;font-weight:bold;color:#6c757d;font-size:11px;text-transform:uppercase;">COP / USD Rate</td>
    <td style="padding:8px 12px;font-size:14px;color:#333;">{metrics$cop_rate}</td>
  </tr>
  <tr>
    <td style="padding:8px 12px;font-weight:bold;color:#6c757d;font-size:11px;text-transform:uppercase;">Colombia TES Signal</td>
    <td style="padding:8px 12px;font-size:13px;color:#333;">{metrics$cop_real_yield}</td>
  </tr>
  <tr style="background:#f8f9fa;">
    <td style="padding:8px 12px;font-weight:bold;color:#6c757d;font-size:11px;text-transform:uppercase;">Render Status</td>
    <td style="padding:8px 12px;font-size:13px;color:#333;">{metrics$render_status}</td>
  </tr>
</table>

<p style="font-family:Arial,sans-serif;font-size:12px;color:#adb5bd;margin-top:20px;">
Open <code>reports/index.html</code> in your browser to view the full dashboard.<br>
Log file: <code>{proj_root}/logs/weekly_snapshot.log</code>
</p>
<p style="font-family:Arial,sans-serif;font-size:11px;color:#dee2e6;">
This is automated research output, not personalized financial advice.
</p>
  ')

  tryCatch({
    email <- blastula::compose_email(body = blastula::html(body_html))
    blastula::smtp_send(
      email,
      to      = "kwestrick@gmail.com",
      from    = "kwestrick@gmail.com",
      subject = subject,
      credentials = blastula::creds_envvar(
        user        = "kwestrick@gmail.com",
        pass_envvar = "GMAIL_APP_PASSWORD",
        host        = "smtp.gmail.com",
        port        = 465,
        use_ssl     = TRUE
      )
    )
    log_timestamp("  ✓ Email sent to kwestrick@gmail.com")
  }, error = function(e) {
    log_timestamp(paste("  ✗ Email failed:", e$message))
  })
}

send_snapshot_email(metrics, render_ok)
log_timestamp("=== Weekly Snapshot Refresh Complete ===\n")
