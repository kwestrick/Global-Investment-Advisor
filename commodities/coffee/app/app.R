# ============================================================
# app.R — entry point. Run with: shiny::runApp("app")
# ============================================================

source("global.R")
source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)
