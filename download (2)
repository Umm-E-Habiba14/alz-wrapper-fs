# =============================================================================
# 08_compare_and_plot.R
#
# Aggregate the tidy benchmark output and produce the comparison plots.
# Replaces ~6 near-identical ggplot blocks (one per feature-selection
# method's own script) with two reusable functions.
# =============================================================================

library(dplyr)
library(ggplot2)
library(tidyr)

#' Summarize benchmark metrics: mean +/- SD per (feature_set, classifier)
summarize_benchmark <- function(metrics) {
  metrics %>%
    dplyr::group_by(feature_set, classifier) %>%
    dplyr::summarise(
      dplyr::across(
        c(accuracy, balanced_accuracy, sensitivity, specificity, f1, auc),
        list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)),
        .names = "{.col}_{.fn}"
      ),
      n_runs = dplyr::n(),
      .groups = "drop"
    )
}

#' Bar chart comparing feature selection methods for ONE classifier
#' (e.g. random forest), across all metrics -- this is the plot used to
#' answer "which feature selection method works best?"
plot_fs_comparison <- function(metrics, classifier_name = "rf", metric_cols = c(
                                  "accuracy", "balanced_accuracy", "f1", "auc")) {
  summary_df <- summarize_benchmark(metrics) %>%
    dplyr::filter(classifier == classifier_name) %>%
    dplyr::select(feature_set, dplyr::ends_with("_mean")) %>%
    tidyr::pivot_longer(-feature_set, names_to = "metric", values_to = "value") %>%
    dplyr::mutate(metric = sub("_mean$", "", metric)) %>%
    dplyr::filter(metric %in% metric_cols)

  ggplot2::ggplot(summary_df, ggplot2::aes(x = metric, y = value, fill = feature_set)) +
    ggplot2::geom_bar(stat = "identity", position = ggplot2::position_dodge(width = 0.8), width = 0.7) +
    ggplot2::labs(
      title = sprintf("Feature selection method comparison (%s classifier)", classifier_name),
      x = "Metric", y = "Score (mean across iterations)", fill = "Feature selection method"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "top",
                   axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1))
}

#' Heatmap of AUC across every (feature_set x classifier) combination --
#' the single-figure "big picture" view for the README/report.
plot_auc_heatmap <- function(metrics) {
  summary_df <- summarize_benchmark(metrics)

  ggplot2::ggplot(summary_df, ggplot2::aes(x = classifier, y = feature_set, fill = auc_mean)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", auc_mean)), size = 3) +
    ggplot2::scale_fill_gradient(low = "white", high = "steelblue", name = "Mean AUC") +
    ggplot2::labs(title = "Mean AUC by feature selection method and classifier",
                  x = "Classifier", y = "Feature selection method") +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

# -----------------------------------------------------------------------
# Example usage:
#   metrics <- read.csv("results/benchmark_metrics.csv")
#   summary_df <- summarize_benchmark(metrics)
#   write.csv(summary_df, "results/benchmark_summary.csv", row.names = FALSE)
#
#   ggsave("figures/rf_comparison.png", plot_fs_comparison(metrics, "random_forest"),
#          width = 8, height = 5, dpi = 150)
#   ggsave("figures/auc_heatmap.png", plot_auc_heatmap(metrics),
#          width = 8, height = 6, dpi = 150)
# -----------------------------------------------------------------------
