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
#' \dontrun{
#' # Enable verbose output
#' set_verbose(TRUE)
#'
#' # Disable verbose output
#' set_verbose(FALSE)
#' }
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
