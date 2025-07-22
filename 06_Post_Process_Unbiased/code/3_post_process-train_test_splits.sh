#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=pp_3
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

# Splits a dataset into test and train sets based on whether the 6th ('test') column is True or False (indicating whether target site is on chr1).
#
# Usage:
#   bash 3_post_process-train_test_splits.sh -i <INPUT_TSV> -t <OUTPUT_TRAIN_TSV> -e <OUTPUT_TEST_TSV>
#
# Arguments:
#   -i   Input file (TSV)
#   -t   Output train set file (TSV)
#   -e   Output test set file (TSV)

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# parse command-line arguments
while getopts i:t:e: flag; do
    case "${flag}" in
        i) input_file=${OPTARG};;
        t) output_train_file=${OPTARG};;
        e) output_test_file=${OPTARG};;
    esac
done

# Check if required arguments are provided
if [ -z "${input_file:-}" ] || [ -z "${output_train_file:-}" ] || [ -z "${output_test_file:-}" ]; then
    echo "Usage: $0 -i input_file -t output_train_file -e output_test_file"
    exit 1
fi

# Make sure output directories exist
mkdir -p "$(dirname "$output_train_file")" "$(dirname "$output_test_file")"

echo "Splitting data from $input_file into train and test sets..."

awk -F'\t' 'NR==1{header=$0; print header > "'"$output_train_file"'"; print header > "'"$output_test_file"'"} NR>1{if($6=="False"){print > "'"$output_train_file"'"} else {print > "'"$output_test_file"'"}}' "$input_file"

echo "Train set saved to $output_train_file"
echo "Test set saved to $output_test_file"
echo "Train and test split for $input_file completed successfully."