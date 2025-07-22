# Preprocessing Pipeline for Chimeric eCLIP Raw Data

## Description

The analysis follows [chim-eCLIP Extract UMI and Trim Pipeline](https://github.com/YeoLab/chim-eCLIP#extract-umi-and-trim) (Last accessed on 21-May-2024) as described by Manakov et al. (2022), and includes the following steps:

1. Extracting 5' UMIs from the reads to the read name using `umi_tools`
2. Trimming 3' adapters using `cutadapt`
3. Trimming the 3' UMI (last 10 nt) from reads using `cutadapt`

## Dependencies

- [umi_tools](https://umi-tools.readthedocs.io/en/latest/) (version 1.1.4)
- [cutadapt](https://cutadapt.readthedocs.io/en/stable/) (version 2.8)

## Instructions

- Create the `data/` directory
- Move, or symlink the downloaded files in the `00_Download_ChimeCLIP_Manakov2022` analysis to `./data` as follows:
```bash
# Symlink all .fastq.gz files (except *_2.fastq.gz) from source directory into ./data/,
# using only the filenames (directory structure flattened), with symlinks pointing to the absolute path as found by 'find'.
find "/full/path/to/source/directory" -type f -name "*.fastq.gz" -not -name "*_2.fastq.gz" -exec bash -c 'ln -s "$1" "./data/$(basename "$1")"' _ {} \;
```
- Run the `RUNME.sh` master script. The master script is designed to be run on an HPC cluster via SLURM job arrays. A text file (`results/raw_chimeCLIP_file_list.txt`) containing a list of file names to be processed in the job array will be created. A total of 20 files are processed; 5 at a time. 

## Notes

- Adapter sequences for `cutadapt` are provided as per the chimeric eCLIP experiment by Manakov et al. (2022).
- The script checks for and skips steps if output already exists, for efficient reruns.
- Intermediate, output files and logs will be organised as follows for each sample under `results/`:
```
    results/
    └── raw_chimeCLIP_file_list.txt         # text file containing a list of file names to be processed; created by the `RUNME.sh`
    └── <SAMPLE_NAME>/
        └── <SAMPLE_NAME>.pp.fastq.gz       # final output file
        └── logs/                           # directory containing log file per step (reports from `umi_tools` and `cutadapt`)
        └── temp/                           # directory containing intermediate files; deleted at end of script if final output file exists
```
- The final output `.fastq.gz` files are to be processed by `HybriDetector` to extract chimeric interactions. 

