"""
Extracts SRX IDs for ChimeCLIP experiments (excluding mouse, enrichment, and over-expression) from a GEO Series using GEOparse.

Usage:
    python getSRX_geoparse.py --geo_id <GSE_ID> --dest_dir <DEST_DIR>

Arguments:
    --geo_id     GEO Series accession ID (e.g. GSE198250)
    --dest_dir   Directory for GEOparse cache/files
"""

import argparse
import GEOparse

def generate_srx_list(geo_series, dest_directory):
    gse = GEOparse.get_GEO(geo=geo_series, destdir=dest_directory)
    srx_list = []
    substrings_to_exclude = ["MusLiver", "C9", "Enriched", "oe"] # excluding experiments involving mouse tissue/cells and enrichment/over-expression

    for gsm_name, gsm in gse.gsms.items():
        title = gsm.metadata['title'][0] # title is a list with one element
        if "ChimeCLIP" in title and not any(sub in title for sub in substrings_to_exclude):
            # Extract SRX from the SRA link
            sra_link = gsm.metadata['relation'][1] # the second relation is the SRA link
            srx = sra_link.split('=')[-1] # the SRX is the last part of the URL following '='
            srx_list.append(srx)

    return " ".join(srx_list)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--geo_id", required=True, help="GEO accession ID (e.g., GSE198250)")
    parser.add_argument("--dest_dir", required=True, help="Destination directory for GEOparse cache/files")

    args = parser.parse_args()
    print(generate_srx_list(args.geo_id, args.dest_dir))

if __name__ == "__main__":
    main()