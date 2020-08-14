#!/usr/bin/perl

################################################################
##                                                              #
##       **************************************************     #
##       ****                                          ****     #
##       ****  jump vms2 (validate MS2 matching)       ****     #
##       ****  by Timothy I Shaw
##       ****  Version 12.1.0                          ****     #
##       ****  Copyright (C) 2012 - 2015               ****     #
##       ****  All rights reserved                     ****     #
##       ****                                          ****     #
##       **************************************************     #
##                                                              #
#################################################################


use Getopt::Long;
use File::Spec;
use File::Basename;
use Cwd;
#my $dir = dirname(File::Spec->rel2abs(__FILE__));

my $dir = cwd();
#print $dir . "\n";
my ($help,$parameter);
GetOptions('-help|h'=>\$help,
			'-p=s'=>\$parameter,
		);

if(!defined($parameter))
{
	help();
}

my $datestring = localtime();

print "\n*** JUMPvms2 initialized $datestring ***\n\n";
print "Step 0. Reading parameter file...\n";		
# The ini file needs to be set for each installation
my $ini_file = "/home/tshaw/Software/JUMPvms2/JUMPvms2.ini";
my $ini_params = parse_param($ini_file);
my $params=parse_param($parameter);
my $OutputFolder = $params->{output_directory};
my $TMT_FLAG = $params->{tmt_tag};
# print "Finish reading parameter file\n";
if (-e $OutputFolder) {
        print "Output directory exist already.  Are you sure you want to override existing result (Y/N)?\n";
	my $input = <STDIN>;
	chomp $input;
	if ($input eq "Y" or $input eq "y" or $input eq "Yes" or $input eq "YES" or $input eq "yes") {
		print "Continuing...\n";
	} else {
        	exit;  
	}
}

# Generate the intermediate folder
my $INTERMEDIATE_FOLDER = $OutputFolder . "/" . $ini_params->{INTERMEDIATE_FOLDER}; 
my $PUBLICATION_FOLDER = $OutputFolder . "/" . $ini_params->{PUBLICATION_FOLDER};
my $DTA_FOLDER = $INTERMEDIATE_FOLDER . "/" . $ini_params->{DTA_FOLDER};
my $OUTPUT_IMG = $INTERMEDIATE_FOLDER . "/" . $ini_params->{OUTPUT_IMG};
my $OUTPUT_CSV = $INTERMEDIATE_FOLDER . "/" . $ini_params->{OUTPUT_CSV};
my $OUTPUT_HTML = $INTERMEDIATE_FOLDER . "/" . $ini_params->{OUTPUT_HTML};
my $OUTPUT_LOG = $INTERMEDIATE_FOLDER . "/" . $ini_params->{OUTPUT_LOG};
my $OUTPUT_DOCX = $PUBLICATION_FOLDER . "/" . $ini_params->{OUTPUT_DOCX};
my $PSM_LIST_OUTPUT = $INTERMEDIATE_FOLDER . "/" . $ini_params->{PSM_LIST};
my $mzXML2dta = $ini_params->{mzXML2dta};
my $drppm = $ini_params->{DRPPM};
print "\n*** Generate directory if not exist ***\n";
if (-e $OutputFolder) {

} else {
  system("mkdir $OutputFolder");
}
if (-e $INTERMEDIATE_FOLDER) {

} else {
  system("mkdir $INTERMEDIATE_FOLDER");
}
if (-e $PUBLICATION_FOLDER) {

} else {
  system("mkdir $PUBLICATION_FOLDER");
}
if (-e $DTA_FOLDER) {

} else {
  system("mkdir $DTA_FOLDER");
}

if (-e $OUTPUT_IMG) {

} else {
  system("mkdir $OUTPUT_IMG");
}

if (-e $OUTPUT_CSV) {

} else {
  system("mkdir $OUTPUT_CSV");
}
if (-e $OUTPUT_HTML) {

} else {
  system("mkdir $OUTPUT_HTML");
}

# log file that keeps track of the progress of the program
my $LOGFILE = $OutputFolder . "/" . $ini_params->{LOGFILE};
open(LOG, ">", $LOGFILE);

$datestring = localtime();
print LOG "Execution Start: $datestring\n";

# The output file presumably containing the word file

my $idtxt = $params->{input_idtxt_file};
my $ipaddress = $params->{server_ipaddress};

if(!defined($idtxt))
{
	print "please input info for input_idtxt_file in the parameter file\n";
	exit;
}

my $jump_folder = $params->{input_jump_folder};
if(!defined($jump_folder))
{
	print "please input info for input_jump_folder in the parameter file\n";
	exit;
}

my $idtxtHash = GenerateHash($idtxt);

print "\nStep 1. Iterate through the PSM list...\n";
print "\nStep 2. Convert mzXML to DTA file...\n";
open(my $PSMOUT, '>', $PSM_LIST_OUTPUT) or die "Could not open file '$PSM_LIST_OUTPUT' $!";
## Iterate through each peptide
foreach $key (keys %$params)
{
	#print $key . "\n";
	if($key =~/peptide_/)
	{
		# Look through the IDmod to find the peptide				
		my $peptide = $params->{$key};
		$peptide =~ s/\*/\#/g;

		print LOG "Reading peptide: (" . $peptide . ")\n";	
		my $paths = $idtxtHash{$peptide};	
		foreach $path (keys %$paths) {
			my $protein_name = $idtxtHash{$peptide}{$path};
			my @split = split(/\//,$path);
			my $keyterm = $split[@split - 1];
			my $folder1 = $split[@split - 2];
			my $folder2 = $split[@split - 3];
			print LOG $path . "\n";
			$keyterm =~ s/.spout/.dta/g;
			print LOG $protein_name . "\n";
			print LOG $keyterm . "\n"; # contains the dta file name
			print LOG $folder1 . "\n"; # folder path contains the fraction number
			print LOG $folder2 . "\n"; # folder path contains the fraction number2
			
			# look inside the dtas file for this scan information			
			my $dtasFile = $jump_folder . "/" . $folder2 . "/" . $folder1 . "/" . $folder1 . ".dtas";
			my $mzXMLFile = $jump_folder . "/" . $folder2 . "/" . $folder1 . "/" . $folder2 . ".mzXML";

			print LOG $mzXMLFile . "\n";
			print LOG $dtasFile . "\n";
			open(IN, '<', $dtasFile) || die $!;			
			while(my $first_row = <IN>)
			{	
				# for each set of lines, find the mass and intensity
				chomp $first_row;
				my @split_first_row = split(/ /, $first_row);
				my $second_row = <IN>;
				chomp $second_row;
				my @split_second_row = split(/ /, $second_row);				
				my $third_row = <IN>;
				chomp $third_row;
				my @split_third_row = split(/ /, $third_row);
				# this line contains the peptide of interest
				if ($split_first_row[0] eq $keyterm) {
					#print $first_row . "\n";
					# write a file and generate the intensity plot
					#my $outputDTA = $DTA_FOLDER . "/" . $split_first_row[0];
					#open(my $fh, '>', $outputDTA) or die "Could not open file '$outputDTA' $!";
					#print $fh $split_first_row[1] . " " . $split_first_row[2] . "\n";
					for (my $i = 0; $i < @split_second_row; $i++) {
						#print $fh $split_second_row[$i] . " " . $split_third_row[$i] . "\n";
					}					
					close($fh);
				}
			}
			close(IN);
			my $outputDTA = $DTA_FOLDER . "/" . $keyterm;
			my @peptide_split = split(/\./,$peptide);
			print $PSMOUT $protein_name . "\t" . $peptide_split[1] . "\t" . $keyterm . "\t" . $dir . "/" . $outputDTA . "\n";

			my @split_keyterm = split(/\./,$keyterm);
			my $scanNum = $split_keyterm[1];
			my $charge = $split_keyterm[3];
			#print "perl mzXML2dta.pm $mzXMLFile $scanNum $charge\n";
			# generate the DTA file
			print LOG "\n### Convert $mzXMLFile to $DTA_FOLDER/$keyterm ###\n";
			print LOG "perl $mzXML2dta $mzXMLFile $scanNum $charge > $DTA_FOLDER/$keyterm\n";
			system("perl $mzXML2dta $mzXMLFile $scanNum $charge > $DTA_FOLDER/$keyterm");

		}
	}
}
close($PSMOUT);

# run the DTA PDF file generation
# Generate the Images for Ion Display
my $generate_display_ion_script = "$drppm -GenerateDisplayIonHTMLImgSimple $PSM_LIST_OUTPUT $ipaddress $OUTPUT_IMG $OUTPUT_CSV $OUTPUT_HTML $OUTPUT_LOG $TMT_FLAG";
print "\nStep 3. Extracting display ion content from html page... \n";
print LOG "### Extract image from the display ion html page ###\n";
print LOG "$generate_display_ion_script\n";
system($generate_display_ion_script);

print LOG "\n";
# Generate the word file as part of the report
my $generate_report_script = "$drppm -GenerateDisplayIonReport $PSM_LIST_OUTPUT $OUTPUT_IMG $OUTPUT_CSV $OUTPUT_DOCX";
print "\nStep 4. Generating Report...\n";
print LOG "### Execute the generation of the display ion report ###\n";
print LOG "$generate_report_script\n";
system($generate_report_script);

#print "Reading quantification raw file\n";
#my ($headline,$peptidehash,$proteinhash) = ReadRawfile($file);
#print OUTPUT $headline,"\n";
#print "Extracting the peptides/proteins\n";
#Extract_data($params,$peptidehash,$proteinhash);

$datestring = localtime();
print LOG "Execution End: $datestring\n";
close(LOG);
print "\n*** JUMPvms2 finished: $datestring ***\n\n";


sub GenerateHash
{
	# load the parameters
	my ($idtxtfile) = shift;
	#print $idtxtfile . "\n";
	my $idtxtHash = {};
	open(IN, '<', $idtxtfile) || die $!;
	while(<IN>)
	{	
		chomp;
		my @data = split(/\;/,$_);
		$idtxtHash{$data[0]}{$data[2]} = $data[1];
	}
	close IN;
	return $idtxtHash;
}

sub ReadRawfile
{
########### Read input file ######################
	my ($file) = shift;
	
	open(IN, '<', $file) || die $!;
	my $database = readline IN; # database line;
	my $headline = readline IN;  # skip first line
	chop $headline;
	my @head_array = split(/\;/,$headline);

	my (%outfilehash, %peptidehash, %proteinhash);

	while(<IN>)
	{	
		chomp;
		my @data = split(/\;/,$_);
		next if ($#data<2);
		my @data1 = split(/\./,$data[0]);
		my $pep = $data1[1];
		print "\rReading peptide: $pep";
		my $protein = $data[1];
		my $out = $data[2];

		$proteinhash{$protein}{$out}=$_;
		$peptidehash{$pep}{$protein}{$out} = $_;		
	}
	close IN;
	print "\n";
	return ($headline,\%peptidehash,\%proteinhash);
}


sub parse_param {
  my($path) = shift;


  if(open(P,"< $path")){
    my($line);
    my $phash = {};
    
    while($line = <P>){
      
      my $linehash = {};
      my $comments = "";
      
      if( $line =~ s/\s*([;\#].*)$// ) {$comments = $1;}
      
      $linehash->{Comments} = $comments;
      
      if($line =~ /^(.+?)\s*=\s*(.+)$/){
        my ($key,$data) = ($1,$2);
        $data =~ s/\s+$//o;
#        $linehash->{data} = $data;
        $phash->{$key} = $data;
      }      
   }
    
    close P;
    $self->{PARAMETERS} = $phash;
	return $phash;
  }
  return 0;
  
}

sub Extract_data
{
	my ($param,$peptidehash,$proteinhash) = @_;
	foreach (keys %$param)
	{
		if($_ =~/peptide_/)
		{
			foreach my $peptide (keys %$peptidehash)
			{
				my $peptide_orig = $peptide;
				$peptide =~ s/[^a-zA-Z0-9 ]//g;
				if($peptide eq $param->{$_})
				{
					print "peptide found: $peptide_orig found\n";
					foreach my $protein (keys %{$peptidehash->{$peptide_orig}})
					{					
						print "protein found: $protein found\n";
						
						foreach my $out (keys %{$peptidehash->{$peptide_orig}->{$protein}})
						{
							print OUTPUT $peptidehash->{$peptide_orig}->{$protein}->{$out},"\n";
						}
					}						
				}
			}			
		}
		if($_ =~/protein_/)
		{
			foreach my $protein (keys %$proteinhash)
			{
				if($protein eq $param->{$_})
				{
					print "protein found: $protein\n";				
					foreach my $out (keys %{$proteinhash->{$protein}})
					{				
						print OUTPUT $proteinhash->{$protein}->{$out},"\n";
					}	
				}
			}	
		}
		
	}

}

sub help {
		print "\n";
		print "     Usage: jump -vms2 jump_v.params \n";
		print "\n";
		exit;
}
		
