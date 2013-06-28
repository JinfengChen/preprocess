echo "prepare fastq list for pro-process pipeline if exists a in_group file from ALLPATH_LG"
sed '{s/,/ /g}' ../soapec/in_groups.HEG4_RAW.csv | cut -d " " -f 3 > HEG4.raw.fastq.list

echo "generate shell of preprocess"
perl pre_process_fq.pl --list example/test.list

echo "run qsub or bash"
perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --lines 6 --convert no preprocess.sh
bash preprocess.sh


echo "HEG4 run"
perl pre_process_fq.pl --list HEG4.raw.fastq.list --output HEG4_clean_reads
qsub preprocess.sh
perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --lines 6 --convert no 1.preprocess.sh

perl pre_process_fq_large.pl --list HEG4.raw.fastq.large.list --output HEG4_clean_reads > log 2> log2 

echo "rc mating lib"
perl fastq_rc.pl --list HEG4.clean.fastq.rc.list
qsub 1.rc.sh

echo "stat fastq"
qsub fastqstat.sh

find /rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/HEG4_clean_reads/*.clean.fq.gz > HEG4.clean.fastq.list

echo "EG4"
perl pre_process_fq_large.pl --list EG4.raw.fastq.list --output EG4_clean_reads > log 2> log2 &
find /rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/EG4_clean_reads/*.clean.fq.gz > EG4.clean.fastq.list
##modify to EG4.clean.fastq.list to add insert size
perl list2csv.pl --list EG4.clean.fastq.list --sample EG4 --project EG4_CLEAN

echo "A123"
perl pre_process_fq_large.pl --list A123.raw.fastq.list --output A123_clean_reads > log 2> log2 &

echo "A119"
perl pre_process_fq_large.pl --list A119.raw.fastq.list --output A119_clean_reads > log 2> log2 &


