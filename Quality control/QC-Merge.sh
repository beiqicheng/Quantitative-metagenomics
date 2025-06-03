#! /bin/bash
#SBATCH --account=fuhrman_1138
#SBATCH --partition=main
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=01:00:00
#SBATCH --mem-per-cpu=4G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-20

module load conda
module load bbmap
module load trimmomatic/0.39
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}

# Create output directories
mkdir -p 00-BBDuk 01-Clean logs/00-BBDuk logs/01-Clean

# Get input files list
input_files=(raw/*_R1.fastq)
INPUT="${input_files[$SLURM_ARRAY_TASK_ID-1]}"
SAMPLE=$(basename "$INPUT" _R1.fastq)

# Step 1: Run bbduk.sh for initial filtering
bbduk.sh -Xmx8g \
  in1="raw/${SAMPLE}_R1.fastq" \
  in2="raw/${SAMPLE}_R2.fastq" \
  out1="00-BBDuk/${SAMPLE}_R1_clean.fastq" \
  out2="00-BBDuk/${SAMPLE}_R2_clean.fastq" \
  ref=phix.fa
  k=31 \
  threads=${SLURM_CPUS_PER_TASK:-1} \
  2>&1 | tee -a "logs/00-BBDuk/${SAMPLE}.out"

# Step 2: Run Trimmomatic for further polishing
java -jar $EBROOTTRIMMOMATIC/trimmomatic-0.39.jar PE -phred33 \
  -threads ${SLURM_CPUS_PER_TASK:-1} \
  "00-BBDuk/${SAMPLE}_R1_clean.fastq" \
  "00-BBDuk/${SAMPLE}_R2_clean.fastq" \
  "01-Clean/${SAMPLE}_1_paired.fastq" \
  "01-Clean/${SAMPLE}_1_unpaired.fq" \
  "01-Clean/${SAMPLE}_2_paired.fastq" \
  "01-Clean/${SAMPLE}_2_unpaired.fq" \
  ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:8:TRUE \
  LEADING:5 TRAILING:5 SLIDINGWINDOW:5:20 MINLEN:50 \
  2>&1 | tee -a "logs/01-Clean/${SAMPLE}.out"

conda deactivate
