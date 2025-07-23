# Running HybriDetector on Preprocessed Chimeric eCLIP Data

## Description 

The master script runs the [HybriDetector](https://github.com/ML-Bioinfo-CEITEC/HybriDetector/tree/fix_clustering) Pipeline on preprocessed chimeric eCLIP data, which produces structured datasets containing chimeric miRNA to target site interactions. 

## Dependencies

- [Miniconda](https://docs.conda.io/en/latest/miniconda.html) or [Anaconda](https://www.anaconda.com/)
- [Snakemake](https://snakemake.readthedocs.io/en/stable/) (version 7.18.2)

## Instructions

- Create a `code/` directory, and move into it. 
- Clone the `fix_clustering` branch from the HybriDetector repository in the `code/` directory using:
```bash
git clone -b fix_clustering git@github.com:ML-Bioinfo-CEITEC/HybriDetector.git
```
- Read the instructions in the HybriDetector repository.
- Move into the `code/HybriDetector` directory. 
- Create and activate the conda environment from the available `.yml` file. 
- Create a `data/` directory (inside `code/HybriDetector`). 
- Move, or symlink the preprocessed output files from the `01_Pre_Process_ChimeCLIP` analysis to `code/HybriDetector/data/`.
```bash
# Symlink all .pp.fastq.gz files from source directory into code/HybriDetector/data/,
# using only the filenames (directory structure flattened), with symlinks pointing to each file's absolute path.
find "/full/path/to/source/directory" -type f -name "*.pp.fastq.gz" -exec bash -c 'ln -s "$(realpath "$1")" "code/HybriDetector/data/$(basename "$1")"' _ {} \;
```
- Move the `RUNME.sh` master script to the `code/HybriDetector/` directory.
- Run the `RUNME.sh` master script from that directory. The script is designed to be run on an HPC cluster via SLURM job arrays. A text file (`results/preprocessed_chimeCLIP_file_list.txt`) containing a list of file names to be processed in the job array will be created. A total of 20 files are processed; 5 at a time. 

## Notes

The output of `HybriDetector` is contained within the directory. Relevant files for downstream analysis include `code/HybriDetector/hyb_pairs/*.unified_length_all_types_unique_high_confidence.tsv`, one of the final outputs of the pipeline. One such file is produced per input sample file that is processed. Out of the 20 samples to be processed with the `HybriDetector` Pipeline, only 19 were successfully processed. These were uploaded to https://zenodo.org/records/14730307. 