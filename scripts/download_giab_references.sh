#!/usr/bin/env bash
# ===========================================================================
# Download GIAB reference genome, truth sets, stratifications, and extras
# to your courses/home directory. Small files only (~6 GB total).
#
# Usage:  ./download_giab_references.sh [output_dir]
#   Default: /home/hussey.sh/CS7150/deepVariant_workspace/data
# ===========================================================================

set -euo pipefail

OUTDIR="${1:-/home/hussey.sh/CS7150/deepVariant_workspace/data}"
mkdir -p "${OUTDIR}"/{reference,truth_sets,stratifications,extras}


REF_NAME="GCA_000001405.15_GRCh38_no_alt_analysis_set"

echo "========================================"
echo "  GIAB References Download"
echo "  Target: ${OUTDIR}"
echo "  Estimated size: ~6 GB"
echo "========================================"


# ===========================
# SECTION 1: REFERENCE GENOME
# ===========================
REF_DIR="${OUTDIR}/reference"
REF_BASE="${GIAB_FTP}/ReferenceSamples/giab/release/references/GRCh38"

echo ""
echo "--- Reference genome + indices ---"

wget -c -P "${REF_DIR}" "${REF_BASE}/${REF_NAME}.fasta.gz"
wget -c -P "${REF_DIR}" "${REF_BASE}/${REF_NAME}.fasta.gz.fai"
wget -c -P "${REF_DIR}" "${REF_BASE}/${REF_NAME}.fasta.gz.gzi"
wget -c -P "${REF_DIR}" "${REF_BASE}/GCA_000001405.15_GRCh38_GRC_exclusions_T2Tv2.bed"

# Decompress (keep .gz copy)
if [ ! -f "${REF_DIR}/${REF_NAME}.fasta" ]; then
    echo "Decompressing reference FASTA..."
    gunzip -k "${REF_DIR}/${REF_NAME}.fasta.gz"
    samtools faidx "${REF_DIR}/${REF_NAME}.fasta"
fi

# Sequence dictionary
if [ ! -f "${REF_DIR}/${REF_NAME}.dict" ]; then
    echo "Building sequence dictionary..."
    samtools dict "${REF_DIR}/${REF_NAME}.fasta" > "${REF_DIR}/${REF_NAME}.dict"
fi

# RTG SDF
if [ ! -d "${REF_DIR}/${REF_NAME}.sdf" ]; then
    if command -v rtg &>/dev/null; then
        echo "Building RTG SDF..."
        rtg format -o "${REF_DIR}/${REF_NAME}.sdf" "${REF_DIR}/${REF_NAME}.fasta"
    else
        echo "SKIPPED: rtg not found. Build SDF manually after installing rtg-tools."
    fi
fi


# ===========================
# SECTION 2: TRUTH SETS (all 7 GIAB samples)
# ===========================
TRUTH_DIR="${OUTDIR}/truth_sets"

echo ""
echo "--- Truth sets (7 samples) ---"

# HG001 (NA12878) — HapMap/CEPH female
echo "  HG001..."
HG001_BASE="${GIAB_FTP}/giab/ftp/release/NA12878_HG001/NISTv4.2.1/GRCh38"
wget -c -P "${TRUTH_DIR}" "${HG001_BASE}/HG001_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
wget -c -P "${TRUTH_DIR}" "${HG001_BASE}/HG001_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi"
wget -c -P "${TRUTH_DIR}" "${HG001_BASE}/HG001_GRCh38_1_22_v4.2.1_benchmark.bed"

# HG002 (NA24385) — Ashkenazi son
echo "  HG002..."
HG002_BASE="${GIAB_FTP}/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38"
wget -c -P "${TRUTH_DIR}" "${HG002_BASE}/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
wget -c -P "${TRUTH_DIR}" "${HG002_BASE}/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi"
wget -c -P "${TRUTH_DIR}" "${HG002_BASE}/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"

# HG003 (NA24149) — Ashkenazi father
echo "  HG003..."
HG003_BASE="${GIAB_FTP}/ReferenceSamples/giab/release/AshkenazimTrio/HG003_NA24149_father/NISTv4.2.1/GRCh38"
wget -c -P "${TRUTH_DIR}" "${HG003_BASE}/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
wget -c -P "${TRUTH_DIR}" "${HG003_BASE}/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi"
wget -c -P "${TRUTH_DIR}" "${HG003_BASE}/HG003_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"

# HG004 (NA24143) — Ashkenazi mother
echo "  HG004..."
HG004_BASE="${GIAB_FTP}/ReferenceSamples/giab/release/AshkenazimTrio/HG004_NA24143_mother/NISTv4.2.1/GRCh38"
wget -c -P "${TRUTH_DIR}" "${HG004_BASE}/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
wget -c -P "${TRUTH_DIR}" "${HG004_BASE}/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi"
wget -c -P "${TRUTH_DIR}" "${HG004_BASE}/HG004_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"

# HG005 (NA24631) — Han Chinese son
echo "  HG005..."
HG005_BASE="${GIAB_FTP}/ReferenceSamples/giab/release/ChineseTrio/HG005_NA24631_son/NISTv4.2.1/GRCh38"
wget -c -P "${TRUTH_DIR}" "${HG005_BASE}/HG005_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
wget -c -P "${TRUTH_DIR}" "${HG005_BASE}/HG005_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi"
wget -c -P "${TRUTH_DIR}" "${HG005_BASE}/HG005_GRCh38_1_22_v4.2.1_benchmark.bed"

# HG006 (NA24694) — Han Chinese father
echo "  HG006..."
HG006_BASE="${GIAB_FTP}/ReferenceSamples/giab/release/ChineseTrio/HG006_NA24694_father/NISTv4.2.1/GRCh38"
wget -c -P "${TRUTH_DIR}" "${HG006_BASE}/HG006_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
wget -c -P "${TRUTH_DIR}" "${HG006_BASE}/HG006_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi"
wget -c -P "${TRUTH_DIR}" "${HG006_BASE}/HG006_GRCh38_1_22_v4.2.1_benchmark.bed"

# HG007 (NA24695) — Han Chinese mother
echo "  HG007..."
HG007_BASE="${GIAB_FTP}/ReferenceSamples/giab/release/ChineseTrio/HG007_NA24695_mother/NISTv4.2.1/GRCh38"
wget -c -P "${TRUTH_DIR}" "${HG007_BASE}/HG007_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
wget -c -P "${TRUTH_DIR}" "${HG007_BASE}/HG007_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi"
wget -c -P "${TRUTH_DIR}" "${HG007_BASE}/HG007_GRCh38_1_22_v4.2.1_benchmark.bed"


# ===========================
# SECTION 3: STRATIFICATIONS
# ===========================
# v3.3+ changed directory layout — BEDs are bundled in a tarball.
# We download the v3.5 GRCh38 tarball and extract.
# If you need individual files from v2.0 (flat layout), those are at:
#   ${GIAB_FTP}/ReferenceSamples/giab/release/genome-stratifications/v2.0/GRCh38/

STRAT_DIR="${OUTDIR}/stratifications"
STRAT_BASE="${GIAB_FTP}/ReferenceSamples/giab/release/genome-stratifications/v3.5"

echo ""
echo "--- Stratification BEDs (v3.5 tarball) ---"

wget -c -P "${STRAT_DIR}" "${STRAT_BASE}/genome-stratifications-GRCh38@all.tar.gz"

echo "Extracting stratifications..."
tar -xzf "${STRAT_DIR}/genome-stratifications-GRCh38@all.tar.gz" -C "${STRAT_DIR}"

echo "  Extracted to: ${STRAT_DIR}/GRCh38@all/"
echo "  TSV index files are inside the extracted directory."
echo "  Key subdirectories: LowComplexity/, SegmentalDuplications/, mappability/, GCcontent/, Union/"


# ===========================
# SECTION 4: EXTRAS
# ===========================
EXTRAS_DIR="${OUTDIR}/extras"

echo ""
echo "--- DeepVariant model + extras ---"

# Pretrained WGS model
wget -c -P "${EXTRAS_DIR}" "https://storage.googleapis.com/deepvariant/models/DeepVariant/1.6.1/savedmodels/deepvariant.wgs.savedmodel.tar.gz"

# PAR regions BED
wget -c -P "${EXTRAS_DIR}" "https://storage.googleapis.com/deepvariant/case-study-testdata/GRCh38_PAR.bed"

# Pedigree files
cat > "${EXTRAS_DIR}/ashkenazi_trio.ped" << 'EOF'
#PED format pedigree
#fam-id	ind-id	pat-id	mat-id	sex	phenotype
AJtrio	HG002	HG003	HG004	1	0
AJtrio	HG003	0	0	1	0
AJtrio	HG004	0	0	2	0
EOF

cat > "${EXTRAS_DIR}/chinese_trio.ped" << 'EOF'
#PED format pedigree
#fam-id	ind-id	pat-id	mat-id	sex	phenotype
CNtrio	HG005	HG006	HG007	1	0
CNtrio	HG006	0	0	1	0
CNtrio	HG007	0	0	2	0
EOF


# ===========================
# SECTION 5: VERIFY
# ===========================
echo ""
echo "========================================"
echo "  Download complete!"
echo "========================================"
echo ""
echo "--- Reference ---"
ls -lh "${REF_DIR}"/${REF_NAME}.fasta "${REF_DIR}"/${REF_NAME}.dict 2>/dev/null || echo "  MISSING"
echo ""
echo "--- Truth sets ---"
ls "${TRUTH_DIR}"/*.vcf.gz 2>/dev/null | wc -l | xargs -I{} echo "  {} VCFs"
ls "${TRUTH_DIR}"/*.bed 2>/dev/null | wc -l | xargs -I{} echo "  {} BEDs"
echo ""
echo "--- Stratifications ---"
ls "${STRAT_DIR}"/GRCh38@all/ 2>/dev/null | head -10
echo "  ..."
find "${STRAT_DIR}/GRCh38@all" -name "*.bed.gz" 2>/dev/null | wc -l | xargs -I{} echo "  {} BED files total"
echo ""
echo "--- Extras ---"
ls "${EXTRAS_DIR}"/ 2>/dev/null
echo ""
echo "Total size:"
du -sh "${OUTDIR}"
echo ""
echo "To link BAMs from scratch into this directory:"
echo "  ln -s /scratch/hussey.sh/giab_bams ${OUTDIR}/bams"