"""
Filters input data that includes various noncoding RNA biotypes for miRNA entries and creates a standardised table with selected columns and a new `test` column indicating whether the target site is located on chromosome 1. 

Usage:
    python filtering.py --ifile <INPUT_TSV> --ofile <OUTPUT_TSV>

Arguments:
    --ifile    Path to input TSV file
    --ofile    Output path for filtered table (TSV)
"""

import pandas as pd
import argparse

def filter_and_create_table(data):

    # filter rows where "noncodingRNA_type" is "miRNA".
    filtered_data = data[data['noncodingRNA_type'] == 'miRNA']

    # create the new dataframe with specific column names and transformations.
    filtered_table = pd.DataFrame({
        'gene': filtered_data['seq.g'],
        'noncodingRNA': filtered_data['noncodingRNA_seq'],
        'noncodingRNA_name': filtered_data['noncodingRNA'].apply(lambda x: x.split('|')[0]),
        'noncodingRNA_fam': filtered_data['noncodingRNA_fam'].apply(lambda x: x if x != '0' else 'unknown'),
        'feature': filtered_data['feature'],
        'test': filtered_data['chr.g'].apply(lambda x: True if x == '1' else False),
        'label': '1',
        'chr': filtered_data['chr.g'],
        'start': filtered_data['start.g'],
        'end': filtered_data['end.g'],
        'strand': filtered_data['strand.g']
    }, columns=['gene', 'noncodingRNA', 'noncodingRNA_name', 'noncodingRNA_fam', 'feature', 'test', 'label', 'chr', 'start', 'end', 'strand'])

    return filtered_table

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ifile', required=True, help="Input file")
    parser.add_argument('--ofile', required=True, help="Output file")
    args = parser.parse_args()

    data = pd.read_csv(args.ifile, sep='\t')
    filtered_table = filter_and_create_table(data)
    filtered_table.to_csv(args.ofile, sep='\t', index=False)

if __name__ == "__main__":
    main()
