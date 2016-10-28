#' Filter files based on their size
#'
#' @inheritParams filter_files
#'
#' @details Filters out the files that are less than (or less than or equal to)
#'    the size with units specified. If all files are filtered out, then a
#'    character vector of length 0 is returned.
#' @return A character vector
#' @examples
#' x <- list.files(path = Sys.getenv("TEMP"), full.names = TRUE)[1]
#' file_size_filter(x, size = 1, units = "KB")
#' @export
file_size_filter <- function(x, size = 0, units = "B", include = FALSE) {
  if (units == "B") {
    adjsize <- size
  } else if (units == "KB") {
    adjsize <- size * 2^10
  } else if (units == "MB") {
    adjsize <- size * 2^20
  } else if (units == "GB") {
    adjsize <- size * 2^30
  } else
    stop(paste("Invalid 'units' specified:", units))

  if (isTRUE(include)) {
    x[base::file.info(x)$size >= adjsize]
  } else {
    x[base::file.info(x)$size > adjsize]
  }
}
