#' A function to perform a read of a hive table
#'
#' @param ... A list of objects to test if they are null
#' @param .all Boolean, should we return the tests for each individual element?
#' @details Good for testing an input(s) to a function when it might be NULL
#' @examples
#' foo <- function(x = NULL, y = NULL) {
#'   if (is_defined(x, y)) {
#'     return(paste0(x, y))
#'   } else if (is_defined(x)) {
#'     return(x)
#'   } else if (any(is_defined(x, y, .all = TRUE))) {
#'     return("one is not null")
#'   }
#' }
#' foo(x = 1)
#' foo(x = 1, y = 2)
#' foo(y = 2)
#' @export
is_defined <- function(..., .all = FALSE) {
  rs <- sapply(list(...), function(x) !is.null(x))
  if (!.all) return(all(rs)) else return(rs)
}
