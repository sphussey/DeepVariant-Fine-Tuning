cd /home/hussey.sh/CS7150/DeepVariant-Fine-Tuning

# Step 1: Get the list of valid contig names from reference
cut -f1 data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.fai > data/outputs/ref_contigs.txt

# Verify — should be 195
wc -l data/outputs/ref_contigs.txt

# Step 2: Build clean header — keep only @SQ lines for contigs in reference
samtools view -H data/inputs/HG001.novaseq.pcr-free.30x.dedup.grch38.chr1.bam | \
    awk '
    /^@SQ/ {
        split($2, sn, ":");
        contig = sn[2];
        if (!(contig in keep)) next;
    }
    { print }
    ' keep_file=1 \
    > data/outputs/clean_header.sam

# That awk might not work — let's use grep instead:
# Keep all non-@SQ lines, plus only @SQ lines matching our contig list
samtools view -H data/inputs/HG001.novaseq.pcr-free.30x.dedup.grch38.chr1.bam | \
    grep -v "^@SQ" > data/outputs/clean_header.sam

# Add back only @SQ lines for contigs in the reference
samtools view -H data/inputs/HG001.novaseq.pcr-free.30x.dedup.grch38.chr1.bam | \
    grep "^@SQ" | while IFS=$'\t' read -r line; do
        contig=$(echo "$line" | grep -oP 'SN:\K[^\t]+')
        if grep -qx "$contig" data/outputs/ref_contigs.txt; then
            echo "$line"
        fi
    done >> data/outputs/clean_header.sam

# Verify header contig count — should be ≤195
grep -c "^@SQ" data/outputs/clean_header.sam

# Step 3: Build clean BAM
samtools view -@ 4 data/inputs/HG001.novaseq.pcr-free.30x.dedup.grch38.chr1.bam chr1 | \
    cat data/outputs/clean_header.sam - | \
    samtools view -b -@ 4 - > data/outputs/HG001.chr1.noalt.unsorted.bam

# Step 4: Sort
samtools sort -@ 4 \
    -T /scratch/hussey.sh/tmp_sort/sort \
    -o data/outputs/HG001.chr1.noalt.bam \
    data/outputs/HG001.chr1.noalt.unsorted.bam

# Step 5: Index
samtools index -@ 4 data/outputs/HG001.chr1.noalt.bam

# Step 6: Final verification
echo "ALT: $(samtools view -H data/outputs/HG001.chr1.noalt.bam | grep '@SQ' | grep -c '_alt')"
echo "Decoy: $(samtools view -H data/outputs/HG001.chr1.noalt.bam | grep '@SQ' | grep -c '_decoy')"
echo "Total @SQ: $(samtools view -H data/outputs/HG001.chr1.noalt.bam | grep -c '@SQ')"
echo "Ref contigs: 195"

# Cleanup
rm -f data/outputs/HG001.chr1.noalt.unsorted.bam data/outputs/clean_header.sam data/outputs/ref_contigs.txt
