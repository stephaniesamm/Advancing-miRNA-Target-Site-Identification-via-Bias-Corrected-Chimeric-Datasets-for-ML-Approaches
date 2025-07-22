#!/bin/bash

# Post-processing pipeline (BIASED) for miRNA-target site datasets:
#   1. Filtering                (code/filtering.py)
#   2. Deduplication
#   3. Family assignment        (code/family_assign.py)
#   4. Sorting
#   5. Negative generation      (code/make_neg_sets.py)
#   6. Train/test splitting
#   7. Removal of the test column from train/test sets
#
# Usage:
#   bash post_process.sh -i <INPUT_TSV> [-o <OUTPUT_DIR>] [-n <INTERMEDIATE_DIR>] [-t <NEG_RATIOS>] [-r <MIN_EDIT_DIST>]
#
# Arguments:
#   -i   Input data file (TSV, required)
#   -o   Output directory for train/test files (optional; default: ./output)
#   -n   Directory for intermediate files (optional; default: ./intermediate)
#   -t   Comma-separated negative ratios (e.g., 1,10,100; optional; default: 1,10,100)
#   -r   Minimum required edit distance (optional; default: 3)

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# parse command-line arguments
while getopts i:o:n:t:r: flag; do
    case "${flag}" in
        i) input_file=${OPTARG};;
        o) output_dir=${OPTARG};;
        n) intermediate_dir=${OPTARG};;
        t) IFS=',' read -r -a neg_ratios <<< "${OPTARG}";;
        r) min_edit_distance=${OPTARG};;
    esac
done

# check if required argument is provided
if [ -z "$input_file" ]; then
    echo "Usage: $0 -i input_file [-o output_dir] [-n intermediate_dir] [-t neg_ratios] [-r min_edit_distance]"
    exit 1
fi

# set default values for neg_ratios and min_edit_distance if not specified
default_ratios=(1 10 100)
neg_ratios=( "${neg_ratios[@]:-"${default_ratios[@]}"}" )
min_edit_distance=${min_edit_distance:-3}

# define directories for output and intermediate files
output_dir="${output_dir:-$(pwd)/output}"
intermediate_dir="${intermediate_dir:-$(pwd)/intermediate}"
mature_dir="$intermediate_dir/mature"

# create output and intermediate directories if they don't exist
mkdir -p "$intermediate_dir" "$output_dir" "$mature_dir"

# download mature.fa file if it doesn't exist
mature_file="$mature_dir/mature.fa"
if [ ! -f "$mature_file" ]; then
    echo "Downloading mature.fa file..."
    wget -O "$mature_file" "https://www.mirbase.org/download/mature.fa"
    echo "Download completed. File saved to $mature_file"
fi

# define constants for suffixes with extensions
FILTERED_SUFFIX="_filtered_data.tsv"
DEDUPLICATED_SUFFIX="_deduplicated_data.tsv"
FAMILY_ASSIGNED_SUFFIX="_family_assigned_data.tsv"
SORTED_FAMILY_ASSIGNED_SUFFIX="_family_assigned_data_sorted.tsv"
TRAIN_SUFFIX="_train_"
TEST_SUFFIX="_test_"
NEG_SUFFIX="_with_negatives_"

# define file names based on the input file
base_name=$(basename "$input_file" .tsv)
filtered_file="$intermediate_dir/${base_name}${FILTERED_SUFFIX}"
deduplicated_file="$intermediate_dir/${base_name}${DEDUPLICATED_SUFFIX}"
family_assigned_file="$intermediate_dir/${base_name}${FAMILY_ASSIGNED_SUFFIX}"
family_assigned_file_sorted="$intermediate_dir/${base_name}${SORTED_FAMILY_ASSIGNED_SUFFIX}"

# Step 1: Filtering
echo
echo "Running filtering step..."
if [ ! -f "$filtered_file" ]; then
    python3 "code/filtering.py" --ifile "$input_file" --ofile "$filtered_file"
    echo "Filtering completed. Output saved to $filtered_file"
else
    echo "File $filtered_file already exists. Skipping filtering step."
fi

# Step 2: Deduplication
echo
echo "Running deduplication step..."
# deduplicate based on combination of first two columns
if [ ! -f "$deduplicated_file" ]; then
    awk -F'\t' 'NR==1{print $0} NR>1{if(!seen[$1$2]++){print}}' "$filtered_file" > "$deduplicated_file"
    echo "Deduplication completed. Output saved to $deduplicated_file"
else
    echo "File $deduplicated_file already exists. Skipping deduplication step."
fi

# Step 3: Family Assignment
echo
echo "Running family assignment step..."
if [ ! -f "$family_assigned_file" ]; then
    python3 "code/family_assign.py" --ifile "$deduplicated_file" --mature "$mature_file" --ofile "$family_assigned_file"
    echo "Family assignment completed. Output saved to $family_assigned_file"
else
    echo "File $family_assigned_file already exists. Skipping family assignment step."
fi

# Step 4: Sort the family assigned file based on the first (gene) column in preparation for negative sample generation
echo
echo "Sorting the family assigned file based on the first (gene) column..."
if [ ! -f "$family_assigned_file_sorted" ]; then
    (head -n 1 "$family_assigned_file" && tail -n +2 "$family_assigned_file" | sort -k 1) > "${family_assigned_file_sorted}"
    echo "Family assigned file sorted. Output saved to $family_assigned_file_sorted"
else
    echo "File $family_assigned_file_sorted already exists. Skipping sorting step."
fi

# Step 5: Make negatives with different ratios
echo
for ratio in "${neg_ratios[@]}"; do
    echo "Generating negative samples with ratio $ratio..."
    neg_output="$intermediate_dir/${base_name}${NEG_SUFFIX}${ratio}.tsv"
    if [ -f "$neg_output" ]; then
        echo "File $neg_output already exists. Skipping negative generation for ratio $ratio."
        continue
    fi
    python3 "code/make_neg_sets.py" --ifile "$family_assigned_file_sorted" --ofile "$neg_output" --neg_ratio "$ratio" --min_required_edit_distance "$min_edit_distance"
    echo "File with negative samples for ratio $ratio saved to $neg_output"
done
echo "Negative samples generation completed."

# Step 6: Split Train/Test based on the test column
echo
echo "Splitting data into train and test sets based on the test column..."
for ratio in "${neg_ratios[@]}"; do
    neg_file="$intermediate_dir/${base_name}${NEG_SUFFIX}${ratio}.tsv"
    train_file="$output_dir/${base_name}${TRAIN_SUFFIX}${ratio}.tsv"
    test_file="$output_dir/${base_name}${TEST_SUFFIX}${ratio}.tsv"
    if [ -f "$train_file" ] && [ -f "$test_file" ]; then
        echo "Train and test files for ratio $ratio already exist. Skipping split for this ratio."
        continue
    fi
    awk -F'\t' 'NR==1{header=$0; print header > "'"$train_file"'"; print header > "'"$test_file"'"} NR>1{if($5=="False"){print > "'"$train_file"'"} else {print > "'"$test_file"'"}}' "$neg_file"
    echo "Data split completed. Train set saved to $train_file, test set saved to $test_file"
done

# Step 7: Remove the fifth (test) column from the train and test files
echo
echo "Removing the fifth (test) column from the train and test sets..."
for ratio in "${neg_ratios[@]}"; do
    for suffix in "$TRAIN_SUFFIX" "$TEST_SUFFIX"; do
        file="$output_dir/${base_name}${suffix}${ratio}.tsv"
        if [[ $(head -1 "$file" | awk -F'\t' '{print $5}') == "test" ]]; then
            # Use awk to remove the fifth column without causing column shifts
            awk -F'\t' 'BEGIN{OFS="\t"} {for(i=1;i<=NF;i++) if(i!=5) printf "%s%s", $i, (i==NF?"\n":OFS)}' "$file" > "${file}_tmp" && mv "${file}_tmp" "$file"
        else
            echo "No 'test' column in position 5 for $file; skipping."
        fi
    done
done
echo "Fifth (test) column removed from train set and test sets."

echo
echo "==================================================================="
echo "Post-processing pipeline completed successfully."
echo "==================================================================="
