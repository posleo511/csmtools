#' Apply a row-wise Reduce
#' @return A vector
#'
#' @param DT A \code{\link[data.table]{data.table}}
#' @param FUN Any binary function
#' @param ... Quoted column names from DT
#' @details Apply a row-wise reduce for a given function on a set of a data.table's
#'     columns. The main advantage of this function is that names can be passed
#'     to the function as vectors, eliminating the need to hard code differencing,
#'     etc. based on column names. Additionally, the output is specified by the
#'     user -- often we want to perform a calculation and have vector output,
#'     something usaully implemented with an ugly \code{\link{unlist}}.
#' @return Class will vary
#' @examples
#' library("data.table")
#' DT <- as.data.table(head(iris))
#' # basic differencing
#' dt_reduce(DT, `-`, "Sepal.Length", "Sepal.Width")
#'
#' # paste columns together row-wise
#' dt_reduce(DT, paste, colnames(DT))
#'
#' # calculate the mean
#' dt_reduce(DT, `+`, "Sepal.Length", "Sepal.Width", "Petal.Length") / nrow(DT)
#' @import data.table
#' @export
dt_reduce <- function(DT, FUN, ...) {

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  if (!data.table::is.data.table(DT)) stop("'DT' is not a data.table!")

  return(DT[, base::Reduce(FUN, .SD), .SDcols = c(...)])
}
