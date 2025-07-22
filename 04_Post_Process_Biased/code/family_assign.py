"""
Assigns or updates miRNA family annotations for each entry using a reference mature miRNA FASTA file, whenever the current value is missing, empty, or set to '0'.

Usage:
    python family_assign.py --ifile <INPUT_TSV> --mature <MATURE_FA> --ofile <OUTPUT_TSV>

Arguments:
    --ifile     Path to input TSV file
    --mature    Path to mature miRNA FASTA file (mature.fa downloaded from miRBase)
    --ofile     Output path for annotated TSV file
"""

import pandas as pd
import argparse

def filter_and_create_table(data, mature_sequences):
    # ensure the necessary column is present in the data
    if 'noncodingRNA_fam' not in data.columns:
        raise KeyError("The column 'noncodingRNA_fam' is not found in the input data.")
    
    # update 'noncodingRNA_fam' based on mature sequences if it is '0'
    data['noncodingRNA_fam'] = data.apply(
        lambda row: mature_sequences.get(row['noncodingRNA'].replace('T', 'U'), row['noncodingRNA_fam']) if pd.isna(row['noncodingRNA_fam']) or row['noncodingRNA_fam'] == '' or row['noncodingRNA_fam'] == '0' else row['noncodingRNA_fam'],
        axis=1
    )
    
    # remove 'hsa-' prefix from 'noncodingRNA_fam' values if present
    data['noncodingRNA_fam'] = data['noncodingRNA_fam'].apply(lambda x: x.replace('hsa-', '') if 'hsa-' in x else x)
    
    return data

def load_mature_sequences(file_path):
    # load mature sequences from a file and map sequences to their families
    mature_sequences = {}
    with open(file_path, 'r') as f:
        lines = f.readlines()
        for i in range(0, len(lines), 2):
            header = lines[i].strip()
            sequence = lines[i+1].strip().replace('T', 'U')
            family = header.split()[0][1:]
            mature_sequences[sequence] = family
    return mature_sequences

def main():
    # parse command-line arguments for input, mature, and output files
    parser = argparse.ArgumentParser()
    parser.add_argument('--ifile', help="Input file")
    parser.add_argument('--mature', help="Mature miRNA file")
    parser.add_argument('--ofile', help="Output file")

    args = parser.parse_args()

    # load mature sequences from the specified file
    mature_sequences = load_mature_sequences(args.mature)

    # read input data from the specified file
    data = pd.read_csv(args.ifile, sep='\t')

    # process the data to update the 'noncodingRNA_fam' column
    filtered_table = filter_and_create_table(data, mature_sequences)

    # write the processed data to the specified output file
    filtered_table.to_csv(args.ofile, sep='\t', index=False)

if __name__ == "__main__":
    main()
