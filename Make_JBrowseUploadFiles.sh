#!/bin/bash

### This script has the whole functions for whatever input like bam or bdg or bed
### It should load "ml Anaconda3/2020.02" "source activate /home/sb14489/.conda/envs/Jbrowse"
#ml Anaconda3/2020.02
#source activate /home/sb14489/.conda/envs/Jbrowse

: '
ml Anaconda3/2020.02
source activate /home/sb14489/.conda/envs/Jbrowse

module load SAMtools/1.16.1-GCC-11.3.0
module load BEDTools/2.30.0-GCC-12.2.0


Make JBrowseUpload File.\
    1: From bdg file to bw file: \
        bash /home/sb14489/Epigenomics/Jbrowse/Make_JBrowseUploadFiles.sh \
        -Step bdgTobw -bdgFile {Path+Name} -Fai {chrFai} -OutputName {Path+NamePreFix} \
    2: bash /home/sb14489/Epigenomics/Jbrowse/Make_JBrowseUploadFiles.sh     \
      -Step BedToTrack -bed /scratch/sb14489/3.scATAC/0.Data/MarkerGene/CLV3_ZmCLE7_MaizeV5.bed \
      -OutputName CLV3_ZmCLE7_MaizeV5
    3: bash /home/sb14489/Epigenomics/Jbrowse/Make_JBrowseUploadFiles.sh \
     -readlength 151 -sam Final_Bif3Ref_AddedSeqInfo_Overlapped.txt  \
     -OutputName Final_Bif3Ref_AddedSeqInfo_Overlapped.bed -Step SamToBed
     4:
     source activate /home/sb14489/.conda/envs/ucsc
     module load SAMtools/1.10-iccifort-2019.5.281
     module load BEDTools/2.29.2-GCC-8.3.0
     bash /home/sb14489/Epigenomics/Jbrowse/Make_JBrowseUploadFiles.sh -Step BamTobw  \
      -Fai /scratch/sb14489/0.Reference/TAIR10/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.fai \
       -bam /scratch/sb14489/7.DAPorChIP/CHIPseq_Ara_WUS/2.Mapped/SRR8192661_unique_bowtie2_algn.bam
'

function from_bdgfile_to_bwfile() {
    local BdgFile=$1
    local OutFileName=$2
    local Fai=$3

    awk '{print $1"\t"$2}' ${Fai} > ${Fai}_length.txt
    # Filter the BED file
    awk -v lengthFile="${Fai}_length.txt" \
     'BEGIN{while(getline k < lengthFile){split(k,a); len[a[1]]=a[2];}} {if($3 <= len[$1]) print $0;}' \
     ${BdgFile} > ${BdgFile}.RemoveLinesOutofRange

    Cmd_sort="bedSort ${BdgFile}.RemoveLinesOutofRange ${BdgFile}_Sorted"
    Cmd="bedGraphToBigWig ${BdgFile}_Sorted ${Fai} ${OutFileName}.bw"

    $Cmd_sort
    $Cmd
}

function from_bedfile_to_dirforTrack() {
    local BedFile=$1
    local OutFileName=$2
    local Path=$(dirname $OutFileName)
    local Prefix=$(basename $OutFileName)

    Cmd="/home/sb14489/jbrowse/bin/flatfile-to-json.pl --bed ${BedFile} --trackLabel ${Prefix} --out ${Path}"
    $Cmd
}

function make_bed_from_samfile() {
    local Samfile=$1
    local ReadLength=$2
    local OutFileName=$3

    Outfile=$OutFileName
    Infile=$Samfile

    while IFS=$'\t' read -r -a List; do
        nFragment=${List[8]}
        nFragment=${nFragment/#-/}
        if (( nFragment < ReadLength )); then
            nlength=$nFragment
        else
            nlength=$ReadLength
        fi
        nStart=${List[3]}
        sChr=${List[2]}
        echo -e "$sChr\t$nStart\t$((nStart + nlength))" >> $Outfile
    done < $Infile
}

function from_bam_to_bwfile() {
    local Bamfile=$1
    local Fai=$2
    if [[ ! -f "$Bamfile.bai" ]]; then
      samtools index -@ 24 "$Bamfile"
    fi
    python /home/bth29393/jbscripts/file_to_bigwig_pe.py $Fai $Bamfile
    BedName="${Bamfile%.bam}.bed"
    bedtools bamtobed -i $Bamfile > $BedName
    bedtools genomecov -i "$BedName" -split -bg -g "$Fai"  > "${Bamfile%.bam}.bg"
    wigToBigWig "${Bamfile%.bam}.bg" "$Fai"  "${Bamfile%.bam}.bw"
}

# Parse command-line arguments

while [[ $# -gt 0 ]]; do
    case $1 in
        -Step) Step="$2"; shift ;;
        -OutputName) OutputName="$2"; shift ;;
        -bdgFile) BdgFile="$2"; shift ;;
        -Fai) Fai="$2"; shift ;;
        -bed) BedFile="$2"; shift ;;
        -sam) Samfile="$2"; shift ;;
        -bam) Bamfile="$2"; shift ;;
        -readlength) ReadLength="$2"; shift ;;
        *) echo "Invalid option: $1" >&2 ;;
    esac
    shift
done

# Function calls based on Step

if [[ $Step == "bdgTobw" ]]; then
    from_bdgfile_to_bwfile "${BdgFile:-}" "${OutputName:-}" "${Fai:-}"
elif [[ $Step == "BedToTrack" ]]; then
    from_bedfile_to_dirforTrack "${BedFile:-}" "${OutputName:-}"
elif [[ $Step == "SamToBed" ]]; then
    make_bed_from_samfile "${Samfile:-}" "${ReadLength:-}" "${OutputName:-}"
elif [[ $Step == "BamTobw" ]]; then
    from_bam_to_bwfile "${Bamfile:-}" "${Fai:-}"
fi


#bash script.sh -Step <Step> -OutputName <OutputName> -bdgFile <BdgFile> -Fai <Fai> -bed <BedFile> -sam <Samfile> -bam <Bamfile> -readlength <ReadLength>
