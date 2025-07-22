# Clusters gene sequences in a FASTA file using DECIPHER and outputs cluster assignments as a CSV.
#
# Usage:
#   Rscript clustering.R <INPUT_FASTA> <OUTPUT_CSV>
#
# Arguments:
#   <INPUT_FASTA>   Path to input FASTA file with gene sequences
#   <OUTPUT_CSV>    Output CSV file for sequence-to-cluster assignments

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
    stop("Usage: script.R <input_fasta> <output_csv>")
}
file_path <- args[1]
output_file <- args[2]

# Set seed for reproducibility
set.seed(42)  

# Load necessary libraries
library(Biostrings)  
library(DECIPHER)    

# Read DNA sequences from the file
dna <- readDNAStringSet(file_path)

# Cluster using DECIPHER::Clusterize
clusters <- Clusterize(myXStringSet = dna, cutoff = 0.1, processors = 8)

# Create data frame
clusters_df <- data.frame(
    Seq_ID = names(dna),
    Cluster_ID = clusters
)

# Rename the column
names(clusters_df)[2] <- "Cluster_ID"

# Write to CSV
write.csv(clusters_df, file = output_file, row.names = FALSE)
