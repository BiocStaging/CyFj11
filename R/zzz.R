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

# Create a package-level environment to store settings
.pkgenv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Initialize verbose to FALSE when package loads
  .pkgenv$verbose <- FALSE
}

#' Set verbose mode
#'
#' Enable or disable verbose output for debugging and monitoring package operations.
#' When enabled, the package will print detailed information about its operations,
#' including file processing, gate conversion, and data extraction steps.
#'
#' @param v Logical. TRUE to enable verbose output, FALSE to disable it
#' @return Invisible NULL. Called for side effects.
#' @export
#' @examples
#' set_verbose(TRUE)
#' set_verbose(FALSE)
set_verbose <- function(v) {
  .pkgenv$verbose <- v
}

#' Get verbose mode
#'
#' Check whether verbose output is currently enabled.
#'
#' @return Logical. TRUE if verbose output is enabled, FALSE otherwise
#' @export
#' @examples
#' \dontrun{
#' # Check current verbose setting
#' is_verbose <- get_verbose()
#' }
get_verbose <- function() {
  .pkgenv$verbose
}
