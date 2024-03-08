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



