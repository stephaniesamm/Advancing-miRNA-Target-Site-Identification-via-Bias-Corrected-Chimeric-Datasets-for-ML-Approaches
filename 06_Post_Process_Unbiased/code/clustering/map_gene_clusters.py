"""
Maps cluster IDs from a CSV file to gene entries in a TSV dataset and outputs the merged table with a new 'gene_cluster_ID' column. 

Usage:
    python map_gene_clusters.py --cluster_csv <CLUSTERS_CSV> --dataset_tsv <INPUT_TSV> --output_tsv <OUTPUT_TSV>

Arguments:
    --cluster_csv   Path to CSV file with cluster assignments
    --dataset_tsv   Path to input dataset (TSV)
    --output_tsv    Output path for merged TSV file
"""

import argparse
import pandas as pd

def main():
    parser = argparse.ArgumentParser(description="Map cluster IDs to sequences and merge with gene data.")
    parser.add_argument("--cluster_csv", required=True, help="CSV file containing cluster information")
    parser.add_argument("--dataset_tsv", required=True, help="Input dataset TSV file")
    parser.add_argument("--output_tsv", required=True, help="Output TSV file path")
    args = parser.parse_args()

    clusters_df = pd.read_csv(args.cluster_csv)
    gene_df = pd.read_csv(args.dataset_tsv, sep="\t")

    gene_df["gene_cluster_ID"] = clusters_df["Cluster_ID"]

    gene_df.to_csv(args.output_tsv, sep="\t", index=False)
    print(f"Results saved to {args.output_tsv}")

if __name__ == "__main__":
    main()
