#!/bin/bash

cd data/mags

for i in $(ls *.fna); do
    prokka --outdir ${i//.fna} --prefix ${i//.fna} $i --centre X --compliant;
done

cd ../..

touch results/done.txt
echo "done" > done.txt