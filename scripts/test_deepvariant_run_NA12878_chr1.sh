#!/usr/bin/env bash
# ===========================================================================
# DeepVariant chr1 test run — Parabricks 4.6.0 on Northeastern Explorer
#
# Calls variants on chr1 of HG001 (NA12878) using pbrun deepvariant,
# then outputs a VCF suitable for benchmarking with hap.py.
#
# https://rc-docs.northeastern.edu/en/latest/gpus/accessinggpus.html
# Usage:
#   sbatch run_dv_test_chr1.sh
# ===========================================================================

#SBATCH --job-name=dv_chr1_test
#SBATCH --partition=gpu
#SBATCH --gres=gpu:h200:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=slurm_logs/dv_chr1_%j.out
#SBATCH --error=slurm_logs/dv_chr1_%j.err

set -euo pipefail

# ===========================================================================
# MODULES
# ===========================================================================
module load samtools 2>/dev/null || true
module load bcftools 2>/dev/null || true

# ===========================================================================
# PATHS
# ===========================================================================

# Parabricks container
SIF="/home/hussey.sh/CS7150/DeepVariant-Fine-Tuning/clara-parabricks_4.6.0-1.sif"

# Reference (in DeepVariant-Fine-Tuning project directory)
REF="/home/hussey.sh/CS7150/DeepVariant-Fine-Tuning/data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta"

# Input BAM (chr1 only)
INPUT_BAM="/home/hussey.sh/CS7150/DeepVariant-Fine-Tuning/data/inputs/HG001.novaseq.pcr-free.30x.dedup.grch38.chr1.bam"

# Output directory
OUTDIR="/home/hussey.sh/CS7150/DeepVariant-Fine-Tuning/data/outputs"
mkdir -p "${OUTDIR}" slurm_logs

# Output VCF
OUT_VCF="${OUTDIR}/HG001_chr1_deepvariant.vcf.gz"

# ===========================================================================
# PRE-FLIGHT CHECKS
# ===========================================================================
echo "[$(date)] === DeepVariant chr1 test ==="
echo ""

# Verify inputs exist
for f in "${SIF}" "${REF}" "${REF}.fai" "${INPUT_BAM}" "${INPUT_BAM}.bai"; do
    if [ ! -f "${f}" ]; then
        echo "ERROR: Missing file: ${f}"
        exit 1
    fi
done
echo "[$(date)] All input files verified."

# Report GPU and auto-detect stream count
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'unknown')
GPU_MEM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null || echo '0')
echo "  GPU: ${GPU_NAME} (${GPU_MEM_MB} MB)"

# Auto-set streams based on GPU memory
# ≥32 GB (A100, H200): 4 streams for best throughput
# <32 GB (V100, T4):   2 streams to avoid OOM
if [ "${GPU_MEM_MB}" -ge 32000 ] 2>/dev/null; then
    NUM_STREAMS=4
    echo "  Using ${NUM_STREAMS} streams (high-memory GPU detected)"
else
    NUM_STREAMS=2
    echo "  Using ${NUM_STREAMS} streams (standard-memory GPU)"
fi
echo ""

# ===========================================================================
# RUN PARABRICKS DEEPVARIANT
# ===========================================================================
#
# Key flags:
#   --run-partition         Partitions work across GPU for speedup.
#   --num-streams-per-gpu   Default 2. Increase to 4-6 on ≥32 GB GPUs.
#   (no --gvcf)             VCF only — sufficient for hap.py benchmarking.
#   (no --norealign-reads)  Keep local realignment ON — important for indels.
#

echo "[$(date)] Running pbrun deepvariant..."

apptainer exec --nv \
    -B "$(dirname ${REF})":"$(dirname ${REF})" \
    -B "$(dirname ${INPUT_BAM})":"$(dirname ${INPUT_BAM})" \
    -B "${OUTDIR}":"${OUTDIR}" \
    "${SIF}" \
    pbrun deepvariant \
        --ref "${REF}" \
        --in-bam "${INPUT_BAM}" \
        --out-variants "${OUT_VCF}" \
        --no-alt-contigs \
        --num-streams-per-gpu "${NUM_STREAMS}"

# ===========================================================================
# SANITY CHECKS
# ===========================================================================
echo ""
echo "[$(date)] DeepVariant complete."
echo ""

echo "=== Output VCF: ${OUT_VCF} ==="
echo "  File size: $(ls -lh ${OUT_VCF} | awk '{print $5}')"

if command -v bcftools &>/dev/null; then
    TOTAL=$(bcftools view -H "${OUT_VCF}" | wc -l)
    SNPS=$(bcftools view -H -v snps "${OUT_VCF}" | wc -l)
    INDELS=$(bcftools view -H -v indels "${OUT_VCF}" | wc -l)
    PASS=$(bcftools view -H -f PASS "${OUT_VCF}" | wc -l)

    echo "  Total variants: ${TOTAL}"
    echo "  SNPs:           ${SNPS}"
    echo "  Indels:         ${INDELS}"
    echo "  PASS filter:    ${PASS}"
else
    echo "  (bcftools not available — load module or install to see variant counts)"
fi

# ===========================================================================
# NEXT STEP: hap.py benchmarking command
# ===========================================================================
echo ""
echo "=== Next step: benchmark with hap.py ==="
echo ""
echo "  conda activate happy"
echo "  hap.py \\"
echo "    /home/hussey.sh/CS7150/deepVariant_workspace/data/truth_sets/HG001_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \\"
echo "    ${OUT_VCF} \\"
echo "    -r ${REF} \\"
echo "    -f /home/hussey.sh/CS7150/deepVariant_workspace/data/truth_sets/HG001_GRCh38_1_22_v4.2.1_benchmark.bed \\"
echo "    --engine=vcfeval \\"
echo "    --engine-vcfeval-template=/home/hussey.sh/CS7150/deepVariant_workspace/data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.sdf \\"
echo "    -l chr1 \\"
echo "    -o ${OUTDIR}/happy_HG001_chr1"
echo ""
echo "[$(date)] Done."