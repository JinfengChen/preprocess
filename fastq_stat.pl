#!/usr/bin/perl
use Getopt::Long;
use File::Basename;
use FindBin qw ($Bin);

GetOptions (\%opt,"list:s","project:s","help");


my $help=<<USAGE;
perl $0 --list fastq.list
--list: fastq list file, where 1 and 2 are indicated by ?. So we can convert in this scripts. (USE full path for files!!!!!!)
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/soapec/HEG4_0_500bp/FC52_7_?.fq
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/soapec/HEG4_0_500bp/FC52_8_?.fq

USAGE

if ($opt{help} or keys %opt < 1){
    print "$help\n";
    exit();
}

$opt{project} ||= "1";

my $fqlist=readlist($opt{list});


open OUT, ">$opt{project}.fastq.stat" or die "$!";
print OUT "Sample\t#Read\tAverage\tTotal\tDepth\n";
foreach my $file (keys %$fqlist){
        print "$file\n";
        if ($file=~/gz$/){
           my $fqhead= $1 if $file=~/(.*)\.f.*q.gz$/;
           my $name  = basename($fqhead);
           $fqhead=~s/\?/\*/;
           $fqhead.=".*";
           print "$fqhead\n";
           my $cmd=`ls $fqhead | xargs zcat | awk '{if(NR%4==2){num++;len+=length($1)}}END{print num"\t"len/num"\t"len"\t"len/372000000}'`;
           chomp $cmd;
           my @sum=split("\t",$cmd);
           print OUT "$name\t$cmd\n";
        }else{
           my $fqhead= $1 if $file=~/(.*)\.f.*q$/;
           my $name  = basename($fqhead);
           $fqhead=~s/\?/\*/;
           $fqhead.=".*";
           my $cmd=`ls $fqhead | xargs cat | awk '{if(NR%4==2){num++;len+=length($1)}}END{print num"\t"len/num"\t"len"\t"len/372000000}'`; 
           chomp $cmd;
           my @sum=split("\t",$cmd);
           print OUT "$name\t$cmd\n";
        }
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
 
