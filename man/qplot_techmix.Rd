% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qplot_techmix.R
\name{qplot_techmix}
\alias{qplot_techmix}
\title{Create a quick techmix plot}
\usage{
qplot_techmix(data)
}
\arguments{
\item{data}{A data frame. Requirements:
\itemize{
\item The structure must be like \link{market_share}.
\item The following columns must have a single value: \code{sector}, \code{region},
\code{scenario_source}.
\item The column \code{metric} must have a portfolio (e.g. "projected"), a benchmark
(e.g. "corporate_economy"), and a single \code{scenario} (e.g. "target_sds").
\item (Optional) If present, the column \code{label} is used for data labels.
\item (Optional) If present, the column \code{label_tech} is used for technology
labels.
}}
}
\value{
An object of class "ggplot".
}
\description{
Compared to \code{\link[=plot_techmix]{plot_techmix()}} this function:
\itemize{
\item is restricted to plotting future as 5 years from the start year,
\item outputs pretty bar labels, based on metric column,
\item outputs pretty legend labels, based on technology column,
\item outputs a title.
}
}
\examples{
# `data` must meet documented "Requirements"
data <- subset(
  market_share,
  sector == "power" &
    region == "global" &
    scenario_source == "demo_2020" &
    metric \%in\% c("projected", "corporate_economy", "target_sds")
)

qplot_techmix(data)
}
\seealso{
plot_techmix
}
