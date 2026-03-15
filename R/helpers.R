#' @title Helper Functions for the Package
#' @name helpers
#' @keywords internal
NULL

#' Custom Null Coalescing Operator
#'
#' Provides a null coalescing operator that returns the second argument if the first is NULL.
#'
#' @param x First value to check
#' @param y Second value to return if first is NULL
#' @return Either x if not NULL, or y
#' @keywords internal
#' @examples
#' NULL %||% "default"  # Returns "default"
#' "value" %||% "default"  # Returns "value"
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}





