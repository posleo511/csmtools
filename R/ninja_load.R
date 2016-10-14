#' Load packages silently
#'
#' @param ... The quoted names of the packages you wish to load with deadly silence
#'
#' @export
#' @examples
#' # load some notoriously loud packages
#' ninja_load("data.table", "bit64")
ninja_load <- function(...) {
  devnull <- sapply(c(...), function(x)
    suppressMessages(library(x, character.only = TRUE)))
}
