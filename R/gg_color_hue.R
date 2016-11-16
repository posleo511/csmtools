#' Emulate the default ggplot2 color palette
#'
#' @param n The number of colors to produce
#' @param rgb A Boolean, should a \code{rgb(<r>, <g>, <b>)} character string
#'    be returned instead of the hex values?
#' @details An adapted function from John Colby's \link[answer]{http://stackoverflow.com/a/8197703/3034614}
#'    on how to emulate the ggplot2 default color palette, which is just equal
#'    spacing on the color wheel.
#' @return A character vector
#' @export
#'
#' @examples
#' gg_color_hue(5)
#' gg_color_hue(5, rgb = FALSE)
gg_color_hue <- function(n, rgb = TRUE) {
  hues <- seq(15, 375, length = n + 1)
  hout <- hcl(h = hues, l = 65, c = 100)[1:n]
  if (isTRUE(rgb)) {
    lapply(hout, col2rgb) %>%
      lapply(as.vector) %>%
      sapply(function(x) paste0("rgb(", x[1], ",", x[2], ",", x[3], ")"))
  } else {
    return(hout)
  }
}
