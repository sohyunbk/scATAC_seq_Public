## RemovemultiMap & deduplication



sh /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/Mapping_RefiningBam/RemoveMultiMap_Deduplication_PicardVersionUpdate.sh \
 --path /scratch/sb14489/3.scATAC/4.Bif3Ref_Ki3/ \
--MappedDir 2.Mapped  --OGSampleName "${OGSampleNameList[SLURM_ARRAY_TASK_ID]}" \
 --NewSampleName_forBam "${NewSampleNameList[SLURM_ARRAY_TASK_ID]}"

## FixingBarcode


~/.conda/envs/ucsc/bin/python /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/SocratesStart_QC/FixingBarcodeName.py \
 -BAM ./3.SortedBam/"${List[SLURM_ARRAY_TASK_ID]}"_Rmpcr.bam -exp_name "${List[SLURM_ARRAY_TASK_ID]}" | samtools view -@ 12 - > ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_BarcodeFixed.sam

 ~/.conda/envs/ucsc/bin/python /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/SocratesStart_QC/MakeTn5bed.py \
 -sam ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_BarcodeFixed.sam -output_file ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_Unique.bed



## Bulkupload - GenomeBrowser
module load Anaconda3/2022.10
source activate /home/sb14489/.conda/envs/ucsc
module load SAMtools/1.16.1-GCC-11.3.0
module load BEDTools/2.29.2-GCC-8.3.0

bash /home/sb14489/Epigenomics/Jbrowse/Make_JBrowseUploadFiles.sh -Step BamTobw  \
 -Fai /scratch/sb14489/0.Reference/Maize_Ki3/Zm-Ki3-REFERENCE-NAM-1.0.fa.fai \
  -bam /scratch/sb14489/3.scATAC/4.Bif3Ref_Ki3/3.SortedBam/"${NewSampleNameList[SLURM_ARRAY_TASK_ID]}"_Rmpcr.bam

## By Cluster Upload 
 ~/.conda/envs/r_env/bin/python /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/PeakCalling_byCellTypes/CellTypeBW_fromBed_KnownCT.py \
 -BedFile /scratch/sb14489/3.scATAC/4.Bif3Ref_Ki3/4.Bam_FixingBarcode/"${BedList[SLURM_ARRAY_TASK_ID]}" \
 -Outfile /scratch/sb14489/3.scATAC/4.Bif3Ref_Ki3/5.Jbrowse_MACS2/"${OutFileList[SLURM_ARRAY_TASK_ID]}" \
 -MetaFile /scratch/sb14489/3.scATAC/2.Maize_ear/6.Annotation/0.AnnotatedMeta/"${MetaData[SLURM_ARRAY_TASK_ID]}" \
 --Thread 10 --Fai /scratch/sb14489/0.Reference/Maize_Ki3/Zm-Ki3-REFERENCE-NAM-1.0_OnlyChr_Bif3.fa.fai
