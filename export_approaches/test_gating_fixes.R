#!/usr/bin/env Rscript

# Test script for gating comparison framework fixes

# Load required libraries
library(tidyverse)
library(flowCore)
library(flowWorkspace)
library(openCyto)
library(ggcyto)
library(gridExtra)
library(RColorBrewer)

# Source the main package
devtools::load_all()

# Test function to check if our fixes work
test_gating_functions <- function() {
  cat("Testing gating functions...\n")
  
  # Create a simple test flowFrame
  # We'll create some mock data for testing
  test_data <- data.frame(
    "FSC-A" = rnorm(1000, 100000, 50000),
    "SSC-A" = rnorm(1000, 50000, 30000),
    "FL1-A" = c(rnorm(500, 1000, 500), rnorm(500, 10000, 2000)),
    check.names = FALSE
  )
  
  # Create a flowFrame
  fr <- flowFrame(as.matrix(test_data))
  
  cat("Created test flowFrame\n")
  
  # Test gate_mindensity with 1D gating
  cat("Testing gate_mindensity 1D...\n")
  tryCatch({
    gate_1d <- gate_mindensity(fr, channel = "FL1-A")
    cat("1D gate_mindensity successful\n")
    cat("Gate class:", class(gate_1d), "\n")
    if (inherits(gate_1d, "rectangleGate")) {
      cat("Gate min:", gate_1d@min, "\n")
      cat("Gate max:", gate_1d@max, "\n")
    }
  }, error = function(e) {
    cat("1D gate_mindensity failed:", e$message, "\n")
  })
  
  # Test gate_flowclust_1d
  cat("Testing gate_flowclust_1d...\n")
  tryCatch({
    gate_fc1d <- gate_flowclust_1d(fr, channel = "FL1-A", K = 2)
    cat("gate_flowclust_1d successful\n")
    cat("Gate class:", class(gate_fc1d), "\n")
    if (inherits(gate_fc1d, "rectangleGate")) {
      cat("Gate min:", gate_fc1d@min, "\n")
    }
  }, error = function(e) {
    cat("gate_flowclust_1d failed:", e$message, "\n")
  })
  
  # Test gate_flowclust_2d
  cat("Testing gate_flowclust_2d...\n")
  tryCatch({
    gate_fc2d <- gate_flowclust_2d(fr, channels = c("FSC-A", "SSC-A"), K = c(2, 2))
    cat("gate_flowclust_2d successful\n")
    cat("Gate class:", class(gate_fc2d), "\n")
    if (inherits(gate_fc2d, "rectangleGate")) {
      cat("Gate min:", gate_fc2d@min, "\n")
      cat("Gate max:", gate_fc2d@max, "\n")
    }
  }, error = function(e) {
    cat("gate_flowclust_2d failed:", e$message, "\n")
  })
  
  cat("Testing completed.\n")
}

# Run the test
test_gating_functions()