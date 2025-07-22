#!/bin/bash

#SBATCH --account=ssamm10 
#SBATCH --job-name=pp_raw_chimeCLIP
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --array=1-20%5
#SBATCH --nice=500
#SBATCH --output=pp_%A_%a.out
#SBATCH --error=pp_%A_%a.err

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

IN_DIR="data/"
OUT_DIR="results/"
RAW_FILE_LIST="$OUT_DIR/raw_chimeCLIP_file_list.txt"

if [[ ! -f "$RAW_FILE_LIST" ]]; then
    echo "Generating file list of raw chimeric eCLIP FASTQ files..."
    find "$IN_DIR" -maxdepth 1 \( -type f -o -type l \) -name "*.fastq.gz" -printf "%f\n" | sort > "$RAW_FILE_LIST"
    echo "File list generated: $RAW_FILE_LIST"
fi

# Read FASTQ filename from the list based on the SLURM array job index
RAW_FILE_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$RAW_FILE_LIST")
RAW_FILE="$IN_DIR/$RAW_FILE_NAME"
BASE_NAME=$(basename "$RAW_FILE" .fastq.gz)

# Create required directories
mkdir -p "$OUT_DIR/$BASE_NAME/temp" "$OUT_DIR/$BASE_NAME/logs"

bash code/preprocess_raw_chimeCLIP.sh -i "$RAW_FILE" -o "$OUT_DIR"