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

foreach my $file (keys %$fqlist){
           print "$file\n";
           my $cat = $file=~/gz$/ ? "zcat" : "cat";
           my $fqhead= $1 if ($file=~/(.*)\.f.*q\.gz$/ or $file=~/(.*)\.f.*q$/);
           my $fq1=$file;
           my $fq2=$file;
           my $fh1=$fqhead."."."rc.fq";
           my $fh2=$fqhead."."."rc.fq";
           $fq1=~s/\?/1/;
           $fq2=~s/\?/2/;
           $fh1=~s/\?/1/;
           $fh2=~s/\?/2/;
           print "$fq1\n$fq2\n$fh1\n$fh2\n";
           #`$cat $fq1 | perl -e'while(<>){$h1 = $_;$s = <>;$h2 = <>;$q = <>;chomp $s;chomp $q;$s = reverse $s;$s =~ tr/ATCGNatcgn/TAGCNtagcn/;$q = reverse $q;print $h1.$s."\n".$h2.$q."\n";}' > $fh1`;
           #`gzip $fh1`;
           #`$cat $fq2 | perl -e'while(<>){$h1 = $_;$s = <>;$h2 = <>;$q = <>;chomp $s;chomp $q;$s = reverse $s;$s =~ tr/ATCGNatcgn/TAGCNtagcn/;$q = reverse $q;print $h1.$s."\n".$h2.$q."\n";}' > $fh2`;
           #`gzip $fh2`;
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
 
