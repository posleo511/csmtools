#' Read a Hive table that is stored as a text file
#'
#' @param x A character string, the directory path of the hive table to read
#' @param data_types A character vector, the data types of the columns, in order
#' @param col_names A character vector, the column names, in order
#' @param ... Additional arguments to \code{\link[data.table]{fread}}
#' @details The function allows you to assign your own additional arguments to
#'    fread, but it defaults the separator to pipe ("|") and adds to the
#'    na.string to recognize the hive default.
#' @return A data.table
#' @export
hive_read <- function(x, data_types, col_names, ...) {
  na.strings <- unique(c("\\N", na.strings)) # adding the default hive null
  sep <- ifelse(is.null(sep), "|", sep)
  data.table::fread(paste0("cat ", x, " | tr '\001' '|'"), sep = sep,
                    showProgress = TRUE, colClasses = data_types,
                    col.names = col_names, na.strings = c("\\N", "NA", ""), ...)
}
