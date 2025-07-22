"""
Converts a TSV file containing a 'gene' column with sequences, to FASTA format.

Usage:
    python gene_fasta.py --input <INPUT_TSV> --output <OUTPUT_FASTA>

Arguments:
    --input    Path to input TSV file with gene sequences
    --output   Output path for generated FASTA file
"""

import pandas as pd
import argparse

def convert_tsv_to_fasta(input_file, output_file):
   
    data = pd.read_csv(input_file, sep='\t')
    
    with open(output_file, 'w') as fasta_file:
        for index, row in data.iterrows():
            sequence = row['gene']
            fasta_file.write(f">Seq_{index + 1}\n{sequence}\n")
    
    print(f"FASTA file created: {output_file}")

def main():

    parser = argparse.ArgumentParser(description='Convert TSV file with gene sequences to FASTA format')
    parser.add_argument('--input', required=True, help='Input TSV file path')
    parser.add_argument('--output', required=True, help='Output FASTA file path')

    args = parser.parse_args()
    
    convert_tsv_to_fasta(args.input, args.output)

if __name__ == "__main__":
    main()

