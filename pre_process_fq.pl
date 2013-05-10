#!/usr/bin/perl
use Getopt::Long;
use File::Basename;
use FindBin qw ($Bin);

GetOptions (\%opt,"list:s","output:s","help");


my $help=<<USAGE;
perl $0 --list fastq.list --output HEG4_clean
Do vector trim and quality trim for Pair-end reads. Check before run: 1. full path of file name in list
--list: fastq list file, where 1 and 2 are indicated by ?. So we can convert in this scripts. (USE full path for files!!!!!!)
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/soapec/HEG4_0_500bp/FC52_7_?.fq
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/soapec/HEG4_0_500bp/FC52_8_?.fq
--output: output dir name for clean fastq

Run shell (Use less memory, so it is easy to run):
No need to convert path and use 3 lines
perl /rhome/cjinfeng/software/bin/qsub-pbs.pl --lines 3 --convert no preprocess.sh
or 
qsub preprocess.sh
USAGE

if ($opt{help} or keys %opt < 1){
    print "$help\n";
    exit();
}

$opt{output} ||= "fq_clean";
$opt{output} ="$Bin/$opt{output}";

my $Trimmomatic="/rhome/cjinfeng/software/tools/Trimmomatic-0.30";
my $adaptor="/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/adaptor.fa";
my $trim="/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/trim.pl";
my $minlen=50;  ## min length shorter than 50, so both reads will be removed
my $minqual=20; 

`mkdir $opt{output}` unless (-d $opt{output});

my $fqlist=readlist($opt{list});


open OUT, ">preprocess.sh" or die "$!";
foreach my $file (keys %$fqlist){
        print "$file\n";
        my $fqhead= $file=~/fastq$/ ? basename($file,".fastq") : basename($file,".fq");
        my $fq1=$file; my $fq2=$file;
        $fq1=~s/\?/1/;
        $fq2=~s/\?/2/;
        my $fq1head= $fq1=~/fastq$/ ? basename($fq1,".fastq") : basename($fq1,".fq");
        my $fq2head= $fq2=~/fastq$/ ? basename($fq2,".fastq") : basename($fq2,".fq");
        print "$fq1\n$fq2\n$fq1head\n$fq2head\n"; 
        my $trimvector="java -classpath $Trimmomatic/trimmomatic-0.30.jar org.usadellab.trimmomatic.TrimmomaticPE -phred33 -trimlog $opt{output}/$fqhead.log $fq1 $fq2 $opt{output}/$fq1head.trim.fq $opt{output}/$fq1head.trim.unpaired.fq $opt{output}/$fq2head.trim.fq $opt{output}/$fq2head.trim.unpaired.fq LEADING:0 TRAILING:0 ILLUMINACLIP:$adaptor:2:40:15 SLIDINGWINDOW:4:15 MINLEN:$minlen";
        my $trimqual  ="perl $trim --type 1 --qual-threshold $minqual --length-threshold $minlen --pair1 $opt{output}/$fq1head.trim.fq  --pair2 $opt{output}/$fq2head.trim.fq --outpair1 $opt{output}/$fq1head.clean.fq  --outpair2 $opt{output}/$fq2head.clean.fq  --single $opt{output}/$fqhead.clean.single.fq";       
        my $clean     ="rm $opt{output}/$fq1head.trim.unpaired.fq $opt{output}/$fq2head.trim.unpaired.fq $opt{output}/$fq1head.trim.fq $opt{output}/$fq2head.trim.fq";
        print OUT "$trimvector\n$trimqual\n$clean\n";
}
close OUT;

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
 
