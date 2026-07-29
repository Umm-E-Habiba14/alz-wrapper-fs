# Wrapper-Based Feature Selection for Alzheimer's Biomarker Discovery

Benchmarks 2 wrapper-type feature selection methods (Boruta, RFE) against 9
classifiers on blood-based Alzheimer's disease gene expression data,
evaluating both predictive performance and feature-selection stability
across resamples.

> Part of a 3-part comparative series on feature selection paradigms for
> biomarker discovery: Filter methods (`alz-filter-fs`) · **Wrapper methods**
> (this repo) · Embedded methods (`alz-embedded-fs`). Each repo is fully
> standalone; together they let you compare paradigms head-to-head using the
> same classifiers, dataset, and evaluation protocol.

## Why wrapper methods

Wrapper methods use a model's actual performance to decide which features to
keep, rather than scoring features independently. That lets them capture
feature interactions and redundancy in a way filter methods can't -- but at
real computational cost, since they involve repeatedly training a model on
different feature subsets. On a 30,000+ feature expression matrix this is
the most expensive paradigm of the three in this series, which is also why
both methods here work by iteratively shrinking the candidate feature set
rather than exhaustively searching all subsets.

## Methods included

| Method | Idea |
|---|---|
| Boruta | All-relevant selection: compares each real feature's importance (via random forest) against "shadow" (randomly permuted) copies of itself, iteratively confirming or rejecting features whose importance doesn't consistently beat its shadow |
| RFE (Recursive Feature Elimination) | Minimal-optimal selection: repeatedly fits a model, ranks features by importance, drops the weakest, and repeats -- cross-validated across candidate subset sizes |

Boruta and RFE answer different questions worth contrasting directly: Boruta
tends to keep *all* features that carry any real signal (larger, more
inclusive sets), while RFE searches for a *minimal* subset that maximizes
predictive performance (smaller, more parsimonious sets). Both are reported
here so that difference is visible in the results rather than assumed.

## Dataset

Blood-based gene expression data from the AddNeuroMed (ANM) cohort
(Illumina HumanHT-12), public on GEO/ArrayExpress:
[GSE63060](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63060) /
A-MEXP-1171 (249 samples) and
[GSE63061](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63061) /
A-GEOD-10558 (273 samples). Confirm the exact accession against your source
file before the full run -- no code changes needed either way.

Expected input: one row per sample, a `Disease` label column, and one
numeric column per probe.

## Project structure

```
alz-wrapper-fs/
├── R/
│   ├── 00_utils.R                # Jaccard index, safe error handling
│   ├── 01_preprocessing.R        # load + clean the expression matrix
│   ├── 02_feature_selection.R    # Boruta + RFE (FS_METHODS registry)
│   ├── 03_train_evaluate.R       # generic train+evaluate for any caret classifier
│   ├── 04_run_benchmark.R        # main driver: loops methods x iterations x classifiers
│   ├── 05_stability_jaccard.R    # feature selection stability report
│   └── 06_compare_and_plot.R     # aggregate results + comparison plots
├── demo/
│   ├── generate_synthetic_data.R # toy dataset, same shape, for smoke-testing
│   └── run_demo.R                # end-to-end run on synthetic data
├── environment/install_packages.R
├── data/                         # not committed -- see Dataset section
├── results/                      # generated: benchmark_metrics.csv, stability_report.csv
└── figures/                      # generated plots
```

## How to run

```r
source("environment/install_packages.R")   # one time

source("demo/run_demo.R")                  # quick smoke test, synthetic data
# note: Boruta especially is slower than filter methods -- the demo uses a
# small synthetic dataset (500 features) and 3 iterations to stay fast;
# expect the full real-data run to take substantially longer per iteration.

# Full run on real data:
source("R/04_run_benchmark.R")
data <- load_expression_data("data/alz_nor_data.csv")
summarize_dataset(data)

results <- run_benchmark(data, n_iterations = 20, top_n = 100)
write.csv(results$metrics, "results/benchmark_metrics.csv", row.names = FALSE)
saveRDS(results$selected_features, "results/selected_features.rds")

source("R/05_stability_jaccard.R")
stability <- stability_report(results$selected_features)

source("R/06_compare_and_plot.R")
ggplot2::ggsave("figures/auc_heatmap.png", plot_auc_heatmap(results$metrics),
                width = 8, height = 6, dpi = 150)
```

## Evaluation design

20 repeated random 70/30 train/test splits per method, feature selection
performed on the training split only (no leakage into test), metrics
averaged across iterations (accuracy, balanced accuracy, sensitivity,
specificity, F1, AUC). Stability = mean pairwise Jaccard similarity of the
selected feature sets across the 20 iterations -- worth watching closely
here, since Boruta's all-relevant sets and RFE's minimal-optimal sets can
have very different stability profiles even at similar accuracy.

## Results

*(Populate after running against the real dataset. Worth highlighting: how
much larger are Boruta's selected sets than RFE's, on average, and does
that size difference correspond to a stability or performance tradeoff?)*

## Tech stack

R · Boruta · caret (rfe, rfFuncs) · glmnet · ranger · pROC · ggplot2 · dplyr
