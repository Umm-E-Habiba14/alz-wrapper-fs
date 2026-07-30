# =============================================================================
# 07_stability_jaccard.R
#
# Feature selection stability analysis: a feature selection method is only
# useful for biomarker discovery if it selects a *similar* set of features
# every time it's run on a resampled training split. This measures that
# with pairwise Jaccard similarity across the 20 iterations from the
# benchmark run.
#
# This replaces the original Jaccard_score_estimation.R, which repeated the
# same ~20-line block by hand for each of 4 feature selection methods
# (boruta, rfe, xgboost, lasso/ridge) with hardcoded object names.
# =============================================================================

source("R/00_utils.R")

#' Compute stability (mean pairwise Jaccard similarity) for every feature
#' selection method in a `selected_features` list produced by run_benchmark()
#'
#' @param selected_features named list of lists (method -> iteration -> features),
#'   as returned by run_benchmark()$selected_features
#' @return a data.frame with one row per feature selection method:
#'   method, n_iterations_used, mean_jaccard, n_features_avg
stability_report <- function(selected_features) {
  rows <- lapply(names(selected_features), function(fs_name) {
    feature_lists <- Filter(Negate(is.null), selected_features[[fs_name]])
    data.frame(
      method               = fs_name,
      n_iterations_used    = length(feature_lists),
      mean_jaccard         = mean_pairwise_jaccard(feature_lists),
      mean_features_selected = if (length(feature_lists) > 0)
        mean(vapply(feature_lists, length, numeric(1))) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  df <- do.call(rbind, rows)
  df[order(-df$mean_jaccard), ]
}

# -----------------------------------------------------------------------
# Example usage:
#   selected_features <- readRDS("results/selected_features.rds")
#   stability <- stability_report(selected_features)
#   write.csv(stability, "results/stability_report.csv", row.names = FALSE)
# -----------------------------------------------------------------------
