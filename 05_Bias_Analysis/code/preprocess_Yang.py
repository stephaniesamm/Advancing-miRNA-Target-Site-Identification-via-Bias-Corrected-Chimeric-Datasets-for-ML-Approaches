"""
Preprocesses Yang datasets: concatenates positive and negative CSVs, assigns labels, and renames columns to miRBench standard.

Usage:
    python preprocess_Yang.py --positive_file <POS_CSV> --negative_file <NEG_CSV> --output_file <OUTPUT_TSV>

Arguments:
    --positive_file   Path to CSV file with positive examples
    --negative_file   Path to CSV file with negative examples
    --output_file     Output path for processed dataset (.tsv)
"""

import argparse
import pandas as pd

def main():
    parser = argparse.ArgumentParser(description="Preprocess Yang datasets: concatenate, label, and rename columns to miRBench standard.")
    parser.add_argument("--positive_file", required=True, help="CSV file with positive examples")
    parser.add_argument("--negative_file", required=True, help="CSV file with negative examples")
    parser.add_argument("--output_file", required=True, help="Output TSV filename")
    args = parser.parse_args()

    # Read csv files
    pos_df = pd.read_csv(args.positive_file)
    neg_df = pd.read_csv(args.negative_file) 

    # Add label
    pos_df["label"] = 1
    neg_df["label"] = 0

    # Concatenate
    combined_df = pd.concat([pos_df, neg_df], ignore_index=True)

    # Rename columns
    if "miRNA_seq" not in combined_df.columns:
        raise ValueError("Expected column 'miRNA_seq' not found in input files.")
    combined_df = combined_df.rename(columns={"miRNA_seq": "noncodingRNA"})

    # Save
    combined_df.to_csv(args.output_file, sep='\t', index=False)

if __name__ == "__main__":
    main()
