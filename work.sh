echo "prepare fastq list for pro-process pipeline if exists a in_group file from ALLPATH_LG"
sed '{s/,/ /g}' ../soapec/in_groups.HEG4_RAW.csv | cut -d " " -f 3 > fastq.list

echo "generate shell of preprocess"
perl pre_process_fq.pl --list example/test.list

echo "run qsub or bash"
perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --lines 6 --convert no preprocess.sh
bash preprocess.sh


echo "HEG4 run"
perl pre_process_fq.pl --list fastq.list --output HEG4_clean_reads
qsub preprocess.sh
perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --lines 6 --convert no 1.preprocess.sh

perl pre_process_fq_large.pl --list fastq.large.list --output HEG4_clean_reads > log 2> log2 



echo "stat fastq"
qsub fastqstat.sh

