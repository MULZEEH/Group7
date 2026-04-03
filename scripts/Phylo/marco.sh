#!/bin/bash
#on phylophlan we have phylo assignement
# phylophlan_metagenomic return instead the taxonomy annotation

phylophlan_metagenomic --database_list
phylophlan_metagenomic i [mags]-ou -d CMG2526 --database_folder [db folder] --nproc -n 1 #(dont we already have only 1 sgb?)

# write the default configuration inside the current folder
phylophlan_write_default_configs.sh

# in conda roary
roary [input] -e -n -cd 90 -p 8 -i 90 -f roary_output_w_aln

 FastTreeMP -pseudo -spr 4 -mlacc 2 -slownni -fastest -no2nd -mlnni 4 -gtr -nt -out core_gene_phylogeny.nwk core_gene_alignment.aln 

# 
