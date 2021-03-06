% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/StatisticTest.R
\name{Stat.nonpara}
\alias{Stat.nonpara}
\title{U test (non parameter test) for permutation. This is one probe vs nearby gene 
which is good for computing each probes for nearby genes.}
\usage{
Stat.nonpara(Probe, NearGenes, Top = NULL, Meths = Meths, Exps = Exps)
}
\arguments{
\item{Probe}{A character of name of Probe in array.}

\item{NearGenes}{A list of nearby gene for each probe which is output of GetNearGenes function.}

\item{Top}{A number determines the percentage of top methylated/unmethylated samples.}

\item{Meths}{A matrix contains methylation for each probe (row) and each sample (column).}

\item{Exps}{A matrix contains Expression for each gene (row) and each sample (column).}
}
\value{
U test results
}
\description{
U test (non parameter test) for permutation. This is one probe vs nearby gene 
which is good for computing each probes for nearby genes.
}
