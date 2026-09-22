# scripts/setup_email_credentials.R
# One-time setup for Gmail SMTP credentials used by the automated email alerts.
# Run this interactively in RStudio — do NOT run in crontab.
#
# Prerequisites:
#   1. Enable 2-Step Verification on your Google account:
#      https://myaccount.google.com/security
#   2. Create a Gmail App Password (NOT your regular Gmail password):
#      https://myaccount.google.com/apppasswords
#      - Select app: "Mail"
#      - Select device: "Mac" (or "Other" → name it "GIA Automation")
#      - Copy the 16-character password shown
#   3. Run this script and enter that App Password when prompted.

if (!requireNamespace("blastula", quietly = TRUE)) {
  message("Installing blastula...")
  install.packages("blastula")
}

library(blastula)

message("
=== Global Investment Advisor — Email Credentials Setup ===

This will save an encrypted Gmail credential file to:
  ~/.blastula_gmail_creds

You will need a Gmail App Password (NOT your regular password).
If you haven't created one:
  1. Go to: https://myaccount.google.com/apppasswords
  2. Create an App Password for 'Mail' / 'Mac'
  3. Copy the 16-character code

Press Enter to continue and enter your App Password at the prompt.
")
readline("Press Enter to continue...")

# Store credentials — this will prompt for your App Password securely
create_smtp_creds_file(
  file          = file.path(Sys.getenv("HOME"), ".blastula_gmail_creds"),
  user          = "kwestrick@gmail.com",
  host          = "smtp.gmail.com",
  port          = 465,
  use_ssl       = TRUE,
  # provider    = "gmail"  # uncomment if using blastula >= 0.4.0 provider shortcut
)

message("
✓ Credentials saved to ~/.blastula_gmail_creds

Sending a test email to kwestrick@gmail.com to confirm setup...")

# Send a test email
tryCatch({
  test_email <- compose_email(
    body = md("
## Global Investment Advisor — Email Test

This is a test email confirming that automated email notifications are working correctly.

- **Weekly snapshot** emails will arrive every Monday at 7:00 AM
- **Quarterly plan** emails will arrive on Jan 1, Apr 1, Jul 1, Oct 1 at 8:00 AM

---
*Global Investment Advisor — automated research system*
    ")
  )
  smtp_send(
    test_email,
    to          = "kwestrick@gmail.com",
    from        = "kwestrick@gmail.com",
    subject     = "[GIA] Email notification test — setup successful",
    credentials = creds_file(file.path(Sys.getenv("HOME"), ".blastula_gmail_creds"))
  )
  message("✓ Test email sent! Check kwestrick@gmail.com to confirm receipt.")
}, error = function(e) {
  message("✗ Test email failed: ", e$message)
  message("  Verify your App Password is correct and that 2-Step Verification is enabled.")
  message("  Then re-run this script.")
})
