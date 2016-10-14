#' A function to perform a read of a hive table
#'
#' @param fp The name of the hive table
#' @param schema The name of the hive schema
#' @param schema_loc The directory path of where the schema is located on the HDFS
#' @return A data.table
#' @details Will automatically read all files under the directory after finding
#'    the datatypes and column names from the hive metastore
#' @import data.table magrittr
#' @export
hread <- function(fp, schema, schema_loc, ...) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  }

  fqp <- file.path(schema_loc, fp)
  fn_all <- list.files(fqp, full.names = TRUE)
  info <- file.info(fn_all)
  fn <- rownames(info[info$size > 0, ])
  if (length(fn) == 0) stop("No files found!")
  writeLines(paste("Found", length(fn), "files and", nrow(info) - length(fn), "empty files."))
  writeLines("Finding column information from Hive's metastore...")
  dt_types <- paste0("cd; cd ", schema_loc, ";
                     hive -S -e 'describe ", schema, ".", fp, "'") %>%
    system(intern = TRUE) %>%
    gsub(pattern = " ", replacement = "") %>%
    gsub(pattern = "\t$", replacement = "") %>%
    gsub(pattern = "\t", replacement = "|") %>%
    strsplit(split = "\\|") %>%
    lapply(FUN = as.list) %>%
    data.table::rbindlist()

  setnames(dt_types, c("name", "type"))
  dt_types[grepl("int|decimal|double|float", dt_types$type, ignore.case = TRUE), type := "numeric"]
  dt_types[grepl("string|char", dt_types$type, ignore.case = TRUE), type := "character"]
  dt_types[grepl("time|date", dt_types$type, ignore.case = TRUE), type := "date"]

  writeLines("Performing read...")


  stack <- lapply(fn, netmathtools::hive_read) %>%
    data.table::rbindlist()
  writeLines(paste0("Read a total of ", nrow(stack), " lines."))

  return(stack)
}
