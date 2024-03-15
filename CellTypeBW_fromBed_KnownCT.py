import argparse
import sys
import os, glob
import pybedtools ##
import pandas as pd
import numpy
from multiprocessing import Pool, Manager
import multiprocessing
from functools import partial
import subprocess
import copy
import errno
import datetime
import random
import string
from subprocess import PIPE


## This script is only for the genome browser not for the peak calling !
def get_parser():
    parser = argparse.ArgumentParser(
        description="Call Peaks for scATAC data. \
    Requires cluster annnotations, as well as BED file ipput."
    )
    parser.add_argument(
        "-BedFile",
        "--BedFile",
        help="BedFile",
        required=True,
        dest="bed",
    )
    parser.add_argument(
        "-MetaFile",
        "--MetaFile",
        help="MetaFile",
        required=True,
        dest="m",
    )
    parser.add_argument(
        "-Outfile",
        "--Outfile",
        help="Outfile",
        required=True,
        dest="Outfile",
    )
    parser.add_argument(
        "-Fai",
        "--Fai",
        help="Fai",
        required=True,
        dest="fai",
    )
    parser.add_argument(
        "-Thread",
        "--Thread",
        help="Thread",
        required=True,
        dest="cores",
    )
    args = vars(parser.parse_args())
    return parser

### 1) First get bed file  by cell type
def process_bed_by_celltype(meta_file, bed_file, output_file_base):
    """
    Processes a BED file and writes separate BED files for each cell type.

    :param meta_file: Path to the metadata file.
    :param bed_file: Path to the BED file.
    :param output_file_base: Base path for the output files.
    """
    # Read metadata file and create a dictionary mapping barcodes to cell types
    list = []
    with open(meta_file, "r") as infile:
        infile.readline()  # Skip header
        dic = {}
        for sLine in infile:
            sList = sLine.strip().split("\t")
            cell_type = sList[-1]
            barcode = sList[0]
            dic[barcode] = cell_type

    # Process BED file and group data by cell type
    all_dic = {}
    with open(bed_file, "r") as tn5_bed_file:
        for sLine in tn5_bed_file:
            sList = sLine.strip().split("\t")
            if sList[3] in dic:
                assigned_cell = dic[sList[3]]
                all_dic.setdefault(assigned_cell, []).append(sLine)

    # Write output BED files for each cell type
    for cell_type in all_dic:
        with open(f"{output_file_base}_{cell_type}.bed", "w") as outfile:
            list.append(f"{output_file_base}_{cell_type}.bed")
            for sNewLine in all_dic[cell_type]:
                outfile.write(sNewLine)

    return(list)


## 2) Run Macs2
def check_files_exist(meta_file, output_file_base):
    """
    Check if the output BED files for each cell type already exist.

    :param meta_file: Path to the metadata file.
    :param output_file_base: Base path for the expected output files.
    :returns: A tuple (all_files_exist, list_of_files)
    """
    list_of_files = []
    all_files_exist = True
    with open(meta_file, "r") as infile:
        infile.readline()  # Skip header
        cell_types = set()
        for sLine in infile:
            cell_type = sLine.strip().split("\t")[-1]
            cell_types.add(cell_type)

    for cell_type in cell_types:
        expected_file = f"{output_file_base}_{cell_type}.bed"
        list_of_files.append(expected_file)
        if not os.path.exists(expected_file):
            all_files_exist = False

    return all_files_exist, list_of_files


def run_macs2_threaded(bed_files, output_directory, cores):
    with Pool(int(cores)) as pool:
            pool.map(
                partial(sub_func_macs2, output_dir=output_directory),
                bed_files,
            )


def sub_func_macs2(bed_file, output_dir):
    output_file_name = bed_file.split("/")[-1].replace(".bed", ".macs")
    final_output_dir_name = output_dir if output_dir else "."

    generate_macs2_command = f"macs2 callpeak -t {bed_file} -f BED --nomodel \
    --keep-dup all --extsize 150 --shift -50 --qvalue .05 --outdir {final_output_dir_name} --bdg \
    -n {output_file_name}"

    print(f"Running MACS2 Command: {generate_macs2_command}")
    subprocess.run(generate_macs2_command, shell=True, check=True)
    print("Done Running MACS2 Calls")

## Normalizztion
def Normaliztion_bdg(FaiFile,Dir):
    Fai = {}
    TotalReadDic = {}
    infile = open(FaiFile,"r")
    for sLine in infile:
        Fai[sLine.split("\t")[0]] = int(sLine.split("\t")[1])
    for bdgFiles in glob.glob(Dir+"/*_treat_pileup.bdg"):
        TotalBed = open(bdgFiles,"r")
        Length = len(TotalBed.readlines())
        #print(Length)
        TotalReadDic[bdgFiles] = Length
        TotalBed.close()
    for Files in TotalReadDic.keys():
        infile = open(Files,"r")
        outfile = open(Files.replace(".bdg","_CPM.bdg"),"w")
        for sLine in infile:
            sList = sLine.strip().split("\t")
            if int(sList[2]) < Fai[sList[0]]:
                nAbundance = float(sList[3])
                Normalized = (nAbundance/int(TotalReadDic[Files]))*1000000
                outfile.write("\t".join(sList[0:3])+"\t"+str(Normalized)+"\n")
        infile.close()
        outfile.close()

if __name__ == "__main__":
    args = get_parser().parse_args()
    BedFile = args.bed
    MetaFile = args.m
    Outfile = args.Outfile
    ## 1) Make bed files
    # Check if the bed files for each cell type already exist
    files_exist, bed_files = check_files_exist(MetaFile, Outfile)

    if not files_exist:
        # Generate bed files if they don't exist
        bed_files = process_bed_by_celltype(MetaFile, BedFile, Outfile)
    print(bed_files)
    # 2) Run Macs2
    run_macs2_threaded(bed_files, Outfile, args.cores)

    ## 3) Normalize bdg
    Normaliztion_bdg(args.fai,args.Outfile)
    print("Done Normaliztion")
