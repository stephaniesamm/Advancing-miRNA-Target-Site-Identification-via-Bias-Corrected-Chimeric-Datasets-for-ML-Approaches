#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=benchmarking
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results

exec > >(tee -a results/RUNME.log) 2>&1

DATASETS=(
    "eCLIP_Klimentova2022_test" \
    "CLASH_Hejret2023_test" \
    "eCLIP_Manakov2022_test" \
    "eCLIP_Manakov2022_leftout"
)

mkdir -p results/benchmarking results/evaluation results/pr_curves

# ===== Run Inference =====

echo "Starting benchmarking process..."
python code/benchmark_all.py \
    --out_dir results/benchmarking
echo "Benchmarking process completed successfully."

# ===== Run Evaluation =====

METRICS=(
    "avg_p_score" \
    "auc_pr" \
    "auc_roc"
)
echo
echo "Starting evaluation metrics calculation..."
for DATASET in "${DATASETS[@]}"; do
    for METRIC in "${METRICS[@]}"; do
        echo "Computing ${METRIC} for dataset ${DATASET}..."
        python code/get_metric.py \
            --ifile results/benchmarking/AGO2_${DATASET}_predictions.tsv \
            --ofile results/evaluation/AGO2_${DATASET}_${METRIC}.tsv \
            --metric ${METRIC}
    done
done
echo
echo "Evaluation metrics calculated successfully."

# ===== Create PR Curve Plots =====

echo
echo "Starting PR curve plots generation..."
for DATASET in "${DATASETS[@]}"; do
    echo "Generating PR curve for dataset ${DATASET}..."
    python code/plot_pr_curve.py \
        --ifile results/benchmarking/AGO2_${DATASET}_predictions.tsv \
        --ofile results/pr_curves/AGO2_${DATASET}_pr_curve.png
done

echo
echo "PR curve plots generation completed successfully."
echo
echo
echo "All tasks completed successfully. Check the results directory for outputs and log."






