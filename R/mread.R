#' "Meta-read": Read a file with an accompanying meta file
#'
#' @param filepath The file path of the file to be read
#' @param metafilepath Default NULL, the file path of the meta file. Assumes the
#'     file is in the same directory and has an identical naming convention
#' @param ... Other arguments to \code{\link[data.table]{fread}}
#'
#' @details Silently assigns the meta table to the global environment
#' @return A data.table object
#' @export
#' @import data.table
mread <- function(filepath, metafilepath = NULL, ...) {

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  nm <- tolower(gsub("(.*)\\.(.*)$", "\\1", basename(filepath)))
  if (is.null(metafilepath))
    metafilepath <- gsub("\\.[^\\/]+$", "\\.Rmeta", filepath)

  meta <- data.table::fread(metafilepath, sep = "|",
                            col.names = c("name", "datatype"), header = FALSE)

  assign(paste0(nm, "_meta"), meta, envir = .GlobalEnv)

  data.table::fread(filepath, ..., colClasses = meta$datatype, col.names = meta$name)

}
