#' Create a techmix plot
#'
#' @param data A data frame. Requirements:
#'   * The structure must be like [market_share].
#'   * The following columns must have a single value: `sector`, `region`,
#'   `scenario_source`.
#'   * The column `metric` must have a portfolio (e.g. "projected"), a benchmark
#'   (e.g. "corporate_economy"), and a single `scenario` (e.g. "target_sds").
#'   * (Optional) If present, the column `label` is used for data labels.
#'   * (Optional) If present, the column `label_tech` is used for technology
#'   labels.
#'
#' @seealso [market_share].
#'
#' @return An object of class "ggplot".
#'
#' @export
#' @examples
#' # `data` must meet documented "Requirements"
#' data <- subset(
#'   market_share,
#'   scenario_source == "demo_2020" &
#'     sector == "power" &
#'     region == "global" &
#'     metric %in% c("projected", "corporate_economy", "target_sds")
#' )
#'
#' plot_techmix(data)
plot_techmix <- function(data) {
  check_plot_techmix(data)

  prep <- prep_techmix(data)
  plot_techmix_impl(prep)
}

check_plot_techmix <- function(data, env = parent.frame()) {
  stopifnot(is.data.frame(data))
  crucial <- c(common_crucial_market_share_columns(), "technology_share")
  hint_if_missing_names(abort_if_missing_names(data, crucial), "market_share")
  abort_if_has_zero_rows(data, env = env)
  enforce_single_value <- c("sector", "region", "scenario_source")
  abort_if_multiple(data, enforce_single_value, env = env)
  abort_if_multiple_scenarios(data, env = env)

  invisible(data)
}

abort_if_multiple_scenarios <- function(data, env = parent.frame()) {
  .data <- deparse_1(substitute(data, env = env))

  scen <- extract_scenarios(data$metric)
  n <- length(scen)

  if (n == 0L) {
    abort(c(
      glue("`{.data}$metric` must have one scenario."),
      x = "It has none."
    ))
  }

  if (n > 1L) {
    example <- c(setdiff(unique(data$metric), scen), first(scen))
    abort(c(
      glue("`{.data}$metric` must have a single scenario not {n}."),
      i = glue(
        "Do you need to pick one scenario? E.g. pick '{first(scen)}' with: \\
        `subset({.data}, metric %in% {fmt_vector(fmt_string(example))})`."
      ),
      x = glue("Provided: {toString(scen)}.")
    ))
  }

  invisible(data)
}

prep_techmix <- function(data,
                         convert_label = identity,
                         span_5yr = FALSE,
                         convert_tech_label = identity) {
  out <- data %>%
    prep_common() %>%
    add_label_tech_if_missing() %>%
    mutate(
      value = .data$technology_share,
      sector = recode_sector(.data$sector),
      label = convert_label(.data$label),
      label_tech = convert_tech_label(.data$label_tech)
    )

  if (span_5yr) {
    out <- span_5yr(out)
  }

  start_year <- min(out$year)
  future_year <- max(out$year)
  if (!quiet()) {
    .data <- deparse_1(substitute(data, env = parent.frame()))
    inform(glue(
      "The `technology_share` values are plotted for extreme years.
       Do you want to plot different years? E.g. filter {.data} with:\\
       `subset({.data}, year %in% c(2020, 2030))`."
    ))
  }
  out <- out %>%
    filter(.data$year %in% c(start_year, future_year))
  out
}

plot_techmix_impl <- function(data) {
  colours <- get_technology_colours(data)
  labels <- techmix_labels(data)

  ggplot(
    data = data,
    aes(
      x = factor(.data$label, levels = labels),
      y = .data$value,
      fill = factor(.data$technology, levels = colours$technology)
    )
  ) +
    geom_bar(
      position = "fill",
      stat = "identity",
      width = .5
    ) +
    scale_y_continuous(
      labels = scales::percent_format(),
      expand = c(0, 0),
      sec.axis = dup_axis()
    ) +
    scale_x_discrete(labels = labels) +
    scale_fill_manual(
      labels = colours$label_tech,
      values = colours$hex
    ) +
    coord_flip() +
    guides(fill = guide_legend(ncol = 3, byrow = TRUE, reverse = TRUE)) +
    theme_2dii() +
    theme(axis.line.y = element_blank()) +
    theme(axis.ticks.y = element_blank()) +
    theme(legend.position = "bottom") +
    xlab("") +
    ylab("") +
    facet_wrap(~year, nrow = 2, strip.position = "right")
}

techmix_labels <- function(data) {
  metrics_other <- data %>%
    filter(
      .data$metric != "projected",
      !is_scenario(.data$metric)
           ) %>%
    pull(.data$metric) %>%
    unique()
  scenario <- data %>%
    filter(is_scenario(.data$metric)) %>%
    pull(.data$metric) %>%
    unique()
  metrics_order <- c("projected", metrics_other, scenario)

  labels <- data %>%
    arrange(factor(.data$metric, levels = metrics_order)) %>%
    pull(.data$label) %>%
    unique() %>%
    rev()
}

get_technology_colours <- function(data) {
  colours <- semi_join(technology_colours, data, by = c("sector", "technology")) %>%
    left_join(
      data %>%
        select(.data$technology, .data$label_tech) %>%
        unique(),
      by = "technology"
    )
}

recode_sector <- function(x) {
  # styler: off
  case_when(
    grepl("(?i)power(?-i)", x)             ~ "power",
    grepl("(?i)auto(?-i)[a-zA-Z]+", x)     ~ "automotive",
    grepl("(?i)oil(?-i).*(?i)gas(?-i)", x) ~ "oil&gas",
    grepl("(?i)fossil(?-i)[a-zA-Z]+", x)   ~ "fossil fuels",
    TRUE ~ tolower(x)
  )
  # styler: on
}

extract_scenarios <- function(x) {
  unique(x[startsWith(x, "target_")])
}

add_label_tech_if_missing <- function(data) {
  if (has_name(data, "label_tech")) {
    return(data)
  }

  data$label_tech <- data$technology
  data
}
