# =============================================================================
# 01_preprocessing.R
# Load and clean the normalized expression matrix.
#
# Expected input: a CSV with one row per sample, a "Disease" label column,
# and one column per probe (numeric, already normalized -- e.g. an
# AddNeuroMed / Illumina HumanHT-12 style expression matrix).
# =============================================================================

#' Load and lightly clean the expression matrix
#'
#' @param path path to the CSV file
#' @param target_col name of the outcome/label column (default "Disease")
#' @return a cleaned data.frame with `target_col` as a factor, all other
#'   columns numeric, and any leading index/ID column removed
load_expression_data <- function(path, target_col = "Disease") {
  df <- read.csv(path, check.names = FALSE)

  # Drop an unnamed leading index column if present (common artifact of
  # writing data.frames with row names via write.csv)
  if (names(df)[1] %in% c("", "X", "X.1")) {
    df <- df[, -1, drop = FALSE]
  }

  if (!target_col %in% names(df)) {
    stop(sprintf("Expected a '%s' column in %s but didn't find one.", target_col, path))
  }

  # Coerce every non-target column to numeric, and report (rather than
  # silently drop) anything that fails to parse
  feature_cols <- setdiff(names(df), target_col)
  non_numeric  <- character(0)
  for (col in feature_cols) {
    original <- df[[col]]
    coerced  <- suppressWarnings(as.numeric(original))
    if (any(is.na(coerced) & !is.na(original))) {
      non_numeric <- c(non_numeric, col)
    }
    df[[col]] <- coerced
  }
  if (length(non_numeric) > 0) {
    warning(sprintf(
      "%d column(s) contained non-numeric values that were coerced to NA: %s%s",
      length(non_numeric),
      paste(utils::head(non_numeric, 5), collapse = ", "),
      if (length(non_numeric) > 5) ", ..." else ""
    ))
  }

  # Missing values: fill with 0 (matches the original analysis choice).
  # NOTE: for a real write-up it's worth flagging this as a modeling decision
  # -- 0-imputation assumes MNAR-below-detection-limit, which is a reasonable
  # assumption for normalized expression data but should be stated explicitly.
  n_missing <- sum(is.na(df[feature_cols]))
  if (n_missing > 0) {
    message(sprintf("Imputing %d missing values with 0.", n_missing))
    df[feature_cols][is.na(df[feature_cols])] <- 0
  }

  df[[target_col]] <- as.factor(df[[target_col]])
  df
}

#' Basic sanity-check summary of a loaded dataset, useful to confirm you're
#' looking at the dataset you think you are (sample size / class balance /
#' feature count) before running a 20-iteration benchmark.
summarize_dataset <- function(df, target_col = "Disease") {
  list(
    n_samples  = nrow(df),
    n_features = ncol(df) - 1,
    class_counts = table(df[[target_col]])
  )
}
