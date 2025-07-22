# Benchmarking with miRBench

## Description

This analysis benchmarks and evaluates all miRNA-target site predictors available on the `miRBench` Python package. It performs the following main steps:

1. **Inference:** Runs all available miRBench predictors on all included datasets and splits, generating prediction files.
2. **Evaluation:** Calculates key evaluation metrics (`avg_p_score`, `auc_pr`, `auc_roc`) for each dataset.
3. **Plotting:** Generates precision-recall (PR) curve plots for each dataset.

## Dependencies

- [miRBench](https://github.com/katarinagresova/miRBench) (version 1.0.1); follow instructions to install the package, including all dependencies required for encoders and predictors.
- `pandas`
- `numpy`
- `scikit-learn`
- `matplotlib`

## Notes

`miRBench` predictors include:
- `TargetScanCnn_McGeary2019`,
- `CnnMirTarget_Zheng2020`,
- `TargetNet_Min2021`,
- `miRBind_Klimentova2022`,
- `miRNA_CNN_Hejret2023`,
- `InteractionAwareModel_Yang2024`, 
- `RNACofold`, 
- `Seed8mer`, 
- `Seed7mer`, 
- `Seed6mer`, 
- `Seed6merBulgeOrMismatch`

These are downloaded to `/home/user/.miRBench/models/`.

`miRBench` evaluation datasets include:
- `AGO2_eCLIP_Klimentova2022_test.tsv.gz`
- `AGO2_CLASH_Hejret2023_test.tsv.gz`
- `AGO2_eCLIP_Manakov2022_test.tsv.gz`
- `AGO2_eCLIP_Manakov2022_leftout.tsv.gz`

These are downloaded to `/home/user/.miRBench/datasets/`. 

`miRBench` also includes encoders to prepare evaluation data in the format compatible with each of the available predictors. 

All outputs are saved in corresponding `results/` subdirectories, as follows:
```
results/
├── benchmarking/
├── evaluation/
└── pr_curves/
```