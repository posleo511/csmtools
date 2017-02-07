#' Make a upc form component parts
#'
#' @param sys A vector that can be coerced to integer
#' @param gen A vector that can be coerced to integer
#' @param ven A vector that can be coerced to integer
#' @param ite A vector that can be coerced to integer
#' @param format A character string with the four letters "s", "g", "v", and "i"
#'    arranged in the desired format of the outout, e.g. 'svig'
#'
#' @return A character vector
#' @export
#' @import data.table
#'
#' @examples
#' set.seed(1)
#' sys <- rep(0, 5)
#' gen <- rep(1, 5)
#' ven <- sample(10000:99999, 5)
#' ite <- sample(10000:99999, 5)
#' make_upc(sys, gen, ven, ite, format = "sgiv")
make_upc <- function(sys, gen, ven, ite, format = "sgvi") {

  # pad the components
  sys <- formatC(as.integer(sys), width = 2, format = "d", flag = "0")
  gen <- as.integer(gen)
  ven <- formatC(as.integer(ven), width = 5, format = "d", flag = "0")
  ite <- formatC(as.integer(ite), width = 5, format = "d", flag = "0")

  hold <- list(sys, gen, ven, ite)

  # figure out the format specified
  fmt <- unlist(strsplit(format, ""))

  # qc the format specified
  invalid_chars <- any(!fmt %in% c("s", "g", "v", "i"))
  if (invalid_chars)
    stop("Invalid characters present in 'format', use only 's', 'g', 'v' and 'i' once each.")

  invalid_freq <- any(table(fmt) > 1)
  if (invalid_freq)
    stop("Invalid frequency of guide letters present in 'format', use only 's', 'g', 'v' and 'i' once each.")

  fmt_order <- match(fmt, c("s", "g", "v", "i"))

  frame <- data.table::as.data.table(hold[fmt_order])
  return(csmtools::dt_reduce(frame, paste0, colnames(frame)))
}

#' Split up a character UPC
#'
#' @param upc A character vector
#' @param format A character string with the four letters "s", "g", "v", and "i"
#'    arranged in the format of the input upc, e.g. 'svig'
#' @param convert A boolean, should the final component pieces be converted to
#'     numeric?
#'
#' @return A named list of the component pieces
#' @export
#'
#' @examples
#' upcs <- c("0000790350211", "0007403067401", "0010248198421")
#' split_upc(upcs, format = "svig", convert = TRUE)
split_upc <- function(upc, format = "sgvi", convert = FALSE) {

  if (any(nchar(upc) != 13))
    stop("Invalid UPC length, only defined for use with 13-digit UPCs")

  # figure out the format specified
  fmt <- unlist(strsplit(format, ""))

  # qc the format specified
  invalid_chars <- any(!fmt %in% c("s", "g", "v", "i"))
  if (invalid_chars)
    stop("Invalid characters present in 'format', use only 's', 'g', 'v' and 'i' once each.")

  invalid_freq <- any(table(fmt) > 1)
  if (invalid_freq)
    stop("Invalid frequency of guide letters present in 'format', use only 's', 'g', 'v' and 'i' once each.")

  fmt_order <- match(fmt, c("s", "g", "v", "i"))

  nms <- c("sys", "gen", "ven", "ite")[fmt_order]
  lns <- c(2, 1, 5, 5)[fmt_order]

  i <- 1
  start <- end <- vector()
  for (k in lns) {
    start <- c(start, i)
    end <- c(end, k + i - 1)
    i <- i + k
  }

  names(start) <- names(end) <- nms
  if (isTRUE(convert)) {
    f <- function(x, y) as.integer(substr(upc, start = x, stop = y))
  } else {
    f <- function(x, y) substr(upc, start = x, stop = y)
  }

  return(mapply(f, start, end, SIMPLIFY = FALSE))
}
