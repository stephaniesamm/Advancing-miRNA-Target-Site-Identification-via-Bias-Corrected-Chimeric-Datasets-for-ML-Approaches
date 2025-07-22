#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=pp_4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

# Removes the 6th ('test') column from a TSV dataset.
#
# Usage:
#   bash 4_post_process-drop_test_col.sh -i <INPUT_TSV> -o <OUTPUT_TSV>
#
# Arguments:
#   -i   Input file (TSV)
#   -o   Output file with 6th ('test') column removed (TSV)

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# parse command-line arguments
while getopts i:o: flag; do
    case "${flag}" in
        i) input_file=${OPTARG};;
        o) output_file=${OPTARG};;
    esac
done

# Check if required arguments are provided
if [ -z "${input_file:-}" ] || [ -z "${output_file:-}" ]; then
    echo "Usage: $0 -i input_file -t output_file"
    exit 1
fi

# Make sure output directory exists
mkdir -p "$(dirname "$output_file")"

# Removing the 'test' (6th) column from the input file
echo "Removing the 'test' (6th) column from $input_file..."

# Use awk to remove the 6th column without causing column shifts
awk -F'\t' 'BEGIN{OFS="\t"} {for(i=1;i<=NF;i++) if(i!=6) printf "%s%s", $i, (i==NF?"\n":OFS)}' "$input_file" > "$output_file"

echo "Dropping 'test' column completed successfully."

echo "Output written to $output_file"