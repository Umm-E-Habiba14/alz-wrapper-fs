# =============================================================================
# generate_synthetic_data.R
#
# Generates a small synthetic dataset shaped like the real AddNeuroMed-style
# input (a Disease label + thousands of normalized probe-level features),
# so the whole pipeline can be smoke-tested end-to-end WITHOUT the real
# (large, and possibly restricted-access) data file.
#
# This is a toy dataset only -- it injects a handful of truly informative
# features into a sea of noise features, so a working pipeline should be
# able to recover them. It is NOT a substitute for the real analysis; it
# exists purely so reviewers/collaborators can run `Rscript demo/run_demo.R`
# and see the pipeline execute successfully in under a minute.
#
# Usage:
#   Rscript demo/generate_synthetic_data.R
# =============================================================================

set.seed(42)

n_samples          <- 120     # ~ small multiple of a real cohort, kept light for CI speed
n_noise_features   <- 500     # bulk of "probes" carry no signal
n_signal_features  <- 15      # a handful of features are genuinely predictive

# Class labels (roughly matches the real AD:control ratio in AddNeuroMed, ~55:45)
disease <- factor(sample(c("Alzheimer", "Control"), n_samples,
                          replace = TRUE, prob = c(0.55, 0.45)))

noise <- matrix(rnorm(n_samples * n_noise_features, mean = 0, sd = 1),
                nrow = n_samples, ncol = n_noise_features)
colnames(noise) <- paste0("probe_noise_", seq_len(n_noise_features))

# Signal features: shifted mean for Alzheimer samples, so real feature
# selection methods should be able to recover them
signal <- matrix(rnorm(n_samples * n_signal_features, mean = 0, sd = 1),
                  nrow = n_samples, ncol = n_signal_features)
shift <- ifelse(disease == "Alzheimer", 0.8, -0.8)
signal <- signal + shift  # same shift applied across signal columns
colnames(signal) <- paste0("probe_signal_", seq_len(n_signal_features))

demo_data <- data.frame(Disease = disease, signal, noise, check.names = FALSE)

dir.create("data", showWarnings = FALSE)
write.csv(demo_data, "data/demo_alz_data.csv", row.names = FALSE)

message(sprintf(
  "Wrote data/demo_alz_data.csv: %d samples x %d features (%d signal, %d noise)",
  n_samples, n_signal_features + n_noise_features, n_signal_features, n_noise_features
))
