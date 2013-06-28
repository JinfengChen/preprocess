#!/usr/bin/perl
use Getopt::Long;
use File::Basename;
use Data::Dumper;
use FindBin qw($Bin);


GetOptions (\%opt,"list:s","sample:s","project:s","help");


my $help=<<USAGE;
perl $0 --list EG4.clean.fastq.list --sample EG4 --project EG4_CLEAN
Generate in_group and in_libs file for ALLPATH_LG and RunMapping from fastq.list.
Need to modify the content after run this scripts.
--list: file	[librarysize insertsize sd]
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/EG4_clean_reads/EG4_3_p?.clean.fq.gz  [200] [180] [26]
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/EG4_clean_reads/EG4_4_p?.clean.fq.gz  [200] [180] [26]
/rhome/cjinfeng/HEG4_cjinfeng/fastq/errorcorrection/trim/EG4_clean_reads/FC124_1_?.clean.fq.gz [200] [180] [26]

output:
in_lib.HEG4_RAW.clean.csv

in_group.HEG4_RAW.clean.csv
group_name,library_name,file_name
USAGE


if ($opt{help} or keys %opt < 1){
    print "$help\n";
    exit();
}

$opt{project} ||= "HEG4";
$opt{sample} ||=$opt{project};

readtable($opt{list},$opt{sample},$opt{project});

sub readtable
{
my ($file,$sample,$title)=@_;
my %hash;
my %count;
open OUT, ">in_groups.$opt{project}.csv" or die "$!";
print OUT "group_name,library_name,file_name\n";
open IN, "$file" or die "$!";
while(<IN>){
    chomp $_;
    next if ($_=~/^$/);
    my @unit=split("\t",$_);
    $count{$unit[1]}++;
    my $group= $unit[1] ? "frag_$unit[1]_P$count{$unit[1]}" : "frag_200_P$count{$unit[1]}";
    my $lib  = $unit[1] ? "illumina_$unit[1]" : "illumina_200";
    print OUT "$group,$lib,$unit[0]\n";
    $hash{$lib}=$unit[1] ? [$unit[1],$unit[2],$unit[3]] : [200,200,0];
}
close IN;
close OUT;
open OUT1, ">in_libs.$opt{project}.csv" or die "$!";
print OUT1 "library_name,project_name,organism_name,type,paired,frag_size,frag_stddev,insert_size,insert_stddev,read_orientation,genomic_start,genomic_end\n";
if (keys %hash == 1){ ## insert size not specified
   print OUT1 "illumina_200,$title,$sample,fragment,1,216,47,,,inward,0,0\n";
   print OUT1 "illumina_500,$title,$sample,jumping,1,,,433,27,inward,0,0\n";
   print OUT1 "illumina_3k,$title,$sample,jumping,1,,,2570,550,outward,0,0\n";
}else{ ## insert size specified
   foreach my $l(sort keys %hash){
      my $type= $hash{$l}->[0] == 200 ? "fragment" : "jumping";
      my $direct= $hash{$l}->[0] >= 2000 ? "outward" : "inward";
      my $insert= $type eq "fragment" ? "$hash{$l}->[1],$hash{$l}->[2],," : ",,$hash{$l}->[1],$hash{$l}->[2]"; 
      print OUT1 "$l,$title,$sample,$type,1,$insert,$direct,0,0\n";
   }
}
close OUT1;
}
 
