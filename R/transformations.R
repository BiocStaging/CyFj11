#' @title Transformation Functions for FlowJo v11
#' @name transformations
#' @keywords internal
#' @importFrom flowWorkspace transformerList
#' @importFrom flowCore logicleTransform arcsinhTransform logTransform linearTransform
NULL

#' Extract Transformations from FlowJo v11 Workspace
#'
#' Extracts transformation functions for each channel and sample
#'
#' @param populationDefinitions Population definitions from workspace
#' @param sample_uuids Vector of sample UUIDs
#' @return Named list of transformation lists (one per sample)
#' @details
#' Extracts transformations from parameter specifications in gate definitions.
#' Supports biexponential (Biex) transformations which are mapped to logicle transforms.
#' Transformations are extracted per channel/marker, not per gate.
#' @keywords internal
extract_transformations <- function(populationDefinitions, sample_uuids) {
  
  trans_list <- list()
  
  for (sample_uuid in sample_uuids) {
    # Extract transformation specs from data source
    trans_spec <- extract_transformation_spec(sample_uuid, populationDefinitions)
    
    if (!is.null(trans_spec)) {
      # Convert to flowWorkspace transformation objects
      trans_obj <- create_transformation_list(trans_spec = trans_spec)
      trans_list[[sample_uuid]] <- trans_obj
    }
  }
  # browser()
  return(trans_list)
}


#' Extract Transformation Specification
#' @keywords internal
#' @details
#' Extracts transformation specifications from parameter specifications in gate definitions.
#' Transformations are per marker (channel), not per gate. Supports biexponential (Biex)
#' transformations which are mapped to logicle transforms with appropriate parameters.
extract_transformation_spec <- function(sample_uuid, populationDefinitions) {
  
  # Find the sample's data source
  # In FlowJo v11, transformations are per marker (channel), not per gate
  # We'll look for transformation information in the parameter specifications
  
  # Collect all transformations from parameter specifications
  trans_spec <- list()
  
  for (pop_uuid in names(populationDefinitions)) {
    pop_def <- populationDefinitions[[pop_uuid]]
    
    # Check for sample-specific transformations in desyncTable
    gate_def <- NULL
    if (!is.null(pop_def$definition$desyncTable) &&
        sample_uuid %in% names(pop_def$definition$desyncTable)) {
      gate_def <- pop_def$definition$desyncTable[[sample_uuid]]
    } else if (!is.null(pop_def$definition$gateDefinition)) {
      # Check master gate definition
      gate_def <- pop_def$definition$gateDefinition
    }
    
    if (is.null(gate_def)) next
    
    # Extract transformations from x-axis parameter
    if (!is.null(gate_def$xAxis) && is.list(gate_def$xAxis)) {
      param_spec <- gate_def$xAxis$parameterSpec
      transform_info <- gate_def$xAxis$transform
      
      if (!is.null(param_spec) && !is.null(transform_info)) {
        channel_name <- param_spec$name
        if (!is.null(channel_name) && !(channel_name %in% names(trans_spec))) {
          trans_spec[[channel_name]] <- parse_transformation_info(transform_info)
          trans_spec[[channel_name]]$channel <- channel_name
        }
      }
    }
    
    # Extract transformations from y-axis parameter
    if (!is.null(gate_def$yAxis) && is.list(gate_def$yAxis)) {
      param_spec <- gate_def$yAxis$parameterSpec
      transform_info <- gate_def$yAxis$transform
      
      if (!is.null(param_spec) && !is.null(transform_info)) {
        channel_name <- param_spec$name
        if (!is.null(channel_name) && !(channel_name %in% names(trans_spec))) {
          trans_spec[[channel_name]] <- parse_transformation_info(transform_info)
          trans_spec[[channel_name]]$channel <- channel_name
        }
      }
    }
  }
  
  if (length(trans_spec) == 0) {
    return(NULL)
  }
  
  return(trans_spec)
}


#' Parse Transformation Info
#' @keywords internal
#' @details
#' Parses transformation information from FlowJo v11 transformation specifications.
#' Supports normalization of various transformation type names including biexponential (Biex)
#' which maps to the biexponential type for proper handling.
parse_transformation_info <- function(trans_info) {
  
  # Handle different transformation type names
  trans_type <- trans_info$transformType %||% trans_info$type %||% "linear"
  # Normalize transformation type names
  normalized_type <- switch(trans_type,
                           "Biex" = "biexponential",
                           "biex" = "biexponential",
                           "Log" = "log",
                           "log" = "log",
                           "Linear" = "linear",
                           "linear" = "linear",
                           # "Logicle" = "logicle",
                           # "logicle" = "logicle",
                           # "Arcsinh" = "arcsinh",
                           # "arcsinh" = "arcsinh",
                           # "hyperlog" = "biexponential",  # Replace hyperlog with biexponential
                           trans_type)
  
  # If the transformation type is still not recognized, replace with biexponential
  if (!(normalized_type %in% c("biexponential", "logicle", "arcsinh", "log", "linear"))) {
    warning(paste0("Unknown transformation type '", trans_type, "' replaced with biexponential"))
    normalized_type <- "biexponential"
  }
  
  params <- list(
    type = normalized_type,
    channel = trans_info$channel %||% trans_info$parameter,
    vectorLength <- trans_info$vectorLength %||% 256
  )
  
  # Extract type-specific parameters
  switch(normalized_type,
         # "logicle" = {
         #   browser()
         #   params$w = trans_info[["w"]] %||% trans_info[["W"]] %||% 0.5
         #   params$t = trans_info[["t"]] %||% trans_info[["T"]] %||% 262144
         #   params$m = trans_info[["m"]] %||% trans_info[["M"]] %||% 4.5
         #   params$a = trans_info[["a"]] %||% trans_info[["A"]] %||% 0
         # },
         "biexponential" = {
           # Biex transformation parameters - map to logicle or appropriate transform
           params$t = trans_info[["t"]] %||% trans_info[["T"]] %||% 262144
           params$a = trans_info[["a"]] %||% trans_info[["A"]] %||% 0
           params$m = trans_info[["m"]] %||% trans_info[["M"]] %||% 3.55
           params$w = trans_info[["w"]] %||% trans_info[["W"]] %||% -25.11886
         },
         # "arcsinh" = {
         #   browser()
         #   params$a = trans_info[["a"]] %||% trans_info[["A"]] %||% 0
         #   params$b = trans_info[["b"]] %||% trans_info[["B"]] %||% 1/150
         #   params$c = trans_info[["c"]] %||% trans_info[["C"]] %||% 0
         # },
         "log" = {
           params$base = trans_info[["base"]] %||% trans_info[["Base"]] %||% 10
           params$offset = trans_info[["offset"]] %||% trans_info[["r"]] %||% 1
         },
         "linear" = {
           params$a = trans_info[["a"]] %||% trans_info[["A"]] %||% trans_info[["maxRange"]] %||% 1
           params$b = trans_info[["b"]] %||% trans_info[["B"]] %||% trans_info[["minRange"]] %||% 0
         }
  )
  
  return(params)
}


#' Create Transformation List
#' @keywords internal
#' @importFrom flowWorkspace transformerList
#' @importFrom flowCore logicleTransform arcsinhTransform logTransform linearTransform
#' @details
#' Creates a list of flowCore transformation objects from transformation specifications.
#' Supports biexponential transformations which are mapped to logicle transforms.
create_transformation_list <- function(trans_spec) {
  
  trans_list <- list()
  
  for (channel in names(trans_spec)) {
    spec <- trans_spec[[channel]]
    
    trans_obj <- switch(spec$type,
                        # "logicle" = create_logicle_transform(spec),
                        "biexponential" = create_biexponential_transform(spec),
                        # "arcsinh" = create_arcsinh_transform(spec),
                        "log" = create_log_transform(spec),
                        "linear" = create_linear_transform(spec),
                        NULL)
    
    if (!is.null(trans_obj)) {
      trans_list[[channel]] <- trans_obj
    }
  }
  
  return(trans_list)
}





#' Create Biexponential Transform (FlowJo version)
#' @keywords internal
#' @importFrom flowWorkspace flowjo_biexp_trans
create_biexponential_transform <- function(spec) {
  # browser()
  # Verify spec is provided and is a list
  if (missing(spec) || is.null(spec)) {
    stop("spec argument is required")
  }
  
  if (!is.list(spec)) {
    stop("spec must be a list")
  }
  
  # Define valid arguments (including aliases)
  valid_args <- c(
    # maxValue aliases
    "t", "T", "maxValue",
    # pos aliases
    "m", "M", "pos",
    # widthBasis aliases
    "w", "W", "widthBasis",
    # neg aliases
    "a", "A", "neg",
    # channelRange aliases
    "vectorLength", "channelRange",
    # flowjo_biexp_trans specific arguments
    "n", "equal.space"
  )
  
  # Get arguments present in spec
  spec_args <- names(spec)
  
  # Check for invalid arguments
  invalid_args <- setdiff(spec_args, valid_args)
  
  if (length(invalid_args) > 0) {
    warning(
      "The following arguments are not valid for biexponential transform and will be ignored: ",
      paste(invalid_args, collapse = ", ")
    )
  }
  
  # Extract parameters with aliases and defaults
  maxValue <- spec[["t"]] %||% spec[["T"]] %||% spec[["maxValue"]] %||% 262144
  pos <- spec[["m"]] %||% spec[["M"]] %||% spec$pos %||% 4.5
  widthBasis <- spec$w %||% spec$W %||% spec$widthBasis %||% -10
  neg <- spec[["a"]] %||% spec[["A"]] %||% spec[["neg"]] %||% 0
  channelRange <- spec$vectorLength %||% spec$channelRange %||% 256
  
  # Check for conflicting aliases and warn
  maxValue_params <- c("t", "T", "maxValue")
  if (sum(maxValue_params %in% spec_args) > 1) {
    warning("Multiple aliases for 'maxValue' detected (t/T/maxValue). Using first available.")
  }
  
  pos_params <- c("m", "M", "pos")
  if (sum(pos_params %in% spec_args) > 1) {
    warning("Multiple aliases for 'pos' detected (m/M/pos). Using first available.")
  }
  
  widthBasis_params <- c("w", "W", "widthBasis")
  if (sum(widthBasis_params %in% spec_args) > 1) {
    warning("Multiple aliases for 'widthBasis' detected (w/W/widthBasis). Using first available.")
  }
  
  neg_params <- c("a", "A", "neg")
  if (sum(neg_params %in% spec_args) > 1) {
    warning("Multiple aliases for 'neg' detected (a/A/neg). Using first available.")
  }
  
  channelRange_params <- c("vectorLength", "channelRange")
  if (sum(channelRange_params %in% spec_args) > 1) {
    warning("Multiple aliases for 'channelRange' detected (vectorLength/channelRange). Using first available.")
  }
  
  # Build arguments list for flowJoTrans (via ...)
  flowJoTrans_args <- list(
    channelRange = channelRange,
    maxValue = maxValue,
    pos = pos,
    neg = neg,
    widthBasis = widthBasis
  )
  
  # Extract flowjo_biexp_trans specific arguments
  biexp_args <- list()
  if ("n" %in% spec_args) {
    biexp_args$n <- spec$n
  }
  if ("equal.space" %in% spec_args) {
    biexp_args$equal.space <- spec$equal.space
  }
  
  # Combine all arguments
  all_args <- c(flowJoTrans_args, biexp_args)
 
  # Use flowWorkspace's flowjo_biexp_trans for GatingSet compatibility
  biexpTrans <- do.call(
    flowWorkspace::flowjo_biexp_trans,
    all_args
  )
  
  biexpTrans
}
#' Create Log Transform (scales version)
#' @keywords internal
#' @importFrom flowCore logTransform
create_log_transform <- function(spec) {
  # Verify spec is provided and is a list
  if (missing(spec) || is.null(spec)) {
    stop("spec argument is required")
  }
  
  if (!is.list(spec)) {
    stop("spec must be a list")
  }
  
  # Get valid arguments for flowjo_log_trans
  valid_args <- c("decade", "offset", "scale", "n", "equal.space")
  
  # Get arguments present in spec
  spec_args <- names(spec)
  
  # Check for invalid arguments
  invalid_args <- setdiff(spec_args, valid_args)
  
  if (length(invalid_args) > 0) {
    warning(
      "The following arguments are not valid for flowjo_log_trans and will be ignored: ",
      paste(invalid_args, collapse = ", ")
    )
  }
  
  # Filter spec to only include valid arguments
  valid_spec <- spec[names(spec) %in% valid_args]
  
  # Call flowjo_log_trans with valid arguments only
  fc_trans <- do.call(
    flowWorkspace::flowjo_log_trans,
    valid_spec
  )
  
  fc_trans
}

#' Create Linear Transform
#' @keywords internal
create_linear_transform <- function(spec) {
  # Verify spec is provided and is a list
  if (missing(spec) || is.null(spec)) {
    stop("spec argument is required")
  }
  
  if (!is.list(spec)) {
    stop("spec must be a list")
  }
  
  # Define valid arguments for linear transform
  valid_args <- c("a", "b", "channel")
  
  # # Get arguments present in spec
  # spec_args <- names(spec)
  # 
  # # Check for invalid arguments
  # invalid_args <- setdiff(spec_args, valid_args)
  # 
  # if (length(invalid_args) > 0) {
  #   warning(
  #     "The following arguments are not valid for linear transform and will be ignored: ",
  #     paste(invalid_args, collapse = ", ")
  #   )
  # }
  
  #TODO carry over gateResolution from definition$GateDefinition
  gateResolution =  256 
  # Extract valid parameters with defaults
  a <- spec[["a"]] %||% 1
  b <- spec[["b"]] %||% 0
  channel <- spec$channel %||% "unknown"
  
  # Validate numeric parameters
  if (!is.numeric(a) || length(a) != 1) {
    stop("Parameter 'a' must be a single numeric value")
  }
  
  if (!is.numeric(b) || length(b) != 1) {
    stop("Parameter 'b' must be a single numeric value")
  }
 
  # if (a == 0) {
  #   # browser()
  #   stop("Parameter 'a' cannot be zero (would cause division by zero in inverse)")
  # }
  # it seems that in FlowJo 10 there is no transformation being done, just 
  # for visualization min/maxRange are being used.
  a = 1
  b = 0
  # Create the linear transformation: y = b + a*x
  # Inverse: x = (y - a)/b
  trans_obj = scales::trans_new(
    name = paste0("linear_", channel),
    transform = function(x) b + a * x,
    inverse = function(y) (y - b) / a,
    domain = c(0, gateResolution)  # Add this - input range
  )
  # browser()
  attr(trans_obj, "type") = "linear"
  attr(trans_obj, "parameters") = list(
    minRange = spec[["b"]] %||% 0,
    maxRange = spec[["a"]] %||% 1,
    gateResolution = gateResolution
  )
  attributes(trans_obj)
  trans_obj
}

