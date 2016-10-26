#' Check if the system has hive capabilities
#'
#' @return A boolean
#' @details Checks to see if the hive binaries are in the PATH variable
#' @export
#'
#' @examples
#' if(has_hive()) {
#'     print("yes")
#' } else {
#'     print("no")
#' }
has_hive <- function(){
  hive_exec_path <- tryCatch(system("which hive", intern = TRUE),
                             error = function(e) if (!is.null(e)) return(NULL))

  if (is.null(hive_exec_path)) {
    return(FALSE)
  } else {
    return(TRUE)
  }
}
