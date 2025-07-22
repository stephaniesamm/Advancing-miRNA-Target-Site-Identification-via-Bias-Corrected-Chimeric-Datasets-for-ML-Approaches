#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=pp_2
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

# Generates negative samples for miRNA-target site datasets.
#   1. Converts input TSV to FASTA                 (calls code/clustering/gene_fasta.py)
#   2. Performs gene sequence clustering           (calls code/clustering/clustering.R)
#   3. Maps clusters to input file                 (calls code/clustering/map_gene_clusters.py)
#   4. Sorts file by noncodingRNA family
#   5. Generates negative samples                  (calls code/make_neg_sets/make_neg_sets.py)
#
# Usage:
#   bash 2_post_process-make_negatives.sh -i <INPUT_TSV> -o <OUTPUT_TSV> -n <INTERMEDIATE_DIR>
#
# Arguments:
#   -i   Input file (TSV)
#   -o   Output file with added negatives (TSV)
#   -n   Directory for various intermediate files

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

# Ensure intermediate dir and output dir exist
mkdir -p "$intermediate_dir" "$(dirname "$output_file")"

# define paths to the directories where the scripts are located
clustering_dir="./code/clustering"
make_negs_dir="./code/make_neg_sets"

# define constants for suffixes with extensions
CLUSTERING_OUTPUT_SUFFIX=".gene_clusters"
CLUSTERS_ADDED_SUFFIX=".gene_clusters_added"
SORTED_SUFFIX=".mirfam_sorted"

base_name=$(basename "$input_file" .tsv)
fasta_file="$intermediate_dir/${base_name}.fasta"
clustering_output="$intermediate_dir/${base_name}${CLUSTERING_OUTPUT_SUFFIX}.csv"
input_file_with_clusters="$intermediate_dir/${base_name}${CLUSTERS_ADDED_SUFFIX}.tsv"
mirfam_sorted_file="$intermediate_dir/${base_name}${CLUSTERS_ADDED_SUFFIX}${SORTED_SUFFIX}.tsv"

# Step 1: Generating FASTA file
echo "Generating FASTA file for $input_file..."
python3 "$clustering_dir/gene_fasta.py" --input "$input_file" --output "$fasta_file"
echo "FASTA file generated for $input_file. Output saved to $fasta_file"

# Step 2: Performing sequence clustering on gene sequences in the generated FASTA file
echo "Running gene sequence clustering for $fasta_file..."
Rscript "$clustering_dir/clustering.R" "$fasta_file" "$clustering_output"
echo "Gene sequence clustering completed. Output saved to $clustering_output"

# Step 3: Mapping clusters to input file
echo "Mapping clusters to $input_file..."
python3 "$clustering_dir/map_gene_clusters.py" --cluster_csv "$clustering_output" --dataset_tsv "$input_file" --output_tsv "$input_file_with_clusters"
echo "Clusters mapped to $input_file. Output saved to $input_file_with_clusters"

# Step 4: Sort the file based on the noncodingRNA_fam column in preparation for negative sample generation
echo "Sorting the input file with added clusters based on the noncodingRNA_fam column..."

# Find the column number of the "noncodingRNA_fam" column
column_number=$(head -n 1 "$input_file_with_clusters" | tr '\t' '\n' | nl -v 0 | grep "noncodingRNA_fam" | awk '{print $1}') # nl -v 0 (0-based) and sork -k in line 82 (1-based) produce an off-by-1 error that we are aware of and have documented as an issue to fix in future versions

# If the column number is found, sort the file by that column
if [ -n "$column_number" ]; then
    (head -n 1 "$input_file_with_clusters" && tail -n +2 "$input_file_with_clusters" | sort -k "$column_number") > "${mirfam_sorted_file}"
    echo "Input file with added clusters sorted by the 'noncodingRNA_fam' column. Output saved to $mirfam_sorted_file"
else
    echo "Error: 'noncodingRNA_fam' column not found in $mirfam_sorted_file"
    exit 1
fi

# Step 5: Make negatives
echo "Generating negatives for $mirfam_sorted_file..."
python3 "$make_negs_dir/make_neg_sets.py" --ifile "$mirfam_sorted_file" --ofile "$output_file"
echo "Negative samples generated. Output saved to $output_file"

echo "Negative samples generation successfully completed for $input_file"