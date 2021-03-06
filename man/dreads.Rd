% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dreads.R
\name{dreads}
\alias{dreads}
\title{A function to do multiple directory reads}
\usage{
dreads(envs, pattern, colnames = NULL, filters = NULL, combine_dir = TRUE,
  combine_env = TRUE, ...)
}
\arguments{
\item{envs}{A named list
\itemize{
   \item dir_path A character string sepecifying the path of the directory
   \item hive A boolean, is this a hive table or a regular file
   \item ext Optional, if \code{hive} is \code{FALSE}, specify if only files
       with a certain extension should be read, e.g. \code{.dat} or \code{.csv}.

}}

\item{pattern}{A \link[base]{regex} character string. Only file names which
match the regular expression will be returned.}

\item{colnames}{Any column names for the tables being read in. Note these must
be universal so if any of the tables differ, leave this \code{NULL} and
turn off the \code{combine_*} actions as appropriate}

\item{filters}{Any regex filters to apply, no negation works at this time.
Can be passed as a list or vector}

\item{combine_dir}{A Boolean, collapse the list of data.tables read in from
 each env into a data.table, keeping the file/table names in the
\code{table_name} column?}

\item{combine_env}{A Boolean, collapse the list of data.tables from the
different envs into a data.table, keeping the names of the envs in the
\code{env_name} column?}

\item{...}{Additional arguments to \code{\link[data.table]{fread}}}
}
\value{
A list of data.tables or a data.table
}
\description{
A function to do multiple directory reads
}
\examples{
\dontrun{
# read all walmart trip types from three different environments
# some are hive, some are regular files

wlm_01_envs <- list(
  prd = list(dir_path = file.path(home, "csm_synd_hive_schemas/csm_syndicated")
             , hive = TRUE)
  , dev = list(dir_path = file.path(home, "csm_synd_hive_schemas/csm_syndicated_dev")
               , hive = TRUE)
  , leg = list(dir_path = file.path(home, "dev/trip_typing/legacy_walmart/artifacts")
               , hive = FALSE
               , ext = ".dat")
)

ft <- paste0(1929:1940, collapse = "|")

dreads(wlm_01_envs, "wm_triptypes", filters = ft)
}
}
\seealso{
\link{dread}
}

