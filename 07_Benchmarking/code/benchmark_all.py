"""
Benchmarks all available miRBench predictors on all available datasets and splits.
Automatically downloads any missing datasets to subdirectories under /home/user/.miRBench/datasets/.
Saves per-tool predictions for each dataset/split.

Usage:
    python benchmark_all.py --out_dir <OUTPUT_DIR>

Arguments:
    --out_dir   Output directory for predictions (default: .)
"""

from miRBench.encoder import get_encoder
from miRBench.predictor import get_predictor, list_predictors
from miRBench.dataset import get_dataset_df, list_datasets
import pandas as pd
import argparse
import os

def benchmark_all(df, dset, split):
    for tool in list_predictors():
        print(f"Running {tool} on {dset} dataset, {split} split")           
        encoder = get_encoder(tool)
        predictor = get_predictor(tool)
        input = encoder(df)
        output = predictor(input)
        df[tool] = output
    return df

def main():
    parser = argparse.ArgumentParser(description="Benchmark all available predictors on all available datasets and splits")
    parser.add_argument("--out_dir", type=str, default=".", help="Output directory for predictions")
    args = parser.parse_args()
    os.makedirs(args.out_dir, exist_ok=True)

    special_dataset = "AGO2_eCLIP_Manakov2022"
    default_split = ["test"]
    special_splits = ["test", "leftout"]

    # Loop over all available datasets
    for dset in list_datasets():
        # Use both splits for Manakov, else only test split
        splits = special_splits if dset == special_dataset else default_split
        for split in splits:
            df = get_dataset_df(dset, split=split)
            output_file = os.path.join(args.out_dir, f"{dset}_{split}_predictions.tsv")
            df_preds = benchmark_all(df, dset, split)
            df_preds.to_csv(output_file, sep='\t', index=False)
            print(f"Predictions for {dset} dataset, {split} split, written to {output_file}")

    print(f"Predictions for all datasets and splits written to {args.out_dir}")

if __name__ == "__main__":
    main()
