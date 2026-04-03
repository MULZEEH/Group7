#!/bin/bash
# script to run roary
mkdir -p results/pangenome/tmp/

for dir in results/annotations/*/     # list directories in the form "/tmp/dirname/"
do
    sample=$(basename $dir)
    # dir=${dir%*/}      # remove the trailing "/"
    # echo $dir    # print everything after the final "/"
    # echo $sample
    ln -sf $(realpath $dir/$sample.gff) results/pangenome/tmp/
done

cd results/pangenome/tmp/ && roary -f ../output --mafft -p 16 -e -n -v -cd 90 -i 95 -r *.gff 2>&1 | tee log/out.log

        #  -qc       generate QC report with Kraken
        #  -k STR    path to Kraken database for QC, use with -qc