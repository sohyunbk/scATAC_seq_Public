#!/bin/bash

### This step is after mapping
## Should load this packages
## It's for the output of cellranger v2

module load Anaconda3/2022.10
source activate /home/sb14489/.conda/envs/r_env
module load picard/2.27.5-Java-15
module load  SAMtools/1.10-GCC-8.3.0
module load BEDTools/2.29.2-GCC-8.3.0

# Parse command line arguments
## This is updated version of picard/2.27.5-Java-15! Sapelo2 keeps changing the version...
## Updtaed picard has an error in "CB:Z:TGTGTCCAGACTAATG-1" when I remove -1 the error disappear.
## "-1" came from cellranger mapping
## Howver, now they do not have an error about the "header"for bamfile

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --path)
            Path="$2"
            shift
            shift
            ;;
        --MappedDir)
            MappedDir="$2"
            shift
            shift
            ;;
        --RemoveDup)
            MappedDir="$2"
            shift
            shift
            ;;
        --OGSampleName)
            OGSampleName="$2"
            shift
            shift
            ;;
        --NewSampleName_forBam)
            NewSampleName_forBam="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
done

# Function 1: Remove Multimap
remove_multimap() {
    mkdir -p 3.SortedBam

    if [ "$RemoveDup" == "yes" ]; then
    samtools view -@ 24 -h -f 3 -q 10 "$Path"/"$MappedDir"/"$OGSampleName"/outs/possorted_bam.bam |
    grep -v -e 'XA:Z:' -e 'SA:Z:' |
    samtools view -@ 24 -bS - > "$Path"/3.SortedBam/"$NewSampleName_forBam"_Sorted.bam

    ### -v -e : exclude the lines
    # XA:Z: SA:Z:(rname ,pos ,strand ,CIGAR ,mapQ ,NM ;)+ Other canonical alignments in a chimeric alignment,
    # XA: Alternative hits; format: (chr,pos,CIGAR,NM;)*
    # SA: Z, not sure what it is but, it almost always coincides with the 256 flag = not primary alignment
    samtools view -h "$Path"/3.SortedBam/"$NewSampleName_forBam"_Sorted.bam | \
    sed 's/CB:Z:\([^-\t]*\)-1/CB:Z:\1/g' | \
    samtools view -b -o "$Path"/3.SortedBam/"$NewSampleName_forBam"_Sorted_FixedCB.bam

    else
    samtools view -@ 24 -h -f 3 "$Path"/"$MappedDir"/"$OGSampleName"/outs/possorted_bam.bam |
    samtools view -@ 24 -bS - > "$Path"/3.SortedBam/"$NewSampleName_forBam"_NotRemoveMultiMap_Sorted.bam

    samtools view -h "$Path"/3.SortedBam/"$NewSampleName_forBam"_NotRemoveMultiMap_Sorted.bam | \
    sed 's/CB:Z:\([^-\t]*\)-1/CB:Z:\1/g' | \
    samtools view -b -o "$Path"/3.SortedBam/"$NewSampleName_forBam"_Sorted_FixedCB.bam
    fi
}

# Function 2: Deduplication
deduplication() {
    cd "$Path"/3.SortedBam
    java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
        -MAX_FILE_HANDLES_FOR_READ_ENDS_MAP 1000 -MAX_RECORDS_IN_RAM 1500000 \
        -REMOVE_DUPLICATES true -METRICS_FILE "./$NewSampleName_forBam"_dups_Markingpcr.txt \
        -I "./$NewSampleName_forBam"_Sorted_FixedCB.bam \
        -O "./$NewSampleName_forBam"_Rmpcr.bam \
        -BARCODE_TAG CB \
        -ASSUME_SORT_ORDER coordinate \
        -USE_JDK_DEFLATER true
}


# Call the functions
remove_multimap
deduplication
