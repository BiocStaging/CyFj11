#' Pretty Print FlowJo Workspace
#'
#' This function takes a FlowJo v11 workspace file (.flowjo) and extracts the JSON content,
#' then pretty prints it to a text file with "_pretty.json" suffix.
#'
#' @param flowjo_file Path to the FlowJo workspace file (.flowjo)
#' @return Path to the created pretty printed JSON file
#' @export
#'
#' @examples
#' \dontrun{
#' pretty_print_flowjo("large.mi.flowjo")
#' }
pretty_print_flowjo <- function(flowjo_file) {
  # Check if the file exists
  if (!file.exists(flowjo_file)) {
    stop("File not found: ", flowjo_file)
  }
  
  # Create temporary directory for extraction
  temp_dir <- tempfile(pattern = "flowjo_extract_")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  # Extract the zip file
  unzip_cmd <- paste("unzip", shQuote(flowjo_file), "-d", shQuote(temp_dir))
  system(unzip_cmd)
  
  # Find the analysis JSON file
  json_files <- list.files(file.path(temp_dir, "analyses"), pattern = "\\.json$", recursive = TRUE, full.names = TRUE)
  # browser()
  if (length(json_files) == 0) {
    stop("No JSON files found in the FlowJo workspace")
  }
  
  # Use the first JSON file (assuming there's only one main analysis file)
  json_file <- json_files[1]
  
  json_data <- jsonlite::read_json(json_file, simplifyVector = FALSE)
  
  # Create output file name
  base_name <- sub("\\.flowjo$", "", basename(flowjo_file))
  output_file <- paste0(base_name, "_pretty.json")
  
  # Write the pretty printed JSON to file
  jsonlite::write_json(path = output_file, x = json_data, auto_unbox = TRUE, pretty = TRUE, always_decimal = TRUE)

  cat("Pretty printed JSON saved to:", output_file, "\n")
  
  return(output_file)
}

# Example usage:
# pretty_print_flowjo("large.mi.flowjo")