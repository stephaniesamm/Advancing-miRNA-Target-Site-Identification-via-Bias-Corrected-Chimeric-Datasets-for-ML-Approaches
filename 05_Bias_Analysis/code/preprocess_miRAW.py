"""
Preprocesses miRAW datasets: standardises column names to the miRBench convention.

Usage:
    python preprocess_miRAW.py --input_file <INPUT_TSV> --output_file <OUTPUT_TSV>

Arguments:
    --input_file   Path to input TSV dataset file
    --output_file  Output path for processed TSV file
"""

import argparse
import pandas as pd
import sys

def main():
    parser = argparse.ArgumentParser(description="Standardise miRAW TSV dataset column names to miRBench convention.")
    parser.add_argument("--input_file", required=True, help="Input TSV dataset file")
    parser.add_argument("--output_file", required=True, help="Output filename for processed file (.tsv)")
    args = parser.parse_args()

    # Read the input TSV file
    df = pd.read_csv(args.input_file, sep='\t')

    # List of possible column mappings
    mapping_options = [
        # miRAW test set
        {"Mature_mirna_transcript": "noncodingRNA", "Positive_Negative": "label"},
        # miRAW train set
        {"mature_miRNA_Transcript": "noncodingRNA", "validation": "label"},
    ]

    # Check if any of the mapping options match the columns in the DataFrame and rename accordingly
    for mapping in mapping_options:
        if all(col in df.columns for col in mapping):
            df = df.rename(columns=mapping)
            break
    else:
        sys.exit("Error: No known column mapping pattern found in input file. ")
    
    # Save the processed DataFrame to the output file
    df.to_csv(args.output_file, sep='\t', index=False)

if __name__ == "__main__":
    main()
