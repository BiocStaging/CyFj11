# Copyright (c) 2026 Institut Pasteur
# Author: Bernd Jagla
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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
