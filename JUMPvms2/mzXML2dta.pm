#!/usr/bin/perl -w -I /data1/pipeline/release/version12.1.0/JUMPq/
use strict;
use Utils::XMLParser;
my $mzXML = $ARGV[0];
my $scanNumber = $ARGV[1];
my $charge = $ARGV[2];
open (XML, "<", $mzXML) or die "  Cannot open $mzXML\n";
my $xml = new Utils::XMLParser();
my $indexOffset = $xml -> get_IndexOffset(*XML);
my ($indexArray, $lastScan) = $xml -> get_IndexArray(*XML, $indexOffset);
my @peaksArray;
my $index = $$indexArray[$scanNumber - 1];
$xml -> get_Peaks(*XML, \@peaksArray, $index);           
my $precursor = $xml -> get_Precursor(*XML, $index);
my @psplit = split(/\>/, $precursor);
my @psplit2 = split(/\</, $psplit[1]);
my $precursor_mz = $psplit2[0];
my $shift = $precursor_mz * $charge;
print "$shift $charge\n";
my $total = 0+@peaksArray;
for (my $i = 0; $i < $total; $i++) {
    print $peaksArray[$i] . " ";
    $i++;
    print $peaksArray[$i] . "\n";
}
#print 0+@peaksArray . "\n";
#print $precursor . "\n";

