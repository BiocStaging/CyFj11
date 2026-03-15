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
#' @name null-coalesce
#' @rdname null-coalesce
#' @keywords internal
#' @examples
#' NULL %||% "default"  # Returns "default"
#' "value" %||% "default"  # Returns "value"
#' @export
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
