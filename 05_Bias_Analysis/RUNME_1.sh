#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=bias_analysis
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME_1.log) 2>&1

# ========= CONFIGURATION =========

K=3
COLUMN_NAME="noncodingRNA"
DATASETS=("biasedManakov" "originalHejret" "miraw" "Yang" "unbiasedManakov" "correctedHejret")

# ========= SCRIPT STARTS ==========

for DATASET in "${DATASETS[@]}"; do

    echo
    echo "Analysing dataset: $DATASET"

    # ==== File naming conventions for this DATASET ====

    DATA_DIR="data/${DATASET}_data"
    ENCODING_DIR="results/encoding/${DATASET}"
    TRAINING_DIR="results/training/${DATASET}"
    INFERENCE_DIR="results/predictions/${DATASET}"
    EVALUATION_DIR="results/evaluation/${DATASET}"

    TRAIN_TSV="${DATA_DIR}/${DATASET}_train_set.tsv"
    TEST_TSV="${DATA_DIR}/${DATASET}_test_set.tsv"

    TRAIN_ENCODED="${ENCODING_DIR}/${DATASET}_train_set_encoded.tsv"
    TEST_ENCODED="${ENCODING_DIR}/${DATASET}_test_set_encoded.tsv"

    TRAIN_LABELS="${ENCODING_DIR}/${DATASET}_train_set_labels.npy"
    TEST_LABELS="${ENCODING_DIR}/${DATASET}_test_set_labels.npy"

    MODEL_PKL="${TRAINING_DIR}/${DATASET}_${COLUMN_NAME}_${K}_model.pkl"

    TEST_PRED="${INFERENCE_DIR}/${DATASET}_predictions.npy"
    TEST_RANDOM_PRED="${INFERENCE_DIR}/${DATASET}_random_predictions.npy"

    EVAL_METRICS="${EVALUATION_DIR}/${DATASET}_evaluation.tsv"

    # ==== Additional file naming conventions for unbiasedManakov (leftout set) ====

    if [[ "$DATASET" == "unbiasedManakov" ]]; then
        LEFTOUT_TSV="${DATA_DIR}/${DATASET}_leftout_set.tsv"

        LEFTOUT_ENCODED="${ENCODING_DIR}/${DATASET}_leftout_set_encoded.tsv"

        LEFTOUT_LABELS="${ENCODING_DIR}/${DATASET}_leftout_set_labels.npy"

        LEFTOUT_PRED="${INFERENCE_DIR}/${DATASET}_leftout_predictions.npy"
        LEFTOUT_RANDOM_PRED="${INFERENCE_DIR}/${DATASET}_leftout_random_predictions.npy"

        LEFTOUT_EVAL_METRICS="${EVALUATION_DIR}/${DATASET}_leftout_evaluation.tsv"
    fi

    # ==== Main workflow ====

    mkdir -p "$ENCODING_DIR" "$TRAINING_DIR" "$INFERENCE_DIR" "$EVALUATION_DIR"

    START_TIME=$(date +%s)

    echo "Encoding train set..."
    python code/encode.py \
        --input_dataset "$TRAIN_TSV" \
        --column_name "$COLUMN_NAME" \
        --k "$K" \
        --output_encoding "$TRAIN_ENCODED" \
        --output_labels "$TRAIN_LABELS"

    echo "Training model..."
    python code/train.py \
        --encoded_train_set "$TRAIN_ENCODED" \
        --output_model "$MODEL_PKL" \
        --labels "$TRAIN_LABELS"

    echo "Encoding test set..."
    python code/encode.py \
        --input_dataset "$TEST_TSV" \
        --column_name "$COLUMN_NAME" \
        --k "$K" \
        --output_encoding "$TEST_ENCODED" \
        --output_labels "$TEST_LABELS"

    echo "Predicting on test set..."
    python code/predict.py \
        --encoded_test_set "$TEST_ENCODED" \
        --model "$MODEL_PKL" \
        --output_predictions "$TEST_PRED" \
        --output_random_predictions "$TEST_RANDOM_PRED"

    echo "Evaluating predictions..."
    python code/evaluate.py \
        --predictions "$TEST_PRED" \
        --random_predictions "$TEST_RANDOM_PRED" \
        --labels "$TEST_LABELS" \
        --output_metrics "$EVAL_METRICS"

    # ==== Extra steps for unbiasedManakov (leftout set) ====
    
    if [[ "$DATASET" == "unbiasedManakov" ]]; then
        echo
        echo "Encoding leftout set..."
        python code/encode.py \
            --input_dataset "$LEFTOUT_TSV" \
            --column_name "$COLUMN_NAME" \
            --k "$K" \
            --output_encoding "$LEFTOUT_ENCODED" \
            --output_labels "$LEFTOUT_LABELS"

        echo "Predicting on leftout set..."
        python code/predict.py \
            --encoded_test_set "$LEFTOUT_ENCODED" \
            --model "$MODEL_PKL" \
            --output_predictions "$LEFTOUT_PRED" \
            --output_random_predictions "$LEFTOUT_RANDOM_PRED"

        echo "Evaluating leftout predictions..."
        python code/evaluate.py \
            --predictions "$LEFTOUT_PRED" \
            --random_predictions "$LEFTOUT_RANDOM_PRED" \
            --labels "$LEFTOUT_LABELS" \
            --output_metrics "$LEFTOUT_EVAL_METRICS"
    fi

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo "Finished in $ELAPSED seconds. "
done
