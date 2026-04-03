#!/bin/bash
# Script to remember the process for the usage of functionla annotation of specific genes

# [ execution of functional_annoatin.py for the preparation o fthe .faa files for the eggnog-mapper ]

# -------------------- ACHTUM --------------------
# THE DB URL HAS CHANGED, SO THE DOWNLOAD_EGGNOG_DATA.PY SCRIPT MIGH NOT WORK,
# TO FIX THE ISSUE I HAVE CHANGED THE DOMAIN OF THE API REQUEST BY USING:
#
# BASE_URL = f'http://eggnogdb.embl.de/download/emapperdb-{__DB_VERSION__}'
# BASE_URL = f'http://eggnog5.embl.de/download/emapperdb-{__DB_VERSION__}'
# EGGNOG_URL = f'http://eggnog5.embl.de/download/eggnog_5.0/per_tax_level'
# EGGNOG_URL = f'http://eggnog5.embl.de/download/eggnog_5.0/per_tax_level'
# EGGNOG_DOWNLOADS_URL = 'http://eggnog5.embl.de/#/app/downloads'
# EGGNOG_DOWNLOADS_URL = 'http://eggnog5.embl.de/#/app/downloads'
# NOVEL_FAMS_BASE_URL = f'http://eggnogdb.embl.de/download/novel_fams-{__NOVEL_FAMS_DB_VERSION__}'
# NOVEL_FAMS_BASE_URL = f'http://eggnogdb.embl.de/download/novel_fams-{__NOVEL_FAMS_DB_VERSION__}'

# ------------------- END OF ACHTUM -------------------
# May use replace script to fix the db_download file

# Skipping novel families diamond and annotation databases (or already present). Use -F and -f to force download
# Skipping Pfam database (or already present). Use -P and -f to force download
# Skipping MMseqs2 database (or already present). Use -M and -f to force download
# No HMMER database requested. Use "-H -d taxid" to download the hmmer database for taxid
download_eggnog_data.py --data_dir data/dbs/eggnog

emapper.py \
  -i proteins.faa \
  --itype proteins \
  -o my_annotation \
  --output_dir results/ \
  --data_dir /path/to/eggnog_db \
  --cpu 8

# emapper.py -i results/checkm2/protein_files/healthy/tot.faa --itype proteins -o healthy --output_dir results_egg/ --data_dir data/dbs/eggnog/ --cpu 8

# [ Usage of the KeggaNOG tool for the visual representation of the eggNOG results]
# Change the enviornment of from Egg to Kegg since they use different dependancies for python and biopython

conda activate keggnog

KEGGaNOG -M -i results_egg/group_egg_protein.txt -o results/keg --overwrite -g

# group_egg_protein.txt
restults/healthy.emapper.annotations
results/periimpl.emapper.annotations
results/muco.emapper.annotations