"""
Trains and tunes decision tree, random forest, and XGBoost models with Bayesian optimization, saving final models and cross-validation results.

Usage:
    python train.py --encoded_train_dataset <TRAIN_TSV> --model_types_to_train <MODEL_TYPES> --output_dir <OUTPUT_DIR> [--cv_results_suffix <SUFFIX>] [--final_model_suffix <SUFFIX>]

Arguments:
    --encoded_train_dataset   Path to training feature matrix (TSV)
    --model_types_to_train    List of model types to train (choices: all, dt, rf, xgb)
    --output_dir              Directory to save trained models and CV results
    --cv_results_suffix       Suffix for CV results filenames (default: cv_results)
    --final_model_suffix      Suffix for final model filenames (default: final_model)
"""

import time
import argparse
import sys
import os
import pandas as pd
from sklearn.pipeline import Pipeline
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
import xgboost as xgb
from skopt import BayesSearchCV
from skopt.space import Real, Integer, Categorical
import joblib

# Constants for Bayesian optimization
N_ITER = 30
CV_FOLDS = 5
SCORING = 'average_precision'
BO_SEED = 42

def get_estimator_and_search_spaces(model_type):
    # Returns the estimator and hyperparameter search space for the given model type.
    if model_type == 'dt':
        estimator = DecisionTreeClassifier(class_weight='balanced', random_state=42)
        search_spaces = {
            'criterion': Categorical(['gini', 'entropy']),
            'max_depth': Integer(10, 25),
            'min_samples_split': Real(0.0002, 0.02, prior='log-uniform'),
            'min_samples_leaf': Real(0.0001, 0.01, prior='log-uniform'),
            'max_features': Categorical(['sqrt', 'log2', 0.25, 0.5])
        }
    elif model_type == 'rf':
        estimator = RandomForestClassifier(class_weight='balanced', random_state=42)
        search_spaces = {
            'criterion': Categorical(['gini','entropy']),
            'max_depth': Integer(10, 25),
            'min_samples_split': Real(0.0002, 0.02, prior='log-uniform'),
            'min_samples_leaf': Real(0.0001, 0.01, prior='log-uniform'),
            'n_estimators': Integer(100, 300),
            'max_features': Categorical(['sqrt', 'log2', 0.25, 0.5])
        }
    elif model_type == 'xgb':
        estimator = xgb.XGBClassifier(objective='binary:logistic', random_state=42)
        search_spaces = {
            'n_estimators': Integer(100, 300),
            'max_depth': Integer(3, 10), # default 6
            'learning_rate': Real(0.01, 0.5, prior='log-uniform') # default 0.3
        }
    else:
        # Unsupported model type
        raise ValueError(f"Unsupported model type: {model_type}")
    return estimator, search_spaces

def run_bayes_search(X, y, model_type):
    # Get estimator and search spaces
    estimator, search_spaces = get_estimator_and_search_spaces(model_type)

    # Create a BayesSearchCV object for hyperparameter optimization.
    opt = BayesSearchCV(
        estimator,
        search_spaces,
        n_iter=N_ITER,
        cv=CV_FOLDS, # for integer input, if the estimator is a classifier and y is binary (or multiclass), StratifiedKFold is used by default
        scoring=SCORING,
        random_state=BO_SEED, 
        n_jobs=-1,
        return_train_score=True
    )
    
    # Fit the model using Bayesian optimization with cross-validation and measure the time taken.
    start_time = time.time()
    opt.fit(X, y)
    elapsed = time.time() - start_time
    print("BayesSearchCV for", model_type, "finished in", elapsed, "sec.")

    return opt.cv_results_, opt.best_params_

def train_full_model(X, y, model_type, best_params):
    # Get the estimator and set the best parameters found from Bayesian search.
    estimator, _ = get_estimator_and_search_spaces(model_type)
    estimator.set_params(**best_params)

    # Fit the model on the full dataset and measure the time taken.
    start_time = time.time()
    estimator.fit(X, y)
    elapsed = time.time() - start_time
    print("Full training for", model_type, "finished in", elapsed, "sec.")

    return estimator

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--encoded_train_dataset', type=str, required=True, help="Path to the train feature matrix TSV file")
    parser.add_argument('--model_types_to_train', type=str, nargs='+', default=['all'], choices=['all', 'dt', 'rf', 'xgb'], help="List of model types to train. Use 'all' to run all models (e.g., --model all or --model dt rf).")
    parser.add_argument('--output_dir', type=str, required=True, help='Directory to save the trained models and CV results')
    parser.add_argument('--cv_results_suffix', type=str, default='cv_results', help='Suffix for the CV results file name')
    parser.add_argument('--final_model_suffix', type=str, default='final_model', help='Suffix for the final model file name')
    return parser.parse_args()

def main():
    args = parse_args()
    
    if not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir)
    
    print("Loading train feature matrix from", args.encoded_train_dataset)
    df = pd.read_csv(args.encoded_train_dataset, sep='\t')
    
    feature_columns = [col for col in df.columns if col not in ['noncodingRNA', 'gene', 'label']]
    X = df[feature_columns]
    y = df['label']

    model_types_to_train = ['dt', 'rf', 'xgb'] if 'all' in args.model_types_to_train else args.model_types_to_train

    for model in model_types_to_train:

        # Run Bayesian search
        print("Running Bayesian search for model:", model)
        cv_results, best_params = run_bayes_search(X, y, model)

        # Save the CV results to a TSV file
        cv_results_df = pd.DataFrame(cv_results)
        cv_results_filename = os.path.join(args.output_dir, f"{model}_{args.cv_results_suffix}.tsv")
        cv_results_df.to_csv(cv_results_filename, sep='\t', index=False)
        print("Bayesian search with CV results saved to", cv_results_filename)

        # Run training on full datasets with the best parameters found
        print("Training final model with best parameters:", best_params)
        final_model = train_full_model(X, y, model, best_params)

        # Save the trained model
        final_model_filename = os.path.join(args.output_dir, f"{model}_{args.final_model_suffix}.pkl")
        joblib.dump(final_model, final_model_filename)
        print("Final", model, "model trained on the full dataset saved to", final_model_filename)

if __name__ == '__main__':
    main()
