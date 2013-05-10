echo "prepare fastq list for pro-process pipeline if exists a in_group file from ALLPATH_LG"
sed '{s/,/ /g}' ../soapec/in_groups.HEG4_RAW.csv | cut -d " " -f 3 > fastq.list

echo "generate shell of preprocess"
perl pre_process_fq.pl --list example/test.list

echo "run qsub or bash"
perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --lines 3 --convert no preprocess.sh
bash preprocess.sh


echo "HEG4 run"
perl pre_process_fq.pl --list fastq.list --output HEG4_clean_reads
qsub preprocess.sh

