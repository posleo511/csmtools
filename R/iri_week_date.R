#' A function to derive the week-ending or week-begining date for an IRI week
#'
#' @param x An IRI week
#' @param week_ending A boolean, should we return the date for week-ending (\code{TRUE})
#'     or week-beginning (\code{FALSE})
#'
#' @return A Date
#' @seealso \link{}
#' @examples
#' iri_week_date(1900, week_ending = FALSE)
#' @export
iri_week_date <- function(x, week_ending = TRUE) {
  if (all(is.null(x))) return(NULL)
  vr <- sapply(x, function(x) {
    if (is.null(x)) return(NULL)
    # preserve the missingness of the argument
    if (is.na(x)) return(x)

    return(7* x + 3525)
  }, USE.NAMES = FALSE)

  if (isTRUE(week_ending))
    vr <- vr + 6

  dvr <- as.Date(vr, origin = "1970-01-01")
  return(dvr)
}
