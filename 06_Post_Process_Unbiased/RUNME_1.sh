#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=postprocess_unbiased
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

# Post-processing pipeline (UNBIASED) for miRNA-target site datasets:
#   1. Filter and deduplicate positive sets                                             (calls code/0_post_process-filter_and_deduplicate.sh)
#   2. Exclude overlapping miRNA families to create "excluded" and "remaining" sets     (calls code/1_post_process-exclude_mirna_families.sh)
#   3. Generate negatives for all major datasets                                        (calls code/2_post_process-make_negatives.sh)
#   4. Split negatives into train and test sets                                         (calls code/3_post_process-train_test_splits.sh)
#   5. Drop the "test" column from the new files                                        (calls code/4_post_process-drop_test_col.sh)
#
# Usage:
#   sbatch RUNME_1.sh
#
# Arguments:
#   All inputs/outputs are specified within the script; no command-line args.
#
# Input files are expected in the `data/` directory, specifically:
#   - data/AGO2_eCLIP_Manakov2022_positives.tsv
#   - data/AGO2_CLASH_Hejret2023_positives.tsv
#   - data/AGO2_eCLIP_Klimentova2022_positives.tsv
# All intermediate and final files are saved in the results/ subdirectories.

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME_1.log) 2>&1

# ========= VARIABLES =========

MANAKOV="eCLIP_Manakov2022"
HEJRET="CLASH_Hejret2023"
KLIMENTOVA="eCLIP_Klimentova2022"

PP0="results/0_post_process"
PP1="results/1_post_process"
PP2="results/2_post_process"
PP3="results/3_post_process"
PP4="results/4_post_process"
FINAL="results"

# ========= HELPER FUNCTION ==========

# Move only if destination doesn't already exist
move_if_not_exists() {
    SRC="$1"
    DEST="$2"
    if [[ -f "$DEST" ]]; then
        echo "File $DEST already exists. Skipping move."
    else
        mv "$SRC" "$DEST"
        echo "Moved $SRC to $DEST."
    fi
}

# ========= SCRIPT STARTS ==========

mkdir -p "$PP0/intermediate" "$PP1/intermediate" "$PP2/intermediate" "$PP3" "$PP4"

echo "===== Running 0_post_process-filter_and_deduplicate.sh ====="
echo
for DATASET in "$MANAKOV" "$HEJRET" "$KLIMENTOVA"; do
    INPUT="data/AGO2_${DATASET}_positives.tsv"
    OUTPUT="${PP0}/AGO2_${DATASET}.filt_and_dedup.tsv"
    if [[ -f "$OUTPUT" ]]; then
        echo "File $OUTPUT already exists. Skipping filter/deduplication for $DATASET."
        continue
    fi   
    bash code/0_post_process-filter_and_deduplicate.sh \
        -i "$INPUT" \
        -o "$OUTPUT" \
        -n "$PP0/intermediate"
done

echo
echo "===== Running 1_post_process-exclude_mirna_families.sh ====="
echo
EXCL="$PP1/AGO2_${MANAKOV}.excluded.tsv"
REM="$PP1/AGO2_${MANAKOV}.remaining.tsv"
if [[ -f "$EXCL" && -f "$REM" ]]; then
    echo "Manakov excluded and remaining files exist. Skipping exclusion step."
else
bash code/1_post_process-exclude_mirna_families.sh \
    -m "$PP0/AGO2_${MANAKOV}.filt_and_dedup.tsv" \
    -h "$PP0/AGO2_${HEJRET}.filt_and_dedup.tsv" \
    -k "$PP0/AGO2_${KLIMENTOVA}.filt_and_dedup.tsv" \
    -o "$EXCL" \
    -r "$REM" \
    -n "$PP1/intermediate"
fi

echo
echo "===== Running 2_post_process-make_negatives.sh ====="
echo

FILES_TO_MAKE_NEGS=(
    "$PP1/AGO2_${MANAKOV}.excluded.tsv"
    "$PP1/AGO2_${MANAKOV}.remaining.tsv"
    "$PP0/AGO2_${KLIMENTOVA}.filt_and_dedup.tsv"
    "$PP0/AGO2_${HEJRET}.filt_and_dedup.tsv"
)

for FILE in "${FILES_TO_MAKE_NEGS[@]}"; do
    OUTPUT="${PP2}/$(basename "$FILE" .tsv).negatives.tsv"
    if [[ -f "$OUTPUT" ]]; then
        echo "File $OUTPUT already exists. Skipping negative generation for $(basename "$FILE")."
        continue
    fi
    bash code/2_post_process-make_negatives.sh \
        -i "$FILE" \
        -o "$OUTPUT" \
        -n "$PP2/intermediate"
done

echo
echo "===== Running 3_post_process-split_negatives.sh ====="
echo
FILES_TO_SPLIT=(
    "$PP2/AGO2_${MANAKOV}.remaining.negatives.tsv"
    "$PP2/AGO2_${HEJRET}.filt_and_dedup.negatives.tsv"
)

for FILE in "${FILES_TO_SPLIT[@]}"; do
    TRAIN="${PP3}/$(basename "$FILE" .tsv).train.tsv"
    TEST="${PP3}/$(basename "$FILE" .tsv).test.tsv"
    if [[ -f "$TRAIN" && -f "$TEST" ]]; then
        echo "Files $TRAIN and $TEST already exist. Skipping splitting for $(basename "$FILE")."
        continue
    fi
    bash code/3_post_process-train_test_splits.sh \
        -i "$FILE" \
        -t "$TRAIN" \
        -e "$TEST"
done

echo
echo "===== Running 4_post_process-drop_test_col.sh ====="
echo

FILES_TO_DROP_TEST_COL=(
    "$PP2/AGO2_${MANAKOV}.excluded.negatives.tsv"
    "$PP2/AGO2_${KLIMENTOVA}.filt_and_dedup.negatives.tsv"
    "$PP3/AGO2_${MANAKOV}.remaining.negatives.train.tsv"
    "$PP3/AGO2_${MANAKOV}.remaining.negatives.test.tsv"
    "$PP3/AGO2_${HEJRET}.filt_and_dedup.negatives.train.tsv"
    "$PP3/AGO2_${HEJRET}.filt_and_dedup.negatives.test.tsv"
)

for FILE in "${FILES_TO_DROP_TEST_COL[@]}"; do
    OUTPUT="$PP4/$(basename "$FILE" .tsv).dropped_test_col.tsv"
    if [[ -f "$OUTPUT" ]]; then
        echo "File $OUTPUT already exists. Skipping dropping test column."
        continue
    fi
    bash code/4_post_process-drop_test_col.sh \
        -i "$FILE" \
        -o "$OUTPUT"
done

echo
move_if_not_exists "$PP4/AGO2_${MANAKOV}.excluded.negatives.dropped_test_col.tsv" "$FINAL/AGO2_${MANAKOV}_leftout.tsv" # final Manakov left-out set
move_if_not_exists "$PP4/AGO2_${MANAKOV}.remaining.negatives.train.dropped_test_col.tsv" "$FINAL/AGO2_${MANAKOV}_train.tsv" # final Manakov train set
move_if_not_exists "$PP4/AGO2_${MANAKOV}.remaining.negatives.test.dropped_test_col.tsv" "$FINAL/AGO2_${MANAKOV}_test.tsv" # final Manakov test set
move_if_not_exists "$PP4/AGO2_${HEJRET}.filt_and_dedup.negatives.train.dropped_test_col.tsv" "$FINAL/AGO2_${HEJRET}_train.tsv" # final Hejret train set
move_if_not_exists "$PP4/AGO2_${HEJRET}.filt_and_dedup.negatives.test.dropped_test_col.tsv" "$FINAL/AGO2_${HEJRET}_test.tsv" # final Hejret test set
move_if_not_exists "$PP4/AGO2_${KLIMENTOVA}.filt_and_dedup.negatives.dropped_test_col.tsv" "$FINAL/AGO2_${KLIMENTOVA}_test.tsv" # final Klimentova test set

echo
echo
echo "==============================================================================="
echo "Post-processing completed successfully. Final datasets are located in $FINAL."
echo "==============================================================================="