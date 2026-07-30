# =============================================================================
# 04_run_benchmark.R
# Main driver: for each filter feature selection method, for each of N
# resampling iterations, select features on the training split only, then
# train + evaluate all 9 classifiers. Output is one tidy long-format
# data.frame, ready for aggregation/plotting.
# =============================================================================

library(caret)
library(dplyr)

source("R/00_utils.R")
source("R/01_preprocessing.R")
source("R/02_feature_selection.R")   # defines FS_METHODS
source("R/03_train_evaluate.R")

#' Run the filter-method feature-selection x classifier benchmark
#'
#' @param data full dataset (target_col + feature columns)
#' @param fs_methods named list of feature-selection functions to compare
#'   (default: all methods in FS_METHODS)
#' @param n_iterations number of random train/test resamples (default 20)
#' @param train_fraction proportion of data used for training (default 0.7)
#' @param top_n number of features kept by each method
#' @param target_col name of the outcome column
#' @param seed base random seed, for reproducibility
#'
#' @return list(metrics = tidy data.frame, selected_features = named list)
run_benchmark <- function(data,
                           fs_methods = FS_METHODS,
                           n_iterations = 20,
                           train_fraction = 0.7,
                           top_n = 100,
                           target_col = "Disease",
                           seed = 42) {

  ctrl <- caret::trainControl(method = "cv", number = 10, savePredictions = FALSE)

  metrics_list <- list()
  selected_features <- setNames(vector("list", length(fs_methods)), names(fs_methods))
  for (nm in names(fs_methods)) selected_features[[nm]] <- vector("list", n_iterations)

  for (fs_name in names(fs_methods)) {
    fs_fn <- fs_methods[[fs_name]]
    message(sprintf("== Feature selection method: %s ==", fs_name))

    for (iter in seq_len(n_iterations)) {
      set.seed(seed + iter)
      idx <- caret::createDataPartition(data[[target_col]], p = train_fraction,
                                         list = FALSE, times = 1)
      train_full <- data[idx, ]
      test_full  <- data[-idx, ]

      features <- safely(
        do.call(fs_fn, c(list(train_data = train_full, target_col = target_col),
                          if ("top_n" %in% names(formals(fs_fn))) list(top_n = top_n) else list())),
        context = sprintf("feature_selection=%s iter=%d", fs_name, iter)
      )
      if (is.null(features) || length(features) == 0) next

      selected_features[[fs_name]][[iter]] <- features

      train_sub <- train_full[, c(target_col, features), drop = FALSE]
      test_sub  <- test_full[,  c(target_col, features), drop = FALSE]

      iter_results <- evaluate_all_classifiers(train_sub, test_sub, target_col, ctrl = ctrl)
      if (is.null(iter_results) || nrow(iter_results) == 0) next

      iter_results$feature_set <- fs_name
      iter_results$iteration   <- iter
      iter_results$n_features  <- length(features)
      metrics_list[[length(metrics_list) + 1]] <- iter_results

      message(sprintf("  iteration %2d/%d done (%d features selected)",
                       iter, n_iterations, length(features)))
    }
  }

  list(
    metrics           = dplyr::bind_rows(metrics_list),
    selected_features = selected_features
  )
}

# -----------------------------------------------------------------------
# Example usage (run interactively or via Rscript R/04_run_benchmark.R):
#
#   data <- load_expression_data("data/alz_nor_data.csv")
#   summarize_dataset(data)
#
#   results <- run_benchmark(data, n_iterations = 20, top_n = 100)
#   write.csv(results$metrics, "results/benchmark_metrics.csv", row.names = FALSE)
#   saveRDS(results$selected_features, "results/selected_features.rds")
# -----------------------------------------------------------------------
