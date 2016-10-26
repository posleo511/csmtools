#' A function to perform a read of a hive table
#'
#' @param table_name A character string, the name of the hive table
#' @param schema A character string, the name of the hive schema
#' @param schema_loc A character string, the directory path of where the schema
#'    is located on the HDFS
#' @param ... Additional arguments to \code{\link{hive_read}}
#' @return A data.table
#' @details Will automatically read all files under the directory after finding
#'    the datatypes and column names from the hive metastore. Note that the
#'    \code{schema} can have a different physical location instead of being forced
#'    to have the \code{schema_loc/schema} naming convention.
#' @import data.table magrittr
#' @examples
#' \dontrun{
#' schema_loc <- "/mapr/mapr03r/analytic_users/msmck/csm_synd_hive_schemas/csm_syndicated/"
#' hread("dictionary", "csm_syndicated", schema_loc)
#' }
#' @export
hread <- function(table_name, schema, schema_loc, ...) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  }

  fn <- file.path(schema_loc, table_name) %>%
    list.files(full.names = TRUE) %>%
    csmtools::filter_empty_files

  if (length(fn) == 0) stop("No files found!")
  writeLines(paste("Found", length(fn), "non-empty files."))

  writeLines("Extracting data types from the Hive metastore...")
  meta <- csmtools::hive_datatypes(schema, table_name)

  writeLines("Attempting read...")

  stack <- lapply(fn, csmtools::hive_read, ...) %>%
    data.table::rbindlist()
  writeLines(paste0("Read a total of ", nrow(stack), " lines."))

  return(stack)
}
