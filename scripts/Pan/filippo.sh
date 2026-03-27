#!/bin/bash

while getopts "i:o:h" opt; do
  case $opt in
    i) INPUT_DIR=$(realpath "$OPTARG") ;;
    o) OUTPUT_DIR=$(realpath "$OPTARG") ;;
    h) 
       echo "Usage: ./filippo.sh -i <input_gff_dir> -o <output_dir>"
       echo "Note: Input should contain the .gff files from Prokka."
       exit 0
       ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: Missing arguments. Use -h for help."
    exit 1
fi

TEMP_DIR="roary_temp_$(date +%s)"
mkdir -p "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Creating symbolic links in $TEMP_DIR..."

# 4. Link the files
# Find all .gff in subfolders of the input path
find "$INPUT_DIR" -name "*.gff" -exec ln -s {} "$TEMP_DIR/" \;

cd "$TEMP_DIR" || exit

echo "Running Roary..."
# -f: Output directory
# -e: Create a multi-FASTA alignment of core genes
roary -e --mafft -cd 80 -p 4 -f "$OUTPUT_DIR" *.gff

cd ..

# 6. Cleanup
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "Done! Results are in $OUTPUT_DIR"