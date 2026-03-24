library(shiny)
library(bslib)

# Custom theme
custom_theme <- bs_theme(
  version = 5,
  bg = "white",
  fg = "black",
  primary = "#0072B2",
  secondary = "#D55E00"
)

ui <- page_navbar(
  title = tags$span(style = "color: white; background-color: #0072B2; padding: 10px 20px; border-radius: 5px;", "RSA-UVvis"),
  theme = custom_theme,
  
  # ===== "HOW TO CITE" BUTTON =====
  header = tagList(
    tags$head(
      tags$style(HTML("
        .cite-button {
          margin-right: 20px !important;
        }
        .navbar .container-fluid {
          display: flex !important;
          justify-content: space-between !important;
          align-items: center !important;
        }
      "))
    ),
    div(style = "display: flex; align-items: center;",
        actionButton("cite_btn", "How to cite this software", 
                     class = "btn-info", 
                     style = "background-color: #17a2b8; border-color: #17a2b8; color: white; margin-left: 20px;")
    )
  ),
  
  # ===== CSS STYLES =====
  tags$head(
    tags$style(HTML("
      .navbar {
        background-color: #0072B2 !important;
        position: sticky !important;
        top: 0 !important;
        z-index: 1000 !important;
      }
      .navbar-brand {
        color: white !important;
        font-size: 20px !important;
        font-weight: bold !important;
      }
      .navbar-nav .nav-link {
        color: white !important;
        font-size: 16px !important;
        padding: 12px 20px !important;
        background-color: #0072B2 !important;
      }
      .navbar-nav .nav-link:hover {
        background-color: #005a8c !important;
      }
      .navbar-nav .nav-link.active {
        background-color: #004b73 !important;
        font-weight: bold !important;
      }
      body {
        overflow-y: auto !important;
        height: auto !important;
      }
      .container-fluid {
        padding: 20px !important;
        max-width: 1600px !important;
        margin: 0 auto !important;
      }
      .sidebar {
        background-color: #f8f9fa !important;
        border-radius: 8px !important;
        padding: 20px !important;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1) !important;
        margin-bottom: 20px !important;
      }
      .sidebar h4 {
        color: #0072B2 !important;
        margin-top: 0 !important;
        margin-bottom: 20px !important;
        font-weight: bold !important;
      }
      .sidebar .btn-primary {
        background-color: #0072B2 !important;
        border-color: #0072B2 !important;
        width: 100% !important;
        padding: 12px !important;
        font-size: 16px !important;
        font-weight: bold !important;
      }
      .layout_columns {
        margin-bottom: 30px !important;
      }
      .card {
        border-radius: 8px !important;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1) !important;
        margin-bottom: 20px !important;
      }
      .card-header {
        background-color: #f8f9fa !important;
        font-weight: bold !important;
        font-size: 18px !important;
      }
      .shiny-plot-output {
        width: 100% !important;
        height: 500px !important;
      }
      .table-responsive {
        max-height: 300px !important;
        overflow-y: auto !important;
        margin-bottom: 15px !important;
      }
      .nav-tabs {
        margin-top: 20px !important;
        border-bottom: 2px solid #0072B2 !important;
      }
      .nav-tabs .nav-link {
        color: #0072B2 !important;
        font-size: 16px !important;
        padding: 10px 20px !important;
      }
      .nav-tabs .nav-link.active {
        background-color: #0072B2 !important;
        color: white !important;
        border-color: #0072B2 !important;
      }
      .diagnostico-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(600px, 1fr));
        gap: 25px;
        padding: 10px;
      }
      .diagnostico-item {
        background: white;
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        padding: 20px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.05);
      }
      .diagnostico-item h4 {
        margin-top: 0;
        margin-bottom: 15px;
        color: #0072B2;
        font-size: 18px;
        border-bottom: 1px solid #e0e0e0;
        padding-bottom: 10px;
      }
      .btn-success {
        margin-top: 10px !important;
      }
      .modal-header {
        background-color: #0072B2 !important;
        color: white !important;
      }
    "))
  ),
  
  # DPPH Panel
  nav_panel(
    title = "DPPH",
    div(class = "container-fluid",
        fluidRow(
          column(width = 3,
                 div(class = "sidebar",
                     h4("Upload DPPH files"),
                     fileInput("m_dpph", "Upload sample CSV files", 
                               multiple = TRUE, accept = ".csv"),
                     fileInput("c_dpph", "Upload control CSV files", 
                               multiple = TRUE, accept = ".csv"),
                     actionButton("p_dpph", "Process DPPH data", 
                                  class = "btn-primary")
                 )
          ),
          column(width = 9,
                 layout_columns(
                   col_widths = c(6, 6),
                   card(
                     card_header("Results by time"),
                     div(class = "table-responsive",
                         tableOutput("r_dpph")
                     ),
                     downloadButton("d_dpph", "Download Excel", 
                                    class = "btn-success")
                   ),
                   card(
                     card_header("RSA vs Time plot"),
                     plotOutput("g_dpph", height = "500px")
                   )
                 )
          )
        ),
        navset_tab(
          nav_panel("Individual data",
                    div(class = "table-responsive",
                        tableOutput("di_dpph")
                    )
          ),
          nav_panel("Peak heights",
                    div(class = "table-responsive",
                        tableOutput("ai_dpph")
                    )
          ),
          nav_panel("Diagnostic",
                    uiOutput("dg_dpph")
          )
        )
    )
  ),
  
  # ABTS Panel
  nav_panel(
    title = "ABTS",
    div(class = "container-fluid",
        fluidRow(
          column(width = 3,
                 div(class = "sidebar",
                     h4("Upload ABTS files"),
                     fileInput("m_abts", "Upload sample CSV files", 
                               multiple = TRUE, accept = ".csv"),
                     fileInput("c_abts", "Upload control CSV files", 
                               multiple = TRUE, accept = ".csv"),
                     actionButton("p_abts", "Process ABTS data", 
                                  class = "btn-primary")
                 )
          ),
          column(width = 9,
                 layout_columns(
                   col_widths = c(6, 6),
                   card(
                     card_header("Results by time"),
                     div(class = "table-responsive",
                         tableOutput("r_abts")
                     ),
                     downloadButton("d_abts", "Download Excel", 
                                    class = "btn-success")
                   ),
                   card(
                     card_header("RSA vs Time plot"),
                     plotOutput("g_abts", height = "500px")
                   )
                 )
          )
        ),
        navset_tab(
          nav_panel("Individual data",
                    div(class = "table-responsive",
                        tableOutput("di_abts")
                    )
          ),
          nav_panel("Peak heights",
                    div(class = "table-responsive",
                        tableOutput("ai_abts")
                    )
          ),
          nav_panel("Diagnostic",
                    uiOutput("dg_abts")
          )
        )
    )
  )
)