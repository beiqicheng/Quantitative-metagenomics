# Quantitative metagenomics
Absolute quantification of microbial cells acorss the Atlantic Meridional Transect

---

High-throughput sequencing has revolutionized our understanding of microbial biodiversity in marine ecosystems. However, most sequencing-based studies report only relative (compositional) rather than absolute abundance, limiting their application in ecological modeling and biogeochemical analyses. To address this gap, we developed a quantitative metagenomic protocol that incorporates genomic internal standards to measure absolute abundances of both prokaryotes and eukaryotic phytoplankton in unfractionated seawater samples.

We present a suite of bash scripts for quantitative metagenomic analysis using internal standards and single-copy gene markers. This pipeline was applied to samples from the 29th Atlantic Meridional Transect (AMT29) to absolutely quantify microbial populations. Three internal genomic standards (ISDs: Thermus thermophilus, Blautia producta, Deinococcus radiodurans) were added to the lysis buffer after bead beating (crude DNA extraction), targeting approximately 1% of total DNA content as internal standards. For bacteria, the recombinase A genes (recA in bacteria, radA in archaea) were selected for their universal distribution and single-copy nature. The psbO gene, encoding a photosystem II oxygen-evolving complex protein, serves as a dual marker for Cyanobacteria (bacterial photosynthesis) and Eukaryotic phytoplankton (nuclear-encoded photosynthesis genes), which together form the base of the marine food web.

---

Important papers:

If you wnat to know more background of quantative metagenomics, please read the following papers:

Gifford, Scott M., et al. "Microbial niche diversification in the galápagos archipelago and its response to El Niño." Frontiers in Microbiology 11 (2020): 575194.

Pierella Karlusich, Juan José, et al. "A robust approach to estimate relative phytoplankton cell abundances from metagenomes." Molecular Ecology Resources 23.1 (2023): 16-40.

Satinsky, Brandon M., et al. "Use of internal standards for quantitative metatranscriptome and metagenome analysis." Methods in enzymology. Vol. 531. Academic Press, 2013. 237-250.

---

**Bioinformatics Pipeline:**

0. Quality control
1. Mergeing paired-end reads
2. Internal standard recovery
3. Haploid genome equivalents

---

## 0. Quality control

**Note:** This tutorial assumes your samples were sequenced on a short read sequencer (300bp x 2 by illumina or AVITI in our study). We suggest to creat a new Conda environment when working in High performance computing (HPC).

Raw reads quality control and trimming (via Trimmomatic). Trimmomatic removes low quality reads as well as adapter sequences. Raw sequencing data also needs to be processed to remove artifacts. This process is to remove contaminant sequences that are present in the sequencing process such as PhiX which is sometimes added as an internal control for sequencing runs (bbduk.sh).

## 1. Mergeing paired-end reads

After quality control, PEAR (Paired-End reAd mergeR) software was applied to merge paired-end reads to generate long reads. Although metagenome assemblers like MEGAHIT and MetaSPAdes can genrate longer reads, the numbers of ISDs and single-copy genes were much lower than that of pair-end merged reads. In our study, around 90% paired-end reads can be merged by PEAR and the average length was 250bp for AMT29 samples.

## 2. Internal standards recovery

The number of three genomic ISDs should be quantified by first using a BLASTn homology search against the reference genome sequence to identify all potential standard reads (cuttoff: e-value < 0.001, %ID > 95%, alignment length > 50% of the read length, bit score > 50). The identified internal standard reads were then annotated via a BLASTx (e-value < 0.001) homology search against a database of the internal standard protein sequences, and hits with bit scores < 40 or %ID < 95 were removed. Recovery of internal standards in the libraries was used to estimate gene volumetric abundances using calculations derived from Satinsky et al. (2013):

![image](https://github.com/user-attachments/assets/db8dc973-7a69-48d0-aff0-a1ac71c65261)


## 3. Haploid genome equivalents

Taxon genome equivalents per liter were calculated by dividing the number of annotated single-copy genes annotated by the recovery ratio R then dividing by the seawater volume filtered (1L for AMT29). To identify recA genes in the metagenomics, the bacterial RecA protein sequences were downloaded from NCBI, metagenome reads were then compared to the custom RecA database using a DIAMOND homology search (blastx), with top hits having a bit score > 50 counted as a recA gene, and the results checked against the KEGG database (https://www.kegg.jp/ghostkoala/) to confirm the RecA annotation. For the psbO gene, assembled reads were searched against the database generated from Tara Oceans datasets using BLASTn (e-value < 0.001, %id > 80%, bit score > 50).





