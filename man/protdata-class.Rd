% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/protdata.R
\docType{class}
\name{protdata-class}
\alias{protdata-class}
\title{Protein Data Object - class}
\description{
An S4 class for storing the feature- or peptide-level data of a set of LC-MS proteomics experiments, grouped by accession (typically protein accession).
Objects of this class are supplied as an argument to the \code{\link{fit.model}} function.
}
\section{Slots}{

\describe{
\item{\code{accession}}{A factor vector with length \code{k} equal to the total number of accessions (mostly proteins or protein groups) in the data.}

\item{\code{data}}{A list of length \code{k} containing data frames with preprocessed intensity values in a single column and other covariates of interest in the other columns.}
}}

