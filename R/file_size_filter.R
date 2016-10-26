#' Filter files based on their size
#'
#' @inheritParams filter_files
#'
#' @return A character vector
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
    x[base::file.size(x) >= adjsize]
  } else {
    x[base::file.size(x) > adjsize]
  }
}
