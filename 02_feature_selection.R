# =============================================================================
# 00_utils.R
# Small shared helpers used across the pipeline. Kept dependency-free where
# possible (the original code relied on qpcR:::cbind.na just for NA-padded
# cbind/rbind — that's easy enough to implement directly and drop the
# dependency on an internal, unexported qpcR function).
# =============================================================================

#' Jaccard similarity between two sets
#'
#' Used for feature-selection stability analysis: how similar are the
#' feature sets chosen across repeated train/test splits?
#'
#' @param a,b character/numeric vectors (e.g. selected feature names)
#' @return numeric in [0, 1]
jaccard_index <- function(a, b) {
  a <- unique(stats::na.omit(a))
  b <- unique(stats::na.omit(b))
  if (length(a) == 0 && length(b) == 0) return(NA_real_)
  intersection <- length(intersect(a, b))
  union_size   <- length(union(a, b))
  intersection / union_size
}

#' Mean pairwise Jaccard similarity across a list of feature sets
#'
#' @param feature_sets a list of character vectors, one per iteration
#' @return a single numeric summarizing selection stability (higher = more
#'   stable / reproducible feature selection across resamples)
mean_pairwise_jaccard <- function(feature_sets) {
  n <- length(feature_sets)
  if (n < 2) return(NA_real_)
  pairs <- utils::combn(n, 2, simplify = FALSE)
  scores <- vapply(pairs, function(p) {
    jaccard_index(feature_sets[[p[1]]], feature_sets[[p[2]]])
  }, numeric(1))
  mean(scores, na.rm = TRUE)
}

#' cbind data frames of unequal length, padding the shorter ones with NA
#'
#' Drop-in replacement for qpcR:::cbind.na (an unexported/internal function
#' the original scripts depended on directly).
cbind_na <- function(...) {
  dfs <- list(...)
  max_len <- max(vapply(dfs, function(x) NROW(x), integer(1)))
  padded <- lapply(dfs, function(x) {
    x <- as.data.frame(x)
    n_pad <- max_len - nrow(x)
    if (n_pad > 0) {
      pad <- as.data.frame(matrix(NA, nrow = n_pad, ncol = ncol(x)))
      names(pad) <- names(x)
      x <- rbind(x, pad)
    }
    x
  })
  do.call(cbind, padded)
}

#' Safe wrapper: run an expression, warn and return NULL on error instead of
#' halting the whole benchmark loop (a handful of classifier/feature-set
#' combinations failing shouldn't kill a 20-iteration x 9-classifier run).
safely <- function(expr, context = "") {
  tryCatch(
    expr,
    error = function(e) {
      message(sprintf("[SKIPPED] %s -- %s", context, conditionMessage(e)))
      NULL
    }
  )
}
