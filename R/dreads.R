#' A function to do multiple directory reads
#'
#' @param envs A list
#' \itemize{
#'    \item env A character string sepecifying the path of the directory
#'    \item hive A boolean, is this a hive table or a regular file
#'    \item ext Optional, if \code{hive} is \code{FALSE}, specify if only files
#'        with a certain extension should be read, e.g. \code{.dat} or \code{.csv}.
#'
#' }
#' @param pattern A \link[base]{regex} character string. Only file names which
#'    match the regular expression will be returned.
#' @param colnames Any column names for the tables being read in. Note these must
#'    be universal so if any of the tables differ, leave this \code{NULL} and
#'    turn off the \code{combine_*} actions as appropriate
#' @param filters Any regex filters to apply, no negation works at this time.
#'    Can be passed as a list or vector
#' @param combine_dir A Boolean, collapse the list of data.tables read in from
#'     each env into a data.table, keeping the file/table names in the
#'    \code{table_name} column?
#' @param combine_env A Boolean, collapse the list of data.tables from the
#'    different envs into a data.table, keeping the names of the envs in the
#'    \code{env_name} column?
#' @param ... Additional arguments to \code{\link[data.table]{fread}}
#'
#' @return A list of data.tables or a data.table
#' @details directory + reads = dreads, ha!
#' @export
#' @import data.table magrittr
dreads <- function(envs, pattern, colnames = NULL, filters = NULL,
                   combine_dir = TRUE, combine_env = TRUE, ...) {
  dat_list <- sapply(names(envs),
                     function(env) {
                       with(envs[[env]], {
                         dir_paths <- list.files(dir_path, pattern = pattern, full.names = TRUE)

                         # if not a hive table, we're just doing a regular delim
                         # read of all files in the directory
                         if (isTRUE(hive)) {
                           f <- dread
                         } else {
                           f <- data.table::fread
                         }

                         # apply regex filters
                         if (!is.null(filters)) {
                           for (filter in filters) {
                             dir_paths <- dir_paths[grepl(filter, basename(dir_paths))]
                           }
                         }

                         # add extensions if populated to filter out .meta, .log, etc
                         if (exists("ext")) {
                           dir_paths <- dir_paths[grepl(paste0(ext, "$"), basename(dir_paths))]
                           bn <- gsub(ext, "", basename(dir_paths))
                         } else {
                           bn <- basename(dir_paths)
                         }

                         # read the directories
                         dir_sets <- lapply(dir_paths, f, ...)
                         names(dir_sets) <- bn

                         if (isTRUE(combine_dir)) {
                           dir_sets %<>% data.table::rbindlist(idcol = "table_name")
                         }

                         dir_sets
                       })
                     }, USE.NAMES = TRUE, simplify = FALSE) #/ end dat_list sapply

  if (isTRUE(combine_env)) {
    dat_list %<>% data.table::rbindlist(idcol = "env_name")
  }

  return(dat_list)
}


#' Fread all files in a directory
#'
#' @param dir_path A valid directory path
#' @param ... Additional arguments to \code{\link[data.table]{fread}}
#'
#' @return A data table
#' @export
#' @import data.table magrittr
dread <- function(dir_path, ...) {
  paste0("cat ", dir_path, "/*") %>%
    lapply(data.table::fread, ...) %>%
    data.table::rbindlist()
}
