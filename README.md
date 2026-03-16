# DeepVariant Fine-Tuning



## NVIDIA Parabricks DeepVariant (GPU-Accelerated via NVIDIA Parabricks)

*Latest Version 4.6.0-1*

This repository contains the configuration and scripts for running **NVIDIA Parabricks DeepVariant** v4.6.0-1 on a High Performance Computing (HPC) cluster using **Apptainer**.

*Source: [NVIDIA Parabricks Documentation](https://docs.nvidia.com/clara/parabricks/latest/documentation/tooldocs/man_deepvariant.html)*

## Overview
NVIDIA Parabricks is a GPU-optimized version of DeepVariant. By leveraging CUDA and TensorRT, it can process a 30x–60x Whole Genome (WGS) in ~20 minutes, compared to several hours for the standard CPU-based Docker version.


## Setup & Installation

### 1. Environment Configuration
To prevent filling up your limited Home directory quota, redirect Apptainer's cache and temporary files to your scratch space.

**Pulling the latest Parabricks image from NVIDIA**


```bash
apptainer pull docker://nvcr.io/nvidia/clara/clara-parabricks:4.6.0-1
```

**Confirming Functionality**

```bash
apptainer exec clara-parabricks_4.6.0-1.sif pbrun --version
```


## Prerequisites: HPC Modules
The following bioinformatics tools are required for data preprocessing and downstream VCF analysis. On the **Explorer** cluster, these can be loaded via the environment module system:

| Tool | Version | Purpose |
| :--- | :--- | :--- |
| **bwa** | 0.7.18 | Sequence alignment to reference genome |
| **samtools** | 1.21 | Manipulation of SAM/BAM files |
| **bcftools** | 1.21 | VCF/BCF manipulation and variant calling |
| **bamtools** | 2.5.2 | Toolkit for working with BAM files |
| **bedtools** | 2.31.1 | Genomic interval arithmetic |
| **vcftools** | 0.1.16 | VCF file filtering and statistics |

### Loading Modules
To prepare your environment, run the following command:
```bash
module load bwa/0.7.18 samtools/1.21 bcftools/1.21 bamtools/2.5.2 bedtools/2.31.1 vcftools/0.1.16
```




```bash
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.gz
gunzip GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.gz
#module load samtools
samtools faidx GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi
```