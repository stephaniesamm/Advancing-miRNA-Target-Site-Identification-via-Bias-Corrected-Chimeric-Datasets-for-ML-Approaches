#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=concatenate_files
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME_1.log) 2>&1

DATA_DIR="data"
RESULTS_DIR="results"
OUTPUT_FILE="${RESULTS_DIR}/AGO2_eCLIP_Manakov2022_full_dataset.tsv"

# Initialize a flag to check if the header has been written
HEADER_WRITTEN=false

for FILE in "$DATA_DIR"/*.unified_length_all_types_unique_high_confidence.tsv; do
  # Check if the file exists and is a regular file or a valid symlink to a regular file
  if [ -f "$FILE" ] || { [ -L "$FILE" ] && [ -f "$(readlink -f "$FILE")" ]; }; then
    # If the header hasn't been written yet, write it from the first file
    if [ "$HEADER_WRITTEN" = false ]; then
        head -n1 "$FILE" > "$OUTPUT_FILE"
        HEADER_WRITTEN=true
    fi
    # Append the content (excluding header) to the output file
    tail -n+2 "$FILE" >> "$OUTPUT_FILE"
  else
    # If the file is not a regular file or valid symlink, skip it and print a message
    echo "Skipping "$FILE": Not a regular file or valid symlink."
  fi
done
echo "Concatenation of all files in $DATA_DIR completed. Output written to $OUTPUT_FILE"

echo "Compressing the output file to gzip format..."
gzip -f "$OUTPUT_FILE"
echo "Compression completed. Output file is now $OUTPUT_FILE_GZ.gz"