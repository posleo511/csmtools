#' Extract the R-datatypes for a hive table
#'
#' @inheritParams hread
#' @details For now the functions converts all number-y datatypes like integer,
#'    float, decimal to \code{numeric} and both date and string types to \code{character}.
#' @return A \code{\link[data.table]{data.table}} with columns:
#' \itemize{
#'   \item \code{name} The column name (\code{character})
#'   \item \code{type} The R-datatype (\code{character})
#' }
#' @import data.table magrittr
#' @export
hive_datatypes <- function(schema, table_name) {
  if (!csmtools::has_hive())
    stop("Hive not found! If you're reading over a mount to a hive directory, use `fread` instead.")

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  }

  writeLines("Finding column information from Hive's metastore...")
  dt_types <- paste0("cd; hive -S -e 'describe ", schema, ".", table_name, "'") %>%
    system(intern = TRUE) %>%
    gsub(pattern = " ", replacement = "") %>%
    gsub(pattern = "\t$", replacement = "") %>%
    gsub(pattern = "\t", replacement = "|") %>%
    strsplit(split = "\\|") %>%
    lapply(FUN = as.list) %>%
    data.table::rbindlist()

  data.table::setnames(dt_types, c("name", "type"))
  dt_types[grepl("int|decimal|double|float", type, ignore.case = TRUE), type := "numeric"]
  dt_types[grepl("string|char", type, ignore.case = TRUE), type := "character"]
  dt_types[grepl("time|date", type, ignore.case = TRUE), type := "date"]

  return(dt_types)
}
