#!/bin/bash

while getopts "i:o:h" opt; do
  case $opt in
    i) INPUT_DIR=$(realpath "$OPTARG") ;;
    o) OUTPUT_DIR=$(realpath "$OPTARG") ;;
    h) 
       echo "Usage: ./filippo.sh -i <input_faa_dir> -o <output_dir>"
       echo "Note: Input should contain the .faa files from Prokka."
       exit 0
       ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

echo "$INPUT_DIR"
echo "$OUTPUT_DIR" 
if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: Missing arguments. Use -h for help."
    exit 1
fi

TEMP_DIR="phylo_temp_$(date +%s)"
mkdir -p "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Creating symbolic links in $TEMP_DIR..."
mkdir "$TEMP_DIR"
cd "$TEMP_DIR"
ln -s ../"$INPUT_DIR"/*.faa .
cd ..

echo "Generating configuration files"
mkdir -p conf
cd conf
phylophlan_write_default_configs.sh
cd ..

echo "Running Phylophlan..."
phylophlan -i "$TEMP_DIR" -o "$OUTPUT_DIR" -d phylophlan -t a -f ./conf/supermatrix_aa.cfg --diversity low --fast --nproc 8 --verbose 2>&1 | tee "$OUTPUT_DIR"/ppa_out.log

# 6. Cleanup
echo "Cleaning up temporary files..."
# rm -rf "$TEMP_DIR"
rm -rf conf

echo "Done! Results are in $OUTPUT_DIR"

# phylophlan -i ppa_inp -o ../../results/Phylo -d phylophlan -t a -f ./conf/supermatrix_aa.cfg --diversity low --fast --nproc 8 --verbose 2>&1 | tee ../../results/Phylo/ppa_out.log