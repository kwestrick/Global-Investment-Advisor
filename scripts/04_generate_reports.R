# 04_generate_reports.R
# Render Quarto reports and memos

source("R/00_setup.R")
load_required_packages()
create_project_dirs()

render_investment_memo <- function(input = "notebooks/investment_memo_template.qmd",
                                   output_dir = "reports/investment_memos") {
  quarto::quarto_render(
    input = input,
    output_dir = output_dir
  )
}

# Run manually when ready:
# render_investment_memo()

message("Report rendering helpers loaded.")
