#' Filter out file names with non-zero rowcounts
#'
#' @param x A character vector of filenames
#'
#' @return A character vector
#' @export
filter_empty_files <- function(x) {
  info <- file.info(x)
  fn <- rownames(info[info$size > 0, ])
  return(fn)
}
