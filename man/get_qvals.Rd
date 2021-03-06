% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/prot_p_adjust.R
\name{get_qvals}
\alias{get_qvals}
\title{Adjust P-values for Multiple Comparisons}
\usage{
get_qvals(pvals, signs, method, threshold_excess1)
}
\arguments{
\item{pvals}{A numeric vector of p-values (possibly with \link{NA}s).}

\item{signs}{A numeric vector containing only -1, 1, 0 and \link{NA}. It indicates the sign of the corresponding T statistics.}

\item{method}{Correction method. Can be abbreviated. Defaults to \code{"fdr"}. To get all available methods, type \code{c("fdrtool", p.adjust.methods)}. For more information on the "fdrtool" method, check out the package \code{fdrtool} by Bernd Klaus and Korbinian Strimmer. For more information on the other methods, see the \code{\link{p.adjust}} function.}

\item{threshold_excess1}{A numeric value between 0 and 1 indicating the threshold at which correcting for an excess in p-values close to 1 should be performed. This is sometimes needed when a null distribution needs to be fitted. Note that the method still accounts for the total number of p-values when performing this correction. Only if there is, according to a binomial test, a significant enrichment of p-values above an automatically determined cut-off at the \code{threshold_excess1} significance level, a correction for enrichment in  p-values close to 1 will be performed. If you never want to correct for an excess in p-values close to 1, set \code{threshold_excess1} to \code{0}. If you always want to correct for an excess in p-values close to 1, set \code{threshold_excess1} to \code{1}. Defaults to \code{1e-90}.}
}
\value{
A data frame containing either one column with corrected p-values, or when \code{method = "fdrtool"}, a data frame with three columns: p-values adjusted for scale and proportion of null values, q-values (FDR) and local fdr.
}
\description{
Given data frame or a vector of p-values, creates a data frame with column(s) containing p-values adjusted using one or more methods.
}
\examples{
.....
}
