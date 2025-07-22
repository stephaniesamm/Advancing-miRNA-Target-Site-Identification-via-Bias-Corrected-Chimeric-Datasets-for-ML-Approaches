#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=download_datasets
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME_0.log) 2>&1

DATA_URL="https://zenodo.org/api/records/14730307/files-archive"
DATA_FILE="Manakov2022_HybriDetectorOutputs.zip"

mkdir -p data
echo "Downloading data from $DATA_URL to data/$DATA_FILE ..."
wget -O "data/$DATA_FILE" "$DATA_URL"
echo "Unzipping data/$DATA_FILE to data/ directory ..."
unzip "data/$DATA_FILE" -d "data"
echo
echo "Data downloaded and unzipped successfully."