#!/bin/bash
#SBATCH --account=fuhrman_1138
#SBATCH --partition=main
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=4:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-20

module load conda
module load blast
module load seqtk
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}

# Create directory structure
mkdir -p merged-fasta blastn_results blastx_results filtered_reads logs/{convert,blastn,blastx,filter}

# Get sample list from PEAR output
input_files=(02-Merged/*.assembled.fastq)
SAMPLE=$(basename "${input_files[$SLURM_ARRAY_TASK_ID-1]}" .assembled.fastq)

# Step 1: Convert merged FASTQ to FASTA
seqtk seq -A "02-Merged/${SAMPLE}.assembled.fastq.gz" > "merged-fasta/${SAMPLE}.fasta"
echo "Converted ${SAMPLE} to FASTA" | tee -a "logs/convert/${SAMPLE}.log"

# Step 2: BLASTn against ISD-DNA.fa
blastn -query "merged-fasta/${SAMPLE}.fasta" \
       -db /path/to/ISDs-DNA.fa \
       -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen" \
       -num_threads ${SLURM_CPUS_PER_TASK:-1} \
       -evalue 1e-3 \
       -perc_identity 95 \
       -qcov_hsp_perc 50 \
       -max_hsps 1 \
       -max_target_seqs 1 \
       > "blastn_results/${SAMPLE}_vs_ISD-DNA.blastn"

# Count BLASTn hits (filtered at 95% identity)
blastn_hits=$(wc -l < "blastn_results/${SAMPLE}_vs_ISD-DNA.blastn")
echo "${SAMPLE} BLASTn hits (95% id): ${blastn_hits}" | tee -a "logs/blastn/${SAMPLE}.log"

# Step 3: Extract BLASTn hits
awk '{print $1}' "blastn_results/${SAMPLE}_vs_ISD-DNA.blastn" | sort | uniq > "blastn_results/${SAMPLE}_hit_ids.txt"
seqtk subseq "merged-fasta/${SAMPLE}.fasta" "blastn_results/${SAMPLE}_hit_ids.txt" > "blastn_results/${SAMPLE}_hits.fasta"

# Step 4: BLASTx against ISD-pro.fa
blastx -query "blastn_results/${SAMPLE}_hits.fasta" \
       -db /path/to/ISDs-pro.fa \
       -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen" \
       -num_threads ${SLURM_CPUS_PER_TASK:-1} \
       -evalue 1e-3 \
       -perc_identity 95 \
       -max_hsps 1 \
       -max_target_seqs 1 \
       > "blastx_results/${SAMPLE}_vs_ISD-pro.blastx"

# Count BLASTx hits
blastx_hits=$(wc -l < "blastx_results/${SAMPLE}_vs_ISD-pro.blastx")
echo "${SAMPLE} BLASTx hits (95% id): ${blastx_hits}" | tee -a "logs/blastx/${SAMPLE}.log"

# Step 5: Filter final sequences
awk '{print $1}' "blastx_results/${SAMPLE}_vs_ISD-pro.blastx" | sort | uniq > "blastx_results/${SAMPLE}_final_ids.txt"
seqtk subseq "merged-fasta/${SAMPLE}.fasta" "blastx_results/${SAMPLE}_final_ids.txt" > "filtered_reads/${SAMPLE}_final.fasta"

# Generate summary report
echo "=== ${SAMPLE} Summary (95% identity thresholds) ===" > "logs/${SAMPLE}_summary.txt"
echo "Total merged reads: $(grep -c '^>' merged-fasta/${SAMPLE}.fasta)" >> "logs/${SAMPLE}_summary.txt"
echo "BLASTn hits (95% id): ${blastn_hits}" >> "logs/${SAMPLE}_summary.txt"
echo "BLASTx hits (95% id): ${blastx_hits}" >> "logs/${SAMPLE}_summary.txt"
echo "Final sequences: $(grep -c '^>' filtered_reads/${SAMPLE}_final.fasta)" >> "logs/${SAMPLE}_summary.txt"

conda deactivate
