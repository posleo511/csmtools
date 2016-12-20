#' A function to derive the IRI week for the date specified
#'
#' @param x A date or character string
#' @param fmt A date format
#' @param ... Additional arguments to \code{as.Date} including further arguments
#'     to be passed from or to other methods, including \code{format} for
#'     \code{as.character} and \code{as.Date} methods.
#' @return A numeric
#' @seealso \link{iri_week_date}
#' @examples
#' iri_week(Sys.Date())
#' iri_week("Dec. 12, 2016", "%b. %d, %Y")
#' @export
iri_week <- function(x, fmt = "%Y-%m-%d", ...) {
  if (all(is.null(x))) return(NULL)
  sapply(x, function(x) {
    if (is.null(x)) return(NULL)
    # preserve the missingness of the argument as as.numeric(as.Date(...)) below
    # will alter this
    if (is.na(x)) return(x)
    ceiling((as.numeric(as.Date(x, format = fmt, ...)) + 25568) / 7) - 4157
  }, USE.NAMES = FALSE)
}
