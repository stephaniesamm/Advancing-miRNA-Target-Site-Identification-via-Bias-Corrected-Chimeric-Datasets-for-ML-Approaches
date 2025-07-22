#!/bin/bash
#SBATCH --account=ssamm10
#SBATCH --job-name=retrainCNN
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME.log) 2>&1

# ===== Define variables =====

MANAKOV="AGO2_eCLIP_Manakov2022"
HEJRET="AGO2_CLASH_Hejret2023"
KLIMENTOVA="AGO2_eCLIP_Klimentova2022"

TRAIN_SETS=(
    "${MANAKOV}_train"
    "${HEJRET}_train"
)

TEST_SETS=(
    "${MANAKOV}_test"
    "${MANAKOV}_leftout"
    "${HEJRET}_test"
    "${KLIMENTOVA}_test"
)

ALL_DATASETS=(
    "${TRAIN_SETS[@]}"
    "${TEST_SETS[@]}"
)

mkdir -p results/encoding results/training results/predictions results/evaluation

# ===== Download or locate dataset, and encode it=====
echo
echo "Encoding datasets..."
echo
for DATASET in "${ALL_DATASETS[@]}"; do
    # Extract base dataset name and split (everything before/after last '_')
    DATASET_NAME="${DATASET%_*}"
    SPLIT="${DATASET##*_}"

    echo "Locating dataset: $DATASET_NAME, split: $SPLIT..."
    DATASET_PATH=$(python code/get_dataset_path.py --dataset "$DATASET_NAME" --split "$SPLIT")

    echo "Encoding ${DATASET}.tsv into the 50_20_1 tensor..."
    python code/encode_50_20_1.py \
        --i_file "$DATASET_PATH" \
        --o_prefix "results/encoding/${DATASET}_50_20_1"
    
    echo "Adding dotbracket structures to ${DATASET}.tsv..."
    python code/get_dotbracket_structure.py \
        --dataset_path "$DATASET_PATH" \
        --output_path "results/encoding/${DATASET}_dotbracket.tsv"

    echo "Encoding ${DATASET}.tsv into the 50_20_2 tensor..."
    python code/encode_50_20_2.py \
        --i_file "results/encoding/${DATASET}_dotbracket.tsv" \
        --o_prefix "results/encoding/${DATASET}_50_20_2"
done
echo "All datasets encoded in results/encoding/ directory."

# ===== Train CNN models =====

echo
echo "Training CNN models..."
echo
for DATASET in "$HEJRET" "$MANAKOV"; do
    for CHANNEL in "1" "2"; do
        echo "Training CNN model on ${DATASET} train set using the 50 x 20 x ${CHANNEL} encoding..."
        python code/train_CNN_50_20_channels.py \
            --ratio 1 \
            --data "results/encoding/${DATASET}_train_50_20_${CHANNEL}_dataset.npy" \
            --labels "results/encoding/${DATASET}_train_50_20_${CHANNEL}_labels.npy" \
            --num_rows "results/encoding/${DATASET}_train_50_20_${CHANNEL}_num_rows.npy" \
            --model "results/training/CNN_${DATASET}_train_50_20_${CHANNEL}.keras" \
            --channels "${CHANNEL}" \
            --debug 1
    done
done
echo "CNN models trained and saved in results/training/ directory."

# ===== Predict and evaluate models =====

echo
echo "Predicting and evaluating CNN models on test sets..."
echo
for MODEL in "$HEJRET" "$MANAKOV"; do
    for CHANNEL in "1" "2"; do
        for DATASET in "${TEST_SETS[@]}"; do
            echo "Predicting with ${MODEL} CNN model on ${DATASET} set using the 50 x 20 x ${CHANNEL} encoding..."
            python code/predict.py \
                --model_path "results/training/CNN_${MODEL}_train_50_20_${CHANNEL}.keras" \
                --dataset "results/encoding/${DATASET}_50_20_${CHANNEL}_dataset.npy" \
                --num_rows "results/encoding/${DATASET}_50_20_${CHANNEL}_num_rows.npy" \
                --channels "${CHANNEL}" \
                --output_path "results/predictions/${DATASET}_CNN_${MODEL}_train_50_20_${CHANNEL}_preds.npy"

            echo "Evaluating predictions ${MODEL} CNN model on ${DATASET} set using the 50 x 20 x ${CHANNEL} encoding..."
            python code/evaluate.py \
                --preds_path "results/predictions/${DATASET}_CNN_${MODEL}_train_50_20_${CHANNEL}_preds.npy" \
                --labels_path "results/encoding/${DATASET}_50_20_${CHANNEL}_labels.npy" \
                --output_path "results/evaluation/${DATASET}_CNN_${MODEL}_train_50_20_${CHANNEL}_metrics.json" \
                --model_name "CNN_${MODEL}_train_50_20_${CHANNEL}" \
                --test_set_name "${DATASET}"
        done
    done
done
echo "All predictions and evaluations completed. Results are in results/predictions/ and results/evaluation/ directories."

echo
echo "Script completed successfully. Check results in the results/ directory."