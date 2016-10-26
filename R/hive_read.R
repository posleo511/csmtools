#' Read a Hive table that is stored as a text file
#'
#' @param x A character string, the directory path of the hive table to read
#' @param ... Additional arguments to \code{\link[data.table]{fread}}
#' @details The function allows you to assign your own additional arguments to
#'    fread, but it defaults the separator to pipe ("|") and adds to the
#'    na.string to recognize the hive default.
#' @return A \code{\link[data.table]{data.table}}
#' @export
hive_read <- function(x, ...) {
  na.strings <- unique(c("\\N", na.strings)) # adding the default hive null
  sep <- ifelse(is.null(sep), "|", sep)
  data.table::fread(paste0("cat ", x, " | tr '\001' '|'"), sep = sep,
                    showProgress = TRUE, na.strings = c("\\N", "NA", ""), ...)
}
