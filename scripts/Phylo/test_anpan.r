suppressPackageStartupMessages({
  library(anpan)
  library(ape)
  library(dplyr)
  library(progressr)
  library(future)
})

META_FILE <- "metadata_with_genes.tsv"

BUG_DIR <- "functional_profiles/gene_presence_absence.csv"

COVARIATES <- c( "smoking_state","sex",	"bmi", "age")  

OUTCOME <- "study_group"  


anpan(bug_file           = BUG_DIR,
            meta_file         = META_FILE,
            out_dir           = "output",
            # annotation_file   = "/path/to/annotation.tsv", #optional, used for plots
            filtering_method  = "none",
            model_type        = "fastglm",
            covariates        = COVARIATES,
            outcome           = OUTCOME,
            plot_ext          = "pdf",
            save_filter_stats = TRUE)