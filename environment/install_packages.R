# Run once to install everything this pipeline needs.

cran_packages <- c(
  "caret", "dplyr", "tidyr", "ggplot2", "scales",   # pipeline + plotting
  "FSelectorRcpp",                                  # Info Gain, Gain Ratio, SU, ReliefF
  "pROC", "kernlab", "kknn", "e1071", "nnet",        # classifiers
  "glmnet", "ranger"                                # classifiers (glmnet, ranger)
)

new_cran <- cran_packages[!(cran_packages %in% installed.packages()[, "Package"])]
if (length(new_cran) > 0) install.packages(new_cran, repos = "https://cloud.r-project.org")

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("FCBF", quietly = TRUE)) {
  BiocManager::install("FCBF", update = FALSE, ask = FALSE)
}

message("All dependencies installed.")
