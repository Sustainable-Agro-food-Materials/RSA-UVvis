library(readr)
library(dplyr)
library(stringr)
library(tidyr)
library(tools)

# Function to clean numeric data
clean_numeric <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x[x == ""] <- NA
  x[x == "10"] <- NA
  as.numeric(x)
}

# Function to extract time from filename (case insensitive)
extract_time_from_filename <- function(filename) {
  time_value <- 0
  time_match <- str_extract(filename, "[Tt]\\d+")
  if(!is.na(time_match)) {
    time_value <- as.numeric(str_remove(time_match, "[Tt]"))
  }
  return(time_value)
}

# Function to detect if file contains multiple spectra in columns
detect_multi_spectra <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE, n = 20)
  
  wavelength_line <- grep("Wavelength", lines)
  if(length(wavelength_line) > 0 && wavelength_line[1] > 1) {
    prev_line <- lines[wavelength_line[1] - 1]
    if(grepl(",", prev_line) && length(strsplit(prev_line, ",")[[1]]) > 2) {
      return(TRUE)
    }
  }
  
  for(i in seq_along(lines)) {
    if(grepl("^\\d", lines[i])) {
      cells <- strsplit(lines[i], ",")[[1]]
      cells <- cells[cells != ""]
      if(length(cells) > 4) {
        return(TRUE)
      }
      break
    }
  }
  
  return(FALSE)
}

# Function to parse multi-spectra file
parse_multi_spectra <- function(file_path, file_name) {
  lines <- readLines(file_path, warn = FALSE)
  lines <- lines[nchar(trimws(lines)) > 0]
  
  header_idx <- grep("Wavelength", lines)[1]
  if(is.na(header_idx)) {
    stop("Could not find Wavelength header")
  }
  
  sample_line <- lines[header_idx - 1]
  sample_names <- strsplit(sample_line, ",")[[1]]
  sample_names <- trimws(sample_names)
  sample_names <- sample_names[sample_names != ""]
  
  clean_names <- gsub("[^a-zA-Z0-9]", "_", sample_names)
  global_time <- extract_time_from_filename(file_name)
  
  data_lines <- lines[(header_idx + 1):length(lines)]
  temp_file <- tempfile()
  writeLines(data_lines, temp_file)
  data <- read.csv(temp_file, header = FALSE, stringsAsFactors = FALSE)
  unlink(temp_file)
  
  data <- data[, colSums(is.na(data) | data == "") < nrow(data), drop = FALSE]
  
  n_spectra <- min(length(sample_names), floor(ncol(data) / 2))
  sample_names <- sample_names[1:n_spectra]
  clean_names <- clean_names[1:n_spectra]
  
  spectra_list <- list()
  
  for(i in 1:n_spectra) {
    wl_col <- 2*i - 1
    abs_col <- 2*i
    
    wl_data <- clean_numeric(data[[wl_col]])
    abs_data <- clean_numeric(data[[abs_col]])
    
    valid <- !is.na(wl_data) & !is.na(abs_data)
    wl_data <- wl_data[valid]
    abs_data <- abs_data[valid]
    
    if(length(wl_data) > 5) {
      if(global_time > 0) {
        spec_name <- sprintf("%s_%s_T%d", 
                             file_path_sans_ext(file_name), 
                             clean_names[i], 
                             global_time)
      } else {
        spec_name <- sprintf("%s_%s", 
                             file_path_sans_ext(file_name), 
                             clean_names[i])
      }
      
      spectra_list[[spec_name]] <- list(
        data = data.frame(WL = wl_data, Abs = abs_data),
        time = global_time
      )
    }
  }
  
  return(spectra_list)
}

# File reader for single spectra
read_single_spectrum <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  
  data_start <- 1
  for(i in seq_along(lines)) {
    first_char <- substr(trimws(lines[i]), 1, 1)
    if(first_char %in% c("0","1","2","3","4","5","6","7","8","9","-")) {
      data_start <- i
      break
    }
  }
  
  data_lines <- lines[data_start:length(lines)]
  
  temp_file <- tempfile()
  writeLines(data_lines, temp_file)
  
  data <- tryCatch({
    read.csv(temp_file, header = FALSE, stringsAsFactors = FALSE)
  }, error = function(e) {
    read.table(temp_file, sep = ",", header = FALSE, fill = TRUE)
  })
  
  unlink(temp_file)
  
  if(is.null(data) || ncol(data) < 2) {
    stop("Could not parse file")
  }
  
  for(j in 1:ncol(data)) {
    data[[j]] <- clean_numeric(data[[j]])
  }
  
  numeric_cols <- which(sapply(data, function(col) sum(!is.na(col)) > 5))
  
  if(length(numeric_cols) < 2) {
    stop("Not enough numeric columns")
  }
  
  wl_col <- numeric_cols[1]
  abs_col <- numeric_cols[2]
  
  data.frame(
    WL = data[[wl_col]],
    Abs = data[[abs_col]]
  )
}

# MAIN PROCESSING FUNCTION
process_file <- function(file_path, file_name, file_type, assay_type) {
  tryCatch({
    if(detect_multi_spectra(file_path)) {
      cat("📊 Detected multi-spectra file:", file_name, "\n")
      spectra_list <- parse_multi_spectra(file_path, file_name)
      
      if(length(spectra_list) == 0) {
        stop("No valid spectra found in file")
      }
      
      results <- list()
      for(spec_name in names(spectra_list)) {
        spec_info <- spectra_list[[spec_name]]
        result <- process_spectrum_data(
          spec_info$data, 
          spec_name, 
          file_type, 
          assay_type, 
          spec_info$time
        )
        if(!is.null(result)) {
          results[[spec_name]] <- result
        }
      }
      return(results)
      
    } else {
      data <- read_single_spectrum(file_path)
      data <- data[!is.na(data$WL) & !is.na(data$Abs), ]
      
      if(nrow(data) < 10) {
        stop("Not enough valid data points")
      }
      
      time_value <- extract_time_from_filename(file_name)
      result <- process_spectrum_data(data, file_name, file_type, assay_type, time_value)
      
      if(!is.null(result)) {
        results <- list()
        results[[file_name]] <- result
        return(results)
      }
      return(NULL)
    }
  }, error = function(e) {
    message("Error processing file ", file_name, ": ", e$message)
    NULL
  })
}

# Core spectrum processing function - CON IDENTIFICADOR ÚNICO
process_spectrum_data <- function(data, name, file_type, assay_type, time_value) {
  
  # === CONFIGURACIÓN SEGÚN ENSAYO ===
  if(assay_type == "DPPH") {
    # DPPH - RANGOS OPTIMIZADOS
    search_range <- c(400, 600)
    lower_range <- c(400, 480)      # Zona izquierda
    upper_range <- c(560, 620)      # Zona derecha AMPLIADA
    diag_min <- 350                  # Rango diagnóstico
    diag_max <- 650                  # Rango diagnóstico
  } else {
    # ABTS - RANGOS ORIGINALES (SIN MODIFICAR)
    search_range <- c(400, 800)
    lower_range <- c(650, 700)      # Zona izquierda
    upper_range <- c(760, 800)      # Zona derecha
    diag_min <- 600                  # Rango diagnóstico
    diag_max <- 800                  # Rango diagnóstico
  }
  
  # === 1. ENCONTRAR EL PICO ===
  data_cut <- data %>% filter(between(WL, search_range[1], search_range[2]))
  if(nrow(data_cut) == 0) {
    message("No data in search range for ", name)
    return(NULL)
  }
  
  peak_idx <- which.max(data_cut$Abs)
  wl_max <- data_cut$WL[peak_idx]
  
  # Ajuste de pico para ABTS si está fuera de rango
  if(assay_type != "DPPH" && (wl_max < 720 || wl_max > 750)) {
    expected <- data_cut %>% filter(between(WL, 720, 750))
    if(nrow(expected) > 0) {
      wl_max <- expected$WL[which.max(expected$Abs)]
    }
  }
  
  # === 2. DATOS PARA ANÁLISIS ===
  analysis_data <- data %>% filter(between(WL, wl_max - 60, wl_max + 60))
  if(nrow(analysis_data) == 0) {
    analysis_data <- data
  }
  
  # === 3. DATOS PARA DIAGNÓSTICO ===
  diagnostic_data <- data %>% filter(between(WL, diag_min, diag_max))
  if(nrow(diagnostic_data) == 0) {
    diagnostic_data <- analysis_data
  }
  
  # === 4. SELECCIÓN DE PUNTOS DE LÍNEA BASE ===
  
  # Zona inferior
  lower_zone <- data %>% filter(between(WL, lower_range[1], lower_range[2]))
  if(nrow(lower_zone) > 0) {
    lower_point <- lower_zone[which.min(lower_zone$Abs), ]
  } else {
    left_points <- data %>% filter(WL < wl_max - 30)
    if(nrow(left_points) > 0) {
      lower_point <- left_points[which.min(left_points$Abs), ]
    } else {
      lower_point <- data[1, ]
    }
  }
  
  # Zona superior
  upper_zone <- data %>% filter(between(WL, upper_range[1], upper_range[2]))
  if(nrow(upper_zone) > 0) {
    upper_point <- upper_zone[which.min(upper_zone$Abs), ]
  } else {
    right_points <- data %>% filter(WL > wl_max + 30)
    if(nrow(right_points) > 0) {
      upper_point <- right_points[which.min(right_points$Abs), ]
    } else {
      upper_point <- data[nrow(data), ]
    }
  }
  
  # === 5. VERIFICAR ORDEN ===
  if(upper_point$WL <= lower_point$WL) {
    temp <- lower_point
    lower_point <- upper_point
    upper_point <- temp
  }
  
  # === 6. CALCULAR LÍNEA BASE ===
  
  # Para análisis
  baseline_analysis <- approx(c(lower_point$WL, upper_point$WL),
                              c(lower_point$Abs, upper_point$Abs),
                              xout = analysis_data$WL)$y
  analysis_data$baseline <- baseline_analysis
  analysis_data$Abs_corr <- pmax(analysis_data$Abs - baseline_analysis, 0)
  
  # Para diagnóstico
  baseline_diag <- approx(c(lower_point$WL, upper_point$WL),
                          c(lower_point$Abs, upper_point$Abs),
                          xout = diagnostic_data$WL,
                          rule = 2)$y
  diagnostic_data$baseline <- baseline_diag
  diagnostic_data$Abs_corr <- pmax(diagnostic_data$Abs - baseline_diag, 0)
  
  # === 7. RESULTADO ===
  list(
    data = diagnostic_data,
    analysis_data = analysis_data,
    time = time_value,
    max_abs = max(analysis_data$Abs_corr, na.rm = TRUE),
    type = file_type,
    wl_max = wl_max,
    lower_point = lower_point,
    upper_point = upper_point,
    has_time = time_value != 0,
    assay_type = assay_type
  )
}
# Function to generate plots - CON RANGOS AMPLIADOS
generate_plots <- function(filtered_data, file_name, file_type, lower_point, upper_point, assay_type) {
  safe_dev_off <- function() {
    try(dev.off(), silent = TRUE)
  }
  
  tryCatch({
    dir.create("www/spectra_png", recursive = TRUE, showWarnings = FALSE)
    dir.create("www/diagnostic_png", recursive = TRUE, showWarnings = FALSE)
    
    # RANGOS AMPLIADOS
    if(assay_type == "DPPH") {
      x_min <- 350   # Ampliado de 400 a 350
      x_max <- 650   # Ampliado de 600 a 650
    } else {
      x_min <- 600
      x_max <- 800
    }
    
    # Corrected spectrum plot
    png(file.path("www", "spectra_png", paste0(file_name, ".png")), 
        width = 600, height = 400, res = 100)
    plot(filtered_data$WL, filtered_data$Abs_corr, type = "l",
         main = file_name, xlab = "Wavelength (nm)", ylab = "Corrected Absorbance",
         col = ifelse(file_type == "sample", "#0072B2", "#D55E00"), lwd = 2,
         xlim = c(x_min, x_max))
    grid()
    safe_dev_off()
    
    # Diagnostic plot
    png(file.path("www", "diagnostic_png", paste0(file_name, "_diag.png")), 
        width = 600, height = 400, res = 100)
    plot(filtered_data$WL, filtered_data$Abs, type = "l",
         main = paste("Diagnostic:", file_name), 
         xlab = "Wavelength (nm)", ylab = "Absorbance",
         col = "black", lwd = 2,
         xlim = c(x_min, x_max),
         ylim = range(filtered_data$Abs, filtered_data$baseline, na.rm = TRUE))
    
    lines(filtered_data$WL, filtered_data$baseline, col = "red", lty = 2, lwd = 2)
    
    if(!is.null(lower_point) && nrow(lower_point) > 0) {
      points(lower_point$WL, lower_point$Abs, col = "blue", pch = 19, cex = 1.5)
    }
    if(!is.null(upper_point) && nrow(upper_point) > 0) {
      points(upper_point$WL, upper_point$Abs, col = "blue", pch = 19, cex = 1.5)
    }
    
    idx_max <- which.max(filtered_data$Abs_corr)
    points(filtered_data$WL[idx_max], filtered_data$Abs[idx_max], 
           col = "green", pch = 19, cex = 1.5)
    
    grid()
    legend("topright", 
           legend = c("Spectrum", "Baseline", "Base points", "Max peak"),
           col = c("black", "red", "blue", "green"),
           lty = c(1, 2, NA, NA), pch = c(NA, NA, 19, 19),
           bg = "white", box.lty = 1)
    safe_dev_off()
    
  }, error = function(e) {
    safe_dev_off()
    safe_dev_off()
    message("Error generating plots for ", file_name, ": ", e$message)
  })
}

# Function to process results
process_results <- function(data_list, rsa_results, summary_results, peak_heights) {
  try({
    rsa_df <- data.frame()
    peaks_df <- data.frame()
    
    flat_data <- list()
    for(name in names(data_list)) {
      if(is.list(data_list[[name]]) && !is.null(data_list[[name]]$data)) {
        flat_data[[name]] <- data_list[[name]]
      } else if(is.list(data_list[[name]])) {
        for(subname in names(data_list[[name]])) {
          flat_data[[subname]] <- data_list[[name]][[subname]]
        }
      }
    }
    
    samples <- names(flat_data)[sapply(flat_data, function(x) x$type == "sample")]
    controls <- names(flat_data)[sapply(flat_data, function(x) x$type == "control")]
    
    controls_have_time <- any(sapply(controls, function(n) flat_data[[n]]$has_time))
    
    if(!controls_have_time && length(controls) > 0) {
      control_times <- rep(0, length(controls))
    } else {
      control_times <- sapply(controls, function(n) flat_data[[n]]$time)
    }
    
    control_lookup <- data.frame(
      name = controls,
      time = control_times,
      max_abs = sapply(controls, function(n) flat_data[[n]]$max_abs)
    )
    
    for(sample in samples) {
      sample_time <- flat_data[[sample]]$time
      sample_abs <- flat_data[[sample]]$max_abs
      
      peaks_df <- rbind(peaks_df, 
                        data.frame(Name = sample, 
                                   Time = sample_time, 
                                   Peak_height = sample_abs, 
                                   Type = "sample"))
      
      if(controls_have_time) {
        ctrl_for_sample <- control_lookup %>% 
          filter(time == sample_time) %>%
          pull(name)
      } else {
        ctrl_for_sample <- controls
      }
      
      for(ctrl in ctrl_for_sample) {
        if(!(ctrl %in% peaks_df$Name)) {
          peaks_df <- rbind(peaks_df, 
                            data.frame(Name = ctrl, 
                                       Time = flat_data[[ctrl]]$time,
                                       Peak_height = flat_data[[ctrl]]$max_abs, 
                                       Type = "control"))
        }
      }
      
      if(length(ctrl_for_sample) > 0) {
        mean_ctrl <- mean(sapply(ctrl_for_sample, function(c) flat_data[[c]]$max_abs), na.rm = TRUE)
        if(mean_ctrl > 0 && !is.na(mean_ctrl)) {
          rsa <- (mean_ctrl - sample_abs) / mean_ctrl * 100
          
          rsa_df <- rbind(rsa_df, 
                          data.frame(Sample = sample,
                                     Time = sample_time,
                                     Peak_height = sample_abs,
                                     RSA = rsa,
                                     Control = paste(ctrl_for_sample, collapse = ", ")))
        }
      }
    }
    
    for(ctrl in controls) {
      if(!(ctrl %in% peaks_df$Name)) {
        peaks_df <- rbind(peaks_df, 
                          data.frame(Name = ctrl, 
                                     Time = flat_data[[ctrl]]$time,
                                     Peak_height = flat_data[[ctrl]]$max_abs, 
                                     Type = "control"))
      }
    }
    
    if(nrow(rsa_df) > 0) {
      ctrl_summary <- peaks_df %>%
        filter(Type == "control") %>%
        group_by(Time) %>%
        summarise(Control_height = mean(Peak_height, na.rm = TRUE))
      
      summary <- rsa_df %>%
        left_join(ctrl_summary, by = "Time") %>%
        group_by(Time) %>%
        summarise(
          Mean_height = mean(Peak_height, na.rm = TRUE),
          SD_height = sd(Peak_height, na.rm = TRUE),
          Mean_RSA = mean(RSA, na.rm = TRUE),
          SD_RSA = sd(RSA, na.rm = TRUE),
          Control_height = first(Control_height)
        ) %>%
        arrange(Time)
      
      rsa_results(rsa_df)
      summary_results(summary)
      peak_heights(peaks_df)
    }
  })
}