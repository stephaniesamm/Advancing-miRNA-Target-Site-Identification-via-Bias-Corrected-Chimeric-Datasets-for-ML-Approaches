#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=pp_0
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

# Filters and deduplicates a positive set for unbiased miRNA-target site processing.
#   1. Filters input TSV using code/filtering/filtering.py
#   2. Deduplicates rows based on the first two columns (gene and noncodingRNA)
#
# Usage:
#   bash 0_post_process-filter_and_deduplicate.sh -i <INPUT_TSV> -o <OUTPUT_TSV> -n <INTERMEDIATE_DIR>
#
# Arguments:
#   -i   Input file (.tsv)
#   -o   Output file for filtered/deduplicated data (.tsv)
#   -n   Directory for intermediate files

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# parse command-line arguments
while getopts i:o:n: flag; do
    case "${flag}" in
        i) input_file=${OPTARG};;
        o) output_file=${OPTARG};;
        n) intermediate_dir=${OPTARG};;
    esac
done

# check if required argument is provided
if [ -z "${input_file:-}" ] || [ -z "${output_file:-}" ] || [ -z "${intermediate_dir:-}" ]; then
    echo "Usage: $0 -i input_file -o output_file -n intermediate_dir"
    exit 1
fi

# Make sure intermediate dir and output dir exist
mkdir -p "$intermediate_dir" "$(dirname "$output_file")"

base_name=$(basename "$input_file" .tsv)
filtered_file="$intermediate_dir/${base_name}.filtered.tsv"

# Step 1: Filtering
echo "Running filtering step on $input_file..."
python3 ./code/filtering/filtering.py --ifile "$input_file" --ofile "$filtered_file"
echo "Filtering completed. Output saved to $filtered_file"

# Step 2: Deduplication
echo "Running deduplication step on $filtered_file..."
awk -F'\t' 'NR==1{print $0} NR>1{if(!seen[$1$2]++){print}}' "$filtered_file" > "$output_file"
echo "Deduplication completed. Output saved to $output_file"

echo "Filtering and deduplication of $input_file completed successfully. "