#' Filter out file names based on criteria
#'
#' @param x A character vector of filenames
#' @param size A numeric vector, the size of the file
#' @param units A character vector specifying the units. Options are \code{B}
#'    , \code{KB}, \code{MB} and \code{GB}. Must match the length of \code{size}
#'    if specifying more than one unit.
#' @param include A boolean, include files of size \code{size}?
#' @param simplify A boolean, should we create a data.table from the list of output?
#' @details Automatically excludes any non-existant items
#' @return A list or a \code{\link[data.table]{data.table}}
#' @examples
#' # single file size and unit specification
#' x <- list.files(path = Sys.getenv("TEMP"), full.names = TRUE)[1:100]
#' filter_files(x, size = 1, units = "KB")
#'
#' # multiple specifications
#' size <- c(0, rep(1, 4))
#' units <- c("B", "B", "KB", "MB", "GB")
#' res <- filter_files(x, size, units)
#' res$min_file_size <- factor(res$min_file_size, levels = paste(size, units))
#' table(res$min_file_size)
#' @export
filter_files <- function(x, size = 0, units = "B", include = FALSE, simplify = TRUE) {

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  ix <- file.exists(x)
  if (any(!ix)) {
    warning("Some file(s) not found, automatically excluded.")
    x <- x[ix]
  }

  if (length(size) != length(units) & length(units) > 1)
    stop("'size' and 'units' arguments must conform!")

  res <- mapply(file_size_filter, size, units, include, MoreArgs = list(x = x), SIMPLIFY = FALSE)
  names(res) <- paste(size, units)

  if (isTRUE(simplify)) {

    dtlist <- lapply(res, data.table::as.data.table)
    sim_res <- data.table::rbindlist(dtlist, idcol = "min_file_size")
    data.table::setnames(sim_res, "V1", "filename")

    return(sim_res)
  }

  return(res)
}
