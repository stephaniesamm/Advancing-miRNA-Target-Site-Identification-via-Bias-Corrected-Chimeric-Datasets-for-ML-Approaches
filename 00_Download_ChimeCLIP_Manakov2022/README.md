# Raw Data Acquisition

## Description

The master script downloads the relevant samples from the GEO series: GSE198250. This is where the raw chimeric eCLIP Manakov2022 data was deposited by the authors. Relevant samples include those produced by chimeric eCLIP experiments carried out on human cell line only, and exclude those produced by experiments that involve enrichment or over-expression of specific miRNAs. A total of 20 samples are relevant.

The relevant sample names are first extracted from the GEO series ID via `code/getSRX_geoparse.py` using `GEOparse`, and the corresponding FASTQ files are downloaded to `data/` using `enaBrowserTools`.  

## Dependencies

- Python (version 3.8.19)
    - [GEOparse](https://geoparse.readthedocs.io/en/latest/) (version 2.0.4) 
- [enaBrowserTools](https://github.com/enasequence/enaBrowserTools). Clone the repository to `code/`. 

## Notes

- The downloaded files have the following structure per sample:
```
data/
└── <SAMPLE_SRX>/
    └── <SAMPLE_SRR>/
        └── <SAMPLE_SRR>.fastq.gz
```