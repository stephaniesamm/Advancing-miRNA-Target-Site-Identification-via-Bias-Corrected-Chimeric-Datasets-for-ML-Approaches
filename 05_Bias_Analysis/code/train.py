"""
Trains a Decision Tree classifier on a k-mer encoded train set and saves the model.

Usage:
    python train.py --encoded_train_set <TRAIN_TSV> --labels <LABELS_NPY> --output_model <MODEL_PKL>

Arguments:
    --encoded_train_set  Path to encoded training set (.tsv)
    --labels             Path to labels file (.npy)
    --output_model       Output path to save trained model (.pkl)
"""

import pandas as pd
import numpy as np
from sklearn.tree import DecisionTreeClassifier
import joblib
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--encoded_train_set", type=str, required=True, help="Path to the encoded dataset (.tsv).")
    parser.add_argument("--labels", type=str, required=True, help="Path to the labels file (.npy).")
    parser.add_argument("--output_model", type=str, required=True, help="Path to save the trained model (.pkl).")
    args = parser.parse_args()

    # Read the encoded training set and labels
    X_train = pd.read_csv(args.encoded_train_set, sep="\t")
    y_train = np.load(args.labels)
    
    # Check if the number of samples in X_train matches y_train
    if len(X_train) != len(y_train):
        raise ValueError("The number of samples in the training set does not match the number of labels.")
    
    # Train a Decision Tree Classifier
    model = DecisionTreeClassifier(random_state=42)
    model.fit(X_train, y_train)
    
    # Save the trained model to a file
    joblib.dump(model, args.output_model)

if __name__ == "__main__":
    main()
