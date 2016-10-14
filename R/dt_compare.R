#' Merge two data.tables and check differences
#'
#' @param x A data.table
#' @param y A data.table
#' @param names The names of the common columns to check
#' @param all Argument to the merge of the dataset
#' @param suffixes Define suffixes for the merge, necessary to know for the comparison
#' @param FUN The comparison function
#' @param dekey Unset the keys (if any) on the data.tables before uniq and/or merge
#' @param dedupe Take only unique rows
#' @param precision The precision with which to use when rounding
#' @param ... Other arguments to `merge`, one of which must be
#'
#' @details The function will merge two data.tables, compare the columns specified with the specified function.
#' @return A data.table
#' @export
#'
#' @examples
#' library("data.table")
#' x <- y <- transform(as.data.table(iris), Id = seq(nrow(iris)))
#'
#' # perturb the values a bit
#' value_vars <- colnames(y)[!colnames(y) %in% c("Species", "Id")]
#' y[, (value_vars) := lapply(.SD, function(x) x + rnorm(length(x), sd = 0.1)), .SDcol = value_vars]
#'
#' # compare absolute differences
#' dt_compare(x, y, names = value_vars, by = "Species")
#' @import data.table magrittr
dt_compare <- function(x, y, cnames = NULL, all = TRUE, suffixes = NULL, dekey = TRUE,
                       FUN = `-`, precision = NULL, dedupe = TRUE, ...){

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  }
browser()
  if (!is.data.table(x)) data.table::setDT(x)
  if (!is.data.table(y)) data.table::setDT(y)

  tblx <- deparse(substitute(x))
  tbly <- deparse(substitute(y))
  nrx <- nrow(x)
  nry <- nrow(y)
  writeLines(paste(tblx, "has", nrx, "rows"))
  writeLines(paste(tbly, "has", nry, "rows"))

  xkey <- key(x)
  ykey <- key(y)
  if (isTRUE(dekey)) {
    if (!is.null(xkey)) {
      writeLines("Found DT keys for x, removing...")
      setkeyv(x, NULL)
    }
    if (!is.null(ykey)) {
      writeLines("Found DT keys for y, removing...")
      setkeyv(y, NULL)
    }
  }

  dx <- sum(duplicated(x))
  dy <- sum(duplicated(y))
  writeLines(paste(tblx, "has", dx, "duplicates! Rows:", nrx - dx))
  writeLines(paste(tbly, "has", dy, "duplicates! Rows:", nry - dy))

  if (isTRUE(dedupe) & any(dx > 0, dy > 0)) {

    writeLines("De-duping the sets...")
    if (any(!is.null(xkey), !is.null(ykey))) {
      warning("Keys set on one or more of the tables, deduping on key only!")
    }

    x <- unique(x)
    y <- unique(y)
  }

  if (is.null(suffixes)) {
    suffixes <- c(".x", ".y")
  }

  if (!is.null(cnames)) {
    if (any(! cnames %in% c(colnames(x), colnames(y)))) {
      stop("Invalid 'colnames' choice! Not present in one or more sets.")
    }
    if (!is.null(precision)) {
      writeLines(paste("Precision defined, rounding colnames to", precision, "places"))
      x[, (cnames) := lapply(.SD, round, digits = precision), .SDcols = cnames]
      y[, (cnames) := lapply(.SD, round, digits = precision), .SDcols = cnames]
    }

  }

  comp <- merge(x, y, all = all, suffixes = suffixes, ...)

  if (netmathtools::is_defined(cnames)) {
    compare_vars <- lapply(suffixes, function(x) paste0(names, x))
  } else return(comp)

  nms <- do.call(paste, c(compare_vars, sep = "_"))
  for (ix in seq(nms)) {
    xnm <- compare.vars[[1]][ix]
    ynm <- compare.vars[[2]][ix]
    nm <- nms[ix]
    dt_reduce(DT = comp, FUN = FUN, NAME = nm, xnm, ynm)
  }

  print(comp[, summary(.SD), .SDcols = (nms)])

  return(comp)
}
