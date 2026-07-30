# Filter-Based Feature Selection for Alzheimer's Biomarker Discovery

Benchmarks 6 filter-type feature selection methods against 9 classifiers on
blood-based Alzheimer's disease gene expression data, evaluating both
predictive performance and feature-selection stability across resamples.

> Part of a 3-part comparative series on feature selection paradigms for
> biomarker discovery: **Filter methods** (this repo) · Wrapper methods
> (`alz-wrapper-fs`) · Embedded methods (`alz-embedded-fs`). Each repo is
> fully standalone; together they let you compare paradigms head-to-head
> using the same classifiers, dataset, and evaluation protocol.

## Why filter methods

Filter methods score each feature independently of any downstream model —
they're the cheapest FS paradigm computationally (no repeated model
fitting), model-agnostic (the same ranking works for any classifier), and a
sensible first pass on a 30,000+ feature expression matrix before anything
more expensive. Their tradeoff: because they ignore feature interactions and
which model will consume them, they can miss features that are only useful
in combination, or select redundant, correlated features that all carry the
same signal.

## Methods included

| Method | Idea |
|---|---|
| Information Gain | Entropy reduction in the class label given a feature |
| Gain Ratio | Information Gain normalized by feature's intrinsic entropy (corrects IG's bias toward high-cardinality features) |
| Symmetrical Uncertainty | A normalized, symmetric variant of IG in [0,1] |
| ReliefF | Nearest-neighbor based; rewards features that separate different-class neighbors and agree within same-class neighbors |
| One-way ANOVA (F-test) | Per-feature test of mean difference between classes, FDR-corrected |
| FCBF (Fast Correlation-Based Filter) | Combines relevance (to class) with redundancy removal (between features) |

## Dataset

Blood-based gene expression data from the AddNeuroMed (ANM) cohort
(Illumina HumanHT-12), public on GEO/ArrayExpress:
[GSE63060](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63060) /
A-MEXP-1171 (249 samples) and
[GSE63061](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63061) /
A-GEOD-10558 (273 samples). Confirm the exact accession against your source
file before the full run — no code changes needed either way.

Expected input: one row per sample, a `Disease` label column, and one
numeric column per probe.

## Project structure

```
alz-filter-fs/
├── R/
│   ├── 00_utils.R                # Jaccard index, safe error handling
│   ├── 01_preprocessing.R        # load + clean the expression matrix
│   ├── 02_feature_selection.R    # the 6 filter methods (FS_METHODS registry)
│   ├── 03_train_evaluate.R       # generic train+evaluate for any caret classifier
│   ├── 04_run_benchmark.R        # main driver: loops methods x iterations x classifiers
│   ├── 05_stability_jaccard.R    # feature selection stability report
│   └── 06_compare_and_plot.R     # aggregate results + comparison plots
├── demo/
│   ├── generate_synthetic_data.R # toy dataset, same shape, for smoke-testing
│   └── run_demo.R                # end-to-end run on synthetic data (~1 min)
├── environment/install_packages.R
├── data/                         # not committed -- see Dataset section
├── results/                      # generated: benchmark_metrics.csv, stability_report.csv
└── figures/                      # generated plots
```

## How to run

```r
source("environment/install_packages.R")   # one time

source("demo/run_demo.R")                  # quick smoke test, synthetic data

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
selected feature sets across the 20 iterations.

## Results

*(Populate after running against the real dataset. Worth highlighting: which
filter method gives the best accuracy/AUC vs. which gives the most stable
(reproducible) feature set — these are often not the same method.)*

## Tech stack

R · FSelectorRcpp · FCBF (Bioconductor) · caret · glmnet · ranger · pROC · ggplot2 · dplyr
