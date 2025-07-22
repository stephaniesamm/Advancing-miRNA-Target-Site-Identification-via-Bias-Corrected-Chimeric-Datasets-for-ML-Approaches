"""
Generates model and random predictions for a k-mer encoded test set using a trained classifier.

Usage:
    python predict.py --encoded_test_set <TEST_TSV> --model <MODEL_PKL> --output_predictions <PREDS_NPY> --output_random_predictions <RAND_PREDS_NPY>

Arguments:
    --encoded_test_set           Path to encoded test dataset (.tsv)
    --model                      Path to trained model (.pkl)
    --output_predictions         Output path for model predictions (.npy)
    --output_random_predictions  Output path for random predictions (.npy)
"""

import pandas as pd
import numpy as np
import joblib
import argparse

def generate_random_predictions(X_test):
    """
    Generates random predictions between 0 and 1 for each sample in X_test.
    Args:
        X_test: The test set (features)
    Returns:
        random_preds: Array of random predictions rounded to 4 decimal places
    """
    # np.random.seed(42)
    random_preds = np.random.rand(len(X_test))
    return random_preds

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--encoded_test_set", type=str, required=True, help="Path to the encoded test dataset (.tsv).")
    parser.add_argument("--model", required=True, help="Path to trained model (.pkl).")
    parser.add_argument("--output_predictions", type=str, required=True, help="Path to save the predictions (.npy).")
    parser.add_argument("--output_random_predictions", type=str, required=True, help="Path to save the random predictions (.npy).")
    args = parser.parse_args()
    
    # Read the encoded test set
    X_test = pd.read_csv(args.encoded_test_set, sep="\t")

    # Load the trained model
    model = joblib.load(args.model)
    
    # Predict on the test set using the model and save the predictions
    y_preds = model.predict_proba(X_test)[:, 1]
    y_preds = np.round(y_preds, 4)
    np.save(args.output_predictions, y_preds)

    # Generate and save random predictions
    random_preds = generate_random_predictions(X_test)
    random_preds = np.round(random_preds, 4)
    np.save(args.output_random_predictions, random_preds)

if __name__ == "__main__":
    main()

