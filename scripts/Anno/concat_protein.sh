#!/usr/bin/env bash
set -euo pipefail

# Usage: bash concat_faa.sh <folder_with_faa_files> <name_of_output_file_without_extension>
# Output: tot.faa created inside the target folder

if [ "$#" -ne 1 ]; then
    echo "Usage: bash concat_faa.sh <folder>"
    exit 1
fi

FOLDER="$1"
FILENAME="$2"

if [ ! -d "$FOLDER" ]; then
    echo "ERROR: folder not found: $FOLDER"
    exit 1
fi

OUTPUT="$FOLDER/$FILENAME.faa"

# Check if any .faa files exist (excluding tot.faa itself)
found=0
for f in "$FOLDER"/*.faa; do
    [ "$f" = "$OUTPUT" ] && continue
    [ -e "$f" ] && found=1 && break
done

if [ "$found" -eq 0 ]; then
    echo "ERROR: no .faa files found in $FOLDER"
    exit 1
fi

rm -f "$OUTPUT"

count=0
for f in "$FOLDER"/*.faa; do
    [ "$f" = "$OUTPUT" ] && continue
    echo "  adding: $(basename "$f") ($(grep -c '^>' "$f") sequences)"
    cat "$f" >> "$OUTPUT"
    count=$((count + 1))
done

total_seqs=$(grep -c '^>' "$OUTPUT")
echo ""
echo "done: $count files -> $OUTPUT ($total_seqs sequences total)"