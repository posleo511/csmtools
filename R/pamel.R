#' Element-wise paste of a matrix
#'
#' @param n The number of rows of the incoming/outgoing matrix
#' @param ... One or more R objects, to be converted to character vectors.
#'    Expecting that this contains the matrix object, but that is not strictly
#'    enforced.
#' @details Works just like a normal \link[base]{paste0} function except the input
#'    is expected to be a matrix and the output will likewise be a matrix. Its
#'    a "paste" for a "matrix" "element" = "pa" + "m" + "el" = "pamel". Helpful
#'    for parsing hovertext for 3D plotly objects.
#' @return A matrix
#' @seealso \link{pamat} \link{paman}
#' @export
#'
#' @examples
#' m <- matrix(runif(9), nrow = 3)
#' pamel(nrow(m), "Value: ", round(m, 4), " units")
pamel <- function(n, ...) matrix(paste0(...), nrow = n)
