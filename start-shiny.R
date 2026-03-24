#!/usr/bin/env Rscript

# start-shiny.R - VERSIÓN CORREGIDA
cat("========================================\n")
cat("INICIANDO RSA-UVvis\n")
cat("========================================\n")

# Obtener la ruta del script
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("--file=", args, value = TRUE)
if (length(file_arg) > 0) {
  script_dir <- dirname(sub("--file=", "", file_arg))
} else {
  script_dir <- getwd()
}

cat("📂 Directorio script:", script_dir, "\n")

# La app está en resources/app/
app_dir <- script_dir
cat("📂 App directory:", app_dir, "\n")

# Ruta CORRECTA a las librerías (R-Portable está DENTRO de app_dir)
r_lib_path <- file.path(app_dir, 'R-Portable', 'App', 'R-Portable', 'library')
cat("📚 R library path:", r_lib_path, "\n")

# Verificar que existe
if (!dir.exists(r_lib_path)) {
  stop("❌ No existe carpeta de librerías en: ", r_lib_path)
}

# Establecer .libPaths
.libPaths(c(r_lib_path, .libPaths()))
cat("📚 .libPaths():\n")
print(.libPaths())

# Verificar shiny
if (!require("shiny", character.only = TRUE, quietly = TRUE)) {
  stop("❌ shiny no está instalado en:\n", paste(.libPaths(), collapse = "\n"))
} else {
  cat("✅ shiny encontrado\n")
}

# Cargar librerías
cat("📦 Cargando librerías...\n")
library(shiny)
library(bslib)
library(readr)
library(dplyr)
library(ggplot2)
library(openxlsx)
library(tools)
library(stringr)
library(tidyr)
cat("✅ Librerías cargadas\n")

# Ir a la carpeta shiny
shiny_dir <- file.path(app_dir, 'shiny')
if (!dir.exists(shiny_dir)) {
  stop("❌ No existe carpeta shiny en: ", shiny_dir)
}

setwd(shiny_dir)
cat("📁 Directorio shiny:", getwd(), "\n")

# Verificar archivos
archivos <- c("ui.R", "server.R", "helpers.R")
for (f in archivos) {
  if (file.exists(f)) {
    cat("  ✅", f, "\n")
  } else {
    stop("❌ No se encuentra:", f)
  }
}

# Cargar archivos
cat("🔄 Cargando archivos...\n")
source("helpers.R", local = TRUE)
source("server.R", local = TRUE)
source("ui.R", local = TRUE)

# Verificar UI y server
if (!exists("ui") || !exists("server")) {
  stop("❌ ui o server no definidos")
}

cat("✅ Todo listo. Iniciando app en puerto 8888...\n")
cat("========================================\n")

# Configurar Shiny
options(shiny.port = 8888)
options(shiny.host = "127.0.0.1")

# Iniciar app
shiny::runApp(
  appDir = ".",
  port = 8888,
  host = "127.0.0.1",
  launch.browser = FALSE,
  quiet = FALSE
)