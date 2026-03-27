#!/bin/bash

while getopts "i:o:h" opt; do
  case $opt in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    h) 
       echo "Usage: ./analyze.sh -i <input_dir> -o <output_dir>"
       exit 0
       ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: You must specify both -i and -o."
    echo "Example: ./analyze.sh -i ./mags -o ./results"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

for genome in "$INPUT_DIR"/*.fna; do
    
    # Get the filename without the path or extension (e.g., "strain1")
    sample_name=$(basename "$genome" .fna)
    
    echo "--------------------------------------------"
    echo "Annotating: $sample_name"
    echo "--------------------------------------------"

    # Run Prokka

    prokka "$genome" \
        --outdir "$OUTPUT_DIR/$sample_name" \
        --prefix "$sample_name" \
        --centre X --compliant

done