
<!-- README.md is generated from README.Rmd. Please edit that file -->

# r2dii.ggplot <a href='https://github.com/2DegreesInvesting/r2dii.ggplot'><img src='https://imgur.com/A5ASZPE.png' align='right' height='43' /></a>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![Codecov test
coverage](https://codecov.io/gh/2DegreesInvesting/r2dii.ggplot/branch/master/graph/badge.svg)](https://codecov.io/gh/2DegreesInvesting/r2dii.ggplot?branch=master)
[![R-CMD-check](https://github.com/2DegreesInvesting/r2dii.ggplot/workflows/R-CMD-check/badge.svg)](https://github.com/2DegreesInvesting/r2dii.ggplot/actions)
<!-- badges: end -->

The goal of r2dii.ggplot is to provide users with plotting and data
processing functions that will allow the users to create standard 2DII
plots using `PACTA_analysis` or banks’ output data as input. The plots
are in the form of ggplot objects.

## Installation

You can install the development version of r2dii.ggplot from
[GitHub](https://github.com/2DegreesInvesting/r2dii.ggplot) with:

``` r
# install.packages("devtools")
devtools::install_github("2DegreesInvesting/r2dii.ggplot")
```

## Examples using example data

This is a basic example usage of `plot_trajectory_chart()`:

``` r
library(r2dii.ggplot)

example_data <- get_example_data()
example_data <- process_input_data(example_data)

data_trajectory <- prepare_for_trajectory_chart(
  example_data, 
  sector_filter = "power", 
  technology_filter = "oilcap",
  region_filter = "global", 
  scenario_source_filter = "demo_2020",
  value_name = "production", 
  end_year_filter = 2025,
  normalize_to_start_year = TRUE
)

scenario_specs <- data.frame(
  scenario = c("sds", "sps", "cps", "worse"),
  color = c("#9CAB7C", "#FFFFCC", "#FDE291", "#E07B73"),
  label = c("SDS", "STEPS", "CPS", "worse")
)

main_line_metric <- data.frame(metric = "projected", label = "Portfolio")
additional_line_metrics <- data.frame(
  metric = "corporate_economy",
  label = "Corporate Economy"
)

plot <- plot_trajectory(data_trajectory,
  plot_title = "Production trajectory of Oil Capacity technology \n in the Power sector",
  x_title = "Year", y_title = "Production rate (normalized to 2020)",
  annotate_data = FALSE,
  scenario_specs_good_to_bad = scenario_specs,
  main_line_metric, additional_line_metrics
)

plot
```

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" style="display: block; margin: auto auto auto 0;" />

This is a basic example usage of `plot_techmix_chart()`:

``` r
example_data <- get_example_data()
example_data <- process_input_data(example_data)

data_techmix_power <- prepare_for_techmix_chart(example_data,
  sector_filter = "power",
  years_filter = c(2020, 2025), region_filter = "global",
  scenario_source_filter = "demo_2020",
  scenario_filter = "sds", value_name = "technology_share"
)

tech_colors_power <- get_r2dii_technology_colours("power")
bars_labels_specs <- data.frame(
  "metric_type" = c(
    "portfolio_2020", "benchmark_2020", "portfolio_2025",
    "benchmark_2025", "scenario_2025"
  ),
  "label" = c(
    "Portfolio 2020", "Benchmark 2020", "Portfolio 2025",
    "Benchmark 2025", "Target SDS 2025"
  )
)

plot_techmix_power <- plot_techmix(data_techmix_power,
  plot_title = "Technology mix for the Power sector",
  show_legend = TRUE,
  tech_colors_power,
  bars_labels_specs
)
plot_techmix_power
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" style="display: block; margin: auto auto auto 0;" />

## Metareport code examples

This is a basic example usage of `plot_metareport_security_types()`
given that you have the `total_portfolio.rda` data set from PACTA
analysis results loaded in your environment:

    data_security_type <- prepare_for_metareport_security_type_chart(data_total_portfolio)

    bars_labels_specs <- data.frame(
      "investor_name" = c("pensionfund", "Meta Investor", "insurance", 
      "bank", "assetmanager"),
      "label" = c("Pension Funds", "Meta Investor", "Insurance", 
      "Banks", "Asset Managers")
    )

    bars_asset_type_specs <- data.frame(
      "asset_type" = c("Equity", "Bonds", "Others"),
      "label" = c("Equity", "Bonds", "Others"),
      "r2dii_colour_name" = c("dark_blue", "moss_green", "grey")
    )

    p <- plot_metareport_security_types(data_security_type, 
                                        bars_asset_type_specs, 
                                        bars_labels_specs)
    p

This is a basic example usage of `plot_metareport_pacta_sectors()` given
that you have the `overview_portfolio.rda` data set from PACTA analysis
results loaded in your environment:

    data_climate_relevant <- prepare_for_pacta_sectors_chart(data_overview)

    bars_labels_climate_rel <- data.frame(
      "investor_name" = c("pensionfund","insurance", "bank", "assetmanager"),
      "label" = c("Pension Funds", "Insurance", "Banks", "Asset Managers")
    )

    plot <- plot_metareport_pacta_sectors(data = data_climate_relevant, 
                                          bars_labels_specs = bars_labels_climate_rel,
                                          plot_title = "Percentage of Asset type Portfolios invested in PACTA sectors")
    plot

These are basic examples of using `plot_metareport_distribution()` given
that you have the `Equity_results_portfolio.rda` or
`Bonds_results_portfolio.rda` data set from PACTA analysis results
loaded in your environment:

    investor_labels <- data.frame(
      "investor_name" = c("assetmanager","bank","insurance","pensionfund"),
      "label" = c("Asset Managers","Banks","Insurance","Pension funds")
    )

    data_distr_br_port <- prepare_for_metareport_distribution_chart(data_equity,
                                                          sectors_filter = "Power",
                                                          technologies_filter = c("CoalCap","OilCap","GasCap"),
                                                          year_filter = 2020,
                                                          value_to_plot = "plan_carsten")

    p_br <- plot_metareport_distribution(data_distr_br_port, 
                                      plot_title = "Percentage of a portfolio invested in brown technologies in the Power sector - Listed Equity",
                                      x_title = "Participants",
                                      y_title = "",
                                      investor_labels = investor_labels)
    p_br

    data_distr_gr_prod <- prepare_for_metareport_distribution_chart(data_equity,
                                                          sectors_filter = "Power",
                                                          technologies_filter = c("RenewablesCap", "HydroCap"),
                                                          year_filter = 2020,
                                                          value_to_plot = "plan_tech_share")

    p_gr <- plot_metareport_distribution(data_distr_gr_prod, 
                                      plot_title = "Percentage share of a low carbon power production - Listed Equity",
                                      x_title = "Participants",
                                      y_title = "",
                                      investor_labels = investor_labels)
    p_gr

These are basic examples of using `plot_metareport_bubble()` given that
you have the `Equity_results_portfolio.rda` or
`Bonds_results_portfolio.rda` data set from PACTA analysis results
loaded in your environment:

    data_bubble <- prepare_for_metareport_bubble_chart(data_equity,
                                                    asset_type = "Equity",
                                                    start_year = 2020,
                                                    technologies_filter = c("RenewablesCap"),
                                                    scenario_filter = "WEO2019_SDS",
                                                    scenario_geography_filter = "GlobalAggregate")

    investor_labels <- data.frame(
      "investor_name" = c("assetmanager","bank","insurance","pensionfund"),
      "label" = c("Asset Managers","Banks","Insurance","Pension funds")
    )

    p <- plot_metareport_bubble(data_bubble,
                                plot_title = "Listed Equity",
                                x_title = "Current share of renewable energy capacity",
                                y_title = "Planned build-out as % of build-out required by SDS",
                                investor_labels = investor_labels,
                                colour_investors = TRUE
                                )
    p
