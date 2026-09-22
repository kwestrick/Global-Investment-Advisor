# scripts/setup_email_credentials.R
# One-time setup for Gmail SMTP credentials used by the automated email alerts.
# Run this interactively in RStudio — do NOT run in crontab.
#
# Credentials are stored as an environment variable (GMAIL_APP_PASSWORD) in
# your .Renviron file rather than a separate credentials file.
#
# ── Prerequisites ──────────────────────────────────────────────────────────────
# Step 1. Enable 2-Step Verification on your Google account:
#         https://myaccount.google.com/security
#
# Step 2. Create a Gmail App Password (NOT your regular Gmail password):
#         https://myaccount.google.com/apppasswords
#         - Select app: "Mail"
#         - Select device: "Other" → name it "GIA Automation"
#         - Copy the 16-character password shown (no spaces)
#
# Step 3. Open your .Renviron file and add this line:
#         GMAIL_APP_PASSWORD=your16charpassword
#
#         You can open it with:
#           usethis::edit_r_environ()   # or just open the file directly in RStudio
#
# Step 4. Reload .Renviron (or restart R), then run this script to send a test email.
# ──────────────────────────────────────────────────────────────────────────────

if (!requireNamespace("blastula", quietly = TRUE)) {
  message("Installing blastula...")
  install.packages("blastula")
}

library(blastula)

# Verify the env var is set
app_pw <- Sys.getenv("GMAIL_APP_PASSWORD")
if (nchar(app_pw) == 0) {
  stop(
    "\nGMAIL_APP_PASSWORD is not set in your environment.\n",
    "Add the following line to your .Renviron file:\n\n",
    "  GMAIL_APP_PASSWORD=your16charpassword\n\n",
    "Then run: readRenviron('~/.Renviron')  and re-source this script."
  )
}

message("✓ GMAIL_APP_PASSWORD found (", nchar(app_pw), " characters). Sending test email...")

# Send a test email using creds_envvar — no file written outside the project
tryCatch({
  test_email <- compose_email(
    body = md("
## Global Investment Advisor — Email Test

This is a test email confirming that automated email notifications are configured correctly.

- **Weekly snapshot** emails arrive every **Monday at 7:00 AM**
- **Quarterly plan** emails arrive on **Jan 1, Apr 1, Jul 1, Oct 1 at 8:00 AM**

---
*Global Investment Advisor — automated research system*
    ")
  )

  smtp_send(
    test_email,
    to          = "kwestrick@gmail.com",
    from        = "kwestrick@gmail.com",
    subject     = "[GIA] Email notification test — setup successful",
    credentials = creds_envvar(
      user        = "kwestrick@gmail.com",
      pass_envvar = "GMAIL_APP_PASSWORD",
      host        = "smtp.gmail.com",
      port        = 465,
      use_ssl     = TRUE
    )
  )
  message("✓ Test email sent! Check kwestrick@gmail.com to confirm receipt.")
}, error = function(e) {
  message("✗ Test email failed: ", e$message)
  message("  Double-check your App Password — it should be 16 characters, no spaces.")
  message("  Also confirm 2-Step Verification is enabled on your Google account.")
})
