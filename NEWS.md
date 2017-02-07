# **NEWS**

***

## **csmtools 1.4.0-4**

#### *New Features*

A suite of SAS macros to help with the Syndicated Trip Typing

* [finalsupercat1](inst/SAS/read_finalsupercat1.sas)
* [purchfreq](inst/SAS/read_purchfreq.sas)
* [groupfreq](inst/SAS/read_groupfreq.sas)
* [tripmeans](inst/SAS/read_tripmeans.sas)
* [outletfreq](inst/SAS/read_outletfreq.sas)

A function to read tables with accompanying meta tables (as are common output from [dlm_dump.sas](SAS/dlm_dump.sas) SAS macro statements)

* [mread](R/mread.R)

A script to facilitate dropping many hive schemas/tables at once.

* [schema_dropper.sh](inst/bash/schema_dropper.sh)

#### *Minor Fixes*

* Fixed deprecated hive map-reduce parameters in the [hive config script](hive/hive_base_config.hql)
* Fixed the SAS variable length for the data type of the column in the R-meta section of the [dlm_dump.sas](SAS/dlm_dump.sas)
* [dreads](R/dreads.R) now can read hive default tables (automatically replaces unprintable char sep with pipe delim)
* Plot functionality added to [dt_compare](R/dt_compare.R)

***

## **csmtools 1.3.1-4**

#### *New Features*

* A new [read_pstrinfo](inst/SAS/pstrinfo.sas) macro to read the pstrinfo hive table from SAS over a mount
* A new [waitall](inst/bash/helper_functions.sh) bash function to wait for an array of process IDs

#### *Minor Fixes*

* Fixed the hive variable specification in the [hive config script](inst/hive/hive_base_config.hql) to be compatible with Hive 1.2.0
* Changed the printed output of the [convert_secs](inst/bash/helper_functions.sh) bash function
* Changed the delimited for the [read_the_upcs2](inst/SAS/read_the_upcs2.sas) macro

***

## **csmtools 1.3.0**

#### *Major New Features*

* [pamel](R/pamel.R)
* [pamat](R/pamat.R)
* [paman](R/paman.R)
* [make_color](R/make_color.R)
* [gg_color_hue](R/gg_color_hue.R)
* [preview_palette](R/preview_palette.R)

#### **Pasting Matrices**

This family of functions (`paman`, `pamel`, `pamat`) are just wrapping up commonly used paste operations that
are very useful for parsing meatmap/3D visualization hover and help text but
are not concisely implemented in practice.

Element wise pasting of multiple matices, column/row name paste and multiple 
matrix paste functionality are all available. The implementations use R primatives
when possible, but really are convenience functions rather than programming works
of art. That being said I am pretty excited about the `pamen` function which 
was a big "ah-ha!" for non-standard evaluation in R.

The naming comes from concatenating abbreviated versions of the operations that
are being performed:

* paste + matrix + element-wise = pa + m + el = pamel
* paste + matrices = pa + mat = pamat
* paste + matrix + names = paman

#### **Color Functions**

This family of functions is extending some tools that are useful when picking
out colors to use for a palette. The `preview_palette` function is an adaption
from the RColorBrewer package (I think) that allows you to look at hex colors
instead of making sure the datatype matches. This is useful for when we're just 
trying to quickly use color ramp.

The emulator for the ggplot default color scheme is just for fun really, in case
we want to ever match plots from different sources.

The `make_color` function is another convenience function, wrapping up and 
consolidating a lot of menial tasks to make sure incoming colors are actually valid.

***

## **csmtools 1.2.0**

### *Major New Features*

* [dread](R/dread.R)
* [dreads](R/dreads.R)

#### **Directory Reads**

Added the functions `dread` and `dreads` which attempt to elegantly handle bulk
reading of tables that are comprised of a directory of files. These functions
are especially useful when reading Hive tables over a mounted drive.

The `dread` (directory + read = dread) function handles the `data.table::fread` of all files in a directory
to a single R `data.table::data.table`.

The `dreads` (many directories + read = dreads) function handles the read of 
multiple different directories as well as regular files. The usuage is primarily
to read the same table from multiple environments (i.e. versions) with ease. It 
also allows for the specification of patterns, inclusive filters
and combination options to make validation and comparison tasks simpler.

## **csmtools 1.1.0**

### *Major New Features*

* [filter_files](R/filter_files.R)
* [file_size_filter](R/file_size_filter.R)
* [dt_compare](R/dt_compare.R)

#### **File Filtering**

Filtering files in production streams is especially needed when reading the 
directories of Hive tables stored as text files where Map-R reducers may write
empty files that cause `data.table::fread`s to fail. For this reason we introduce
the `file_size_filter` function to allow the user to filter files with intuitive
units (e.g. `B`, `KB`, `GB`, etc.) utilizing the `file.info` utility.

Alternatively, the profiling of files by size is sometimes also useful but is
usually less than intuitive with shell tools. For this reason we introduce the 
`filter_files` function to filter files based on size, optimized for multiple 
specifications to streamline profiling.

#### **Streamlined Comparison**

Iterative comparison of results for validation and/or development is a ubiquitous
requirement for data analysts. While the task may vary from team to team, the 
basic need to merge two tables on a number of variables and difference one or more
columns is universally needed. For this reason we introduce the `dt_compare`
function.

This function allows for the specification of the merge variables, variables to
check, with what precision to check them and any merge specifications
(e.g. inner, outer, left, right) all in one step. It also handles duplicates,
specifically when a `data.table::data.table` may have keys set and is verbose in
its logging, altering users to summary information and row counts -- all with 
an eye to automating the basic sanity checks most analysts make.
