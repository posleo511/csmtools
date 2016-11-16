#' Element-wise paste of a matrix using the column names
#'
#' @param x A matrix, or object able to be coerced to a matric with non-null
#'    dimnames
#' @param ... Arguments to paste
#' @details Works just like a normal \link[base]{paste0} function except the input
#'    is expected to be a matrix and the output will likewise be a matrix. Its
#'    a "paste" for a "matrix" "element" = "pa" + "m" + "el" = "pamel". Helpful
#'    for parsing hovertext for 3D plotly objects.
#' @return A matrix
#' @seealso \link{pamat} \link{pamel}
#' @export
#'
#' @examples
#' m <- matrix(runif(9), nrow = 3, dimnames = list(LETTERS[1:3], LETTERS[4:6]))
#'
#' paman(m, "From: ", y, " to: ", x)
#' paman(m, "From: ", x, " to: ", y)
paman <- function(x, ...) {

  x <- tryCatch(as.matrix(x), error = function(e) FALSE)

  if (identical(x, FALSE))
    stop("Unable to coerce 'x' to a matrix!")

  if (is.null(dimnames(x)))
    stop("dimnames(x) are NULL, have you named your matrix's rows and cols?")

  if (any(sapply(dimnames(x), is.null)))
    warning("One of the row or col names is null for x, this may lead to unexpected results")

  # make a copy of the function call
  mf <- match.call()
  # remove extra args
  mf$x <- NULL
  # the rest of the arguments will be passed to the 'paste0' function
  mf[[1]] <- as.name("paste0")

  f <- function(x, y) eval(mf)
  return(matrix(outer(rownames(x), colnames(x), f), nrow = nrow(x)))
}
