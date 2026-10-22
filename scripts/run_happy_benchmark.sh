#!/usr/bin/env bash
# ===========================================================================
# hap.py Benchmarking for DeepVariant chr1 test
#
# Part 1: Create conda environment with hap.py + rtg-tools (one-time setup)
# Part 2: Run hap.py with vcfeval engine on chr1 DeepVariant output
#
# Usage:
#   # First time — run setup, then benchmark:
#   bash run_happy_benchmark.sh setup
#
#   # Subsequent runs — skip setup, just benchmark:
#   bash run_happy_benchmark.sh benchmark
#
#   # Or run both:
#   bash run_happy_benchmark.sh all
# ===========================================================================

set -euo pipefail

# ===========================================================================
# PATHS — edit these to match your setup
# ===========================================================================
PROJECT_DIR="/home/hussey.sh/CS7150/DeepVariant-Fine-Tuning"
DATA_DIR="${PROJECT_DIR}/data"

# Reference
REF="${DATA_DIR}/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta"
REF_SDF="${DATA_DIR}/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.sdf"

# DeepVariant output to benchmark
QUERY_VCF="${DATA_DIR}/outputs/HG001_chr1_deepvariant.vcf.gz"

# Truth set (HG001 / NA12878)
# Update these paths to wherever your truth sets live
TRUTH_DIR="/home/hussey.sh/CS7150/deepVariant_workspace/data/truth_sets"
TRUTH_VCF="${TRUTH_DIR}/HG001_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
TRUTH_BED="${TRUTH_DIR}/HG001_GRCh38_1_22_v4.2.1_benchmark.bed"

# Output
HAPPY_OUT="${DATA_DIR}/outputs/happy_HG001_chr1"

# Conda environment name
CONDA_ENV="happy"

# ===========================================================================
# FUNCTIONS
# ===========================================================================

setup_conda_env() {
    echo "========================================"
    echo "  Setting up conda environment: ${CONDA_ENV}"
    echo "========================================"
    echo ""

    # Check if env already exists
    if conda info --envs | grep -q "^${CONDA_ENV} "; then
        echo "Environment '${CONDA_ENV}' already exists."
        echo "To recreate, run: conda env remove -n ${CONDA_ENV}"
        echo ""
    else
        echo "Creating conda environment with hap.py and rtg-tools..."
        echo "  (hap.py requires Python 2.7)"
        echo ""

        conda create -y -n "${CONDA_ENV}" \
            -c bioconda \
            -c conda-forge \
            python=2.7 \
            hap.py \
            rtg-tools

        echo ""
        echo "Environment '${CONDA_ENV}' created successfully."
    fi

    # Activate and verify
    echo ""
    echo "Verifying installation..."

    # Use eval for conda activate in scripts
    eval "$(conda shell.bash hook)"
    conda activate "${CONDA_ENV}"

    echo "  hap.py:     $(which hap.py 2>/dev/null || echo 'NOT FOUND')"
    echo "  rtg:        $(which rtg 2>/dev/null || echo 'NOT FOUND')"
    echo "  Python:     $(python --version 2>&1)"
    echo ""

    # Build RTG SDF if it doesn't exist
    if [ ! -d "${REF_SDF}" ]; then
        echo "Building RTG SDF index (one-time step)..."
        rtg format \
            -o "${REF_SDF}" \
            "${REF}"
        echo "SDF created at: ${REF_SDF}"
    else
        echo "RTG SDF already exists: ${REF_SDF}"
    fi

    conda deactivate
    echo ""
    echo "Setup complete. Run with: bash $0 benchmark"
}

run_benchmark() {
    echo "========================================"
    echo "  hap.py Benchmark: HG001 chr1"
    echo "========================================"
    echo ""

    # Pre-flight checks
    for f in "${REF}" "${QUERY_VCF}" "${TRUTH_VCF}" "${TRUTH_BED}"; do
        if [ ! -f "${f}" ]; then
            echo "ERROR: Missing file: ${f}"
            exit 1
        fi
    done
    if [ ! -d "${REF_SDF}" ]; then
        echo "ERROR: RTG SDF not found at ${REF_SDF}"
        echo "  Run: bash $0 setup"
        exit 1
    fi

    echo "  Query VCF:  ${QUERY_VCF}"
    echo "  Truth VCF:  ${TRUTH_VCF}"
    echo "  Truth BED:  ${TRUTH_BED}"
    echo "  Reference:  ${REF}"
    echo "  Engine:     vcfeval (RTG)"
    echo "  Region:     chr1"
    echo "  Output:     ${HAPPY_OUT}"
    echo ""

    # Activate conda env
    eval "$(conda shell.bash hook)"
    conda activate "${CONDA_ENV}"

    # Create output directory
    mkdir -p "$(dirname ${HAPPY_OUT})"

    # Run hap.py
    echo "[$(date)] Running hap.py..."
    echo ""

    hap.py \
        "${TRUTH_VCF}" \
        "${QUERY_VCF}" \
        -r "${REF}" \
        -f "${TRUTH_BED}" \
        --engine=vcfeval \
        --engine-vcfeval-template="${REF_SDF}" \
        -l chr1 \
        -o "${HAPPY_OUT}" \
        --threads 4

    echo ""
    echo "[$(date)] hap.py complete."
    echo ""

    # Display results
    echo "========================================"
    echo "  Results Summary"
    echo "========================================"
    echo ""

    if [ -f "${HAPPY_OUT}.summary.csv" ]; then
        # Print header + data rows in a readable format
        echo "--- Summary (${HAPPY_OUT}.summary.csv) ---"
        echo ""
        column -t -s',' "${HAPPY_OUT}.summary.csv"
        echo ""

        echo "--- Key Metrics ---"
        echo ""
        # Extract SNP and INDEL PASS rows
        grep "SNP" "${HAPPY_OUT}.summary.csv" | grep "PASS" | \
            awk -F',' '{printf "  SNP    Precision: %s  Recall: %s  F1: %s\n", $11, $12, $13}'
        grep "INDEL" "${HAPPY_OUT}.summary.csv" | grep "PASS" | \
            awk -F',' '{printf "  INDEL  Precision: %s  Recall: %s  F1: %s\n", $11, $12, $13}'
    else
        echo "  WARNING: Summary file not found."
        echo "  Check logs at: ${HAPPY_OUT}.*"
    fi

    echo ""
    echo "--- Output Files ---"
    ls -lh "${HAPPY_OUT}".* 2>/dev/null
    echo ""

    conda deactivate
    echo "[$(date)] Done."
}

# ===========================================================================
# MAIN
# ===========================================================================
ACTION="${1:-all}"

case "${ACTION}" in
    setup)
        setup_conda_env
        ;;
    benchmark)
        run_benchmark
        ;;
    all)
        setup_conda_env
        run_benchmark
        ;;
    *)
        echo "Usage: bash $0 {setup|benchmark|all}"
        exit 1
        ;;
esac
