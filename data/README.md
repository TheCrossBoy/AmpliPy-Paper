[reads.fastq.gz](reads.fastq.gz) was produced by extracting mapped reads from this file, and converting to FASTQ:

```
s3://ucsd-all/210924_A01535_0019_BHT7MHDSX2/210924_A01535_0019_BHT7MHDSX2_results/2021-09-28_01-17-47_pe/210924_A01535_0019_BHT7MHDSX2_samples/SEARCH-54039__E0001197__B04__210924_A01535_0019_BHT7MHDSX2__004/SEARCH-54039__E0001197__B04__210924_A01535_0019_BHT7MHDSX2__004.sorted.bam
```

Run simulations:

```bash
for p in 3 4 6 8 10 12 16 ; do mkdir -p p$p && for n in 100 1000 10000 100000 1000000 ; do mkdir -p p$p/n$n && for r in $(seq -w 1 10) ; do ../scripts/run_subsample.sh reads.fastq.gz $n reference.fas reference.fas.mmi primers.bed p$p/n$n/p$p.n$n.r$r.zip $RANDOM $p ; done && echo "Completed p $p n $n" ; done ; done
```
