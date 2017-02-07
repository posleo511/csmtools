#' Merge and compare columns of data.frames (data.tables)
#'
#' @param x A data.frame
#' @param y A data.frame
#' @param compare A character string or vector of shared column names
#' @param func A binary function to compare the columns with, should be appropriate
#'    for the datatypes of the columns
#' @param round A boolean, should we round at all?
#' @param precision The precision of the comparison, is the \code{digits}
#'    argument to the \code{\link[base]{round}} function
#' @param verbose A boolean, should messages be written to the window?
#' @param plot A boolean, should a summary plot be produced? Requires the loading
#'     of additional packages
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
dt_compare <- function(x, y, compare = NULL, func = `-`, round = TRUE, precision = 6, verbose = TRUE, plot = TRUE, ...){

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

  if (isTRUE(verbose)) writeLines("\n-- Rows Counts ---------\n")
  nrx <- nrow(x)
  nry <- nrow(y)
  if (isTRUE(verbose)) writeLines(paste(tblx, "has", nrx, "rows"))
  if (isTRUE(verbose)) writeLines(paste(tbly, "has", nry, "rows"))

  if (isTRUE(verbose)) writeLines("\n-- DT Keys -------------\n")
  xkey <- data.table::key(x)
  ykey <- data.table::key(y)
  if (!is.null(xkey)) {
    if (isTRUE(verbose)) writeLines(paste0("Found DT keys for", tblx, ", removing..."))
    setkeyv(x, NULL)
  } else {
    if (isTRUE(verbose)) writeLines(paste0("No DT keys for ", tblx, "..."))
  }
  if (!is.null(ykey)) {
    if (isTRUE(verbose)) writeLines(paste0("Found DT keys for", tbly, ", removing..."))
    setkeyv(y, NULL)
  } else {
    if (isTRUE(verbose)) writeLines(paste0("No DT keys for ", tbly, "..."))
  }

  if (isTRUE(verbose)) writeLines("\n-- Duplicates ----------\n")
  dx <- sum(duplicated(x))
  dy <- sum(duplicated(y))
  if (isTRUE(verbose)) writeLines(paste(tblx, "has", dx, "duplicates! Rows:", nrx - dx))
  if (isTRUE(verbose)) writeLines(paste(tbly, "has", dy, "duplicates! Rows:", nry - dy))

  if (dx > 0) x <- unique(x)
  if (dy > 0) y <- unique(y)

  if (!is.null(compare)) {
    if (any(! compare %in% c(colnames(x), colnames(y)))) {
      stop("Invalid 'compare' choice! Not present in one or more sets.")
    }

    if (!is.null(precision) & isTRUE(round)) {


      xclass <- sapply(x, class)
      xrnd <- names(xclass)[xclass == "numeric" & names(xclass) %in% compare]

      yclass <- sapply(y, class)
      yrnd <- names(yclass)[yclass == "numeric" & names(yclass) %in% compare]

      if (length(xrnd) > 0 | length(yrnd) > 0) {
        if (isTRUE(verbose)) writeLines("\n-- Precision -----------\n")
      }

      if (length(xrnd) > 0) {
        if (isTRUE(verbose))
          writeLines(paste0("Rounding ", tblx, " columns: ", paste0(xrnd, collapse = ", ")))
        x[, (xrnd) := lapply(.SD, round, digits = precision), .SDcols = xrnd]
      }

      if (length(yrnd) > 0) {
        if (isTRUE(verbose))
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

  if (isTRUE(verbose)) {
    writeLines("\n-- Summaries -----------\n")
    print(comp[, summary(.SD), .SDcols = (cv$cnames)])
  }

  if (isTRUE(plot)) {
    if (!requireNamespace("dplyr", quietly = TRUE)) {
      stop("`dplyr` needed for this function to work. Please install it.", call. = FALSE)
    }

    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      stop("`ggplot2` needed for this function to work. Please install it.", call. = FALSE)
    }

    if (!requireNamespace("ggthemes", quietly = TRUE)) {
      stop("`ggthemes` needed for this function to work. Please install it.", call. = FALSE)
    }

    if (!requireNamespace("scales", quietly = TRUE)) {
      stop("`scales` needed for this function to work. Please install it.", call. = FALSE)
    }

    good_bad_count <- function(x, precision = 4) {
      n <- length(x)
      good_n <- sum(x, na.rm = TRUE) / n
      na_n <- sum(is.na(x)) / n
      bad_n <- 1 - good_n - na_n

      data.table::data.table(
        type = c("identical", "na", "non-identical"),
        individ = c(good_n, na_n, bad_n),
        cuml = c(1, na_n + bad_n, bad_n))
    }

    calc <- new.env()
    null_dev <- dplyr::select(comp, dplyr::intersect(dplyr::ends_with(".y"), dplyr::contains(".x_"))) %>%
      .[, {assign("plot_dat", lapply(.SD, good_bad_count), envir = calc); NULL}, .SDcols = colnames(.)]

    plotd <- calc$plot_dat %>%
      data.table::rbindlist(idcol = "column") %>%
      transform(
        column = factor(gsub("(.*)\\.x_(.*)\\.y", "\\1", column)),
        type = factor(type, levels = c("identical", "na", "non-identical")),
        individ = round(individ, 4))

    plotd <- plotd[rev(order(type))]

    badd <- plotd[individ > 0 & type %in% c("non-identical", "na")]

    p <- ggplot2::ggplot(plotd, ggplot2::aes(column, individ)) +
      ggplot2::geom_bar(ggplot2::aes(fill = type), stat = "identity") +
      ggplot2::labs(x = "", y = "", fill = "") +
      ggplot2::scale_y_continuous(breaks = scales::pretty_breaks(5),
                                  labels = scales::percent) +
      ggthemes::theme_tufte(ticks = FALSE) +
      ggplot2::geom_errorbar(data = badd,
                             ggplot2::aes(x = column, ymax = cuml, ymin = cuml), colour = "white", lwd = 1) +
      ggplot2::scale_fill_manual(values = c("identical" = "#CCCCCC", "na" = "#999999", "non-identical" = "#666666"))

    rm(calc)

    return(list(comp = comp, p = p))
  } else {
    return(list(comp = comp, p = NULL))
  }

}
