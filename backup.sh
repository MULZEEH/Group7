#!/bin/bash
# script to backup the folde rremoving the results folder and processed data so that the snakemake can run again.
# script must be implented inside the snakefile

mv results backup/results_backup_$(date +%Y%m%d_%H%M%S)
mv log backup/log_backup_$(date +%Y%m%d_%H%M%S)


if [ $1 == "full" ]; then
    mv data/!(mags/ | *.tsv) backup/data$(date +%Y%m%d_%H%M%S)/
fi

