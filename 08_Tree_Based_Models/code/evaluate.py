"""
Calculates average precision scores for multiple model prediction columns in a TSV, saving results to a metrics file.

Usage:
    python evaluate.py --input_pred_labels_file <INPUT_TSV> --output_eval_metrics <OUTPUT_TSV>

Arguments:
    --input_pred_labels_file   Input TSV containing predictions and labels
    --output_eval_metrics      Output TSV file for evaluation metrics
"""

import pandas as pd
import numpy as np
from sklearn.metrics import average_precision_score
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_pred_labels_file", type=str, required=True, help="Path to the input dataframe file containing predictions and labels (.tsv).")
    parser.add_argument("--output_eval_metrics", type=str, required=True, help="Path to save the evaluation metrics (.tsv).")
    args = parser.parse_args()

    # Load the input file containing predictions and labels
    df = pd.read_csv(args.input_pred_labels_file, sep="\t")

    # Extract the labels
    y_test = df["label"]

    # Extract the model names from the DataFrame columns, containing the predictions
    models = [col for col in df.columns if col.endswith("final_model")]
    
    evaluation_dict = {}

    # Evaluate each model's predictions and add to the evaluation dict
    for model in models:
        y_preds = df[model]
        av_prec_score = average_precision_score(y_test, y_preds)
        av_prec_score = round(av_prec_score, 3)
        evaluation_dict[model] = av_prec_score

    # Create a DataFrame to store the evaluation metrics
    evaluation_df = pd.DataFrame([evaluation_dict])

    # Save the metrics to a TSV file
    evaluation_df.to_csv(args.output_eval_metrics, sep="\t", index=False)

if __name__ == "__main__":
    main()

    