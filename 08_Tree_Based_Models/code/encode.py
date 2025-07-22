"""
Encodes each miRNA-target site pair in a TSV with reverse-complement miRNA k-mer count features from the gene sequence, for k = 2 to 12.

Usage:
    python encode.py --input_dataset <INPUT_TSV> --output_encoded_dataset <OUTPUT_TSV>

Arguments:
    --input_dataset           Path to input dataset (TSV)
    --output_encoded_dataset  Output path for encoded dataset with k-mer features (TSV)
"""

from Bio.Seq import Seq
import pandas as pd
import os
import argparse

MIRNA_LENGTH = 20
K_MIN = 2
K_MAX = 12

def reverse_complement(seq):
    """Return the reverse complement of a nucleotide sequence using Biopython."""
    seq_obj = Seq(seq)
    return str(seq_obj.reverse_complement())

def truncate_or_pad(seq, desired_length=MIRNA_LENGTH):
    """
    Truncate the sequence if it's longer than the desired length,
    or pad it with 'N' if it's shorter.
    """
    return seq[:desired_length] if len(seq) > desired_length else seq.ljust(desired_length, 'N')

def count_kmers(miRNA, gene, k):
    """
    For a given k, compute a dictionary of counts for each k-mer's reverse complement
    in the gene. The keys are formatted as 'pos<position>_k<k>'.
    """
    counts = {}
    for i in range(len(miRNA) - k + 1):
        kmer = miRNA[i:i+k]
        rev = reverse_complement(kmer)
        counts[f'pos{i+1}_k{k}'] = gene.count(rev)
    return counts

def process_dataset(dataset, chunk_size=10000):
    """
    Reads a TSV file in chunks and extracts features based on the count of reverse complement k-mers 
    from the miRNA present in the corresponding gene sequence.
    Returns a DataFrame with the original 'noncodingRNA', 'gene', 'label' columns 
    followed by the k-mer count features.
    """
    rows = []
    for chunk in pd.read_csv(dataset, sep='\t', chunksize=chunk_size):
        for _, row in chunk.iterrows():
            # Prepare the feature dictionary with the original columns.
            features = {
                'noncodingRNA': row['noncodingRNA'],
                'gene': row['gene'],
                'label': row['label']
            }
            miRNA = truncate_or_pad(str(row['noncodingRNA']))
            gene = str(row['gene']).upper()
            # Compute k-mer counts for each k between K_MIN and K_MAX.
            for k in range(K_MIN, K_MAX + 1):
                kmers = count_kmers(miRNA, gene, k)
                features.update(kmers)
            rows.append(features)
    df = pd.DataFrame(rows)
    return df

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_dataset", type=str, required=True, help="Path to the input dataset TSV file.")
    parser.add_argument("--output_encoded_dataset", type=str, required=True, help="Path to save the encoded dataset TSV file.")
    args = parser.parse_args()
        
    df = process_dataset(args.input_dataset)
    df.to_csv(args.output_encoded_dataset, sep='\t', index=False)

if __name__ == "__main__":
    main()