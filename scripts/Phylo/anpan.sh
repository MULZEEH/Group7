Rscript -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', 'https://cloud.r-project.org'))"

Rscript -e "cmdstanr::check_cmdstan_toolchain(fix = TRUE)"
Rscript -e "cmdstanr::install_cmdstan(cores = 4)"
#
Rscript -e "remotes::install_github('biobakery/anpan', build_vignettes = FALSE)"

#remember to change the meta data file with MAGsID -> sample_id and the [rediction column must be numerical]