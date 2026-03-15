#' CyFj11: Parse and Extract Data from FlowJo v11 Workspace Files
#'
#' The CyFj11 package provides tools to parse FlowJo v11 workspace files (.flowjo)
#' and extract gating information, populations, and associated FCS files.
#'
#' @section Main Functions:
#' The main functions in the package are:
#' \itemize{
#'   \item \code{\link{read_flowjo11_workspace}} - Main function to read and parse FlowJo v11 workspace files
#'   \item \code{\link{fj11_to_gatingset}} - Convert FlowJo v11 workspace to GatingSet object
#'   \item \code{\link{export_flowjo10_workspace}} - Export GatingSet object to FlowJo v10 workspace format
#' }
#'
#' @section File Organization:
#' The package is organized into several modules:
#' \itemize{
#'   \item \code{archive.R} - ZIP extraction functions
#'   \item \code{boolean-gates.R} - Boolean gate computation functions
#'   \item \code{compensation.R} - Compensation extraction and validation functions
#'   \item \code{conversion.R} - Main GatingSet conversion functions
#'   \item \code{file-search.R} - FCS file searching/resolution
#'   \item \code{gates.R} - Gate conversion functions
#'   \item \code{helpers-conversion.R} - Helper functions for conversion
#'   \item \code{helpers.R} - General utility functions
#'   \item \code{populations.R} - Population tree and node functions
#'   \item \code{transformations.R} - Transformation extraction and creation functions
#'   \item \code{export-flowjo10.R} - FlowJo v10 workspace export functions
#' }
#'
#' @section Example Data:
#' The package includes an example FlowJo v11 workspace file for testing and development:
#' \itemize{
#'   \item \code{inst/extdata/test.data.flowjo} - Example FlowJo v11 workspace
#'   \item \code{\link{load_example_workspace}} - Helper function to load the example workspace
#' }
#'
#' @name CyFj11-package
#' @aliases CyFj11
#' @importFrom methods is
#' @importFrom utils read.table
#' NULL
