"""
Generates a k-mer count matrix from a sequence column in a TSV dataset.

Usage:
    python encode.py --input_dataset <INPUT_TSV> --column_name <SEQ_COLUMN> --k <K> --output_encoding <KMERS_TSV> [--output_labels <LABELS_NPY>]

Arguments:
    --input_dataset    Path to the input TSV dataset.
    --column_name      Name of the column containing sequences. 
    --k                Length of k-mers.
    --output_encoding  Output path for the k-mer count matrix (.tsv).
    --output_labels    (Optional) Output path for the label array (.npy).
"""

import pandas as pd
import numpy as np
from collections import Counter
from itertools import product
import argparse

def get_all_possible_kmers(k):
    """Generate all possible k-mers for a given k."""
    return [''.join(kmer) for kmer in product("ACGT", repeat=k)]

def kmer_count_matrix(sequences, k):
    """Create a k-mer count matrix for a list of sequences."""
    all_kmers = get_all_possible_kmers(k)
    kmer_counts = []
    for sequence in sequences:
        kmer_count = Counter([sequence[i:i+k] for i in range(len(sequence) - k + 1)])
        row = [kmer_count.get(kmer, 0) for kmer in all_kmers]
        kmer_counts.append(row)
    return pd.DataFrame(kmer_counts, columns=all_kmers)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_dataset", type=str, required=True, help="Path to the dataset (.tsv).")
    parser.add_argument("--column_name", type=str, required=True, help="Column name to extract sequences from the dataset.")
    parser.add_argument("--k", type=int, required=True, help="Length of k-mers.")
    parser.add_argument("--output_encoding", type=str, required=True, help="Path to save the k-mer count matrix (.tsv).")
    parser.add_argument("--output_labels", type=str, required=False, help="Path to save the labels (.npy).")
    args = parser.parse_args()
    
    # Read the dataset
    df = pd.read_csv(args.input_dataset, sep="\t")
    
    # Check if the specified column exists
    if args.column_name not in df.columns:
        raise ValueError(f"Column {args.column_name} does not exist in the dataset.")
    
    # Compute the k-mer count matrix
    output_df = kmer_count_matrix(df[args.column_name], args.k)

    # Save the k-mer count matrix to a file
    output_df.to_csv(args.output_encoding, sep="\t", index=False)

    # If output_labels is specified, save the labels
    if args.output_labels:
        labels = df["label"].to_numpy()
        np.save(args.output_labels, labels)

if __name__ == "__main__":
    main()
