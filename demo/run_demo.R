# =============================================================================
# run_demo.R -- end-to-end smoke test on synthetic data
# Run from the project root: Rscript demo/run_demo.R
# =============================================================================

source("demo/generate_synthetic_data.R")
source("R/04_run_benchmark.R")   # also sources 00-03 internally
source("R/05_stability_jaccard.R")
source("R/06_compare_and_plot.R")

data <- load_expression_data("data/demo_alz_data.csv")
print(summarize_dataset(data))

results <- run_benchmark(data, n_iterations = 3, top_n = 20, seed = 1)

dir.create("results", showWarnings = FALSE)
write.csv(results$metrics, "results/demo_benchmark_metrics.csv", row.names = FALSE)

stability <- stability_report(results$selected_features)
write.csv(stability, "results/demo_stability_report.csv", row.names = FALSE)

message("\n=== Benchmark summary (mean AUC by method x classifier) ===")
print(summarize_benchmark(results$metrics) %>%
        dplyr::select(feature_set, classifier, auc_mean) %>%
        dplyr::arrange(dplyr::desc(auc_mean)))

message("\n=== Feature selection stability (mean Jaccard across iterations) ===")
print(stability)

message("\nDemo complete. See results/demo_benchmark_metrics.csv and results/demo_stability_report.csv")
