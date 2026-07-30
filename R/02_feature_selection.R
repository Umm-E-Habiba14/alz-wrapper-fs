# =============================================================================
# 02_feature_selection_filter.R
# Filter-type feature selection methods: score every feature independently
# of any model, rank, and keep the top-k. All functions share the same
# interface so they can be plugged into the benchmark loop interchangeably:
#
#   fs_fn(train_data, target_col, top_n) -> character vector of feature names
# =============================================================================

library(FSelectorRcpp)

#' Information Gain filter
fs_information_gain <- function(train_data, target_col = "Disease", top_n = 100) {
  form <- as.formula(paste(target_col, "~ ."))
  ig <- FSelectorRcpp::information_gain(form, data = train_data, type = "infogain")
  ig <- ig[order(ig$importance, decreasing = TRUE), ]
  utils::head(ig$attributes, top_n)
}

#' Gain Ratio filter
fs_gain_ratio <- function(train_data, target_col = "Disease", top_n = 100) {
  form <- as.formula(paste(target_col, "~ ."))
  gr <- FSelectorRcpp::information_gain(form, data = train_data, type = "gainratio")
  gr <- gr[order(gr$importance, decreasing = TRUE), ]
  utils::head(gr$attributes, top_n)
}

#' Symmetrical Uncertainty filter
fs_symmetrical_uncertainty <- function(train_data, target_col = "Disease", top_n = 100) {
  form <- as.formula(paste(target_col, "~ ."))
  su <- FSelectorRcpp::information_gain(form, data = train_data, type = "symuncert")
  su <- su[order(su$importance, decreasing = TRUE), ]
  utils::head(su$attributes, top_n)
}

#' ReliefF filter
fs_relief <- function(train_data, target_col = "Disease", top_n = 100,
                       neighbours = 5, sample_size = 20) {
  form <- as.formula(paste(target_col, "~ ."))
  rel <- FSelectorRcpp::relief(form, data = train_data,
                                neighboursCount = neighbours, sampleSize = sample_size)
  rel <- rel[order(rel$importance, decreasing = TRUE), ]
  utils::head(rel$attributes, top_n)
}

#' One-way ANOVA filter (per-feature F-test against the class label)
fs_anova <- function(train_data, target_col = "Disease", top_n = 100) {
  y <- train_data[[target_col]]
  feature_cols <- setdiff(names(train_data), target_col)

  p_values <- vapply(feature_cols, function(col) {
    fit <- stats::aov(train_data[[col]] ~ y)
    summary(fit)[[1]][["Pr(>F)"]][1]
  }, numeric(1))

  adj_p <- stats::p.adjust(p_values, method = "fdr")
  ranked <- names(sort(adj_p))
  utils::head(ranked, top_n)
}

#' FCBF (Fast Correlation-Based Filter)
#' Requires the Bioconductor `FCBF` package.
fs_fcbf <- function(train_data, target_col = "Disease", top_n = 100, threshold = 0.05) {
  if (!requireNamespace("FCBF", quietly = TRUE)) {
    stop("Package 'FCBF' is required. Install with BiocManager::install('FCBF').")
  }
  form <- as.formula(paste(target_col, "~ ."))
  selected <- FCBF::fcbf(train_data[, setdiff(names(train_data), target_col)],
                          train_data[[target_col]], thresh = threshold, verbose = FALSE)
  utils::head(rownames(selected), top_n)
}

# Registry so the benchmark driver can loop over these by name -------------
FS_METHODS <- list(
  information_gain      = fs_information_gain,
  gain_ratio             = fs_gain_ratio,
  symmetrical_uncertainty = fs_symmetrical_uncertainty,
  relief                 = fs_relief,
  anova                   = fs_anova,
  fcbf                    = fs_fcbf
)
