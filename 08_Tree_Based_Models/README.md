# Tree-Based ML Models

## Description

This analysis trains and benchmarks tree-based machine learning models for miRNA-target site prediction using the `AGO2_eCLIP_Manakov2022` datasets. It performs the following main steps:

1. **Dataset Retrieval & Encoding:** For each dataset split (`train`, `test`, `leftout`), the script locates or downloads the dataset and encodes it for model input. 
2. **Model Training:** Using the encoded `train` set, Bayesian optimisation with 5-fold cross-validation is used to determine the best model training configuration within the defined search spaces, which is then used to train final models on the entire `train` set. 
3. **Inference & Evaluation:** Runs inference using all 3 trained models on the `test` and `leftout` splits, and computes average precision scores. 

## Dependencies

- [miRBench](https://github.com/katarinagresova/miRBench) (version 1.0.1); for downloading the datasets (predictors and encoders are not required)
- `Biopython` (version 1.85); for `Seq` class
- `pandas`
- `numpy`
- `scikit-learn` (version 1.5.1)
- `xgboost` (version 3.0.0)
- `scikit-optimize` (version 0.10.2); for `BayesSearchCV` class


## Notes

All outputs are saved in corresponding `results/` subdirectories, as follows:
```
results/
├── encoding/           # encoded datasets for training/testing
├── training/           # trained model files and cross-validation results
├── predictions/        # model predictions on test sets
└── evaluation/         # performance metrics for each model/dataset
```

Cross-validation results are included at `results/training`. The final trained models have been renamed and published on Zenodo at https://zenodo.org/records/16307664. 