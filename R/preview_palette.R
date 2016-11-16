#' Preview your hex color palatte
#'
#' @param x A vector of hex colors
#' @details Plots a simple image with swaths of the colors specified in the
#'    palatte, in the order in which they are specified
#' @export
#'
#' @examples
#' colfunc <- colorRampPalette(c("white", "dodgerblue"))
#' my_cols <- colfunc(20)
#' preview_palatte(my_cols)
preview_palatte <- function(x) {

  if (is.null(x))
    stop("Argument 'x' is NULL!")

  if (any(is.na(x)))
    warning("One or more colors are NA!")

  cols <- csmtools::make_color(x)
  sel <- sapply(cols, identical, FALSE)
  if (any(sel))
    stop(paste("Not valid colors:", paste0(x[sel], collapse = ", ")))

  ns <- base::seq_along(x)
  graphics::image(ns, 1, base::as.matrix(ns), col = unlist(cols), xlab = "",
        ylab = "", xaxt = "n", yaxt = "n", bty = "n")
  graphics::axis(1, at = ns, labels = x, tick = FALSE, las = 3,
       cex.axis = min(1, 20 / length(x)))
}
