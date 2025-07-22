#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=tree_models
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME.log) 2>&1

BASENAME="AGO2_eCLIP_Manakov2022"
DATASETS=(
    "train" \
    "test" \
    "leftout"
)

mkdir -p results/encoding results/training results/predictions results/evaluation

# ===== Download or locate dataset, and encode it =====

echo
for DATASET in "${DATASETS[@]}"; do
    echo "Locating dataset path for ${BASENAME}, split ${DATASET}..."
    DATASET_PATH=$(python code/get_dataset_path.py --dataset "$BASENAME" --split "$DATASET")
    echo
    echo "Encoding dataset ${BASENAME}_${DATASET}.tsv..."
    python code/encode.py \
        --input_dataset "$DATASET_PATH" \
        --output_encoded_dataset "results/encoding/${BASENAME}_${DATASET}_encoded.tsv"
done
echo "Encoding completed for all datasets."

# ===== Train models =====

echo
echo "Training models..."
python code/train.py \
    --encoded_train_dataset "results/encoding/${BASENAME}_train_encoded.tsv" \
    --model_types_to_train all \
    --output_dir results/training \
    --cv_results_suffix cv_results \
    --final_model_suffix final_model
echo "Model training completed."

# ===== Run inference & evaluation =====

DATASETS_FOR_INFERENCE=(
    "test" \
    "leftout"
)
echo
for DATASET in "${DATASETS_FOR_INFERENCE[@]}"; do
    echo "Running inference on dataset ${BASENAME}_${DATASET}_encoded.tsv..."
    python code/predict.py \
        --encoded_test_dataset "results/encoding/${BASENAME}_${DATASET}_encoded.tsv" \
        --models results/training/dt_final_model.pkl results/training/rf_final_model.pkl results/training/xgb_final_model.pkl \
        --output_predictions "results/predictions/${BASENAME}_${DATASET}_predictions.tsv"

    echo "Evaluating inference..."
    python code/evaluate.py \
        --input_pred_labels_file "results/predictions/${BASENAME}_${DATASET}_predictions.tsv" \
        --output_eval_metrics "results/evaluation/${BASENAME}_${DATASET}_eval_metrics.tsv"

    echo "Inference and evaluation completed for dataset ${BASENAME}_${DATASET}.tsv."
done

echo "All inference and evaluation tasks completed."

echo 
echo
echo "All tasks completed successfully."
