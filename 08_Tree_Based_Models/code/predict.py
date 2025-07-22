"""
Generates prediction probabilities for one or more trained models and appends the results as columns to a test dataset.

Usage:
    python predict.py --encoded_test_dataset <TEST_TSV> --models <MODEL1_PKL> <MODEL2_PKL> ... --output_predictions <OUTPUT_TSV>

Arguments:
    --encoded_test_dataset   Path to encoded test dataset (TSV)
    --models                Paths to one or more trained model files (Pickle .pkl)
    --output_predictions    Output path for test dataset with added prediction columns (TSV)
"""

import argparse
import os
import pandas as pd
import numpy as np
import joblib

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--encoded_test_dataset', type=str, required=True, help='Path to the encoded test dataset (TSV file)')
    parser.add_argument('--models', type=str, nargs='+', required=True, help='Paths to the saved trained models (pickle files)')
    parser.add_argument('--output_predictions', type=str, required=True, help='Path to save the encoded test dataset with added prediction column per model (TSV file)')
    return parser.parse_args()

def main():
    args = parse_args()
    
    # Load the encoded test dataset
    df = pd.read_csv(args.encoded_test_dataset, sep='\t')
    
    # Extract feature columns (excluding 'noncodingRNA', 'gene', and 'label')
    feature_columns = [col for col in df.columns if col not in ['noncodingRNA', 'gene', 'label']]
    X_test = df[feature_columns]
    
    # Load each model and run inference on the test dataset
    for model_path in args.models:
        model = joblib.load(model_path)
        y_pred_proba = model.predict_proba(X_test)[:, 1]
        y_pred_proba = np.round(y_pred_proba, 4)

        # Add the predictions to the DataFrame
        model_basename = os.path.splitext(os.path.basename(model_path))[0]
        df[model_basename] = y_pred_proba

    # Save the encoded test dataset with added prediction columns to a TSV file
    df.to_csv(args.output_predictions, sep='\t', index=False)
    print(f"Predictions for {args.encoded_test_dataset} saved to {args.output_predictions}")

if __name__ == '__main__':
    main()
