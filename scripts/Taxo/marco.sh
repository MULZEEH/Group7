#!/bin/bash
# move to anno
# Prokka Execution
prokka --outdir results/annotations/ --prefix {wildcards.sample} {input.fna} --force

# Bakta Execution 

