# =============================================================================
# 03_feature_selection_wrapper.R
# Wrapper-type feature selection: use a model's performance to guide which
# features are kept. Same shared interface as the filter methods:
#   fs_fn(train_data, target_col, ...) -> character vector of feature names
# =============================================================================

library(Boruta)
library(caret)

#' Boruta feature selection (all-relevant, shadow-feature based)
fs_boruta <- function(train_data, target_col = "Disease", n_trees = 500, max_runs = 100) {
  x <- train_data[, setdiff(names(train_data), target_col)]
  y <- as.factor(train_data[[target_col]])

  boruta_result <- Boruta::Boruta(x = x, y = y, ntree = n_trees, maxRuns = max_runs)
  Boruta::getSelectedAttributes(boruta_result, withTentative = FALSE)
}

#' Recursive Feature Elimination (caret::rfe), backed by random forest
fs_rfe <- function(train_data, target_col = "Disease",
                    sizes = c(10, 25, 50, 100, 250), n_folds = 10) {
  x <- train_data[, setdiff(names(train_data), target_col)]
  y <- as.factor(train_data[[target_col]])

  ctrl <- caret::rfeControl(functions = caret::rfFuncs, method = "cv", number = n_folds)
  rfe_result <- caret::rfe(x, y, sizes = sizes, rfeControl = ctrl)
  caret::predictors(rfe_result)
}

FS_METHODS <- list(
  boruta = fs_boruta,
  rfe    = fs_rfe
)
