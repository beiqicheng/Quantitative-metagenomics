# Quantitative Metagenomic Analysis Pipeline
_Absolute quantification of microbial cells acorss the Atlantic Meridional Transect_

---

High-throughput sequencing has revolutionized our understanding of microbial biodiversity in marine ecosystems. However, most sequencing-based studies report only relative (compositional) rather than absolute abundance, limiting their application in ecological modeling and biogeochemical analyses. To address this gap, we developed a quantitative metagenomic protocol that incorporates genomic internal standards to measure absolute abundances of both prokaryotes and eukaryotic phytoplankton in unfractionated seawater samples.

We present a suite of bash scripts for quantitative metagenomic analysis using internal standards and single-copy gene markers. This pipeline was applied to samples from the 29th Atlantic Meridional Transect (AMT29) to absolutely quantify microbial populations. Three internal genomic standards (ISDs: Thermus thermophilus, Blautia producta, Deinococcus radiodurans) were added to the lysis buffer after bead beating (crude DNA extraction), targeting approximately 1% of total DNA content as internal standards. For bacteria, the recombinase A genes (_recA_ in bacteria, _radA_ in archaea) were selected for their universal distribution and single-copy nature. The _psbO_ gene, encoding a photosystem II oxygen-evolving complex protein, serves as a dual marker for Cyanobacteria (bacterial photosynthesis) and Eukaryotic phytoplankton (nuclear-encoded photosynthesis genes), which together form the base of the marine food web.

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
2. Internal standards recovery
3. Estimating haploid genome equivalents

---

## 0. Quality control

**Note:** This tutorial assumes your samples were sequenced using a short-read platform (e.g., Illumina or AVITI, 2 × 300 bp reads in our case). We recommend creating a new Conda environment when working on high-performance computing (HPC) systems.

Raw read quality control and adapter trimming are performed using Trimmomatic to remove low-quality bases and adapter sequences. Additionally, we recommend processing sequencing data with bbduk.sh to eliminate common contaminants such as PhiX control sequences, which are frequently spiked into Illumina sequencing runs as internal controls.


## 1. Mergeing paired-end reads

After quality control, PEAR (Paired-End reAd mergeR) is used to merge paired-end reads into longer sequences. While assemblers like MEGAHIT and MetaSPAdes can also generate longer contigs, they typically recover fewer internal standard (ISD) and single-copy gene reads compared to merged paired-end reads. In our study, approximately 90% of paired-end reads were successfully merged using PEAR, with an average merged length of 250 bp for AMT29 samples.

## 2. Internal standards recovery

The abundance of genomic internal standards (ISDs) is first estimated using a BLASTn search against the known reference genomes (e-value < 0.001, %ID > 95%, alignment length > 50% of the read length, bit score > 50). Identified ISD reads are further verified via a BLASTx search against a curated protein database of ISD sequences, applying e-value < 0.001, %ID > 95%, and bit score > 50. The number of recovered ISD reads is used to calculate gene abundances per liter of seawater, following the method of Satinsky et al. (2013):

![image](https://github.com/user-attachments/assets/db8dc973-7a69-48d0-aff0-a1ac71c65261)

Recovery of internal standards in the metagenomics was used to estimate gene volumetric abundances for each sample using calculations partly derived from Gifford et al. [2020]:

<img width="908" height="670" alt="Equations" src="https://github.com/user-attachments/assets/0ba65c56-72cf-4233-a7a2-24e2e4a72744" />


The volumetric abundance of each single copy gene (e.g. radA or recA) was determined by dividing gene counts by the volume of seawater filtered. The psbO gene is encoded by both cyanobacteria and eukaryotic phytoplankton, enabling cross-domain analysis. We employed two approaches to estimate haploid genome equivalent of photosynthetic eukaryotes. The first applied the recovery ratio directly to psbO reads, as done for recA (Equation 3). However, this method underestimated cyanobacterial (Prochlorococcus and Synechococcus) abundances, with a slope of 0.72 (Pearson’s r = 0.99) compared to recA-based estimates. As an alternative, we calculated the ratio of taxon-specific eukaryotic psbO reads to cyanobacterial psbO reads and then multiplied it by the absolute cyanobacterial abundance based on recA (Equation 4). This assumes an accurate recA cyanobacteria count and that psbO-based underestimation similarly affects both cyanobacteria and photosynthetic eukaryotes, likely due to sequencing depth and limitations in the psbO reference database. 

## 3. Estimating haploid genome equivalents

To estimate taxon-specific genome equivalents per liter: The number of annotated single-copy genes is divided by the internal standard recovery ratio (R). The result is normalized by the volume of seawater filtered (1 L for AMT29).

To identify recA genes in the metagenomics, bacterial recA protein sequences were downloaded from NCBI, metagenome reads were queried against the custom recA database using DIAMOND blastx, with top hits having a bit score > 50. The results were also checked against the KEGG database (https://www.kegg.jp/ghostkoala/) to confirm the recA annotation. For the psbO gene, assembled reads were searched against the psbO database generated from Tara Oceans datasets using BLASTn (e-value < 0.001, %id > 80%, bit score > 50).


## Curated databases for _recA_ and _radA_ genes

Archaeal radA and acterial recA protein databases were download from  NCBI containing the key words "recA", "recombinase recA", or "recombinase A". To shrink the recA database for ocean samples, proteins from opportunistic pathogens were removed, such as _Streptococcus pneumoniae_, _Klebsiella pneumoniae_, _Staphylococcus aureus_, _Salmonella enterica_, _Enterococcus faecium_ and _Pseudomonas aeruginosa_.

The _recA_ and _radA_ gene databased in our study are available at https://doi.org/10.6084/m9.figshare.28921349.v1.

The _psbo_ gene database from Juan José is available at https://www.ebi.ac.uk/biostudies/studies/S-BSST659.
