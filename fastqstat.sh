#!/bin/sh
#PBS -l nodes=1:ppn=1
#PBS -l mem=2gb
#PBS -l walltime=100:00:00

cd $PBS_O_WORKDIR

perl fastq_stat.pl --list fastq.list --project HEG4.raw

echo "Done"
