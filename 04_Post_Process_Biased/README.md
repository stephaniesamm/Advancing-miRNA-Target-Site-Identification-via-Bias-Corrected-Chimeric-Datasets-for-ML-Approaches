
# Post-Processing Pipeline - BIASED

## Description

This pipeline is designed to process the concatenated HybriDetector outputs `.tsv` file through multiple stages to produce a set of positive example miRNA to target site interactions for the Manakov2022 dataset. Processing steps include: 

1. Filtering for miRNA interactions
2. Deduplication of interactions
3. miRNA family assignment where missing
4. Negative sample generation at various ratios
5. Data splitting into train and test sets

## Dependencies

- `wget`
- `gunzip`
- Python (version 3.12.4)
   - `pandas` (version 2.2.2)
   - `python-Levenshtein` (version 0.25.1)

## Notes

- The master script first downloads the relevant input file from https://zenodo.org/records/14501607, to the `data/` directory if it doesn't already exist. 
- It then runs the post-processing pipeline on this file to produce train and test sets at 1:1, 1:10, and 1:100, positive to negative examples ratios. 
- This pipeline produces **BIASED** datasets containing the described *miRNA frequency class bias*. 
- These output datasets have been published at https://zenodo.org/records/13909173. 
