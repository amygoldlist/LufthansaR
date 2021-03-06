% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/user_cred.R
\name{add_creds_to_cache}
\alias{add_creds_to_cache}
\title{Store credentials in a cache file}
\usage{
add_creds_to_cache(creds = NULL)
}
\arguments{
\item{creds}{a list generated by a \code{get_creds_from_} function}
}
\description{
When a valid token is available, it is stored in a cache file
for retrieval between R sessions. Care must be taken to ensure this file is
kept confidential. For example, by adding it to a `.gitignore` file.
}
\seealso{
Other token handling functions: \code{\link{add_creds_to_env}},
  \code{\link{get_creds_from_cache}},
  \code{\link{get_creds_from_env}},
  \code{\link{get_creds_from_server}}
}
