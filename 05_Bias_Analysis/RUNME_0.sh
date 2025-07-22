#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=download_datasets
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME_0.log) 2>&1

# ========= FILE NAMES =========

# Manakov
BIASED_MANAKOV_TRAIN="data/biasedManakov_data/biasedManakov_train_set.tsv"
BIASED_MANAKOV_TEST="data/biasedManakov_data/biasedManakov_test_set.tsv"
UNBIASED_MANAKOV_TRAIN_GZ="data/unbiasedManakov_data/unbiasedManakov_train_set.tsv.gz"
UNBIASED_MANAKOV_TRAIN="data/unbiasedManakov_data/unbiasedManakov_train_set.tsv"
UNBIASED_MANAKOV_TEST_GZ="data/unbiasedManakov_data/unbiasedManakov_test_set.tsv.gz"
UNBIASED_MANAKOV_TEST="data/unbiasedManakov_data/unbiasedManakov_test_set.tsv"
UNBIASED_MANAKOV_LEFTOUT_GZ="data/unbiasedManakov_data/unbiasedManakov_leftout_set.tsv.gz"
UNBIASED_MANAKOV_LEFTOUT="data/unbiasedManakov_data/unbiasedManakov_leftout_set.tsv"

# Hejret
ORIG_HEJRET_TRAIN="data/originalHejret_data/originalHejret_train_set.tsv"
ORIG_HEJRET_TEST="data/originalHejret_data/originalHejret_test_set.tsv"
CORR_HEJRET_TRAIN_GZ="data/correctedHejret_data/correctedHejret_train_set.tsv.gz"
CORR_HEJRET_TRAIN="data/correctedHejret_data/correctedHejret_train_set.tsv"
CORR_HEJRET_TEST_GZ="data/correctedHejret_data/correctedHejret_test_set.tsv.gz"
CORR_HEJRET_TEST="data/correctedHejret_data/correctedHejret_test_set.tsv"

# Yang
YANG_TRAIN_ZIP="data/Yang_data/Training_data.zip"
YANG_TRAIN_POS="data/Yang_data/Training_data/positive_training_data.csv"
YANG_TRAIN_NEG="data/Yang_data/Training_data/negative_training_data.csv"
YANG_TEST_ZIP="data/Yang_data/Test_data.zip"
YANG_TEST_POS="data/Yang_data/Test_data/positive_test_data.csv"
YANG_TEST_NEG="data/Yang_data/Test_data/negative_test_data.csv"
YANG_TRAIN="data/Yang_data/Yang_train_set.tsv"
YANG_TEST="data/Yang_data/Yang_test_set.tsv"

# miRAW
MIRAW_DATA_DIR="data/miraw_data"
PLOS_7Z="$MIRAW_DATA_DIR/PLOSComb.7z"
MIRAW_TRAIN_INPUT="${MIRAW_DATA_DIR}/PLOSComb/Data/ValidTargetSites/allTrainingSites.txt"
MIRAW_TEST_INPUT="${MIRAW_DATA_DIR}/PLOSComb/Data/TestData/balanced10/randomLeveragedTestSplit_0.csv"
MIRAW_TRAIN="${MIRAW_DATA_DIR}/miraw_train_set.tsv"
MIRAW_TEST="${MIRAW_DATA_DIR}/miraw_test_set.tsv"

# ========= URLS =========

# Manakov
BIASED_MANAKOV_TRAIN_URL="https://zenodo.org/records/13909173/files/AGO2_eCLIP_Manakov2022_1_train_dataset.tsv?download=1"
BIASED_MANAKOV_TEST_URL="https://zenodo.org/records/13909173/files/AGO2_eCLIP_Manakov2022_1_test_dataset.tsv?download=1"
UNBIASED_MANAKOV_TRAIN_URL="https://zenodo.org/records/14501607/files/AGO2_eCLIP_Manakov2022_train.tsv.gz?download=1"
UNBIASED_MANAKOV_TEST_URL="https://zenodo.org/records/14501607/files/AGO2_eCLIP_Manakov2022_test.tsv.gz?download=1"
UNBIASED_MANAKOV_LEFTOUT_URL="https://zenodo.org/records/14501607/files/AGO2_eCLIP_Manakov2022_leftout.tsv.gz?download=1"

# Hejret
ORIG_HEJRET_TRAIN_URL="https://raw.githubusercontent.com/ML-Bioinfo-CEITEC/HybriDetector/main/ML/Datasets/miRNA_train_set.tsv"
ORIG_HEJRET_TEST_URL="https://raw.githubusercontent.com/ML-Bioinfo-CEITEC/HybriDetector/main/ML/Datasets/miRNA_test_set_1.tsv"
CORR_HEJRET_TRAIN_URL="https://zenodo.org/records/14501607/files/AGO2_CLASH_Hejret2023_train.tsv.gz?download=1"
CORR_HEJRET_TEST_URL="https://zenodo.org/records/14501607/files/AGO2_CLASH_Hejret2023_test.tsv.gz?download=1"

# Yang
YANG_TRAIN_ZIP_URL="http://cosbi2.ee.ncku.edu.tw/mirna_binding/download/download_data"
YANG_TEST_ZIP_URL="http://cosbi2.ee.ncku.edu.tw/mirna_binding/download/download_test_data"

# miRAW
MIRAW_REPO_URL="https://app86@bitbucket.org/bipous/miraw_data.git"

# ========= SCRIPT STARTS =========

mkdir -p data/biasedManakov_data data/originalHejret_data data/Yang_data data/unbiasedManakov_data data/correctedHejret_data

# --- Biased Manakov loop ---
echo "Downloading the biased Manakov datasets..."
for SET in TRAIN TEST; do
    VAR="BIASED_MANAKOV_${SET}"
    URL_VAR="BIASED_MANAKOV_${SET}_URL"
    FILE="${!VAR}"
    URL="${!URL_VAR}"
    if [ ! -f "$FILE" ]; then
        wget --progress=dot:giga -nc -O "$FILE" "$URL"
    else
        echo "$FILE already exists, skipping download."
    fi
done

# --- Unbiased Manakov loop ---
echo
echo "Downloading and gunzipping the unbiased Manakov datasets..."
for SET in TRAIN TEST LEFTOUT; do
    GZ_VAR="UNBIASED_MANAKOV_${SET}_GZ"
    TSV_VAR="UNBIASED_MANAKOV_${SET}"
    URL_VAR="UNBIASED_MANAKOV_${SET}_URL"
    GZ="${!GZ_VAR}"
    TSV="${!TSV_VAR}"
    URL="${!URL_VAR}"
    if [ ! -f "$TSV" ]; then
        wget --progress=dot:giga -nc -O "$GZ" "$URL"
        gunzip "$GZ"
    else
        echo "$TSV already exists, skipping download and gunzip."
    fi
done


# --- Original Hejret loop ---
echo
echo "Downloading the original Hejret datasets..."
for SET in TRAIN TEST; do
    VAR="ORIG_HEJRET_${SET}"
    URL_VAR="ORIG_HEJRET_${SET}_URL"
    FILE="${!VAR}"
    URL="${!URL_VAR}"
    if [ ! -f "$FILE" ]; then
        wget --progress=dot:giga -nc -O "$FILE" "$URL"
    else
        echo "$FILE already exists, skipping download."
    fi
done

# --- Corrected Hejret loop ---
echo
echo "Downloading and gunzipping the corrected Hejret datasets..."
for SET in TRAIN TEST; do
    GZ_VAR="CORR_HEJRET_${SET}_GZ"
    TSV_VAR="CORR_HEJRET_${SET}"
    URL_VAR="CORR_HEJRET_${SET}_URL"
    GZ="${!GZ_VAR}"
    TSV="${!TSV_VAR}"
    URL="${!URL_VAR}"
    if [ ! -f "$TSV" ]; then
        wget --progress=dot:giga -nc -O "$GZ" "$URL"
        gunzip "$GZ"
    else
        echo "$TSV already exists, skipping download and gunzip."
    fi
done

# --- miRAW repository ---
echo
if [ ! -d "$MIRAW_DATA_DIR" ]; then
    echo "Cloning the miRAW repository..."
    git clone "$MIRAW_REPO_URL" "$MIRAW_DATA_DIR"
else
    echo "miraw_data already exists, skipping clone."
fi

# Extract PLOSComb.7z if present
if [ -f "$PLOS_7Z" ]; then
    echo "Extracting $PLOS_7Z..."
    7z x "$PLOS_7Z" -o"$MIRAW_DATA_DIR"
else
    echo "No PLOSComb.7z archive found in $MIRAW_DATA_DIR."
fi

# --- Yang datasets ---
echo
echo "Downloading and unzipping the Yang datasets..."

for SPLIT in TRAIN TEST; do
    ZIP_VAR="YANG_${SPLIT}_ZIP"
    ZIP_URL_VAR="YANG_${SPLIT}_ZIP_URL"
    POS_VAR="YANG_${SPLIT}_POS"
    ZIP="${!ZIP_VAR}"
    ZIP_URL="${!ZIP_URL_VAR}"
    POS="${!POS_VAR}"
    if [ ! -f "$POS" ]; then
        wget --progress=dot:giga -nc -O "$ZIP" "$ZIP_URL"
        unzip "$ZIP" -d data/Yang_data/
    else
        echo "$POS already exists, skipping unzip."
    fi
done

# --- Preprocessing miRAW datasets ---
echo
echo "Preprocessing miRAW datasets..."
for SPLIT in TRAIN TEST; do
    OUT_VAR="MIRAW_${SPLIT}"
    IN_VAR="MIRAW_${SPLIT}_INPUT"
    OUT="${!OUT_VAR}"
    IN="${!IN_VAR}"
    if [ ! -f "$OUT" ]; then
        python code/preprocess_miRAW.py --input_file "$IN" --output_file "$OUT"
    else
        echo "$OUT already exists, skipping preprocessing."
    fi
done

# --- Preprocessing Yang datasets ---
echo
echo "Preprocessing Yang datasets..."
for SPLIT in TRAIN TEST; do
    OUT_VAR="YANG_${SPLIT}"
    POS_VAR="YANG_${SPLIT}_POS"
    NEG_VAR="YANG_${SPLIT}_NEG"
    OUT="${!OUT_VAR}"
    POS="${!POS_VAR}"
    NEG="${!NEG_VAR}"
    if [ ! -f "$OUT" ]; then
        python code/preprocess_Yang.py --positive_file "$POS" --negative_file "$NEG" --output_file "$OUT"
    else
        echo "$OUT already exists, skipping preprocessing."
    fi
done

echo
echo "All datasets have been downloaded and preprocessed successfully."
