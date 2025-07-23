# Concatenation of HybriDetector Outputs from Processed Samples

## Description

This analysis concatenates output files from running the `HybriDetector` pipeline (one output file per sample processed), and produces a single file for downstream analysis. 

There are two master scripts:  
1. `RUNME_0.sh`: [*OPTIONAL**] Downloads a `.zip` file containing all `*.unified_length_all_types_unique_high_confidence.tsv` output files from the `HybriDetector` Pipeline into the `data/` directory, and extracts all files. 
2. `RUNME_1.sh`: Concatenates all extracted files into a single file and compresses it (`results/AGO2_eCLIP_Manakov2022_full_dataset.tsv.gz`). 

**For reproducing the remainder of analyses/experiments without re-running earlier downloading, pre-processing and `HybriDetector` processing steps. Otherwise move or symlink the relevant `HybriDetector` outputs to the data/ directory, and run `RUNME_1.sh` only.*

## Dependencies

- `wget`
- `unzip`
- `gzip`

## Notes

- A total of 19 samples were successfully processed by the `HybriDetector` Pipeline. These were made available at https://zenodo.org/records/14730307 and serve as the input files to this analysis. 
- The `RUNME_1.sh` master script ensures that the header from the first file is included in the output file, while subsequent files have their headers removed to avoid duplication. 
- The output file from this step (`AGO2_eCLIP_Manakov2022_full_dataset.tsv.gz`) was uploaded to https://zenodo.org/records/14501607. 



