#!/usr/bin/env Rscript

# Script to process a single sample type and population
# Arguments: sample_type, target_population
sample_type = "Innate"
target_population = "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56hi CD16dim NK/CD56hi CD16dim NK_CD8a"
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: Rscript population_plot_single.R <sample_type> <target_population>")
}

sample_type <- args[1]
target_population <- args[2]

message(sample_type)
message(target_population)

library(tidyverse)
library(jsonlite)
library(digest)
library(waldo)
library(flowCore)
library(flowWorkspace)
library(tictoc)
library(CytoML)
library(RProtoBufLib)
library(cytolib)
library(openCyto)
library(ggcyto)
library(ggplot2)
library(gridExtra)
library(grid)
library(CytoExploreR)
library(xml2)
devtools::load_all()

# Environment detection pattern
base_path <- {
  mac_paths <- Sys.glob("/Volumes/scBiomarkers*/bernd")
  if (length(mac_paths) > 0) {
    dirname(mac_paths[1])
  } else {
    "/pasteur/helix/projects/scBiomarkers/bernd"
  }
}

base_data_path <- {
  mac_paths <- Sys.glob("/Volumes/")
  if (length(mac_paths) > 0) {
    mac_paths[1]
  } else {
    setwd("/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/")
    "/pasteur/helix/projects/scBiomarkers/bernd/cytometry"
  }
}



flowjo_root <- file.path(base_data_path, "analysis", "MIV3.01.30.26", "Analysis", sample_type, "Flowjo")
gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
gs_dir = gs_dirs[10]
gs <- load_gs(gs_dir)

sample=sampleNames(gs)[1]
xlim = c(-1000,200000)
ylim = c(-20000,100000)


exclude_keywords <- c("Unstained", "Compensation", "LiveDeadFixableBlue", "Control", "FMO", "Stabilized")

# Process the specific sample type and target population

if(!file.exists(flowjo_root)){
  stop("directory doesn't exist: ", flowjo_root)
}

gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
gs_dirs = gs_dirs[grep("_BJ$", gs_dirs)]


make_pop_names <- function(x) {
  x <- gsub("_", ".", x)                               # 1. replace _ with .
  x <- gsub(" /", "/", x)                             # 2. remove space before /
  x <- gsub("/", "_", x)                              # 3. replace / with _
  x <- trimws(x, which = "right")                     # 4. remove trailing spaces
  x <- gsub("-(?=[a-zA-Z0-9])", ".", x, perl = TRUE)  # 5. - between word parts → .
  x <- gsub("-", "m", x, fixed = TRUE)                # 6. remaining - (negatives) → m
  x <- gsub("+", "p", x, fixed = TRUE)                # 7. replace + with p
  x <- gsub(" ", ".", x)                              # 8. replace spaces with .
  return(x)
}


pdf_file <- file.path(flowjo_root, sprintf("%s_%s_sorted.pdf", sample_type, 
                                           make_pop_names(target_population)))
if(file.exists(pdf_file)) {
  message("already done: ", sample_type, " : ", target_population)
  stop()
}

cat(sprintf("\n========================================\n"))
cat(sprintf("Processing %s - Found %d gatingsets\n", sample_type, length(gs_dirs)))
cat(sprintf("========================================\n"))

# Extract all FlowJo counts once and store in a cache
flowjo_counts_cache <- extract_all_flowjo_counts(gs_dirs = gs_dirs, flowjo_root = flowjo_root, sample_type = sample_type)

all_stats <- list()
all_plot_info <- list()
all_marker_stats <- list()

# STEP 1: Collect statistics and plot info
cat("\nSTEP 1: Collecting data and calculating marker statistics...\n")

# Only process the specific target population for this task
for(gs_dir in gs_dirs){
  cat(sprintf("Loading: %s\n", basename(gs_dir)))
  
  tryCatch({
    gs <- load_gs(gs_dir)
    trans <- cyto_transformer_extract(gs)
    
    pop_counts <- gs_pop_get_count_fast(gs, statistic = "count")
    stats <- pop_counts[pop_counts$Population == target_population,]
    if(nrow(stats) < 1) {
      rm(gs)
      gc()
      next()
    }
    
    stats$sample_name <- pData(gs)$name 
    stats$gs_path <- gs_dir
    
    for(sample_idx in seq_len(nrow(stats))){
      sample_gs = stats$name[sample_idx]
      sample_fcs = stats$sample_name[sample_idx]
      if(should_exclude_sample(sample_gs, exclude_keywords)) {
        cat(sprintf("Skipping excluded sample: %s\n", sample_gs))
        next
      }
      count_val <- stats$Count[stats$name == sample_gs]
      
      # Extract marker statistics
      marker_stats <- extract_marker_stats(gs = gs, sample = sample_gs, population = target_population, trans = trans)
      
      if (!is.null(marker_stats)) {
        all_marker_stats[[length(all_marker_stats) + 1]] <- marker_stats
      }
      
      # Generate unique short name (max 5 characters)
      if(sample_type == "Innate") c1 = "I" else c1 = "A"
      c2 = which(stats$name == sample_gs)
      c3 = sample_idx
      short_name <- sprintf("%s%d:%d", c1, c2, c3)
      all_paths = data.frame(full = gs_get_pop_paths(gs, order = "tsort", path = 'full'))
      all_paths$short = gs_get_pop_paths(gs, order = "tsort",path = 'auto')
      short_pop_path =all_paths[which(all_paths == target_population,arr.ind = T)[1],2]
      
      # Extract FlowJo counts from cache
      flowjo_count <- extract_flowjo_counts(gs_dir = gs_dir, 
                                            sample_name = sample_fcs, 
                                            target_population = target_population,
                                            flowjo_counts_cache =  flowjo_counts_cache)
      
      all_plot_info[[length(all_plot_info) + 1]] <- list(
        gs_path = gs_dir,
        sample = sample_gs,
        sample_fcs = sample_fcs,
        gs_name = basename(gs_dir),
        count = count_val,
        short_name = short_name,
        flowjo_count = flowjo_count,
        sample_type = sample_type,
        short_pop_path = short_pop_path
      )
    }
    
    all_stats[[length(all_stats) + 1]] <- stats
    gs_cleanup_temp(gs)
    rm(gs)
    gc()
    
  }, error = function(e) {
    message(sprintf("Error processing %s: %s", gs_dir, e$message))
  })
}

if(length(all_stats) > 0) {
  # save(file = paste0("afterStep1.",sample_type, ".RData"), list = ls())
  combined_stats <- do.call(rbind, all_stats)
  if(nrow(combined_stats) >= 1) {
    combined_stats <- combined_stats[order(combined_stats$name), ]
    
    # Add short names and FlowJo counts to combined_stats
    # Create a data frame from all_plot_info for merging
    plot_info_df <- do.call(rbind, lapply(all_plot_info, function(x) {
      data.frame(
        sample_name = x$sample,
        short_name = x$short_name,
        flowjo_count = x$flowjo_count,
        count = x$count,
        stringsAsFactors = FALSE
      )
    }))
    
    # Merge with combined_stats
    if (!is.null(plot_info_df) && nrow(plot_info_df) > 0) {
      combined_stats <- merge(combined_stats, plot_info_df, by.x = "name", by.y="sample_name", all.x = TRUE)
    } else {
      combined_stats$short_name <- NA
      combined_stats$flowjo_count <- NA
    }
    
    # Calculate difference between FlowJo count and R count
    combined_stats$count_difference <- combined_stats$flowjo_count - combined_stats$Count
    
    # Sort plot info by sample name
    sample_names <- lapply(all_plot_info, function(x) x$sample_fcs) %>% unlist()
    all_plot_info2 <- all_plot_info[order(sample_names, decreasing = FALSE)]
    
    # STEP 2: Aggregate marker statistics
    cat("\nSTEP 2: Aggregating marker statistics across all samples...\n")
    agg_stats <- aggregate_marker_stats(all_stats_list = all_marker_stats)
    
    if (!is.null(agg_stats)) {
      # Print statistics summary
      cat(sprintf("\n--- Marker Statistics Summary ---\n"))
      cat(sprintf("X-axis (%s):\n", agg_stats$x_channel))
      cat(sprintf("  Global range: [%.2f, %.2f]\n", 
                  agg_stats$x_aggregate$global_min, 
                  agg_stats$x_aggregate$global_max))
      cat(sprintf("  99%% range:    [%.2f, %.2f]\n", 
                  agg_stats$x_aggregate$q01_min, 
                  agg_stats$x_aggregate$q99_max))
      cat(sprintf("  99.9%% range:  [%.2f, %.2f]\n", 
                  agg_stats$x_aggregate$q001_min, 
                  agg_stats$x_aggregate$q999_max))
      if(!is.null(agg_stats$y_aggregate)){
        cat(sprintf("\nY-axis (%s):\n", agg_stats$y_channel))
        cat(sprintf("  Global range: [%.2f, %.2f]\n", 
                    agg_stats$y_aggregate$global_min, 
                    agg_stats$y_aggregate$global_max))
        cat(sprintf("  99%% range:    [%.2f, %.2f]\n", 
                    agg_stats$y_aggregate$q01_min, 
                    agg_stats$y_aggregate$q99_max))
        cat(sprintf("  99.9%% range:  [%.2f, %.2f]\n", 
                    agg_stats$y_aggregate$q001_min, 
                    agg_stats$y_aggregate$q999_max))
      }
      # Choose limits (using 99.9% quantiles to exclude extreme outliers)
      global_xlim <- c(agg_stats$x_aggregate$q001_min, 
                       agg_stats$x_aggregate$q999_max)
      if(!is.null(agg_stats$y_aggregate)){
        global_ylim <- c(agg_stats$y_aggregate$q001_min, 
                       agg_stats$y_aggregate$q999_max)
      } else {
        global_ylim = NULL
      }
      cat(sprintf("\nUsing limits:\n"))
      cat(sprintf("  X: [%.2f, %.2f]\n", global_xlim[1], global_xlim[2]))
      if(!is.null(agg_stats$y_aggregate)){
        cat(sprintf("  Y: [%.2f, %.2f]\n", global_ylim[1], global_ylim[2]))
      }
      # STEP 3: Create PDF with consistent limits
      cat("\nSTEP 3: Creating PDF with plots...\n")
      
      pdf(pdf_file, width = 16, height = 20)
      
      # First page: Summary statistics table
      # grid.newpage()
      # grid.table(head(combined_stats, 30))
      
      # Second page: Marker statistics summary
      # grid.newpage()
      # stats_summary <- data.frame(
      #   Metric = c("X Channel", "X Global Min", "X Global Max", "X 99% Min", "X 99% Max",
      #              "Y Channel", "Y Global Min", "Y Global Max", "Y 99% Min", "Y 99% Max",
      #              "Selected X Min", "Selected X Max", "Selected Y Min", "Selected Y Max"),
      #   Value = c(agg_stats$x_channel,
      #             sprintf("%.2f", agg_stats$x_aggregate$global_min),
      #             sprintf("%.2f", agg_stats$x_aggregate$global_max),
      #             sprintf("%.2f", agg_stats$x_aggregate$q01_min),
      #             sprintf("%.2f", agg_stats$x_aggregate$q99_max),
      #             agg_stats$y_channel,
      #             sprintf("%.2f", agg_stats$y_aggregate$global_min),
      #             sprintf("%.2f", agg_stats$y_aggregate$global_max),
      #             sprintf("%.2f", agg_stats$y_aggregate$q01_min),
      #             sprintf("%.2f", agg_stats$y_aggregate$q99_max),
      #             sprintf("%.2f", global_xlim[1]),
      #             sprintf("%.2f", global_xlim[2]),
      #             sprintf("%.2f", global_ylim[1]),
      #             sprintf("%.2f", global_ylim[2]))
      # )
      # grid.table(stats_summary)
      
      # Plot 8 per page (4 rows x 2 columns)
      plots_per_page <- 8
      n_plots <- length(all_plot_info)
      n_pages <- ceiling(n_plots / plots_per_page)
      for(page in 1:n_pages){
        cat(sprintf("Creating page %d of %d\n", page, n_pages))
        
        dev.control(displaylist = "inhibit")
        
        start_idx <- (page - 1) * plots_per_page + 1
        end_idx <- min(page * plots_per_page, n_plots)
        
        par(mfrow = c(4, 2), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
        
        for(i in start_idx:end_idx){
          plot_info <- all_plot_info[[i]]
          
          tryCatch({
            gs <- load_gs(plot_info$gs_path)
            
            title_text <- sprintf("%s (%s)\nRank: %d/%d | Count: %d | ID: %s\n%s",
                                  plot_info$sample,
                                  plot_info$gs_name,
                                  i, n_plots, plot_info$count, plot_info$short_name,
                                  plot_info$short_pop_path)
            
            plot_with_gate(gs = gs, sample = plot_info$sample, population = target_population, 
                           xlim = global_xlim,
                           ylim = global_ylim,
                           add_title = TRUE, 
                           title_text = title_text)
            gs_cleanup_temp(gs)
            
            rm(gs)
            gc(verbose = FALSE)
            
          }, error = function(e) {
            cat(file = stderr(), str(e))
            plot.new()
            par(mar = c(4, 4, 3, 1))
            plot(1, 1, type = "n", axes = FALSE, xlab = "", ylab = "", main = "")
            text(1, 1, sprintf("Error:\n%s", e$message), col = "red", cex = 0.8)
          })
        }
        
        mtext(sprintf("%s - Page %d/%d", sample_type, page, n_pages), 
              outer = TRUE, cex = 1.5, font = 2)
        
        dev.flush()
      }
      
      dev.off()
      
      cat(sprintf("\nSaved PDF: %s\n", pdf_file))
      
      # Save CSV
      # csv_file <- file.path(flowjo_root, sprintf("%s_%s_stats.csv", sample_type, make.names(target_population)))
      # write.csv(combined_stats, csv_file, row.names = FALSE)
      cat(sprintf("Saved stats: %s\n", csv_file))
    }
  }
}
