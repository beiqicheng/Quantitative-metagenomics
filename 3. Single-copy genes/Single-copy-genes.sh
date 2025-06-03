#!/bin/bash
#SBATCH --account=fuhrman_1138
#SBATCH --partition=main
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=6:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-20

module load conda
module load diamond
module load blast
module load seqtk
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}

# Create directory structure
mkdir -p diamond_results psbo_results extracted_genes logs/{diamond,psbo,extract}

# Get sample list
input_files=(filtered_reads/*_final.fasta)
SAMPLE=$(basename "${input_files[$SLURM_ARRAY_TASK_ID-1]}" _final.fasta)

# Database paths
RADA_DB="/path/to/radA.dmnd"
RECA_DB="/path/to/recA.dmnd"
PSBO_DB="/path/to/psbo.fna"

### Step 1: DIAMOND blastx for radA ###
diamond blastx \
  --query "filtered_reads/${SAMPLE}_final.fasta" \
  --db $RADA_DB \
  --out "diamond_results/${SAMPLE}_radA.diamond" \
  --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen \
  --max-target-seqs 1 \
  --evalue 1e-5 \
  --id 80 \
  --query-cover 30 \
  --threads ${SLURM_CPUS_PER_TASK:-1}

### Step 1: DIAMOND blastx for recA ###
diamond blastx \
  --query "filtered_reads/${SAMPLE}_final.fasta" \
  --db $RECA_DB \
  --out "diamond_results/${SAMPLE}_recA.diamond" \
  --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen \
  --max-target-seqs 1 \
  --evalue 1e-5 \
  --id 80 \
  --query-cover 30 \
  --threads ${SLURM_CPUS_PER_TASK:-1}

# Count hits
radA_hits=$(wc -l < "diamond_results/${SAMPLE}_radA.diamond")
recA_hits=$(wc -l < "diamond_results/${SAMPLE}_recA.diamond")
echo "${SAMPLE} radA hits: ${radA_hits}, recA hits: ${recA_hits}" | tee -a "logs/diamond/${SAMPLE}.log"

### Step 2: BLASTn for psbo ###
blastn -query "filtered_reads/${SAMPLE}_final.fasta" \
  -db $PSBO_DB \
  -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen" \
  -perc_identity 80 \
  -qcov_hsp_perc 30 \
  -max_target_seqs 1 \
  -num_threads ${SLURM_CPUS_PER_TASK:-1} \
  > "psbo_results/${SAMPLE}_psbo.blastn"

# Count hits
psbo_hits=$(wc -l < "psbo_results/${SAMPLE}_psbo.blastn")
echo "${SAMPLE} psbo hits: ${psbo_hits}" | tee -a "logs/psbo/${SAMPLE}.log"  # Fixed log directory

### Step 3: Extract all target genes ###
mkdir -p "extracted_genes/${SAMPLE}"

# Extract radA sequences
awk '{print $1}' "diamond_results/${SAMPLE}_radA.diamond" | sort -u > "extracted_genes/${SAMPLE}/radA_ids.txt"
seqtk subseq "filtered_reads/${SAMPLE}_final.fasta" "extracted_genes/${SAMPLE}/radA_ids.txt" > "extracted_genes/${SAMPLE}/radA.fasta"

# Extract recA sequences
awk '{print $1}' "diamond_results/${SAMPLE}_recA.diamond" | sort -u > "extracted_genes/${SAMPLE}/recA_ids.txt"
seqtk subseq "filtered_reads/${SAMPLE}_final.fasta" "extracted_genes/${SAMPLE}/recA_ids.txt" > "extracted_genes/${SAMPLE}/recA.fasta"

# Extract psbo sequences
awk '{print $1}' "psbo_results/${SAMPLE}_psbo.blastn" | sort -u > "extracted_genes/${SAMPLE}/psbo_ids.txt"
seqtk subseq "filtered_reads/${SAMPLE}_final.fasta" "extracted_genes/${SAMPLE}/psbo_ids.txt" > "extracted_genes/${SAMPLE}/psbo.fasta"

### Generate summary report ###
echo "=== ${SAMPLE} Gene Counts ===" > "logs/extract/${SAMPLE}_gene_summary.txt"
echo "radA: ${radA_hits}" >> "logs/extract/${SAMPLE}_gene_summary.txt"
echo "recA: ${recA_hits}" >> "logs/extract/${SAMPLE}_gene_summary.txt"
echo "psbo: ${psbo_hits}" >> "logs/extract/${SAMPLE}_gene_summary.txt"
echo "Total extracted sequences: $(grep -c '^>' extracted_genes/${SAMPLE}/*.fasta | awk -F: '{sum+=$2} END{print sum}')" >> "logs/extract/${SAMPLE}_gene_summary.txt"

conda deactivate
