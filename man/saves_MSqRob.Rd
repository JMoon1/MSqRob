% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/saves_loads_MSqRob.R
\name{saves_MSqRob}
\alias{saves_MSqRob}
\title{Save the variables of a data.frame in distinct binary files}
\usage{
saves_MSqRob(..., envir = environment(), list = character(), file = NULL,
  overwrite = FALSE, ultra.fast = FALSE, shiny = FALSE,
  printProgress = FALSE, message = NULL)
}
\arguments{
\item{...}{R objects: the names of the objects to be saved (as symbols or character strings)}

\item{list}{character vector: the name(s) of the data frame(s) or list(s) to save}

\item{file}{character vector: the (RDatas) filename(s) in which to save the variables in the current working directory}

\item{overwrite}{boolean: if TRUE, existing files will be deleted before saving. Default set to FALSE, which will report error on conflicting file names.}

\item{ultra.fast}{boolean: if TRUE, ultra fast (...) processing is done without any check to parameters, also no archiving or compression is done. Be sure if using this setting, as many uncompressed files could be generated in the working directory's subdirectory named to df. Only recommended for servers dealing with lot of R objects' saves and loads in a monitored environment.}
}
\value{
The saved filename(s) (invisible).
}
\description{
\code{saves_MSqRob} is almost a pure copy of the \code{saves} function from the \code{saves} package by Dar\'oczi (2013) with some minor code tweaks to make it work for MSqRob. It saves dataframe(s) or list(s) to disk in a special, binary format. This binary format consists of distinct binary files of all separate variables of a dataframe/list merged into an uncompressed tar archive. This is done via a loop, which saves each variable/column to an an external representation of the R objects via save in a temporary directory. These 'RData' files are archived to an 'RDatas' tar archive, uncompressed for better speed.
}
\examples{
## Not run:
## Saving the demo dataset to evs.2000.hun.RDatas in current working directory.
data(evs.2000.hun)
saves_MSqRob(evs.2000.hun)
## Saving both the demo dataset and mtcars to current working directory
saves_MSqRob(evs.2000.hun, mtcars)
saves_MSqRob(list=c('evs.2000.hun', 'mtcars'))
## Saving all kind of cars :)
saves_MSqRob(cars, mtcars, overwrite = TRUE)
saves_MSqRob(list=c('cars', 'mtcars'), overwrite = TRUE)

## End(Not run)
}
\references{
Dar\'oczi, G. (2013). saves: Fast load variables. R package version 0.5, URL http://cran.r-project.org/package=saves
}
\seealso{
Other \code{\link{loads_MSqRob}} to load R objects from RDatas binary format.: \code{\link{inspect_loads_MSqRob}}

Other \code{\link{inspect_loads_MSqRob}} to inspect the content of an RDatas binary object.: \code{\link{loads_MSqRob}}
}
