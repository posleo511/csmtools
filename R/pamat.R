#' Element-wise paste of two (or more) matrices with a separator
#'
#' @param ... Matrix objects
#' @param sep A character string, the separator between the element-wise paste
#' @details The matrices will be pasted together in the order in which they are
#'     specified and one separator will be shared used. Its a "paste" for a
#'     "matrix" "element" = "pa" + "m" + "el" = "pamel". Helpful for parsing
#'     hovertext for 3D plotly objects.
#' @return A matrix
#' @seealso \link{pamel} \link{paman}
#' @export
#'
#' @examples
#' caps <- matrix(LETTERS[1:9], nrow = 3)
#' lows <- matrix(letters[1:9], nrow = 3)
#' pamat(caps, lows, sep = " -> ")
pamat <- function(..., sep = " ") {
  args <- list(...)

  if (!all(sapply(args, is.matrix)))
    stop("All arguments must be matrices!")

  n_row <- unique(sapply(args, nrow))
  n_col <- unique(sapply(args, ncol))
  if (length(n_row) > 1 | length(n_col) > 1)
    stop("Incompatible dimensions!")

  f <- function(x, y) paste(x, y, sep = sep)

  return(matrix(Reduce(f, args), nrow = n_row))
}
