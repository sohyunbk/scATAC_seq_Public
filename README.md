1st step:

#!/bin/bash
#SBATCH --job-name=RemoveMultiMap_Deduplication_Browserr        # Job name
#SBATCH --partition=highmem_p         # Partition (queue) name
#SBATCH --ntasks=1                    # Run a single task
#SBATCH --cpus-per-task=20             # Number of CPU cores per task
#SBATCH --mem=400gb                   # Job memory request #For normal fastq : 600gb
#SBATCH --time=50:00:00               # Time limit hrs:min:sec
#SBATCH --output=/scratch/sb14489/0.log/RemoveMultiMap_Deduplication_Browserr.%j.out   # Standard output log
#SBATCH --error=/scratch/sb14489/0.log/RemoveMultiMap_Deduplication_Browserr.%j.err    # Standard error log
#SBATCH --mail-type=BEGIN,END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --array=0-3

OGSampleNameList=(1_A619  1_A619_2  3_bif3  3_bif3_2)
NewSampleNameList=(1_A619  1_A619_2  3_bif3  3_bif3_2)

module load Anaconda3/2022.10
source activate /home/sb14489/.conda/envs/r_env
module load picard/2.25.1-Java-11
module load SAMtools/1.16.1-GCC-11.3.0
module load BEDTools/2.29.2-GCC-8.3.0

## RemovemultiMap & deduplication
sh /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/Mapping_RefiningBam/RemoveMultiMap_Deduplication_PicardVersionUpdate.sh \
 --path /scratch/sb14489/3.scATAC/4.Bif3Ref_Ki3/ \
--MappedDir 2.Mapped  --OGSampleName "${OGSampleNameList[SLURM_ARRAY_TASK_ID]}" \
 --NewSampleName_forBam "${NewSampleNameList[SLURM_ARRAY_TASK_ID]}"


2nd step:

module load Anaconda3/2022.10
source activate /home/sb14489/.conda/envs/ucsc
module load  SAMtools/1.10-GCC-8.3.0

#FixingBarcode
~/.conda/envs/ucsc/bin/python /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/SocratesStart_QC/FixingBarcodeName.py \
 -BAM ./3.SortedBam/"${List[SLURM_ARRAY_TASK_ID]}"_Rmpcr.bam -exp_name "${List[SLURM_ARRAY_TASK_ID]}" | samtools view -@ 12 - > ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_BarcodeFixed.sam

 #FixingBarcode
 ~/.conda/envs/ucsc/bin/python /home/sb14489/Epigenomics/scATAC-seq/0_CoreScript/SocratesStart_QC/MakeTn5bed.py \
 -sam ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_BarcodeFixed.sam -output_file ./4.Bam_FixingBarcode/"${List[SLURM_ARRAY_TASK_ID]}"_Unique.bed



