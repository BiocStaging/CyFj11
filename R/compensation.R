#' @title Compensation Functions for FlowJo v11
#' @name compensation
#' @keywords internal
#' @importFrom flowCore compensation
NULL

#' Extract Compensation Matrices from FlowJo v11 Workspace
#'
#' Extracts compensation matrices for each sample, with option to override
#' with custom compensation.
#'
#' @param dataSources Data sources from workspace
#' @param sample_uuids Vector of sample UUIDs
#' @param custom_compensation NULL, or compensation object/matrix/data.frame,
#'   or named list of these (names = sample UUIDs)
#' @return Named list of compensation matrices (one per sample)
#' @keywords internal
#' @importFrom flowCore compensation
extract_compensation <- function(dataSources,
                                 sample_uuids,
                                 custom_compensation = NULL) {
  
  comp_list <- list()
  
  for (sample_uuid in sample_uuids) {
    ds <- dataSources[[sample_uuid]]
    
    # Check for custom compensation first
    if (!is.null(custom_compensation)) {
      if (is.list(custom_compensation) && !is.data.frame(custom_compensation)) {
        # Named list - check if this sample has custom comp
        if (sample_uuid %in% names(custom_compensation)) {
          comp_list[[sample_uuid]] <- validate_compensation(
            custom_compensation[[sample_uuid]]
          )
          next
        }
      } else {
        # Single compensation for all samples
        comp_list[[sample_uuid]] <- validate_compensation(custom_compensation)
        next
      }
    }
    
    # Extract from workspace
    comp_matrix <- extract_workspace_compensation(ds)
    
    if (!is.null(comp_matrix)) {
      comp_list[[sample_uuid]] <- comp_matrix
    } else {
      warning("No compensation found for sample: ", sample_uuid)
    }
  }
  
  return(comp_list)
}


#' Extract Compensation from Data Source
#' @keywords internal
extract_workspace_compensation <- function(ds) {
  
  # FlowJo v11 stores compensation in different places
  comp_data <- NULL
  
  # Check compensationReference
  if (!is.null(ds$compensationReference)) {
    comp_ref <- ds$compensationReference
    # This would reference a compensation definition elsewhere in workspace
    # For now, we'll look for inline compensation
  }
  
  # Check definition$compensation
  if (!is.null(ds$definition$compensation)) {
    comp_data <- ds$definition$compensation
  }
  
  # Check customKeywords for SPILL or SPILLOVER
  if (is.null(comp_data) && !is.null(ds$definition$customKeywords)) {
    kw <- ds$definition$customKeywords
    comp_data <- kw$SPILL %||% kw$SPILLOVER %||% kw$`$SPILLOVER`
  }
  
  if (is.null(comp_data)) {
    return(NULL)
  }
  
  # Parse compensation data
  comp_matrix <- parse_compensation_data(comp_data)
  
  return(comp_matrix)
}


#' Parse Compensation Data
#' @keywords internal
#' @importFrom flowCore compensation
parse_compensation_data <- function(comp_data) {
  
  if (is.matrix(comp_data)) {
    return(flowCore::compensation(comp_data))
  }
  
  if (is.data.frame(comp_data)) {
    return(flowCore::compensation(as.matrix(comp_data)))
  }
  
  if (is.character(comp_data)) {
    # Parse from string format (common in FCS files)
    # Format: "n,channel1,channel2,...,val1,val2,..."
    parts <- strsplit(comp_data, ",")[[1]]
    n <- as.integer(parts[1])
    
    if (length(parts) != (n + n*n + 1)) {
      warning("Invalid compensation string format")
      return(NULL)
    }
    
    channels <- parts[2:(n+1)]
    values <- as.numeric(parts[(n+2):length(parts)])
    
    comp_matrix <- matrix(values, nrow = n, ncol = n, byrow = TRUE)
    rownames(comp_matrix) <- channels
    colnames(comp_matrix) <- channels
    
    return(flowCore::compensation(comp_matrix))
  }
  
  if (is.list(comp_data)) {
    # FlowJo v11 JSON format
    if (!is.null(comp_data$matrix) && !is.null(comp_data$parameters)) {
      matrix_data <- comp_data$matrix
      params <- comp_data$parameters
      
      if (is.list(matrix_data)) {
        matrix_data <- do.call(rbind, matrix_data)
      }
      
      comp_matrix <- as.matrix(matrix_data)
      rownames(comp_matrix) <- params
      colnames(comp_matrix) <- params
      
      return(flowCore::compensation(comp_matrix))
    }
  }
  
  warning("Unrecognized compensation format")
  return(NULL)
}


#' Validate Compensation Object
#' @keywords internal
#' @importFrom flowCore compensation
validate_compensation <- function(comp) {
  
  if (is(comp, "compensation")) {
    return(comp)
  }
  
  if (is.matrix(comp)) {
    if (is.null(rownames(comp)) || is.null(colnames(comp))) {
      stop("Compensation matrix must have row and column names (channel names)")
    }
    return(flowCore::compensation(comp))
  }
  
  if (is.data.frame(comp)) {
    return(flowCore::compensation(as.matrix(comp)))
  }
  
  stop("Invalid compensation object. Must be compensation, matrix, or data.frame")
}