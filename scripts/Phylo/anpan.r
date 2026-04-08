# install.packages(c("ape", 
#                    "data.table",
#                    "dplyr", 
#                    "fastglm",
#                    "furrr", 
#                    "ggdendro",
#                    "ggnewscale",
#                    "ggplot2",
#                    "loo",
#                    "patchwork",
#                    "phylogram",
#                    "posterior",
#                    "progressr",
#                    "purrr",
#                    "R.utils",
#                    "remotes",
#                    "stringr",
#                    "tibble",
#                    "tidyselect")) # add Ncpus = 4 to go faster

# install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))

# =============================================================================
# anpan_pglmm() — Phylogenetic G(eneral)L(inear)M(odel) for MAGs analysis
#
# PURPOSE
#   Test whether the phylogenetic structure within a MAG species correlates
#   with host metadata (outcome + covariates) using a Bayesian PGLMM.
#
# PGLMM MODEL (Gaussian outcome)
#   y_i = intercept + β * X_i + φ_i + ε_i
#   φ   ~ MVN(0, σ_phylo² * C)      # phylogenetic random effect
#   ε_i ~ N(0, σ_resid²)            # residual noise
#   C   = phylogenetic correlation matrix derived from the MAG tree
#
# PGLMM MODEL (Binary outcome)
#   logit(p_i) = intercept + β * X_i + φ_i
#   φ   ~ MVN(0, σ_phylo² * C)
#
# LOO COMPARISON
#   The function compares the PGLMM against a "base" GLM (without the
#   phylogenetic term) using integrated LOO-CV (Vehtari et al. 2017,
#   JMLR 18:1-37). A positive ELPD difference favours the PGLMM.
# =============================================================================
#   Step 0. Create a new Token on https://github.com/settings/tokens
#   Step 1. 1 under
#   Step 2. 2
# 1. Install cmdstanr (not on conda):
#    Rscript -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', 'https://cloud.r-project.org'))"
# 2. Install CmdStan itself:
#    Rscript -e "cmdstanr::check_cmdstan_toolchain(fix = TRUE)"
#    Rscript -e "cmdstanr::install_cmdstan(cores = 4)"
#
# 3. Install anpan from GitHub:
#    Rscript -e "remotes::install_github('biobakery/anpan', build_vignettes = FALSE)"
#
suppressPackageStartupMessages({
  library(anpan)
  library(ape)
  library(dplyr)
  library(progressr)
  library(future)
})

# ── 0. Parallelisation ────────────────────────────────────────────────────────
# Change workers to match available cores on your machine / cluster node.
plan(multisession, workers = 4)

# Show progress bars in the console
handlers(global = TRUE)


# ── 1. USER INPUTS  (edit these) ─────────────────────────────────────────────

# Path to your metadata TSV.
# Required columns: sample_id  +  all covariates  +  the outcome column.
META_FILE <- "metadata_with_genes.tsv"
# META_FILE <- "simple_meta_data.tsv"

# Path to the Newick tree file for a SINGLE MAG/species.
# Tip labels must match the sample_id values in META_FILE.
# For a batch run across many species see section 6 below.
TREE_FILE <- "simple_tree.nwk"

# Column name of your outcome variable in the metadata.
# Gaussian outcome  → continuous numeric column  (e.g. BMI, Shannon diversity)
# Logistic outcome  → 0/1 or TRUE/FALSE column   (e.g. disease status)
OUTCOME <- "study_group"        
# does not know how many interesting genes i will have so i will retrieve all the column from META_FILE after 'study_group'
interesting_genes <- colnames(read.csv(META_FILE, sep='\t', nrows=0))
index_study_group <- which(interesting_genes == "study_group")
interesting_genes <- interesting_genes[index_study_group + 1: length(interesting_genes)]
interesting_genes <- interesting_genes[!is.na(interesting_genes)]  # remove any NA columns (if no genes were added)
# Vector of covariate column names to control for.
# COVARIATES <- c("sex",	"bmi", "age", "smoking_state", interesting_genes)  
# COVARIATES <- c("sex",	"bmi", "age", "smoking_state")  
# COVARIATES <- c("sex",	"bmi",  "smoking_state", "age")  
COVARIATES <- c( "smoking_state","sex",	"bmi", "age")  

# Output directory
OUT_DIR <- "pglmm_output"

# Model family: "gaussian" for continuous outcomes, "binomial" for binary
FAMILY <- "gaussian"   # <── test on gaussian

# If tip labels in the tree have a consistent prefix/suffix that is NOT in the
# metadata sample_id column, set a regex pattern to strip it.
# Example: tip labels are "ERR123456_mag1" but sample_id is "ERR123456"
# → TRIM_PATTERN <- "_mag1$"
# Leave as NULL if labels already match.
TRIM_PATTERN <- NULL


# ── 2. SINGLE-SPECIES RUN ────────────────────────────────────────────────────

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("Running anpan_pglmm for:", TREE_FILE, "\n")

result <- anpan_pglmm(
  meta_file         = META_FILE,
  tree_file         = TREE_FILE,
  outcome           = OUTCOME,
  covariates        = COVARIATES,
  family            = FAMILY,
  out_dir           = OUT_DIR,
  trim_pattern      = TRIM_PATTERN,
  omit_na           = TRUE,       # drop samples with any NA in selected columns
  ladderize         = TRUE,       # ladderise tree before computing cor matrix
  reg_noise         = TRUE,       # recommended: regularise σ_phylo/σ_resid ratio
  reg_gamma_params  = c(1, 2),    # shape, rate of the Gamma regularising prior
  loo_comparison    = TRUE,       # compare PGLMM vs base GLM via LOO-CV
  run_diagnostics   = TRUE,       # print MCMC diagnostics + Pareto-k table
  show_plot_cor_mat = TRUE,       # plot the phylogenetic correlation matrix
  show_plot_tree    = TRUE,       # plot the tree coloured by outcome
  show_post         = TRUE,       # plot posterior phylogenetic effects on tree
  save_object       = TRUE,       # save the CmdStanMCMC fit object to disk
  iter_warmup       = 1000,
  iter_sampling     = 1000,
  adapt_delta       = 0.95,       # raise to 0.99 if divergences appear
  max_treedepth     = 12,
  seed              = 42,
  refresh           = 200
)
# simplest run with defaults:
# result <- anpan_pglmm(
#   meta_file         = META_FILE,
#   tree_file         = TREE_FILE,
#   outcome           = OUTCOME,
#   covariates        = COVARIATES,
#   family            = FAMILY,
#   out_dir           = OUT_DIR
# )


# ── 3. SUMMARISE RESULTS ─────────────────────────────────────────────────────

cat("\n=== Model summary (key parameters) ===\n")
key_params <- result$pglmm_fit$summary(
  variables = c("sigma_phylo", "sigma_resid", grep("^beta", result$pglmm_fit$metadata()$stan_variables, value = TRUE))
)
print(key_params)

# Phylogenetic signal: sigma_phylo vs sigma_resid
cat("\n=== Phylogenetic signal ===\n")
sigma_summary <- result$pglmm_fit$summary(variables = c("sigma_phylo", "sigma_resid"))
ratio <- sigma_summary$mean[sigma_summary$variable == "sigma_phylo"] /
         sigma_summary$mean[sigma_summary$variable == "sigma_resid"]
cat(sprintf("σ_phylo / σ_resid (posterior means): %.3f\n", ratio))
cat("  > 1 suggests strong phylogenetic signal\n")
cat("  < 1 suggests residual noise dominates\n\n")

# LOO comparison
if (!is.null(result$loo$comparison)) {
  cat("=== LOO model comparison ===\n")
  print(result$loo$comparison)
  elpd_diff <- result$loo$comparison[2, 1]
  se_diff   <- result$loo$comparison[2, 2]
  cat(sprintf("\nELPD difference: %.2f  (SE: %.2f)\n", elpd_diff, se_diff))
  if (abs(elpd_diff / se_diff) > 2) {
    cat("→ Difference is clear (>2 SEs from zero)\n")
  } else {
    cat("→ Difference is not clear (<2 SEs from zero)\n")
  }
}

# Save ELPD difference plot
p_elpd <- plot_elpd_diff(result, verbose = FALSE)
ggplot2::ggsave(
  filename = file.path(OUT_DIR, "elpd_diff.pdf"),
  plot     = p_elpd,
  width    = 6,
  height   = 4
)
cat("\nELPD plot saved to:", file.path(OUT_DIR, "elpd_diff.pdf"), "\n")


# ── 4. SAVE RESULTS TABLE ────────────────────────────────────────────────────

results_table <- result$pglmm_fit$summary() |>
  dplyr::filter(grepl("^beta|sigma_phylo|sigma_resid|intercept", variable))

readr::write_tsv(results_table,
                 file = file.path(OUT_DIR, "pglmm_param_summary.tsv"))

cat("Parameter summary saved to:", file.path(OUT_DIR, "pglmm_param_summary.tsv"), "\n")

# ── 5. OPTIONAL — CLADE EFFECT ───────────────────────────────────────────────
# If you have a clade of interest (e.g. a known sub-lineage of the MAG),
# uncomment and set the clade member sample IDs:

# clade_ids <- c("sample_A", "sample_B", "sample_C")  # replace with your IDs
# clade_result <- compute_clade_effects(
#   clade_members      = clade_ids,
#   anpan_pglmm_result = result,
#   plot_difference    = TRUE
# )
# print(clade_result$clade_summary)

cat("\nDone.\n")