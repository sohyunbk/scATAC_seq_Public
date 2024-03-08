## RemovemultiMap & deduplication

module load Anaconda3/2022.10
source activate /home/sb14489/.conda/envs/r_env
module load picard/2.25.1-Java-11
module load SAMtools/1.16.1-GCC-11.3.0
module load BEDTools/2.29.2-GCC-8.3.0

sh /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/Mapping_RefiningBam/RemoveMultiMap_Deduplication_PicardVersionUpdate.sh \
 --path /scratch/sb14489/3.scATAC/4.Bif3Ref_Ki3/ \
--MappedDir 2.Mapped  --OGSampleName "${OGSampleNameList[SLURM_ARRAY_TASK_ID]}" \
 --NewSampleName_forBam "${NewSampleNameList[SLURM_ARRAY_TASK_ID]}"

#FixingBarcode

module load Anaconda3/2022.10
source activate /home/sb14489/.conda/envs/ucsc
module load  SAMtools/1.10-GCC-8.3.0

~/.conda/envs/ucsc/bin/python /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/SocratesStart_QC/FixingBarcodeName.py \
 -BAM ./3.SortedBam/"${List[SLURM_ARRAY_TASK_ID]}"_Rmpcr.bam -exp_name "${List[SLURM_ARRAY_TASK_ID]}" | samtools view -@ 12 - > ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_BarcodeFixed.sam

 ~/.conda/envs/ucsc/bin/python /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/SocratesStart_QC/MakeTn5bed.py \
 -sam ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_BarcodeFixed.sam -output_file ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_Unique.bed



