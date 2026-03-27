#!/bin/bash

PERC_IDENTITY=95
EVALUE="1e-10"
OUTPUT_DIR="blast_results"

usage() {
    echo "Usage: $0 -i <input_folder> -d <database_name> [-p <perc_identity>]"
    echo "  -i    Path to folder containing .fna or .fasta files"
    echo "  -d    Name/path of the BLAST database"
    echo "  -p    Percent identity threshold (default: 95)"
    exit 1
}

while getopts "i:d:p:h" opt; do
  case ${opt} in
    i ) INPUT_DIR=$OPTARG ;;
    d ) DB_NAME=$OPTARG ;;
    p ) PERC_IDENTITY=$OPTARG ;;
    h ) usage ;;
    * ) usage ;;
  esac
done

if [ -z "$INPUT_DIR" ] || [ -z "$DB_NAME" ]; then
    echo "Error: Input directory and Database name are required."
    usage
fi

mkdir -p "$OUTPUT_DIR"

echo "Processing files in: $INPUT_DIR"
echo "Using Database: $DB_NAME"
echo "Identity Threshold: $PERC_IDENTITY%"

for FILE in "$INPUT_DIR"/*.{fna,fasta}; do
    [ -e "$FILE" ] || continue
    
    BASENAME=$(basename "$FILE")
    OUT_FILE="${OUTPUT_DIR}/${BASENAME}.blast.txt"

    echo "Running BLAST on $BASENAME..."

    blastn -query "$FILE" \
           -db "$DB_NAME" \
           -outfmt 6 \
           -perc_identity "$PERC_IDENTITY" \
           -evalue "$EVALUE" \
           -out "$OUT_FILE"
done

echo "Finished. Results saved to $OUTPUT_DIR"