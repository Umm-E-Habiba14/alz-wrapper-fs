# =============================================================================
# 05_train_evaluate.R
#
# This file replaces what used to be ~9 nearly-identical copy-pasted blocks
# (one per classifier: rf, svmRadial, svmPoly, kknn, lda, glmnet, pcaNNet,
# ranger, stepLDA) repeated across multiple scripts for every feature
# selection method. Same logic, one function, called in a loop.
# =============================================================================

library(caret)
library(pROC)

# The 9 classifiers originally benchmarked, as caret model strings.
CLASSIFIERS <- c(
  random_forest      = "rf",
  svm_radial         = "svmRadial",
  svm_poly           = "svmPoly",
  knn                = "kknn",
  lda                = "lda",
  glmnet             = "glmnet",
  pca_nnet           = "pcaNNet",
  ranger             = "ranger",
  step_lda           = "stepLDA"
)

#' Train one classifier and evaluate it on held-out data
#'
#' @param method a caret model string, e.g. "rf"
#' @param train_data,test_data data.frames with target_col + feature columns
#' @param target_col name of the outcome column
#' @param ctrl a caret::trainControl object
#' @return a one-row data.frame of metrics, or NULL if training/prediction failed
train_evaluate <- function(method, train_data, test_data, target_col = "Disease", ctrl) {
  form <- stats::as.formula(paste(target_col, "~ ."))

  model <- caret::train(form, data = train_data, method = method, trControl = ctrl)
  preds <- stats::predict(model, newdata = test_data)
  truth <- factor(test_data[[target_col]], levels = levels(train_data[[target_col]]))

  cm <- caret::confusionMatrix(preds, truth)

  # AUC needs a numeric encoding; caret's confusionMatrix already validated
  # that preds/truth share the same factor levels, so this is safe here.
  pred_numeric  <- as.numeric(preds)
  truth_numeric <- as.numeric(truth)
  auc_val <- as.numeric(pROC::auc(pROC::roc(truth_numeric, pred_numeric, quiet = TRUE)))

  data.frame(
    classifier         = method,
    accuracy           = unname(cm$overall["Accuracy"]),
    balanced_accuracy  = unname(cm$byClass["Balanced Accuracy"]),
    sensitivity        = unname(cm$byClass["Sensitivity"]),
    specificity        = unname(cm$byClass["Specificity"]),
    f1                 = unname(cm$byClass["F1"]),
    auc                = auc_val,
    stringsAsFactors   = FALSE
  )
}

#' Train + evaluate every classifier in `classifiers` on one train/test split
#'
#' @return a data.frame, one row per classifier
evaluate_all_classifiers <- function(train_data, test_data, target_col = "Disease",
                                      classifiers = CLASSIFIERS, ctrl) {
  rows <- lapply(names(classifiers), function(clf_name) {
    safely(
      train_evaluate(classifiers[[clf_name]], train_data, test_data, target_col, ctrl),
      context = sprintf("classifier=%s", clf_name)
    )
  })
  do.call(rbind, Filter(Negate(is.null), rows))
}
