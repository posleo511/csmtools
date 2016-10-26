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
  } else {
    require("data.table")
  }

  if (!requireNamespace("magrittr", quietly = TRUE)) {
    stop("`magrittr` needed for this function to work. Please install it.", call. = FALSE)
  } else {
    # A super crude way to ensure the magrittr pipe works, need to fix once
    # these functions are included in a package by refrencing properly in the namespace
    require("magrittr")
  }

  fqp <- file.path(schema_loc, fp)
  fn_all <- list.files(fqp, full.names = TRUE)
  info <- file.info(fn_all)
  fn <- rownames(info[info$size > 0, ])
  if (length(fn) == 0) stop("No files found!")
  writeLines(paste("Found", length(fn), "files and", nrow(info) - length(fn), "empty files."))
  writeLines("Finding column information from Hive's metastore...")
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

  writeLines("Performing read...")
  hive_read <- function(x) data.table::fread(
      paste0("cat ", x, " | tr '\001' '|'"), sep = "|",  showProgress = TRUE,
      colClasses = dt_types$type, col.names = dt_types$name, na.strings = c("\\N", "NA", ""), ...)

  stack <- lapply(fn, hive_read) %>%
             data.table::rbindlist()
  writeLines(paste0("Read a total of ", nrow(stack), " lines."))

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

dt_compare <- function(x, y, .names = NULL, all = TRUE, suffixes = NULL,
  FUN = `-`, .summary = TRUE, precision = NULL, ...){

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

  xkey <- key(x)
  ykey <- key(y)
  if (!is.null(xkey)) {
    writeLines("Found DT keys for x, removing...")
    setkeyv(x, NULL)
  }
  if (!is.null(ykey)) {
    writeLines("Found DT keys for y, removing...")
    setkeyv(y, NULL)
  }

  dx <- sum(duplicated(x))
  dy <- sum(duplicated(y))
  writeLines(paste(tblx, "has", dx, "duplicates! Rows:", nrx - dx))
  writeLines(paste(tbly, "has", dy, "duplicates! Rows:", nry - dy))

  x <- unique(x)
  y <- unique(y)

  if (is.null(suffixes)) {
    suffixes <- c(".x", ".y")
  }
  
  if (!is.null(.names)) {
    if (any(! .names %in% c(colnames(x), colnames(y)))) {
      stop("Invalid '.names' choice! Not present in one or more sets.")
    }
    if (!is.null(precision)) {
      writeLines(paste("Precision defined, rounding .names to", precision, "places"))
      x[, (.names) := lapply(.SD, round, digits = precision), .SDcols = .names]
      y[, (.names) := lapply(.SD, round, digits = precision), .SDcols = .names]
    }
    
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
  change = NULL, dropnames = NULL, sas_sep = ",", ...) {

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

  chk_hv <- hread(tolower(dsname), schema, schema_loc)

  print(head(chk_hv))

  sfp <- file.path(compare_loc, paste0(dsname, ".dat"))
  sas_head <- colnames(fread(sfp, head = TRUE, nrow = 0))
  hive_class <- lapply(chk_hv, class)
  print(unlist(hive_class))

  sas_class <- unlist(hive_class[match(sas_head, names(hive_class))])

  cclist <- sas_class[!duplicated(names(sas_class))]
  chk_sas <- fread(sfp, na.strings = c("NA", "", "."), colClasses = cclist, sep = sas_sep)
  chk_sas <- chk_sas[, colnames(chk_sas)[!duplicated(colnames(chk_sas))], with = FALSE]

  print(head(chk_sas))
  print(unlist(sas_class))

  hcn <- colnames(chk_hv)
  scn <- colnames(chk_sas)


  shared <- unique(scn[scn %in% hcn], hcn[hcn %in% scn])

  if (!is.null(dropnames)) {
    shared <- shared[! shared %in% dropnames]
    exclude_sas <- paste0("sas.", unique(scn[!scn %in% hcn | scn %in% dropnames]))
    exclude_hive <- paste0("hive.", unique(hcn[!hcn %in% scn | hcn %in% dropnames]))
  } else {
    exclude_sas <- paste0("sas.", scn[!scn %in% hcn])
    exclude_hive <- paste0("hive.", hcn[!hcn %in% scn])
  }

  if (!is.null(checknames)) {
    if (any(checknames %in% c(exclude_sas, exclude_hive))) {
      stop("Invalid 'checknames' choice! Not present in one or more sets.")
    }
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


  nh <- length(exclude_hive)
  ns <- length(exclude_sas)
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



