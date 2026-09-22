#!/usr/bin/env Rscript
# scripts/auto_quarterly_plan.R
# Automated quarterly investment plan refresh.
# Runs on the 1st of January, April, July, and October at 8:00 AM via crontab.
# Refreshes all market data, screening scores, and indicators; re-renders all
# four HTML report pages; commits to git; and sends an email summary.

# ── 0. Environment Setup ───────────────────────────────────────────────────────
renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
if (file.exists(renviron_path)) readRenviron(renviron_path)

proj_root <- "/Users/kwestrick/Library/CloudStorage/Dropbox/MyBusiness/Development/RCode/Global-Investment-Advisor"
setwd(proj_root)

log_timestamp <- function(msg) {
  cat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S]"), msg, "\n")
}

quarter_label <- function(d = Sys.Date()) {
  paste0("Q", ceiling(as.integer(format(d, "%m")) / 3), " ", format(d, "%Y"))
}

log_timestamp(paste("=== Quarterly Investment Plan Refresh Started —", quarter_label(), "==="))

# ── 1. Refresh Market Data ─────────────────────────────────────────────────────
log_timestamp("Step 1/5: Refreshing ETF price data (48 tickers)...")
tryCatch(
  source("scripts/01_collect_market_data.R"),
  error = function(e) log_timestamp(paste("WARNING: Market data refresh failed:", e$message))
)

# ── 2. Regenerate Global Conviction Scores ────────────────────────────────────
log_timestamp("Step 2/5: Regenerating global conviction scores...")
tryCatch(
  source("scripts/02_screen_global_assets.R"),
  error = function(e) log_timestamp(paste("WARNING: Screening failed:", e$message))
)

# ── 3. Refresh Global Indicators ──────────────────────────────────────────────
log_timestamp("Step 3/5: Refreshing global indicators (FRED, WDI, FX)...")
tryCatch(
  source("scripts/05_collect_global_indicators.R"),
  error = function(e) log_timestamp(paste("WARNING: Indicators refresh failed:", e$message))
)

# ── 4. Run Indicator-Driven Portfolio Ranking ─────────────────────────────────
log_timestamp("Step 4/5: Running indicator-driven portfolio ranking...")
tryCatch(
  source("scripts/09_indicator_driven_portfolio_ranking.R"),
  error = function(e) log_timestamp(paste("WARNING: Portfolio ranking failed:", e$message))
)

# ── 5. Re-render All HTML Pages ───────────────────────────────────────────────
log_timestamp("Step 5/5: Rendering all HTML report pages...")
library(quarto)
render_results <- list()

for (qmd in c("reports/index.qmd", "reports/snapshot.qmd",
              "reports/investment_plan.qmd", "reports/monthly_allocation_brief.qmd")) {
  result <- tryCatch({
    quarto_render(qmd, quiet = TRUE)
    log_timestamp(paste("  ✓ Rendered", qmd))
    list(file = qmd, ok = TRUE)
  }, error = function(e) {
    log_timestamp(paste("  ✗ Failed:", qmd, "—", e$message))
    list(file = qmd, ok = FALSE, msg = e$message)
  })
  render_results[[qmd]] <- result
}

render_ok <- all(sapply(render_results, `[[`, "ok"))

# ── 6. Git Commit and Push ─────────────────────────────────────────────────────
log_timestamp("Committing and pushing to git...")
today_str  <- format(Sys.Date(), "%Y-%m-%d")
commit_msg <- paste0("Auto quarterly plan refresh — ", quarter_label(), " (", today_str, ")")

system(paste0('cd "', proj_root, '" && git add reports/*.html reports/index_files/ reports/investment_plan_files/ reports/monthly_allocation_brief_files/ outputs/ data/processed/ 2>/dev/null; git diff --cached --quiet || git commit -m "', commit_msg, '"'))
system(paste0('cd "', proj_root, '" && git push origin main 2>/dev/null'))
log_timestamp("  ✓ Git push complete")

# ── 7. Collect Key Metrics for Email ──────────────────────────────────────────
metrics <- tryCatch({
  library(tidyverse)

  alloc_file <- "outputs/tables/2026-09-21_ranked_allocation_recommendation.csv"
  top_etfs_str <- "N/A"
  monthly_alloc_str <- "N/A"

  if (file.exists(alloc_file)) {
    alloc <- read_csv(alloc_file, show_col_types = FALSE)
    top3 <- alloc |> arrange(desc(adjusted_score)) |> head(3)
    top_etfs_str <- paste(
      sprintf("%s (%s) %.2f", top3$symbol, top3$country_or_region, top3$adjusted_score),
      collapse = "<br>"
    )
    # Total monthly allocation (non-COP)
    if ("monthly_usd" %in% names(alloc)) {
      monthly_alloc_str <- scales::dollar(sum(alloc$monthly_usd, na.rm = TRUE), accuracy = 1)
    }
  }

  cop_file <- "outputs/tables/2026-09-21_cop_vehicle_ranking.csv"
  cop_top_str <- "N/A"
  if (file.exists(cop_file)) {
    cop <- read_csv(cop_file, show_col_types = FALSE)
    top_cop <- cop |> arrange(desc(cop_score)) |> head(1)
    if (nrow(top_cop) > 0) {
      cop_top_str <- paste0(
        top_cop$vehicle_name[1], " — ", top_cop$nominal_yield_pct[1], "% nominal"
      )
    }
  }

  fx_file <- list.files("data/processed", pattern = "fx_rates", full.names = TRUE) |>
    sort() |> tail(1)
  cop_rate_str <- "N/A"
  if (length(fx_file) > 0) {
    fx <- read_csv(fx_file[1], show_col_types = FALSE)
    cop_row <- fx |> filter(grepl("COP", toupper(ticker))) |> tail(1)
    if (nrow(cop_row) > 0) cop_rate_str <- format(round(cop_row$close[1]), big.mark = ",")
  }

  failed_renders <- render_results[!sapply(render_results, `[[`, "ok")]
  render_note <- if (render_ok) {
    "✓ All 4 pages rendered successfully"
  } else {
    paste0("⚠ ", length(failed_renders), " page(s) failed — check logs")
  }

  manual_checklist <- paste0(
    "1. Export Banktivity accounts as QIF → run scripts/04_quarterly_wealth_dashboard.R<br>",
    "2. Run scripts/06_colombia_economic_snapshot.R — verify COP/USD<br>",
    "3. Run scripts/07_evaluate_colombia_investments.R — check CDT rates<br>",
    "4. Run scripts/08_quarterly_dual_currency_review.R — update COP home value<br>",
    "5. Review outputs/tables/ for changes in top ETFs or COP vehicle rankings<br>",
    "6. Commit any manual updates to git"
  )

  list(
    top_etfs        = top_etfs_str,
    cop_top         = cop_top_str,
    cop_rate        = cop_rate_str,
    monthly_alloc   = monthly_alloc_str,
    render_note     = render_note,
    manual_checklist = manual_checklist
  )
}, error = function(e) {
  list(top_etfs = "N/A", cop_top = "N/A", cop_rate = "N/A",
       monthly_alloc = "N/A", render_note = "⚠ Metrics unavailable",
       manual_checklist = "Check logs for details.")
})

# ── 8. Send Email ──────────────────────────────────────────────────────────────
log_timestamp("Sending email notification...")

send_quarterly_email <- function(metrics, render_ok, ql = quarter_label()) {
  if (!requireNamespace("blastula", quietly = TRUE)) {
    log_timestamp("WARNING: blastula package not installed — skipping email. Run: install.packages('blastula')")
    return(invisible(NULL))
  }
  if (nchar(Sys.getenv("GMAIL_APP_PASSWORD")) == 0) {
    log_timestamp("WARNING: GMAIL_APP_PASSWORD not set in .Renviron — skipping email. Run: source('scripts/setup_email_credentials.R')")
    return(invisible(NULL))
  }

  subject <- paste0(
    if (render_ok) "[GIA] Quarterly Investment Plan Refreshed — " else "[GIA] Quarterly Plan (errors) — ",
    ql, " | ", format(Sys.Date(), "%b %d, %Y")
  )

  body_html <- glue::glue('
<h2 style="font-family:Arial,sans-serif;color:#1e3a5f;">Global Investment Advisor</h2>
<h3 style="font-family:Arial,sans-serif;color:#555;">Quarterly Investment Plan Refresh — {ql}</h3>

<h4 style="font-family:Arial,sans-serif;color:#1e3a5f;margin-top:20px;">Top Global ETFs (Conviction)</h4>
<p style="font-family:Arial,sans-serif;font-size:14px;color:#333;line-height:1.8;">{metrics$top_etfs}</p>

<h4 style="font-family:Arial,sans-serif;color:#1e3a5f;">COP Vehicles</h4>
<table style="font-family:Arial,sans-serif;border-collapse:collapse;width:100%;max-width:500px;">
  <tr style="background:#f8f9fa;">
    <td style="padding:8px 12px;font-weight:bold;color:#6c757d;font-size:11px;text-transform:uppercase;">Top COP Vehicle</td>
    <td style="padding:8px 12px;font-size:13px;color:#333;">{metrics$cop_top}</td>
  </tr>
  <tr>
    <td style="padding:8px 12px;font-weight:bold;color:#6c757d;font-size:11px;text-transform:uppercase;">COP / USD Rate</td>
    <td style="padding:8px 12px;font-size:14px;color:#333;">{metrics$cop_rate}</td>
  </tr>
  <tr style="background:#f8f9fa;">
    <td style="padding:8px 12px;font-weight:bold;color:#6c757d;font-size:11px;text-transform:uppercase;">Render Status</td>
    <td style="padding:8px 12px;font-size:13px;color:#333;">{metrics$render_note}</td>
  </tr>
</table>

<h4 style="font-family:Arial,sans-serif;color:#1e3a5f;margin-top:20px;">Manual Steps Required</h4>
<p style="font-family:Arial,sans-serif;font-size:13px;color:#333;line-height:1.8;">{metrics$manual_checklist}</p>

<p style="font-family:Arial,sans-serif;font-size:12px;color:#adb5bd;margin-top:20px;">
Open <code>reports/investment_plan.html</code> to review the full updated plan.<br>
Log file: <code>{proj_root}/logs/quarterly_plan.log</code>
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

send_quarterly_email(metrics, render_ok)
log_timestamp(paste("=== Quarterly Investment Plan Refresh Complete —", quarter_label(), "===\n"))
