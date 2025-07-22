#!/bin/bash

#SBATCH --account=ssamm10 
#SBATCH --job-name=HD
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --array=1-20%5
#SBATCH --nice=500
#SBATCH --output=HD_%A_%a.out
#SBATCH --error=HD_%A_%a.err

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

IN_DIR="data/"
OUT_DIR="../results"
mkdir -p "$OUT_DIR"
PREPROCESSED_FILE_LIST="$OUT_DIR/preprocessed_chimeCLIP_file_list.txt"

if [[ ! -f "$PREPROCESSED_FILE_LIST" ]]; then
    echo "Generating file list of preprocessed chimeric eCLIP FASTQ files..."
    find "$IN_DIR" -maxdepth 1 \( -type f -o -type l \) -name "*.fastq.gz" -printf "%f\n" | sort > "$PREPROCESSED_FILE_LIST"
    echo "File list generated: $PREPROCESSED_FILE_LIST"
fi

# Read FASTQ filename from the list based on the SLURM array job index
PREPROCESSED_FILE_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$PREPROCESSED_FILE_LIST")
PREPROCESSED_FILE="$IN_DIR/$PREPROCESSED_FILE_NAME"
BASE_NAME=$(basename "$PREPROCESSED_FILE" .fastq.gz)

python HybriDetector.py \
    --input_sample "$BASE_NAME" \
    --read_length 151 \
    --is_umi TRUE \
    --map_perc_single_genomic 0.85 \
    --map_perc_softclip 0.75 \
    --cores 30 \
    --ram 50