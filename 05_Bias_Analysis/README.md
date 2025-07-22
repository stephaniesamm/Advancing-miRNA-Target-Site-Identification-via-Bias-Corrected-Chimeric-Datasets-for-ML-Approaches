# Bias Analysis

The goal of this analysis is to isolate the effect of miRNA frequency class bias in various datasets if present. The analysis involves:
1. Encoding the miRNA or target sequence *only* in the train and test sets into a k-mer count matrix
2. Training a Decision Tree Classifier on the encoded train set
3. Running inference on the encoded test set
4. Evaluating the predictions  

The analysis is performed on the following datasets:
- **biasedManakov** (produced by `04_Post_Process_Biased`)
- **originalHejret** (from https://doi.org/10.1038/s41598-023-49757-z)
- **miraw** (from https://doi.org/10.1371/journal.pcbi.1006185)
- **Yang** (from https://doi.org/10.1021/acs.jcim.3c01150)
- **unbiasedManakov** (produced by `06_Post_Process_Unbiased`)
- **correctedHejret** (produced by `06_Post_Process_Unbiased`)

Each includes one train set and at least one test set. 

There are two master scripts:  
1. `RUNME_0.sh`: Downloads and standardises (miRBench format) all necessary files into the `data/` directory.  
2. `RUNME_1.sh`: Runs the analysis (encoding, training, inference, evaluation) on each of the datasets.

## Dependencies

- `wget`
- `p7zip`
- `gzip`
- `unzip`
- Python (version 3.12.5)
  - `pandas` (version 2.2.2)
  - `numpy` (version 1.26.4)
  - `scikit-learn` (version 1.5.1)

## Notes

- After running `RUNME_0.sh` and `RUNME_1.sh`, the `05_Bias_Analysis` directory will have the following structure:
```
data/
├── <dataset>_data/
│   ├── <dataset>_train_set.tsv
│   ├── <dataset>_test_set.tsv
│   └── ...[other files, if applicable]

results/
├── encoding/<dataset>/
│   ├── <dataset>_train_set_encoded.tsv
│   ├── <dataset>_test_set_encoded.tsv
│   ├── <dataset>_train_set_labels.npy
│   └── <dataset>_test_set_labels.npy
├── training/<dataset>/
│   └── <dataset>_noncodingRNA_3_model.pkl    # using 3-mers from the noncodingRNA column; hard-coded in the Configuration of the RUNME_1.sh
├── predictions/<dataset>/
│   ├── <dataset>_predictions.npy
│   └── <dataset>_random_predictions.npy
└── evaluation/<dataset>/
    └── <dataset>_evaluation.tsv
├── RUNME_0.log
└── RUNME_1.log
```
- `<dataset>` is one of biasedManakov, originalHejret, miraw, Yang, unbiasedManakov, or correctedHejret
- For unbiasedManakov, also includes relevant files for the *leftout_set* in the same subfolders.
- Output models and evaluation results are included in the `results/training` and `results/evaluation` directories, respectively. 
