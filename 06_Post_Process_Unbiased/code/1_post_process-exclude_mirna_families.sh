#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=pp_1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

# Excludes miRNA families unique to the Manakov dataset from a set of three positive sets.
#   1. Identifies and counts miRNA families unique to Manakov compared to Hejret and Klimentova         (calls code/exclude_mirna_families/unique_family_counter.py)
#   2. Splits Manakov dataset into "excluded" (unique families) and "remaining" (shared families)       (calls code/exclude_mirna_families/dataset_split_based_on_unique_families.py)
#
# Usage:
#   bash 1_post_process-exclude_mirna_families.sh -m <INPUT_MANAKOV> -h <INPUT_HEJRET> -k <INPUT_KLIMENTOVA> -o <OUTPUT_EXCLUDED> -r <OUTPUT_REMAINING> -n <INTERMEDIATE_DIR>
#
# Arguments:
#   -m   Input Manakov TSV
#   -h   Input Hejret TSV
#   -k   Input Klimentova TSV
#   -o   Output TSV for excluded unique families
#   -r   Output TSV for remaining families
#   -n   Directory for intermediate files (unique_family_counts.tsv)

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# parse command-line arguments
while getopts m:h:k:o:r:n: flag; do
    case "${flag}" in
        m) input_manakov=${OPTARG};;
        h) input_hejret=${OPTARG};;
        k) input_klimentova=${OPTARG};;
        o) output_excluded=${OPTARG};;
        r) output_remaining=${OPTARG};;
        n) intermediate_dir=${OPTARG};;
    esac
done

# check if required arguments are provided
if [ -z "${input_manakov:-}" ] || [ -z "${input_hejret:-}" ] || [ -z "${input_klimentova:-}" ] || [ -z "${output_excluded:-}" ] || [ -z "${output_remaining:-}" ] || [ -z "${intermediate_dir:-}" ]; then
    echo "Usage: $0 -m input_manakov.tsv -h input_hejret.tsv -k input_klimentova.tsv -o output_excluded.tsv -r output_remaining.tsv -n intermediate_dir"
    exit 1
fi

# Make sure intermediate dir exists
mkdir -p "$intermediate_dir"

# define paths to the directories where the scripts are located
exclude_families_dir="./code/exclude_mirna_families"

# define path to the intermediate file
counts_file="$intermediate_dir/unique_family_counts.tsv"

# Step 1: Identifying and counting miRNA families that are unique in one dataset relative to the other two datasets
echo "Running unique family counts step on $input_manakov..."
python3 "$exclude_families_dir/unique_family_counter.py" \
    --unique_to "$input_manakov" \
    --input_relative_file1 "$input_hejret" \
    --input_relative_file2 "$input_klimentova" \
    --output_unique_fam_counts "$counts_file"

echo "Unique family counting completed. Output saved to $counts_file"

# Step 2: Filtering dataset based on miRNA families that are unique
echo "Running filtering unique families step on $input_manakov..."
python3 "$exclude_families_dir/dataset_split_based_on_unique_families.py" \
    --unique_to "$input_manakov" \
    --input_unique_fam_counts "$counts_file" \
    --excluded_dataset "$output_excluded" \
    --remaining_dataset "$output_remaining"

echo "Filtering unique families step completed. Outputs saved to $output_excluded and $output_remaining"

echo "Excluding miRNA families unique to Manakov dataset completed successfully."