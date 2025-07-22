#!/bin/bash

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME_0.log) 2>&1

mkdir -p data

MANAKOV_POS_URL="https://zenodo.org/records/14501607/files/AGO2_eCLIP_Manakov2022_full_dataset.tsv.gz?download=1"
HEJRET_POS_URL="https://raw.githubusercontent.com/ML-Bioinfo-CEITEC/HybriDetector/refs/heads/main/ML/Datasets/AGO2_CLASH_Hejret2023_full_dataset.tsv"
KLIMENTOVA_URL="https://raw.githubusercontent.com/ML-Bioinfo-CEITEC/miRBind/refs/heads/main/Datasets/AGO2_eCLIP_Klimentova22_full_dataset.tsv"

# Downloading and unzipping the Manakov dataset
MANAKOV_POS_GZ="data/AGO2_eCLIP_Manakov2022_positives.tsv.gz"
MANAKOV_POS="data/AGO2_eCLIP_Manakov2022_positives.tsv"
if [[ ! -f "$MANAKOV_POS" ]]; then
    echo "Downloading positives for eCLIP_Manakov2022..."
    wget --progress=dot:giga -O "$MANAKOV_POS_GZ" "$MANAKOV_POS_URL"
    gunzip "$MANAKOV_POS_GZ"
else
    echo "File $MANAKOV_POS already exists. Skipping download."
fi

# Downloading the Hejret and Klimentova datasets
for DATASET in "CLASH_Hejret2023" "eCLIP_Klimentova2022"; do
    POSITIVES="data/AGO2_${DATASET}_positives.tsv"
    if [[ ! -f "$POSITIVES" ]]; then
        echo "Downloading positives for $DATASET..."
        if [[ "$DATASET" == "CLASH_Hejret2023" ]]; then
            URL="$HEJRET_POS_URL"
        elif [[ "$DATASET" == "eCLIP_Klimentova2022" ]]; then
            URL="$KLIMENTOVA_URL"
        fi
        wget --progress=dot:giga -O "${POSITIVES}" "${URL}"
    else
        echo "File $POSITIVES already exists. Skipping download."
    fi
done

# Renaming miRNA_fam to noncodingRNA_fam in the downloaded Hejret and Klimentova datasets
for DATASET in "CLASH_Hejret2023" "eCLIP_Klimentova2022"; do
    POSITIVES="data/AGO2_${DATASET}_positives.tsv"
    TMP="data/AGO2_${DATASET}_positives.tmp"
    if grep -q 'miRNA_fam' "$POSITIVES"; then
        echo "Renaming miRNA_fam to noncodingRNA_fam in $POSITIVES"
        awk 'BEGIN{FS=OFS="\t"} NR==1{for(i=1;i<=NF;i++) if($i=="miRNA_fam") $i="noncodingRNA_fam"} 1' "$POSITIVES" > "$TMP"
        mv "$TMP" "$POSITIVES"
    else
        echo "No miRNA_fam column found in $POSITIVES; skipping rename."
    fi
done

echo "All downloads and renames complete."