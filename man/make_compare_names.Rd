% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/make_compare_names.R
\name{make_compare_names}
\alias{make_compare_names}
\title{Make names for comparing two data sets}
\usage{
make_compare_names(compare, suffixes = c(".x", ".y"), sep = "_")
}
\arguments{
\item{compare}{The column names to compare}

\item{suffixes}{The suffixes for each set to use}

\item{sep}{The separator between the names, the \code{sep} argument to the
\code{\link[base]{paste}} function}
}
\value{
A character vector
}
\description{
Make names for comparing two data sets
}
\examples{
make_compare_names(compare = c("dollars", "units"), suffixes = c(".hive", ".sas"))
}

