#' Make names for comparing two data sets
#'
#' @param compare The column names to compare
#' @param suffixes The suffixes for each set to use
#' @param sep The separator between the names, the \code{sep} argument to the
#'    \code{\link[base]{paste}} function
#'
#' @return A character vector
#' @export
#'
#' @examples
#' make_compare_names(compare = c("dollars", "units"), suffixes = c(".hive", ".sas"))
make_compare_names <- function(compare, suffixes = c(".x", ".y"), sep = "_") {
  en <- lapply(suffixes, function(x) paste0(compare, x))
  cv <- do.call(paste, c(en, sep = sep))
  out <- list(
    xnames = en[[1]]
    , ynames = en[[2]]
    , cnames = cv
  )
  return(out)
}
