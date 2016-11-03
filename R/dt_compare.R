#' Merge and compare columns of data.frames (data.tables)
#'
#' @param x A data.frame
#' @param y A data.frame
#' @param compare A character string or vector of shared column names
#' @param func A binary function to compare the columns with, should be appropriate
#'    for the datatypes of the columns
#' @param precision The precision of the comparison, is the \code{digits}
#'    argument to the \code{\link[base]{round}} function
#' @param ... Any arguments to the \code{\link[data.table]{merge}} function
#'
#' @return A data.frame
#' @import data.table magrittr
#' @examples
#' x <- iris[1:50,]
#' y <- iris[1:60,]
#' x$id <- seq(nrow(x))
#' y$id <- seq(nrow(y))
#' y$Sepal.Width = y$Sepal.Width + rnorm(n = nrow(y))
#'
#' # can specify any arguments to 'merge'
#' res <- dt_compare(x, y, compare = c("Sepal.Width", "Sepal.Length"), by = "id", all.y = TRUE)
#' @export
dt_compare <- function(x, y, compare = NULL, func = `-`, precision = 6, ...){

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  }

  tblx <- deparse(substitute(x))
  tbly <- deparse(substitute(y))

  if (!data.table::is.data.table(x)) data.table::setDT(x)
  if (!data.table::is.data.table(y)) data.table::setDT(y)

  writeLines("\n-- Rows Counts ---------\n")
  nrx <- nrow(x)
  nry <- nrow(y)
  writeLines(paste(tblx, "has", nrx, "rows"))
  writeLines(paste(tbly, "has", nry, "rows"))

  writeLines("\n-- DT Keys -------------\n")
  xkey <- data.table::key(x)
  ykey <- data.table::key(y)
  if (!is.null(xkey)) {
    writeLines(paste0("Found DT keys for", tblx, ", removing..."))
    setkeyv(x, NULL)
  } else {
    writeLines(paste0("No DT keys for ", tblx, "..."))
  }
  if (!is.null(ykey)) {
    writeLines(paste0("Found DT keys for", tbly, ", removing..."))
    setkeyv(y, NULL)
  } else {
    writeLines(paste0("No DT keys for ", tbly, "..."))
  }

  writeLines("\n-- Duplicates ----------\n")
  dx <- sum(duplicated(x))
  dy <- sum(duplicated(y))
  writeLines(paste(tblx, "has", dx, "duplicates! Rows:", nrx - dx))
  writeLines(paste(tbly, "has", dy, "duplicates! Rows:", nry - dy))

  if (dx > 0) x <- unique(x)
  if (dy > 0) y <- unique(y)

  if (!is.null(compare)) {
    if (any(! compare %in% c(colnames(x), colnames(y)))) {
      stop("Invalid 'compare' choice! Not present in one or more sets.")
    }

    if (!is.null(precision)) {


      xclass <- sapply(x, class)
      xrnd <- names(xclass)[xclass == "numeric" & names(xclass) %in% compare]

      yclass <- sapply(y, class)
      yrnd <- names(yclass)[yclass == "numeric" & names(yclass) %in% compare]

      if (length(xrnd) > 0 | length(yrnd) > 0) {
        writeLines("\n-- Precision -----------\n")
      }

      if (length(xrnd) > 0) {
        writeLines(paste0("Rounding ", tblx, " columns: ", paste0(xrnd, collapse = ", ")))
        x[, (xrnd) := lapply(.SD, round, digits = precision), .SDcols = xrnd]
      }

      if (length(yrnd) > 0) {
        writeLines(paste0("Rounding ", tbly, " columns: ", paste0(yrnd, collapse = ", ")))
        y[, (yrnd) := lapply(.SD, round, digits = precision), .SDcols = yrnd]
      }

    }
  }

  comp <- merge(x, y, ...)

  if (!is.null(compare)) {
    if (!exists("suffixes")) suffixes <- c(".x", ".y")
    cv <- csmtools::make_compare_names(compare, suffixes)
  } else return(comp)

  for (ix in seq(length(cv$cnames))) {
    xnm <- cv$xnames[ix]
    ynm <- cv$ynames[ix]
    nm <- cv$cnames[ix]
    comp[, (nm) := csmtools::dt_reduce(DT = comp, FUN = func, xnm, ynm)]
  }
  writeLines("\n-- Summaries -----------\n")
  print(comp[, summary(.SD), .SDcols = (cv$cnames)])

  return(comp)
}
