#' Extension of base::seq to handle range specification
#'
#' @param range A numeric vector of length two specifying the 'from' and 'to'
#'    arguments to the \code{\link[base]{seq}} function
#' @param ... Other arguments passed to \code{\link[base]{seq}}
#'
#' @return A vector
#' @export
#'
#' @examples
#' seq_(range(1:10), by = 2)
seq_ <- function(range, ...) {
  if (length(range) != 2)
    stop("Invalid range specification")
  seq(from = range[1], to = range[2], ...)
}
