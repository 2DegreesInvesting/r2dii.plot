#' Create a trajectory alignment chart in a ggplot object
#'
#' The function returns a ggplot object containing a stacked bar chart showing a
#' technology mix for different categories (portfolio, scenario, benchmark,
#' etc.).
#'
#' @param data Filtered input data (dataframe with columns: year, metric_type,
#'   metric and value).
#' @param plot_title Title of the plot (character string).
#' @param x_title,y_title Title of the x- and y-axis (character string).
#' @param annotate_data Flag indicating whether the data should be annotated
#'   (boolean).
#' @param scenario_specs_good_to_bad Dataframe containing scenario
#'   specifications like color or label, ordered from the most to least
#'   sustainable (dataframe with columns: scenario, label, color).
#' @param main_line_metric Dataframe containing information about metric that
#'   should be plotted as the main line (dataframe with columns: metric, label).
#' @param additional_line_metrics Dataframe containing information about
#'   additional metrics that should be plotted as lines (dataframe with columns:
#'   metric, label).
#'
#' @export
#' @examples
#' data <- prepare_for_trajectory_chart(
#'   process_input_data(get_example_data()),
#'   sector_filter = "power",
#'   technology_filter = "renewablescap",
#'   region_filter = "global",
#'   scenario_source_filter = "demo_2020",
#'   value_name = "production"
#' )
#'
#' scenario_specs <- dplyr::tibble(
#'   scenario = c("sds", "sps", "cps", "worse"),
#'   color = c("#9CAB7C", "#FFFFCC", "#FDE291", "#E07B73"),
#'   label = c("SDS", "STEPS", "CPS", "worse")
#' )
#'
#' main_line_metric <- dplyr::tibble(metric = "projected", label = "Portfolio")
#'
#' additional_line_metrics <- dplyr::tibble(
#'   metric = "corporate_economy",
#'   label = "Corporate Economy"
#' )
#'
#' plot_trajectory(data,
#'   scenario_specs_good_to_bad = scenario_specs,
#'   main_line_metric = main_line_metric
#' )
plot_trajectory <- function(data,
                            plot_title = "",
                            x_title = "",
                            y_title = "",
                            annotate_data = FALSE,
                            # FIXME: obligatory arguments come before optional
                            scenario_specs_good_to_bad,
                            # FIXME: obligatory arguments come before optional
                            main_line_metric,
                            additional_line_metrics = data.frame()) {
  p_trajectory <- ggplot() +
    theme_2dii_ggplot() +
    coord_cartesian(expand = FALSE, clip = "off") +
    theme(axis.line = element_blank()) +
    xlab(x_title) +
    ylab(y_title) +
    labs(title = plot_title)

  if (annotate_data) {
    p_trajectory <- p_trajectory +
      theme(plot.margin = unit(c(0.5, 4, 0.5, 0.5), "cm"))
  } else {
    p_trajectory <- p_trajectory +
      theme(plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"))
  }

  # adjusting the area border to center the starting point of the lines
  lower_area_border <- min(data$value)
  upper_area_border <- max(data$value)
  value_span <- upper_area_border - lower_area_border

  start_value_portfolio <- data %>%
    filter(.data$year == min(.data$year)) %>%
    filter(.data$metric_type == "portfolio") %>%
    pull(.data$value)

  perc_distance_upper_border <-
    (upper_area_border - start_value_portfolio) / value_span
  perc_distance_lower_border <-
    (start_value_portfolio - lower_area_border) / value_span

  max_delta_distance <- 0.1
  delta_distance <- abs(perc_distance_upper_border - perc_distance_lower_border)
  if (delta_distance > max_delta_distance) {
    if (perc_distance_upper_border > perc_distance_lower_border) {
      lower_area_border <-
        start_value_portfolio - perc_distance_upper_border * value_span
    } else {
      upper_area_border <-
        perc_distance_lower_border * value_span + start_value_portfolio
    }
  }

  year <- unique(data$year)
  data_worse_than_scenarios <- data.frame(year)

  green_or_brown <- r2dii.data::green_or_brown
  tech_green_or_brown <- green_or_brown[
    green_or_brown$technology == data$technology[1],
  ]$green_or_brown

  if (tech_green_or_brown == "brown") {
    scenario_specs <- scenario_specs_good_to_bad

    data_worse_than_scenarios$value <- upper_area_border
    data_worse_than_scenarios$metric <- "worse"

    data_scenarios <- data %>%
      filter(.data$metric_type == "scenario") %>%
      select(.data$year, .data$metric, .data$value)

    data_scenarios <- rbind(data_scenarios, data_worse_than_scenarios) %>%
      group_by(.data$year) %>%
      arrange(.data$year, factor(.data$metric,
        levels = scenario_specs$scenario
      )) %>%
      mutate(value_low = dplyr::lag(.data$value,
        n = 1,
        default = lower_area_border
      ))
  } else if (tech_green_or_brown == "green") {
    scenario_specs <- reverse_rows(scenario_specs_good_to_bad)

    data_scenarios <- data %>%
      filter(.data$metric_type == "scenario") %>%
      select(.data$year, .data$metric, value_low = .data$value)

    data_worse_than_scenarios$value_low <- lower_area_border
    data_worse_than_scenarios$metric <- "worse"

    data_scenarios <- rbind(data_scenarios, data_worse_than_scenarios) %>%
      group_by(.data$year) %>%
      arrange(.data$year, factor(.data$metric,
        levels = scenario_specs$scenario
      )) %>%
      mutate(value = dplyr::lead(.data$value_low,
        n = 1,
        default = upper_area_border
      ))
  }

  for (i in seq_along(scenario_specs$scenario)) {
    scen <- scenario_specs$scenario[i]
    color <- scenario_specs$color[i]
    data_scen <- data_scenarios %>% filter(.data$metric == scen)
    p_trajectory <- p_trajectory +
      geom_ribbon(
        data = data_scen, aes(
          ymin = .data$value_low,
          ymax = .data$value, x = year, group = 1
        ),
        fill = color, alpha = 0.75
      )

    if (scen != "worse") {
      if (tech_green_or_brown == "brown") {
        p_trajectory <- p_trajectory +
          geom_line(
            data = data_scen, aes(x = year, y = .data$value),
            color = color
          )
      } else if (tech_green_or_brown == "green") {
        p_trajectory <- p_trajectory +
          geom_line(
            data = data_scen, aes(x = year, y = .data$value_low),
            color = color
          )
      }
    }

    if (annotate_data) {
      last_year <- max(data$year)

      p_trajectory <- p_trajectory +
        annotate("segment",
          x = last_year, xend = last_year + 0.75,
          y = data_scen[data_scen$year == last_year, ]$value,
          yend = data_scen[data_scen$year == last_year, ]$value,
          colour = color
        ) +
        annotate("text",
          x = (last_year + 0.85),
          (y <- data_scen[data_scen$year == last_year, ]$value),
          label = scenario_specs$label[i], hjust = 0, size = 3
        )
    }
  }

  data_mainline <- data %>% filter(.data$metric == main_line_metric$metric)
  p_trajectory <- p_trajectory +
    geom_line(
      data = data_mainline, aes(x = year, y = .data$value),
      linetype = "solid"
    )

  if (annotate_data) {
    p_trajectory <- p_trajectory +
      annotate("text",
        x = (last_year + 0.1), (
          y <- data_mainline[data_mainline$year == last_year, ]$value
        ),
        label = main_line_metric$label, hjust = 0, size = 3
      )
  }

  if (length(additional_line_metrics) >= 1) {
    linetypes_supporting <- c("dashed", "solid", "solid", "twodash")
    colors_supporting <- c("black", "gray", "grey46", "black")
    for (i in seq_along(additional_line_metrics$metric)) {
      metric_line <- additional_line_metrics$metric[i]
      linetype_metric <- linetypes_supporting[i]
      color_metric <- colors_supporting[i]
      label_metric <- additional_line_metrics$label[i]
      data_metric <- data %>% filter(.data$metric == metric_line)
      p_trajectory <- p_trajectory +
        geom_line(
          data = data_metric, aes(x = year, y = .data$value),
          linetype = linetype_metric, color = color_metric
        )

      if (annotate_data) {
        p_trajectory <- p_trajectory +
          annotate("text",
            x = (last_year + 0.1), (
              y <- data_metric[data_metric$year == last_year, ]$value),
            label = label_metric, hjust = 0, size = 3
          )
      }
    }
  }
  p_trajectory
}

reverse_rows <- function(x) {
  x[sort(rownames(x), decreasing = TRUE), , drop = FALSE]
}