#!/bin/bash

usage() {
    echo "Usage: $0 [-f input_file.fna] [-d input_directory] -o output_directory"
    echo "  -f : Path to a single .fna file"
    echo "  -d : Path to a directory containing multiple .fna files"
    echo "  -o : Output directory (required)"
    exit 1
}

while getopts "f:d:o:" opt; do
    case $opt in
        f) INPUT_FILE=$OPTARG ;;
        d) INPUT_DIR=$OPTARG ;;
        o) OUTPUT_DIR=$OPTARG ;;
        *) usage ;;
    esac
done

# output directory is required
if [ -z "$OUTPUT_DIR" ]; then
    echo "Error: Output directory (-o) is required."
    usage
fi

# Create output directory if it doesn't exist
# -p option : creates the full directory path (D1/D2/...) if missing and avoids errors if it already exists.
mkdir -p "$OUTPUT_DIR" 

# --- MODE 1: SINGLE FILE ---
if [ ! -z "$INPUT_FILE" ]; then
    echo "Running CheckM on single file: $INPUT_FILE"
    
    # Create temporary copy of the file inside a temporary folder because CheckM needs a folder as input
    TEMP_DIR="temp_checkm_$(basename "$INPUT_FILE")"
    mkdir -p "$TEMP_DIR"
    cp "$INPUT_FILE" "$TEMP_DIR/"
    
    # --force: Overwrites the output directory
    checkm2 predict --threads 8 --extension fna --input "$TEMP_DIR" --output-directory "$OUTPUT_DIR" --force
    
    # Cleanup temp folder
    rm -rf "$TEMP_DIR"

# --- MODE 2: DIRECTORY BATCH ---
elif [ ! -z "$INPUT_DIR" ]; then
    echo "Running CheckM on all .fna files in: $INPUT_DIR"
    
    checkm2 predict --threads 8 --extension fna --input "$INPUT_DIR" --output-directory "$OUTPUT_DIR" --force
else
    echo "Error: You must provide either a file (-f) or a directory (-d)."
    usage
fi