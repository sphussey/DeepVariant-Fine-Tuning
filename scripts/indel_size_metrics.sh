#!/usr/bin/env bash
# ===========================================================================
# Extract indel metrics by custom size bins from hap.py output VCF
#
# Bins: SNV (0bp), INDEL_XS (1-4bp), INDEL_S (5-15bp), INDEL_M (16-50bp)
#
# hap.py outputs a 2-sample VCF: [TRUTH] [QUERY]
# BD field = TP/FP/FN/UNK/N   BVT field = SNP/INDEL
# We extract BD from BOTH samples to capture TPs, FPs, and FNs correctly:
#   TRUTH sample BD=TP -> TP, BD=FN -> FN
#   QUERY sample BD=FP -> FP
#
# Usage:
#   bash indel_size_metrics.sh data/outputs/happy_HG001_chr1.vcf.gz
# ===========================================================================

set -euo pipefail

HAPPY_VCF="${1:-data/outputs/happy_HG001_chr1.vcf.gz}"

if [ ! -f "${HAPPY_VCF}" ]; then
    echo "ERROR: hap.py output VCF not found: ${HAPPY_VCF}"
    exit 1
fi

echo "========================================"
echo "  Indel Size-Stratified Metrics"
echo "  Source: ${HAPPY_VCF}"
echo "========================================"
echo ""

# Extract: REF, ALT, TRUTH_BD, TRUTH_BVT, QUERY_BD, QUERY_BVT
bcftools query -f '%REF\t%ALT[\t%BD\t%BVT]\n' "${HAPPY_VCF}" 2>/dev/null | \
awk -F'\t' '
BEGIN {
    bins[0] = "SNV"
    bins[1] = "INDEL_XS_1-4bp"
    bins[2] = "INDEL_S_5-15bp"
    bins[3] = "INDEL_M_16-50bp"
    bins[4] = "INDEL_L_>50bp"
    for (b = 0; b <= 4; b++) { tp[b] = 0; fp[b] = 0; fn[b] = 0 }
}
{
    ref = $1
    alt = $2
    truth_bd  = $3
    truth_bvt = $4
    query_bd  = $5
    query_bvt = $6

    # Compute indel size
    ref_len = length(ref)
    alt_len = length(alt)
    indel_size = alt_len - ref_len
    if (indel_size < 0) indel_size = -indel_size

    # Determine variant type from whichever sample has a call
    if (truth_bvt != "." && truth_bvt != "" && truth_bvt != "NOCALL")
        vtype = truth_bvt
    else if (query_bvt != "." && query_bvt != "" && query_bvt != "NOCALL")
        vtype = query_bvt
    else
        next

    # Determine bin
    if (vtype == "SNP") {
        bin = 0
    } else if (indel_size >= 1 && indel_size <= 4) {
        bin = 1
    } else if (indel_size >= 5 && indel_size <= 15) {
        bin = 2
    } else if (indel_size >= 16 && indel_size <= 50) {
        bin = 3
    } else if (indel_size > 50) {
        bin = 4
    } else {
        next
    }

    # Count from TRUTH sample: TP and FN
    if (truth_bd == "TP") tp[bin]++
    else if (truth_bd == "FN") fn[bin]++

    # Count from QUERY sample: FP
    if (query_bd == "FP") fp[bin]++
}
END {
    printf "%-20s %8s %8s %8s %10s %10s %10s\n", \
        "Bin", "TP", "FP", "FN", "Precision", "Recall", "F1"
    printf "%-20s %8s %8s %8s %10s %10s %10s\n", \
        "----", "----", "----", "----", "---------", "------", "------"

    for (b = 0; b <= 4; b++) {
        if (tp[b] + fp[b] > 0) prec = tp[b] / (tp[b] + fp[b]); else prec = 0
        if (tp[b] + fn[b] > 0) rec = tp[b] / (tp[b] + fn[b]); else rec = 0
        if (prec + rec > 0) f1 = 2 * prec * rec / (prec + rec); else f1 = 0

        printf "%-20s %8d %8d %8d %10.4f %10.4f %10.4f\n", \
            bins[b], tp[b], fp[b], fn[b], prec, rec, f1
    }

    # Indel totals
    itot_tp = 0; itot_fp = 0; itot_fn = 0
    for (b = 1; b <= 4; b++) { itot_tp += tp[b]; itot_fp += fp[b]; itot_fn += fn[b] }
    if (itot_tp + itot_fp > 0) ip = itot_tp / (itot_tp + itot_fp); else ip = 0
    if (itot_tp + itot_fn > 0) ir = itot_tp / (itot_tp + itot_fn); else ir = 0
    if (ip + ir > 0) if1 = 2 * ip * ir / (ip + ir); else if1 = 0

    printf "%-20s %8s %8s %8s %10s %10s %10s\n", \
        "----", "----", "----", "----", "---------", "------", "------"
    printf "%-20s %8d %8d %8d %10.4f %10.4f %10.4f\n", \
        "ALL_INDELS", itot_tp, itot_fp, itot_fn, ip, ir, if1
}
'

echo ""
echo "Note: These counts should approximately match hap.py summary.csv totals."
echo "Small differences are expected due to multi-allelic splitting."
echo ""
echo "Verify against hap.py summary:"
if [ -f "${HAPPY_VCF%.vcf.gz}.summary.csv" ]; then
    grep -E "INDEL|SNP" "${HAPPY_VCF%.vcf.gz}.summary.csv" | grep "PASS" | \
        awk -F',' '{printf "  %-8s TP: %s  FP: %s  FN: %s  F1: %s\n", $1, $4, $6, $5, $14}'
fi
echo ""
echo "Done."