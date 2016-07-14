.libPaths(c("/mapr/mapr03r/analytic_users/msmck/usr/local/lib/R", .libPaths()))

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

flound <- function(x, digits = 2) floor(x * 10^digits) / 10^digits

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


hread <- function(fp, schema, schema_loc, ...) {
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
  if (length(fn) == 0) stop("No files found!")
  writeLines(paste("Found", length(fn), "files... fread may or may not print for all"))
  dt_types <- paste0("cd; cd ", schema_loc, ";
    hive -S -e 'describe ", schema, ".", fp, "'") %>%
    system(intern = TRUE) %>%
    gsub(pattern = " ", replacement = "") %>%
    gsub(pattern = "\t$", replacement = "") %>%
    gsub(pattern = "\t", replacement = "|") %>%
    strsplit(split = "\\|") %>%
    lapply(FUN = as.list) %>%
    data.table::rbindlist()

  setnames(dt_types, c("name", "type"))
  dt_types[grepl("int|decimal|double|float", dt_types$type, ignore.case = TRUE), type := "numeric"]
  dt_types[grepl("string|char", dt_types$type, ignore.case = TRUE), type := "character"]
  dt_types[grepl("time|date", dt_types$type, ignore.case = TRUE), type := "date"]

  hive_read <- function(x) data.table::fread(
      paste0("cat ", x, " | tr '\001' '|'"), sep = "|",  showProgress = TRUE,
      colClasses = dt_types$type, col.names = dt_types$name, ...)
  stack <- lapply(fn, hive_read) %>%
    data.table::rbindlist()

  return(stack)
}

is.defined <- function(..., .all = FALSE) {
  rs <- sapply(list(...), function(x) !is.null(x))
  if (.all) return(all(rs)) else return(rs)
}

dt_reduce <- function(DT, FUN, NAME, ...) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  } else {
    # A super crude way to ensure the data.table .() works, need to fix once
    # these functions are included in a package by refrencing properly in the namespace
    require("data.table")
  }
  if (!is.data.table(DT)) stop("'DT' is not a data.table!")
  COLNAMES <- c(...)
  DT[, (NAME) := Reduce(FUN, .SD), .SDcols = (COLNAMES)]
}

dt_compare <- function(x, y, .names = NULL, names_x = NULL, names_y = NULL,
  all = TRUE, suffixes = NULL, FUN = `-`, .summary = TRUE, ...){

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  } else {
    # A super crude way to ensure the data.table .() works, need to fix once
    # these functions are included in a package by refrencing properly in the namespace
    require("data.table")
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  } else {
    # A super crude way to ensure the magrittr pipe works, need to fix once
    # these functions are included in a package by refrencing properly in the namespace
    require("magrittr")
  }

  if (!is.data.table(x)) data.table::setDT(x)
  if (!is.data.table(y)) data.table::setDT(y)

  tblx <- deparse(substitute(x))
  tbly <- deparse(substitute(y))
  nrx <- nrow(x)
  nry <- nrow(y)
  writeLines(paste(tblx, "has", nrx, "rows"))
  writeLines(paste(tbly, "has", nry, "rows"))

  dx <- sum(duplicated(x))
  dy <- sum(duplicated(y))
  writeLines(paste(tblx, "has", dx, "duplicates! Rows:", nrx - dx))
  writeLines(paste(tbly, "has", dy, "duplicates! Rows:", nry - dy))

  x <- unique(x)
  y <- unique(y)

  if (is.null(suffixes)) {
    suffixes <- c(".x", ".y")
  }

  comp <- merge(x, y, all = all, suffixes = suffixes, ...)

  if (is.defined(.names)) {
    compare.vars <- lapply(suffixes, function(x) paste0(.names, x))
  } else return(comp)

  nms <- do.call(paste, c(compare.vars, sep = "_"))
  for (ix in seq(nms)) {
    xnm <- compare.vars[[1]][ix]
    ynm <- compare.vars[[2]][ix]
    nm <- nms[ix]
    dt_reduce(DT = comp, FUN = FUN, NAME = nm, xnm, ynm)
  }

  print(comp[, summary(.SD), .SDcols = (nms)])
  return(comp)
}


sas_hive_compare <- function(dsname, schema, schema_loc, compare_loc, 
  checknames = NULL, charnames = NULL, numnames = NULL, precision = 2, 
  change = NULL, ...) {

  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("`data.table` needed for this function to work. Please install it.", call. = FALSE)
  } else {
    # A super crude way to ensure the data.table .() works, need to fix once
    # these functions are included in a package by refrencing properly in the namespace
    require("data.table")
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  } else {
    # A super crude way to ensure the magrittr pipe works, need to fix once
    # these functions are included in a package by refrencing properly in the namespace
    require("magrittr")
  }
  
  chk_hv <- hread(tolower(dsname), schema, schema_loc,
                  na.strings = c("", "NA", "\\N"))
                  
  print(head(chk_hv))
  
  sfp <- file.path(compare_loc, paste0(dsname, ".csv"))
  sas_head <- colnames(fread(sfp, head = TRUE, nrow = 0))
  hive_class <- lapply(chk_hv, class)
  print(unlist(hive_class))

  sas_class <- unlist(hive_class[match(sas_head, names(hive_class))])
  
  cclist <- sas_class[!duplicated(names(sas_class))]
  chk_sas <- fread(sfp, na.strings = c("NA", "", "."), colClasses = cclist)
  chk_sas <- chk_sas[, !duplicated(colnames(chk_sas)), with = FALSE]

  print(head(chk_sas))
  print(unlist(sas_class))
  
  hcn <- colnames(chk_hv)
  scn <- colnames(chk_sas)

  if (!is.null(checknames)) {
    chk_sas[, (checknames) := lapply(.SD, round, digits = precision), .SDcols = checknames]
    chk_hv[, (checknames) := lapply(.SD, round, digits = precision), .SDcols = checknames]
  }
  
  if (!is.null(charnames)) {
    chk_sas[, (charnames) := lapply(.SD, as.character), .SDcols = charnames]
    chk_hv[, (charnames) := lapply(.SD, as.character), .SDcols = charnames]
  }
  
   if (!is.null(numnames)) {
    chk_sas[, (numnames) := lapply(.SD, as.numeric), .SDcols = numnames]
    chk_hv[, (numnames) := lapply(.SD, as.numeric), .SDcols = numnames]
  }

  shared <- unique(scn[scn %in% hcn], hcn[hcn %in% scn])
  exclude_sas <- paste0("sas.", scn[!scn %in% hcn])
  exclude_hive <- paste0("hive.", hcn[!hcn %in% scn])

  nh <- length(hcn[!hcn %in% scn])
  ns <- length(scn[!scn %in% hcn])
  if (ns > 0 & nh > 0) {
    writeLines(paste("Excluding:", paste0(c(exclude_sas, exclude_hive), collapse = ", ")))
  } else if (ns > 0 & nh == 0) {
    writeLines(paste("Excluding:", paste0(exclude_sas, collapse = ", ")))
  } else if (ns == 0 & nh > 0) {
    writeLines(paste("Excluding:", paste0(exclude_hive, collapse = ", ")))
  }
  
  if (is.null(checknames)) {
    writeLines(paste("Merging on:", paste0(shared, collapse = ", ")))

    mh <- chk_hv[, shared, with = FALSE]
    ms <- chk_sas[, shared, with = FALSE]
    
    res <- dt_compare(
      mh, ms,
      by = shared,
      suffixes = c(".hv", ".sas"), ...)
  } else {
    writeLines(paste("Merging on:", paste0( shared[!shared %in% checknames], collapse = ", ")))
    res <- dt_compare(
      chk_hv[, shared, with = FALSE],
      chk_sas[, shared, with = FALSE],
      by = shared[!shared %in% checknames],
      .names = checknames,
      suffixes = c(".hv", ".sas"), ...)
  }
  writeLines(paste("Result set has", nrow(res), "rows"))
  return(res)
}



