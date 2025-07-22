"""
Evaluates average precision scores for model and random predictions using label data.

Usage:
    python evaluate.py --predictions <PREDS_NPY> --random_predictions <RAND_PREDS_NPY> --labels <LABELS_NPY> --output_metrics <METRICS_TSV>

Arguments:
    --predictions         Path to model predictions (.npy)
    --random_predictions  Path to random predictions (.npy)
    --labels              Path to ground truth labels (.npy)
    --output_metrics      Output path for evaluation metrics (.tsv)
"""

import pandas as pd
import numpy as np
from sklearn.metrics import average_precision_score
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--predictions", type=str, required=True, help="Path to the predictions file (.npy).")
    parser.add_argument("--random_predictions", type=str, required=True, help="Path to the random predictions file (.npy).")
    parser.add_argument("--labels", type=str, required=True, help="Path to the labels file (.npy).")
    parser.add_argument("--output_metrics", type=str, required=True, help="Path to save the evaluation metrics (.tsv).")
    args = parser.parse_args()

    # Load predictions, random predictions, and labels
    y_preds = np.load(args.predictions)
    random_preds = np.load(args.random_predictions)
    y_test = np.load(args.labels)

    # Check if the lengths of predictions and labels match
    if len(y_preds) != len(y_test):
        raise ValueError("The length of predictions and labels must be the same.")
    if len(random_preds) != len(y_test):
        raise ValueError("The length of random predictions and labels must be the same.")
    
    # Calculate average precision scores
    av_prec_score = average_precision_score(y_test, y_preds)
    random_av_prec_score = average_precision_score(y_test, random_preds)

    # Round the scores to 3 decimal places
    av_prec_score = round(av_prec_score, 3)
    random_av_prec_score = round(random_av_prec_score, 3)

    # Create a DataFrame to store the metrics
    metrics_df = pd.DataFrame({
        "Model": ["Decision Tree", "Random Classifier"],
        "Average Precision Score": [av_prec_score, random_av_prec_score]
    })

    # Save the metrics to a TSV file
    metrics_df.to_csv(args.output_metrics, sep="\t", index=False)

if __name__ == "__main__":
    main()

    