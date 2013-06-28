#!/usr/bin/perl
use Getopt::Long;
use File::Basename;
use FindBin qw ($Bin);

GetOptions (\%opt,"list:s","output:s","project:s","help");


my $help=<<USAGE;
perl $0 --list fastq.list --output HEG4_clean
Do vector trim and quality trim for Pair-end reads. Check before run: 1. full path of file name in list
--list: fastq list file, where 1 and 2 are indicated by ?. So we can convert in this scripts. (USE full path for files!!!!!!)
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/soapec/HEG4_0_500bp/FC52_7_?.fq
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/soapec/HEG4_0_500bp/FC52_8_?.fq
--output: output dir name for clean fastq

Run shell (Use less memory, so it is easy to run/ but java sometimes make errors, need to split large fq files and check the work0001.sh.e* if killed, files are similar in size of 15829:adapter_all.fa or 9961:adaper.fa):
USAGE

if ($opt{help} or keys %opt < 1){
    print "$help\n";
    exit();
}

$opt{output} ||= "fq_clean";
$opt{output} ="$Bin/$opt{output}";
$opt{project} ||= "1";

my $Trimmomatic="/rhome/cjinfeng/software/tools/Trimmomatic-0.30";
my $adaptor="/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/adaptor.fa";
my $trim="/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/trim.pl";
my $fqsplit="/rhome/cjinfeng/software/bin/fastq_split.pl";
my $minlen=50;  ## min length shorter than 50, so both reads will be removed
my $minqual=20; 

`mkdir $opt{output}` unless (-d $opt{output});

my $fqlist=readlist($opt{list});


foreach my $file (keys %$fqlist){
        print "$file\n";
        my $fqhead= $file=~/fastq$/ ? basename($file,".fastq") : basename($file,".fq");
        #$fqhead=~s/\?/O/;
        my $fq1=$file; my $fq2=$file;
        $fq1=~s/\?/1/;
        $fq2=~s/\?/2/;
        my $fq1head= $fq1=~/fastq$/ ? basename($fq1,".fastq") : basename($fq1,".fq");
        my $fq2head= $fq2=~/fastq$/ ? basename($fq2,".fastq") : basename($fq2,".fq");
        print "$fq1\n$fq2\n$fq1head\n$fq2head\n$fqhead\n";
        ### split into small files
        my @split;
        push @split, "perl $fqsplit -s 500000 -o $opt{output}/$fqhead $fq1";
        push @split, "perl $fqsplit -s 500000 -o $opt{output}/$fqhead $fq2";
        my $cmd=join("\n",@split);
        writefile("$fqhead.split.sh","$cmd\n");
        `perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --interval 120 $fqhead.split.sh`;

        ### clean small files
        my @fq=glob("$opt{output}/$fqhead/*.f*q");
        my @fqs=sort @fq;
        my @clean;
        for(my $i=0; $i<@fqs; $i+=2){
           print "$i\t$fqs[$i]\n";
           #my $prefix=substr(basename($fqs[$i]),0,3);
           my $temp=basename($fqs[$i]);
           my $prefix=$1 if ($temp=~/^(p\d+)\./);
           my $trimvector="java -Xmx2G -Xms512M -classpath $Trimmomatic/trimmomatic-0.30.jar org.usadellab.trimmomatic.TrimmomaticPE -phred33 -trimlog $opt{output}/$fqhead/$prefix.$fqhead.log $fqs[$i] $fqs[$i+1] $fqs[$i].trim.fq $fqs[$i].trim.unpaired.fq $fqs[$i+1].trim.fq $fqs[$i+1].trim.unpaired.fq LEADING:0 TRAILING:0 ILLUMINACLIP:$adaptor:2:40:15 MINLEN:$minlen";
           my $trimqual  ="perl $trim --type 1 --qual-threshold $minqual --length-threshold $minlen --pair1 $fqs[$i].trim.fq  --pair2 $fqs[$i+1].trim.fq --outpair1 $fqs[$i].clean.fq  --outpair2 $fqs[$i+1].clean.fq  --single $opt{output}/$fqhead/$prefix.$fqhead.clean.single.fq";
           push (@clean,$trimvector);
           push (@clean,$trimqual);
        }
        my $cmd1=join("\n",@clean);
        writefile("$fqhead.clean.sh","$cmd1\n");
        `perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --maxjob 5 --lines 2 --interval 120 --resource walltime=100:00:00 --convert no $fqhead.clean.sh`;
        
        ### merge and files
        my @merge;
        my $mergefq1="cat $opt{output}/$fqhead/p*.$fq1head.fq.clean.fq > $opt{output}/$fq1head.clean.fq";
        my $mergefq2="cat $opt{output}/$fqhead/p*.$fq2head.fq.clean.fq > $opt{output}/$fq2head.clean.fq";
        my $mergefq ="cat $opt{output}/$fqhead/p*.$fqhead.clean.single.fq > $opt{output}/$fqhead.clean.single.fq";
        my $gz      ="gzip $opt{output}/$fq1head.clean.fq;gzip $opt{output}/$fq2head.clean.fq;gzip $opt{output}/$fqhead.clean.single.fq";
        push (@merge,$mergefq1);
        push (@merge,$mergefq2);
        push (@merge,$mergefq);
        push (@merge,$gz);
        my $cmd2=join("\n",@merge);
        writefile("$fqhead.merge.sh","$cmd2\n");
        `perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --lines 4 --interval 120 $fqhead.merge.sh`;

        ### clear tmp files
        my @clear;
        my $rm="rm -Rf $opt{output}/$fqhead";
        my $rm2="rm -Rf $fqhead.merge.sh* $fqhead.clean.sh* $fqhead.split.sh*";
        push @clear, $rm;
        push @clear, $rm2;
        my $cmd3=join("\n",@clear);
        writefile("$fqhead.clear.sh","$cmd3\n");
}

#################

sub readlist
{
my ($file)=@_;
my %hash;
open IN, "$file" or die "$!";
while(<IN>){
    chomp $_;
    next if ($_=~/^$/);
    my @unit=split("\t",$_);
    $hash{$unit[0]}=1;
}
close IN;
return \%hash;
}
 
sub writefile
{
my ($file,$line)=@_;
open WR, ">$file" or die "$!";
     print WR "$line";
close WR;
}


