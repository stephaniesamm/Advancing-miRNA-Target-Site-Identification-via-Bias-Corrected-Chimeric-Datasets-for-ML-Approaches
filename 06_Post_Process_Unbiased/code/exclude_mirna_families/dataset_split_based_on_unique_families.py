"""
Splits a dataset into 'excluded' and 'remaining' entries based on a provided list of unique miRNA families.

Usage:
    python dataset_split_based_on_unique_families.py --unique_to <INPUT_TSV> --input_unique_fam_counts <FAM_TSV> --excluded_dataset <EXCLUDED_TSV> --remaining_dataset <REMAINING_TSV>

Arguments:
    --unique_to               Original dataset file (TSV)
    --input_unique_fam_counts File with unique families (TSV)
    --excluded_dataset        Output file for entries with families in the unique families file (TSV)
    --remaining_dataset       Output file for entries with families not in the unique families file (TSV)
"""

import pandas as pd
import argparse

def filter_dataset(input_dataset, families_file, excluded_output, remaining_output):
    # Read the original dataset
    df = pd.read_csv(input_dataset, sep='\t')
    
    # Read the families file
    families_df = pd.read_csv(families_file, sep='\t')
    unique_families = families_df['noncodingRNA_fam']
    
    # Split the dataset into two parts
    excluded_dataset = df[df['noncodingRNA_fam'].isin(unique_families)]
    remaining_dataset = df[~df['noncodingRNA_fam'].isin(unique_families)]
    
    # Save both datasets
    excluded_dataset.to_csv(excluded_output, sep='\t', index=False)
    remaining_dataset.to_csv(remaining_output, sep='\t', index=False)
    
    # print(f"Original dataset: {len(df)} rows")
    # print(f"Excluded dataset: {len(excluded_dataset)} rows")
    # print(f"Remaining dataset: {len(remaining_dataset)} rows")

parser = argparse.ArgumentParser()
parser.add_argument('--unique_to', required=True, help='Original dataset TSV file')
parser.add_argument('--input_unique_fam_counts', required=True, help='File with unique families')
parser.add_argument('--excluded_dataset', required=True, help='Output file for families that match input families file')
parser.add_argument('--remaining_dataset', required=True, help='Output file for families not in input families file')

args = parser.parse_args()
filter_dataset(args.unique_to, args.input_unique_fam_counts, args.excluded_dataset, args.remaining_dataset)
