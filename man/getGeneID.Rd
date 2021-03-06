% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methodAccess.R
\name{getGeneID}
\alias{getGeneID}
\title{getGeneID to report gene id from symbol}
\usage{
getGeneID(data, symbol)
}
\arguments{
\item{data}{A multiAssayExperiment with DNA methylation and Gene Expression data. See \code{\link{createMAE}} function.}

\item{symbol}{A vector of characters which are gene symbols}
}
\value{
The gene ID for these gene symbols
}
\description{
getGeneID to report gene id from symbol
}
\examples{
data <- ELMER:::getdata("elmer.data.example")
getGeneID(data, symbol="ZNF697")
}
