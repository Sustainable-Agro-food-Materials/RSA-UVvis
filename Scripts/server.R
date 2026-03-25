library(dplyr)
library(ggplot2)
library(openxlsx)
library(tools)
library(stringr)
library(tidyr)

source("helpers.R", local = TRUE)

server <- function(input, output, session) {
  
  # ===== DEBUGGING FOR ELECTRON =====
  observe({
    if(isTRUE(getOption("shiny.port") == 8888)) {
      print("🚀 App started in Electron mode")
      
      observeEvent(input$m_dpph, {
        if(!is.null(input$m_dpph)) {
          print(paste("📁 DPPH samples:", nrow(input$m_dpph), "files"))
          print(paste("   Names:", paste(input$m_dpph$name, collapse=", ")))
        }
      })
      
      observeEvent(input$c_dpph, {
        if(!is.null(input$c_dpph)) {
          print(paste("📁 DPPH controls:", nrow(input$c_dpph), "files"))
        }
      })
      
      observeEvent(input$m_abts, {
        if(!is.null(input$m_abts)) {
          print(paste("📁 ABTS samples:", nrow(input$m_abts), "files"))
        }
      })
      
      observeEvent(input$c_abts, {
        if(!is.null(input$c_abts)) {
          print(paste("📁 ABTS controls:", nrow(input$c_abts), "files"))
        }
      })
    }
  })
  # =========================
  # DPPH MODULE
  # =========================
  
  dpph_data <- reactiveVal(list())
  dpph_rsa_results <- reactiveVal(NULL)
  dpph_summary <- reactiveVal(NULL)
  dpph_peaks <- reactiveVal(NULL)
  
  observeEvent(input$p_dpph, {
    
    req(input$m_dpph, input$c_dpph)
    
    while(grDevices::dev.cur() > 1) grDevices::dev.off()
    
    showNotification("Processing DPPH data...", type = "message")
    
    tryCatch({
      
      withProgress(message = 'Processing DPPH', value = 0, {
        
        data_list <- list()
        
        # Process samples
        for(i in seq_len(nrow(input$m_dpph))) {
          incProgress(1/(nrow(input$m_dpph) + nrow(input$c_dpph)))
          
          n <- file_path_sans_ext(input$m_dpph$name[i])
          
          result <- process_file(
            input$m_dpph$datapath[i],
            n,
            "sample",
            "DPPH"
          )
          
          if(!is.null(result)) {
            for(spec_name in names(result)) {
              data_list[[spec_name]] <- result[[spec_name]]
              
              # AÑADIR "DPPH" COMO QUINTO PARÁMETRO
              generate_plots(
                result[[spec_name]]$data, 
                spec_name, 
                "sample",
                result[[spec_name]]$lower_point, 
                result[[spec_name]]$upper_point,
                "DPPH"
              )
            }
          }
        }
        
        # Process controls
        for(i in seq_len(nrow(input$c_dpph))) {
          incProgress(1/(nrow(input$m_dpph) + nrow(input$c_dpph)))
          
          n <- file_path_sans_ext(input$c_dpph$name[i])
          
          result <- process_file(
            input$c_dpph$datapath[i],
            n,
            "control",
            "DPPH"
          )
          
          if(!is.null(result)) {
            for(spec_name in names(result)) {
              data_list[[spec_name]] <- result[[spec_name]]
              
              # AÑADIR "DPPH" COMO QUINTO PARÁMETRO
              generate_plots(
                result[[spec_name]]$data, 
                spec_name, 
                "control",
                result[[spec_name]]$lower_point, 
                result[[spec_name]]$upper_point,
                "DPPH"
              )
            }
          }
        }
        
        dpph_data(data_list)
        
        process_results(data_list, dpph_rsa_results, dpph_summary, dpph_peaks)
        
      })
      
      showNotification("DPPH processed successfully!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error processing DPPH:", e$message), type = "error")
    })
  })
  
  
  # =========================
  # ABTS MODULE
  # =========================
  
  abts_data <- reactiveVal(list())
  abts_rsa_results <- reactiveVal(NULL)
  abts_summary <- reactiveVal(NULL)
  abts_peaks <- reactiveVal(NULL)
  
  observeEvent(input$p_abts, {
    
    req(input$m_abts, input$c_abts)
    
    while(grDevices::dev.cur() > 1) grDevices::dev.off()
    
    showNotification("Processing ABTS data...", type = "message")
    
    tryCatch({
      
      withProgress(message = 'Processing ABTS', value = 0, {
        
        data_list <- list()
        
        # Process samples
        for(i in seq_len(nrow(input$m_abts))) {
          
          incProgress(1/(nrow(input$m_abts) + nrow(input$c_abts)))
          
          n <- file_path_sans_ext(input$m_abts$name[i])
          
          result <- process_file(
            input$m_abts$datapath[i],
            n,
            "sample",
            "ABTS"
          )
          
          if(!is.null(result)) {
            for(spec_name in names(result)) {
              data_list[[spec_name]] <- result[[spec_name]]
              
              # AÑADIR "ABTS" COMO QUINTO PARÁMETRO
              generate_plots(
                result[[spec_name]]$data, 
                spec_name, 
                "sample",
                result[[spec_name]]$lower_point, 
                result[[spec_name]]$upper_point,
                "ABTS"
              )
            }
          }
        }
        
        # Process controls
        for(i in seq_len(nrow(input$c_abts))) {
          
          incProgress(1/(nrow(input$m_abts) + nrow(input$c_abts)))
          
          n <- file_path_sans_ext(input$c_abts$name[i])
          
          result <- process_file(
            input$c_abts$datapath[i],
            n,
            "control",
            "ABTS"
          )
          
          if(!is.null(result)) {
            for(spec_name in names(result)) {
              data_list[[spec_name]] <- result[[spec_name]]
              
              # AÑADIR "ABTS" COMO QUINTO PARÁMETRO
              generate_plots(
                result[[spec_name]]$data, 
                spec_name, 
                "control",
                result[[spec_name]]$lower_point, 
                result[[spec_name]]$upper_point,
                "ABTS"
              )
            }
          }
        }
        
        abts_data(data_list)
        
        process_results(data_list, abts_rsa_results, abts_summary, abts_peaks)
        
      })
      
      showNotification("ABTS processed successfully!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error processing ABTS:", e$message), type = "error")
    })
  })
  
  # =========================
  # DPPH OUTPUTS
  # =========================
  
  output$r_dpph <- renderTable({ dpph_summary() }, striped = TRUE)
  output$di_dpph <- renderTable({ dpph_rsa_results() }, striped = TRUE)
  output$ai_dpph <- renderTable({ dpph_peaks() }, striped = TRUE)
  
  output$g_dpph <- renderPlot({
    req(dpph_summary())
    
    ggplot(dpph_summary(), aes(x = Time, y = Mean_RSA)) +
      geom_line(color = "#0072B2", size = 1) +
      geom_point(color = "#0072B2", size = 3) +
      geom_errorbar(aes(
        ymin = Mean_RSA - SD_RSA,
        ymax = Mean_RSA + SD_RSA
      ), width = 0.2, color = "#0072B2") +
      labs(
        title = "Antioxidant Activity (DPPH)",
        y = "RSA (%)",
        x = "Time"
      ) +
      theme_minimal(base_size = 14)
  })
  
  
  # =========================
  # ABTS OUTPUTS
  # =========================
  
  output$r_abts <- renderTable({ abts_summary() }, striped = TRUE)
  output$di_abts <- renderTable({ abts_rsa_results() }, striped = TRUE)
  output$ai_abts <- renderTable({ abts_peaks() }, striped = TRUE)
  
  output$g_abts <- renderPlot({
    req(abts_summary())
    
    ggplot(abts_summary(), aes(x = Time, y = Mean_RSA)) +
      geom_line(color = "#D55E00", size = 1) +
      geom_point(color = "#D55E00", size = 3) +
      geom_errorbar(aes(
        ymin = Mean_RSA - SD_RSA,
        ymax = Mean_RSA + SD_RSA
      ), width = 0.2, color = "#D55E00") +
      labs(
        title = "Antioxidant Activity (ABTS)",
        y = "RSA (%)",
        x = "Time"
      ) +
      theme_minimal(base_size = 14)
  })
  
  
  # =========================
  # DPPH DIAGNOSTIC
  # =========================
  
  output$dg_dpph <- renderUI({
    req(dpph_data())
    
    data_list <- dpph_data()
    names_list <- names(data_list)
    
    if(length(names_list) == 0) {
      return(p("No data to display. Process files first."))
    }
    
    div(class = "diagnostico-grid",
        lapply(names_list, function(name) {
          div(class = "diagnostico-item",
              h4(paste0(name, " (", data_list[[name]]$type, ")")),
              plotOutput(
                outputId = paste0("diag_plot_dpph_", gsub("[^a-zA-Z0-9]", "_", name)),
                height = "300px"
              )
          )
        })
    )
  })
  
  # Render each DPPH diagnostic plot
  observe({
    req(dpph_data())
    
    data_list <- dpph_data()
    names_list <- names(data_list)
    
    for(name in names_list) {
      local({
        n <- name
        d <- data_list[[n]]
        
        output[[paste0("diag_plot_dpph_", gsub("[^a-zA-Z0-9]", "_", n))]] <- renderPlot({
          plot(d$data$WL, d$data$Abs, type = "l",
               main = paste("Diagnostic:", n),
               xlab = "Wavelength (nm)", 
               ylab = "Absorbance",
               col = "black", lwd = 2,
               cex.main = 1.2, cex.lab = 1.1)
          
          # Baseline
          lines(d$data$WL, d$data$baseline, col = "red", lty = 2, lwd = 2)
          
          # Baseline points
          if(!is.null(d$lower_point) && nrow(d$lower_point) > 0) {
            points(d$lower_point$WL, d$lower_point$Abs, col = "blue", pch = 19, cex = 1.5)
          }
          if(!is.null(d$upper_point) && nrow(d$upper_point) > 0) {
            points(d$upper_point$WL, d$upper_point$Abs, col = "blue", pch = 19, cex = 1.5)
          }
          
          # Maximum peak
          idx_max <- which.max(d$data$Abs_corr)
          points(d$data$WL[idx_max], d$data$Abs[idx_max], 
                 col = "green", pch = 19, cex = 1.5)
          
          grid()
          legend("topright", 
                 legend = c("Spectrum", "Baseline", "Base points", "Max peak"),
                 col = c("black", "red", "blue", "green"),
                 lty = c(1, 2, NA, NA), 
                 pch = c(NA, NA, 19, 19),
                 bg = "white", box.lty = 1)
        })
      })
    }
  })
  
  
  # =========================
  # ABTS DIAGNOSTIC
  # =========================
  
  output$dg_abts <- renderUI({
    req(abts_data())
    
    data_list <- abts_data()
    names_list <- names(data_list)
    
    if(length(names_list) == 0) {
      return(p("No data to display. Process files first."))
    }
    
    div(class = "diagnostico-grid",
        lapply(names_list, function(name) {
          div(class = "diagnostico-item",
              h4(paste0(name, " (", data_list[[name]]$type, ")")),
              plotOutput(
                outputId = paste0("diag_plot_abts_", gsub("[^a-zA-Z0-9]", "_", name)),
                height = "300px"
              )
          )
        })
    )
  })
  
  # Render each ABTS diagnostic plot
  observe({
    req(abts_data())
    
    data_list <- abts_data()
    names_list <- names(data_list)
    
    for(name in names_list) {
      local({
        n <- name
        d <- data_list[[n]]
        
        output[[paste0("diag_plot_abts_", gsub("[^a-zA-Z0-9]", "_", n))]] <- renderPlot({
          plot(d$data$WL, d$data$Abs, type = "l",
               main = paste("Diagnostic:", n),
               xlab = "Wavelength (nm)", 
               ylab = "Absorbance",
               col = "black", lwd = 2,
               cex.main = 1.2, cex.lab = 1.1)
          
          # Baseline
          lines(d$data$WL, d$data$baseline, col = "red", lty = 2, lwd = 2)
          
          # Baseline points
          if(!is.null(d$lower_point) && nrow(d$lower_point) > 0) {
            points(d$lower_point$WL, d$lower_point$Abs, col = "blue", pch = 19, cex = 1.5)
          }
          if(!is.null(d$upper_point) && nrow(d$upper_point) > 0) {
            points(d$upper_point$WL, d$upper_point$Abs, col = "blue", pch = 19, cex = 1.5)
          }
          
          # Maximum peak
          idx_max <- which.max(d$data$Abs_corr)
          points(d$data$WL[idx_max], d$data$Abs[idx_max], 
                 col = "green", pch = 19, cex = 1.5)
          
          grid()
          legend("topright", 
                 legend = c("Spectrum", "Baseline", "Base points", "Max peak"),
                 col = c("black", "red", "blue", "green"),
                 lty = c(1, 2, NA, NA), 
                 pch = c(NA, NA, 19, 19),
                 bg = "white", box.lty = 1)
        })
      })
    }
  })
  
  
  # =========================
  # DPPH EXCEL DOWNLOAD (CORREGIDO)
  # =========================
  
  output$d_dpph <- downloadHandler(
    
    filename = function() {
      "DPPH_results.xlsx"
    },
    
    content = function(file) {
      
      wb <- createWorkbook()
      
      # -------- HOJA RSA --------
      addWorksheet(wb, "RSA")
      
      rsa_data <- dpph_rsa_results()
      
      # Remove Control column for display
      if("Control" %in% names(rsa_data)) {
        rsa_data <- rsa_data %>% select(-Control)
      }
      
      # Sort by time
      rsa_data <- rsa_data %>% arrange(Time)
      
      writeData(wb, "RSA", rsa_data)
      
      # Add Mean and SD columns
      writeData(wb, "RSA", "Mean RSA", startCol = 5, startRow = 1)
      writeData(wb, "RSA", "SD RSA", startCol = 6, startRow = 1)
      
      # Get unique times and count replicates
      times <- unique(rsa_data$Time)
      times <- times[!is.na(times)]
      
      start_row <- 2
      replicates_per_time <- c()
      
      for(t in times) {
        nrep <- sum(rsa_data$Time == t, na.rm = TRUE)
        replicates_per_time <- c(replicates_per_time, nrep)
        
        end_row <- start_row + nrep - 1
        
        if(nrep > 1) {
          # Formulas for mean and SD
          mean_formula <- paste0("=AVERAGE(D", start_row, ":D", end_row, ")")
          sd_formula   <- paste0("=STDEV(D", start_row, ":D", end_row, ")")
          
          writeFormula(wb, "RSA", mean_formula, startCol = 5, startRow = start_row)
          writeFormula(wb, "RSA", sd_formula,   startCol = 6, startRow = start_row)
          
          # Merge cells for this time group
          mergeCells(wb, "RSA", cols = 5, rows = start_row:end_row)
          mergeCells(wb, "RSA", cols = 6, rows = start_row:end_row)
        } else {
          # Single replicate: use the same value
          writeFormula(wb, "RSA", paste0("=D", start_row), startCol = 5, startRow = start_row)
          writeFormula(wb, "RSA", "0", startCol = 6, startRow = start_row)
        }
        
        start_row <- end_row + 1
      }
      
      # -------- SUMMARY SHEET --------
      addWorksheet(wb, "Summary")
      
      summary_data <- dpph_summary()
      writeData(wb, "Summary", summary_data)
      
      # Add references to RSA sheet
      if(nrow(summary_data) > 0) {
        rsa_row <- 2
        for(i in 1:nrow(summary_data)) {
          excel_row <- i + 1
          
          if(replicates_per_time[i] > 1) {
            writeFormula(wb, "Summary",
                         paste0("=RSA!E", rsa_row),
                         startCol = ncol(summary_data) + 1,
                         startRow = excel_row)
            
            writeFormula(wb, "Summary",
                         paste0("=RSA!F", rsa_row),
                         startCol = ncol(summary_data) + 2,
                         startRow = excel_row)
          } else {
            writeFormula(wb, "Summary",
                         paste0("=RSA!D", rsa_row),
                         startCol = ncol(summary_data) + 1,
                         startRow = excel_row)
            
            writeFormula(wb, "Summary",
                         "0",
                         startCol = ncol(summary_data) + 2,
                         startRow = excel_row)
          }
          
          rsa_row <- rsa_row + replicates_per_time[i]
        }
        
        # Add headers
        writeData(wb, "Summary", "Mean RSA", startCol = ncol(summary_data) + 1, startRow = 1)
        writeData(wb, "Summary", "SD RSA", startCol = ncol(summary_data) + 2, startRow = 1)
      }
      
      # -------- PEAK HEIGHTS SHEET --------
      addWorksheet(wb, "Peak_heights")
      writeData(wb, "Peak_heights", dpph_peaks())
      
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
  # =========================
  # ABTS EXCEL DOWNLOAD (CORREGIDO)
  # =========================
  
  output$d_abts <- downloadHandler(
    
    filename = function() {
      "ABTS_results.xlsx"
    },
    
    content = function(file) {
      
      wb <- createWorkbook()
      
      # -------- HOJA RSA --------
      addWorksheet(wb, "RSA")
      
      rsa_data <- abts_rsa_results()
      
      # Remove Control column for display
      if("Control" %in% names(rsa_data)) {
        rsa_data <- rsa_data %>% select(-Control)
      }
      
      # Sort by time
      rsa_data <- rsa_data %>% arrange(Time)
      
      writeData(wb, "RSA", rsa_data)
      
      # Add Mean and SD columns
      writeData(wb, "RSA", "Mean RSA", startCol = 5, startRow = 1)
      writeData(wb, "RSA", "SD RSA", startCol = 6, startRow = 1)
      
      # Get unique times and count replicates
      times <- unique(rsa_data$Time)
      times <- times[!is.na(times)]
      
      start_row <- 2
      replicates_per_time <- c()
      
      for(t in times) {
        nrep <- sum(rsa_data$Time == t, na.rm = TRUE)
        replicates_per_time <- c(replicates_per_time, nrep)
        
        end_row <- start_row + nrep - 1
        
        if(nrep > 1) {
          # Formulas for mean and SD
          mean_formula <- paste0("=AVERAGE(D", start_row, ":D", end_row, ")")
          sd_formula   <- paste0("=STDEV(D", start_row, ":D", end_row, ")")
          
          writeFormula(wb, "RSA", mean_formula, startCol = 5, startRow = start_row)
          writeFormula(wb, "RSA", sd_formula,   startCol = 6, startRow = start_row)
          
          # Merge cells for this time group
          mergeCells(wb, "RSA", cols = 5, rows = start_row:end_row)
          mergeCells(wb, "RSA", cols = 6, rows = start_row:end_row)
        } else {
          # Single replicate: use the same value
          writeFormula(wb, "RSA", paste0("=D", start_row), startCol = 5, startRow = start_row)
          writeFormula(wb, "RSA", "0", startCol = 6, startRow = start_row)
        }
        
        start_row <- end_row + 1
      }
      
      # -------- SUMMARY SHEET --------
      addWorksheet(wb, "Summary")
      
      summary_data <- abts_summary()
      writeData(wb, "Summary", summary_data)
      
      # Add references to RSA sheet
      if(nrow(summary_data) > 0) {
        rsa_row <- 2
        for(i in 1:nrow(summary_data)) {
          excel_row <- i + 1
          
          if(replicates_per_time[i] > 1) {
            writeFormula(wb, "Summary",
                         paste0("=RSA!E", rsa_row),
                         startCol = ncol(summary_data) + 1,
                         startRow = excel_row)
            
            writeFormula(wb, "Summary",
                         paste0("=RSA!F", rsa_row),
                         startCol = ncol(summary_data) + 2,
                         startRow = excel_row)
          } else {
            writeFormula(wb, "Summary",
                         paste0("=RSA!D", rsa_row),
                         startCol = ncol(summary_data) + 1,
                         startRow = excel_row)
            
            writeFormula(wb, "Summary",
                         "0",
                         startCol = ncol(summary_data) + 2,
                         startRow = excel_row)
          }
          
          rsa_row <- rsa_row + replicates_per_time[i]
        }
        
        # Add headers
        writeData(wb, "Summary", "Mean RSA", startCol = ncol(summary_data) + 1, startRow = 1)
        writeData(wb, "Summary", "SD RSA", startCol = ncol(summary_data) + 2, startRow = 1)
      }
      
      # -------- PEAK HEIGHTS SHEET --------
      addWorksheet(wb, "Peak_heights")
      writeData(wb, "Peak_heights", abts_peaks())
      
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
  # =========================
  # "HOW TO CITE" MODAL
  # =========================
  
  observeEvent(input$cite_btn, {
    showModal(modalDialog(
      title = tags$span(style = "color: white;", "How to cite this software"),
      size = "m",
      easyClose = TRUE,
      footer = modalButton("Close"),
      tags$div(
        style = "padding: 15px;",
        tags$h4("Citation information", style = "color: #0072B2;"),
        tags$p("If you use this software in your research, please cite it as:"),
        tags$div(
          style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px; font-family: monospace;",
          "Rodríguez-Rodríguez, D., Solano-Moreno, F. J., Muñoz-Pérez, M. del R., Guzmán-Puyol, S., & Heredia-Guerrero, J. A. (2026). RSA-UVvis: A desktop app for antioxidant capacity analysis. Zenodo"
        ),
        tags$p(style = "margin-top: 15px;", "DOI: 10.5281/zenodo.19206254"),
        tags$hr(),
        tags$p(style = "font-style: italic;", "Software developed by the Sustainable Agro-Food Materials research group, IHSM La Mayora.")
      )
    ))
  })
  
}