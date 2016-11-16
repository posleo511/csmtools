#' A function to convert colors to their hex values
#'
#' @param ... A (possibly) mixed-type vector
#'
#' @return A list of hex values or Boolean \code{FALSE} when the element cannot
#'    be interpreted as a color
#' @details A list is returned instead of a vector to avoid the coercion of a
#'    Boolean value to a character one
#' @export
#'
#' @examples
#' make_color(NA, "black", "blackk", 5, "#00", "#000000", "rgb(1, 1, 1, 0.5)")
make_color <- function(...) {
  args <- as.list(c(...))

  if (any(sapply(args, length) > 1))
    stop("Invalid datatype argument! Results in a list with items with length > 1!")

  lapply(args, function(x) {
    if (grepl("^rgb", x)) {
      tryCatch(eval(parse(text = x)),
               error = function(e) FALSE)
    } else {
      tryCatch({
          colMat <- grDevices::col2rgb(x)
          grDevices::rgb(red = colMat[1, ] / 255,
              green = colMat[2, ] / 255,
              blue = colMat[3, ] / 255)
        }, error = function(e) FALSE)
    }
  })
}
