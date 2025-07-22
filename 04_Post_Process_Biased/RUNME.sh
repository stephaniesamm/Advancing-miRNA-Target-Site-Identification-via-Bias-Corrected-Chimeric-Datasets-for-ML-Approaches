#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=postprocess_biased
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME_1.log) 2>&1

# ===== Download the Manakov2022 positives (concatenated HybriDetector output) if needed =====

mkdir -p data

MANAKOV_POS_URL="https://zenodo.org/records/14501607/files/AGO2_eCLIP_Manakov2022_full_dataset.tsv.gz?download=1"
MANAKOV_POS_GZ="data/AGO2_eCLIP_Manakov2022_positives.tsv.gz"
MANAKOV_POS="data/AGO2_eCLIP_Manakov2022_positives.tsv"

if [[ ! -f "$MANAKOV_POS" ]]; then
    echo "Downloading positives for eCLIP_Manakov2022..."
    wget --progress=dot:giga -O "$MANAKOV_POS_GZ" "$MANAKOV_POS_URL"
    gunzip "$MANAKOV_POS_GZ"
else
    echo "File $MANAKOV_POS already exists. Skipping download."
fi

# ===== Run the post-processing script with the downloaded file =====

echo
echo "Running post-processing script on $MANAKOV_POS..."
bash code/post_process.sh \
    -i data/AGO2_eCLIP_Manakov2022_positives.tsv \
    -o results/ \
    -n results/intermediate/ \
    -t 1,10,100 \
    -r 3

