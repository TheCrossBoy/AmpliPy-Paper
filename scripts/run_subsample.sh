#!/usr/bin/env bash
# subsample FASTQ pair w/ sektk, map reads w/ Minimap2, and run both iVar and AmpliPy pipelines
if [ "$#" -ne 8 ] ; then
    echo "USAGE: $0 <FASTQ> <TOT_NUM_READS> <REF_GENOME_FAS> <REF_GENOME_MMI> <PRIMER_BED> <OUT_ZIP> <RNG_SEED> <NUM_PROCESS>"; exit 1
fi

# parse and check args
FQ=$1 ; N=$2 ; REF_FAS=$3 ; REF_MMI=$4 ; PRIMER_BED=$5 ; OUT_ZIP=$6 ; SEED=$7 ; NUM_PROCESS=$8 ; TMP_OUT_DIR=$(mktemp -d)
if [ ! -f "$FQ" ] ; then
    echo "File not found: $FQ" ; exit 1
elif [ -f "$OUT_ZIP" ] ; then
    echo "File already exists: $OUT_ZIP" ; exit 1
fi

# subsample FASTQ pair using seqtk
FQ_SUB="$TMP_OUT_DIR/sub.fastq.gz"
TIME_SEQTK="$TMP_OUT_DIR/time.01.seqtk.subsample.txt"
/usr/bin/time -v -o "$TIME_SEQTK" seqtk sample "-s$SEED" "$FQ" $N | gzip -9 > "$FQ_SUB"

# map reads using Minimap2
UNTRIMMED_BAM="$TMP_OUT_DIR/untrimmed.bam"
TIME_MINIMAP2="$TMP_OUT_DIR/time.02.minimap2.txt"
LOG_MINIMAP2="$TMP_OUT_DIR/log.minimap2.txt"
/usr/bin/time -v -o "$TIME_MINIMAP2" minimap2 -a -x sr "$REF_MMI" "$FQ_SUB" 2> "$LOG_MINIMAP2" | samtools view -S -b > "$UNTRIMMED_BAM"

# sort untrimmed BAM using samtools
UNTRIMMED_SORTED_BAM="$TMP_OUT_DIR/untrimmed.sorted.bam"
TIME_SAMTOOLS_SORT_UNTRIMMED="$TMP_OUT_DIR/time.03.samtools.sort.untrimmed.txt"
/usr/bin/time -v -o "$TIME_SAMTOOLS_SORT_UNTRIMMED" samtools sort -o "$UNTRIMMED_SORTED_BAM" "$UNTRIMMED_BAM"

# trim reads + call variants + call consensus using AmpliPy AIO
AMPLIPY_AIO_TRIMMED_BAM="$TMP_OUT_DIR/trimmed.amplipy.aio.bam"
AMPLIPY_AIO_VARIANTS_VCF="$TMP_OUT_DIR/trimmed.amplipy.aio.variants.vcf"
AMPLIPY_AIO_CONSENSUS_FAS="$TMP_OUT_DIR/trimmed.amplipy.aio.consensus.fas"
TIME_AMPLIPY_AIO="$TMP_OUT_DIR/time.12.amplipy.aio.txt"
LOG_AMPLIPY_AIO="$TMP_OUT_DIR/log.amplipy.aio.txt"
/usr/bin/time -v -o "$TIME_AMPLIPY_AIO" python3 AmpliPy.py aio -i "$UNTRIMMED_SORTED_BAM" -p "$PRIMER_BED" -r "$REF_FAS" -ot "$AMPLIPY_AIO_TRIMMED_BAM" -ov "$AMPLIPY_AIO_VARIANTS_VCF" -oc "$AMPLIPY_AIO_CONSENSUS_FAS" -x 5 -e -mdv 10 -mdc 10 -n N -mfc 0.5 -t $NUM_PROCESS 2> "$LOG_AMPLIPY_AIO"

# zip output and clean up
rm -f $TMP_OUT_DIR/*.fastq.gz $TMP_OUT_DIR/*.bam $TMP_OUT_DIR/*.bam.bai $TMP_OUT_DIR/*.pileup.txt  # delete FASTQs and BAMs to save space
zip -q -j -9 "$OUT_ZIP" $TMP_OUT_DIR/*
rm -rf "$TMP_OUT_DIR"
