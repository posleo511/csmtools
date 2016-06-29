
iri_week <- function(x, fmt = "%Y-%m-%d") {
  ceiling((as.numeric(as.Date(x, format = fmt)) + 25568)/7) - 4157
}

coalesce <- function(...) {
    Reduce(function(x, y) {
        i <- which(is.na(x))
        x[i] <- y[i]
        x
    }, list(...))
}

gg_color_hue <- function(n) {
  stopifnot(n %% floor(n) == 0 & n > 0)
  hues <- seq(15, 375, length = n + 1)
  hcl(h = hues, l = 65, c = 100)[1:n]
}


list_flatten <- function (x, use.names = TRUE, classes = "ANY")
{
  # Count the number of items
  len <- sum(rapply(x, function(x) 1L, classes = classes))
  y <- vector("list", len)
  i <- 0L

  # Descend into the list, saving each leaf level object in a list
  items <- rapply(x, function(x) {
    i <<- i + 1L

    # Separate processing for single values
    if(is.null(dim(x)) & length(x) == 1){
      y[[i]] <<- x
      return(TRUE)
    } else {
      set <- x

      # Separate processing for vectors
      if (is.null(dim(x)) & length(x) > 1) {
        y[[i]] <<- paste0(set, collapse = ":")
      } else {

        # Separate processing for higher dimensioned objects
        data.table::setDT(set)
        set <- unique(set)
        y[[i]] <<- set[, lapply(.SD, function(x) paste0(x, collapse = ":")),
                       .SDcols = names(set)]
      }
      return(FALSE)
    }

  }, classes = classes)
  if (use.names) {
    names(y) <- names(items)
  }

  return(list(data = y, ind = items))
}


hread <- function(fp, schema, schema_loc) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  } else {
    # A super crude way to ensure the magrittr pipe works, need to fix once
    # these functions are included in a package by refrencing properly in the namespace
    require("magrittr")
  }
  
  fqp <- file.path(schema_loc, fp)
  fn <- list.files(fqp, full.names = TRUE)
  rcn <- paste0("cd; cd ", schema_loc, ";
    hive -S -e 'show columns in ", schema, ".", fp, "'") %>%
    system(intern = TRUE) %>%
    gsub(pattern = " ", replacement = "")

  hive_read <- function(x) data.table::fread(paste0("cat ", x, " | tr '\001' '|'"))
  stack <- lapply(fn, hive_read) %>%
    data.table::rbindlist()

  data.table::setnames(stack, rcn)
  
  return(stack)
}
