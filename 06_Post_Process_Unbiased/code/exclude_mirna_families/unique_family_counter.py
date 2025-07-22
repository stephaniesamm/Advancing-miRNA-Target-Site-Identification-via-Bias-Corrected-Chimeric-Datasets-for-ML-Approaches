"""
Identifies and counts miRNA families unique to the input file relative to two comparison files.

Usage:
    python unique_family_counter.py --unique_to <INPUT_TSV> --input_relative_file1 <COMPARE1_TSV> --input_relative_file2 <COMPARE2_TSV> --output_unique_fam_counts <OUTPUT_TSV>

Arguments:
    --unique_to                  File to find unique families from (TSV)
    --input_relative_file1       First comparison file (TSV)
    --input_relative_file2       Second comparison file (TSV)
    --output_unique_fam_counts   Output file for unique family counts (TSV)
"""

import pandas as pd
import argparse

def get_unique_fams(file_path):
   df = pd.read_csv(file_path, sep='\t')
   filtered_df = df[(df['noncodingRNA_fam'] != 'unknown') & (df['noncodingRNA_fam'] != '0')]
   return set(filtered_df['noncodingRNA_fam'].unique())

def analyze_unique_families(unique_input_file, file2_path, file3_path, output_path):
   df1 = pd.read_csv(unique_input_file, sep='\t')
   families1 = get_unique_fams(unique_input_file)
   families2 = get_unique_fams(file2_path) 
   families3 = get_unique_fams(file3_path)

   unique_to_1 = families1 - (families2 | families3)
   unique_counts = df1[df1['noncodingRNA_fam'].isin(unique_to_1)]['noncodingRNA_fam'].value_counts()
   
   unique_counts.to_csv(output_path, sep='\t')
   print(f"Unique families: {len(unique_to_1)}")
   print(f"Total occurrences: {unique_counts.sum()}")

parser = argparse.ArgumentParser()
parser.add_argument('--unique_to', required=True, help='File to find unique families from')
parser.add_argument('--input_relative_file1', required=True, help='Second TSV file to compare against')
parser.add_argument('--input_relative_file2', required=True, help='Third TSV file to compare against')
parser.add_argument('--output_unique_fam_counts', required=True, help='Output file path')

args = parser.parse_args()
analyze_unique_families(args.unique_to, args.input_relative_file1, args.input_relative_file2, args.output_unique_fam_counts)
