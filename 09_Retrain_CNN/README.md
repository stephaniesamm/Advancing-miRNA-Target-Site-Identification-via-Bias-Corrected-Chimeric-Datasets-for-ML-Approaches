# Retraining CNN on Unbiased Datasets

## Description

This analysis retrains the convolutional neural network (CNN) model from [Hejret et al. (2023)](https://doi.org/10.1038/s41598-023-49757-z), on the bias-corrected Hejret2023 train set and on the larger unbiased Manakov2022 train set. The model is independently trained on 2 data representations. The script also runs inference and evaluation on all `miRBench` evaluation datasets. 

1. **Dataset Retrieval & Encoding**: Locates or downloads each required dataset split, adds dot-bracket RNA secondary structure information, and encodes each dataset into two formats: `50_20_1` (Sequence-only) and `50_20_2` (Sequence & Co-folding) data representations.

2. **CNN Model Training**: Trains CNN models on each train split (`AGO2_CLASH_Hejret2023_train` and `AGO2_eCLIP_Manakov2022_train`) for each data representation.

3. **Prediction & Evaluation**: Runs inference for each trained model on all test/leftout splits available on `miRBench` and for each data representation, and evaluates predictions computing evaluation metrics for each combination.

## Dependencies

- [miRBench](https://github.com/katarinagresova/miRBench) (version 1.0.1); for downloading the datasets (predictors and encoders are not required)
- [ViennaRNA package](https://www.tbi.univie.ac.at/RNA/ViennaRNA/doc/html/install.html#python-interface-only); for the `RNA` module
- `pandas`
- `numpy`
- `tensorflow` (version 2.13.1)
- `scikit-learn`
- `matplotlib`

## Notes

All outputs are saved in corresponding `results/` subdirectories, as follows:
```
results/
├── encoding/           # encoded datasets and dot-bracket annotated files
├── training/           # trained CNN model files
├── predictions/        # model predictions for each test set and encoding
└── evaluation/         # evaluation metrics for each model/test set
```
Training history and plots are included in `results/training`. The trained models are published on Zenodo at https://zenodo.org/records/16307664. 
