#!/bin/bash

# Preprocesses raw FASTQ files by extracting 5' UMI, trimming 3' adapters, and removing 3' UMI.
# Reproduces pipeline from Manakov et al., 2022 (chim-eCLIP, Yeo Lab).
#
# Usage:
#   bash preprocess_raw_chimeCLIP.sh -i <INPUT_FASTQ_GZ> -o <OUTPUT_DIR>
#
# Arguments:
#   -i    Input raw FASTQ file
#   -o    Output directory for temp/, logs/, and final processed files

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

# Help function to display usage
usage() {
    echo "Usage: $0 -i IN_FILE -o OUT_DIR"
    echo
    echo "  -i    Input raw FASTQ file (gzip-compressed)"
    echo "  -o    Output directory containing processed files"
    exit 1
}

# Parse command line arguments
while getopts ":i:o:" opt; do
  case $opt in
    i) IN_FILE="$OPTARG" ;;
    o) OUT_DIR="$OPTARG" ;;
    *) usage ;;
  esac
done

# Ensure required arguments are provided
if [[ -z "${IN_FILE:-}" || -z "${OUT_DIR:-}" ]]; then
    usage
fi

BASE_NAME=$(basename "$IN_FILE" .fastq.gz)

# ----------------------------------------------
# Functions
# ----------------------------------------------

# Run a command if the output does not already exist
function run_step {
    local OUTPUT=$1
    local MSG_START=$2
    local MSG_END=$3
    local CMD=$4

    if [[ ! -f "$OUTPUT" ]]; then
        echo "$MSG_START"
        eval $CMD && echo "$MSG_END"
    else
        echo "$OUTPUT already exists, skipping."
    fi
}

# Delete temp folder if the final output exists
function delete_temp {
    local OUTPUT=$1
    local MSG_START=$2
    local MSG_END=$3
    local CMD=$4

    if [[ -f "$OUTPUT" ]]; then
        echo "$MSG_START"
        eval $CMD && echo "$MSG_END"
    else
        echo "$OUTPUT does not exist, temp folder not deleted."
    fi
}

# ----------------------------------------------
# Pipeline Steps
# ----------------------------------------------

# REPRODUCED FROM https://github.com/YeoLab/chim-eCLIP AS RECOMMENDED BY MANAKOV ET AL., 2022

# Step 1: Extract the 5' UMI from the reads to the read name
## Set the random seed to 1 to ensure reproducibility
## Set the barcode pattern to a 10-nt long UMI with each position being one of any of the four nucleotides

# Step 2: Trim the 3' adapters from the reads
## Set the minimum overlap length for adapter removal to 1
## Set the input format to fastq
## Allow IUPAC wildcards also in the reads
## Number of rounds of adapter matching per read set to 3
## Set the maximum error rate to 0.1
## Set the quality cutoff to 6 for trimming the 3' end of the reads
## Set the minimum length of the reads to 18
## Set the regular 3' adapters to be removed from the reads
## Set the number of cores to use to 8

# Step 3: Trim the 3' UMI from the reads
## Set the number of bases to be removed from the 3' end of the reads to 10 (last 10 bases of the reads)
## Set the number of cores to use to 8


run_step "$OUT_DIR/$BASE_NAME/temp/$BASE_NAME.umi.fastq.gz" \
    "Extracting the 5' UMI from the reads to the read name for $BASE_NAME..." \
    "5' UMI extraction complete." \
    "umi_tools extract \
    --random-seed 1 \
    --stdin $IN_FILE \
    --bc-pattern NNNNNNNNNN \
    --log $OUT_DIR/$BASE_NAME/logs/$BASE_NAME.0_umi_tools.log \
    --stdout $OUT_DIR/$BASE_NAME/temp/$BASE_NAME.umi.fastq && gzip $OUT_DIR/$BASE_NAME/temp/$BASE_NAME.umi.fastq"

run_step "$OUT_DIR/$BASE_NAME/temp/$BASE_NAME.umi.adapter.fastq" \
    "Trimming the 3' adapters from the reads for $BASE_NAME..." \
    "Adapter trimming complete." \
    "cutadapt \
    -O 1 \
    -f fastq \
    --match-read-wildcards \
    --times 3 \
    -e 0.1 \
    --quality-cutoff 6 \
    -m 18 \
    -a AGATCGGAAG \
    -a GATCGGAAGA \
    -a ATCGGAAGAG \
    -a TCGGAAGAGC \
    -a CGGAAGAGCA \
    -a GGAAGAGCAC \
    -a GAAGAGCACA \
    -a AAGAGCACAC \
    -a AGAGCACACG \
    -a GAGCACACGT \
    -a AGCACACGTC \
    -a GCACACGTCT \
    -a CACACGTCTG \
    -a ACACGTCTGA \
    -a CACGTCTGAA \
    -a ACGTCTGAAC \
    -a CGTCTGAACT \
    -a GTCTGAACTC \
    -a TCTGAACTCC \
    -a CTGAACTCCA \
    -a TGAACTCCAG \
    -a GAACTCCAGT \
    -a AACTCCAGTC \
    -a ACTCCAGTCA \
    -j 8 \
    $OUT_DIR/$BASE_NAME/temp/$BASE_NAME.umi.fastq.gz > $OUT_DIR/$BASE_NAME/temp/$BASE_NAME.umi.adapter.fastq 2> $OUT_DIR/$BASE_NAME/logs/$BASE_NAME.1_cutadapt.log"
    
run_step "$OUT_DIR/$BASE_NAME/$BASE_NAME.pp.fastq.gz" \
    "Trimming the 3' UMI from the reads for $BASE_NAME..." \
    "3' UMI trimming complete." \
    "cutadapt \
    -u -10 \
    -j 8 \
    $OUT_DIR/$BASE_NAME/temp/$BASE_NAME.umi.adapter.fastq > $OUT_DIR/$BASE_NAME/$BASE_NAME.pp.fastq 2> $OUT_DIR/$BASE_NAME/logs/$BASE_NAME.2_cutadapt.log && gzip $OUT_DIR/$BASE_NAME/$BASE_NAME.pp.fastq"

delete_temp "$OUT_DIR/$BASE_NAME/$BASE_NAME.pp.fastq.gz" \
    "Deleting temporary output files for $BASE_NAME..." \
    "Temporary output files deleted." \
    "rm -r $OUT_DIR/$BASE_NAME/temp"

