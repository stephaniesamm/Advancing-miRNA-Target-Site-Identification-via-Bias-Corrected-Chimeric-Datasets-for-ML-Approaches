#!/bin/bash

#SBATCH --account=ssamm10
#SBATCH --job-name=download_Manakov2022
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30

set -euo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND"; exit 1' ERR

mkdir -p results
exec > >(tee -a results/RUNME.log) 2>&1

OUT_DIR="data"
GEO_ID="GSE198250"
ENA_BROWSER_TOOLS_DIR="code/enaBrowserTools"

# Check if enaBrowserTools directory exists, if not exit with an error message
if [ ! -d "$ENA_BROWSER_TOOLS_DIR" ]; then
    echo "The code/enaBrowserTools directory does not exist. Please clone the repository to code/ before running this script."
    exit 1
fi

mkdir -p "$OUT_DIR"

# Run Python script to get list of SRX IDs
echo "Fetching SRX IDs for GEO ID: $GEO_ID"
SRX_LIST=$(python3 code/getSRX_geoparse.py --geo_id "$GEO_ID" --dest_dir "$OUT_DIR")

# Download FASTQ files for each SRX ID
for SRX in $SRX_LIST; do
    echo "Downloading $SRX"
    python $ENA_BROWSER_TOOLS_DIR/python3/enaDataGet.py -f fastq -d "$OUT_DIR" "$SRX"
done

# Print completion message with timestamp
echo
echo "All human chimeric eCLIP Manakov2022 raw data was downloaded on $(date). Check the data/ directory for files."