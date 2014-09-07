#!/usr/bin/perl -w 
###############################################################################
#
# Copyright 2009 Joshua Randall
#
# Joshua Randall <jcrandall@alum.mit.edu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

################################################################################
# moama-reformat.pl
# 
# This version by Joshua Randall, 20 May 2009.
# 
################################################################################
use strict;

use IO::File;
use IO::Uncompress::Gunzip;
use IO::Compress::Gzip;

use Getopt::Long;

my $scriptcentral_path = "/home/jrandall/scriptcentral";
if(exists($ENV{PIPELINE_HOME})) {
    $scriptcentral_path = $ENV{PIPELINE_HOME}."/bin";
}
if(exists($ENV{SCRIPTCENTRAL})) {
    $scriptcentral_path = $ENV{SCRIPTCENTRAL};
}
require "$scriptcentral_path/fzinout.pl";

use Statistics::Distributions;

my $DEBUG=0;

my $infile;
my $outfile;
my $logfile;
my $insep="\t";
my $outsep="\t";
my $outmissing=".";
my @inmissing = ("NA","",".");

my $result = GetOptions( "in=s" => \$infile,
			 "out=s" => \$outfile,
			 "insep=s" => \$insep,
			 "outsep=s" => \$outsep,
			 "logfile=s" => \$logfile,
			 "outmissing=s" => \$outmissing,
			 "inmissing=s" => \@inmissing,
			 "verbose|v+" => \$DEBUG,
			 );

# Open files
my $infh = fzinopen($infile);
my $outfh = fzoutopen($outfile);
my $logfh = fzoutopen($logfile);

print $logfh "MOAMA data cleaning\n";
print $logfh "infile: $infile\n";
print $logfh "outfile: $outfile\n";
print $logfh "logfile: $logfile\n";
print $logfh "insep: $insep\n";
print $logfh "outsep: $outsep\n";
print $logfh "outmissing: $outmissing\n";
print $logfh "inmissing: [@inmissing]\n";

my $fileOK = 0;

# print header for cleaned output
print $outfh join($outsep,("MarkerName","Strand","N","Effect_allele","Other_allele","EAF","Imputation","Information_type","Information","BETA","SE","P"))."\n";

my $locMARKERNAME = my $locSTRAND = my $locN = my $locEA = my $locNEA = my $locEAF = my $locIMPUTATION = my $locINFOTYPE = my $locINFO = my $locBETA = my $locSE = my $locP = my $locHWE = my $locCALLRATE = -1;
my $fileinfotype = $outmissing;

print $logfh "Processing header for $infile\n";
my $headerline = <$infh>;
chomp $headerline;
$headerline =~ s/\r$//;
my @headerdata = split(/$insep/, $headerline, -1);

for (my $j=0;$j<scalar(@headerdata);$j++) {
    my $header = $headerdata[$j];
    my $headeruc = uc($header);
    if ($headeruc =~ m/(SNP|MARKER|RS).*(NAME|ID)/
	|| $headeruc eq "NAME" 
	|| $headeruc eq "MARKER") { 
	print $logfh "Found MarkerName ($header) at column $j\n";
	$locMARKERNAME=$j;
    } elsif ($headeruc =~ m/STR/) {
	print $logfh "Found Strand ($header) at column $j\n";
	$locSTRAND=$j;
    } elsif ($headeruc eq "N" 
	     || $headeruc eq "WEIGHT"
	     || $headeruc =~ m/(SAMPLE).*(SIZE|N)/
	     || $headeruc =~ m/^N.*(SAMPLE|IND)/) {
	print $logfh "Found N ($header) at column $j\n";
	$locN=$j;
    } elsif ($headeruc =~ m/^(EFF|REF).*(ALLELE)/) {
	print $logfh "Found Effect_allele ($header) at column $j\n";
	$locEA=$j;
    } elsif ($headeruc =~ m/^(OTHER|NON).*(ALLELE)/) {
	print $logfh "Found Other_allele ($header) at column $j\n";
	$locNEA=$j;
    } elsif ($headeruc eq "EAF"
	     || $headeruc =~ m/(FREQ).*(EFF|REF)/
	     || $headeruc =~ m/(EFF|REF).*(FREQ)/) {
	print $logfh "Found EAF ($header) at column $j\n";
	$locEAF=$j;
    } elsif ($headeruc eq "IMPUTATION" 
	     || $headeruc eq "POSTERIOR_PROB"
	     || $headeruc eq "AVERAGE_MAXIMUM_POSTERIOR_CALL") {
	print $logfh "Found Imputation ($header) at column $j\n";
	$locIMPUTATION=$j;
    } elsif ($headeruc =~ m/BETA/ 
	     || $headeruc eq "EFFECT") {
	print $logfh "Found BETA ($header) at column $j\n";
	$locBETA=$j;
    } elsif ($headeruc =~ m/^SE/
	     || $headeruc =~ m/STDERR/) {
	print $logfh "Found SE ($header) at column $j\n";
	$locSE=$j;
    } elsif ($headeruc eq "P" 
	     || $headeruc =~ m/^P.*VAL/) {
	print $logfh "Found P ($header) at column $j\n";
	$locP=$j;
    } elsif ($headeruc =~ m/^RSQ/) {
	print $logfh "Found Information type 1 ($header) at column $j\n";
	$fileinfotype = 1;
	$locINFO=$j;
    } elsif ($headeruc =~ m/^PROPER/) {
	print $logfh "Found Information type 2 ($header) at column $j\n";
	$fileinfotype = 2;
	$locINFO=$j;
    } elsif ($headeruc =~ m/^INFO.*TYPE/) {
	print $logfh "Found Information_type ($header) at column $j\n";
	$locINFOTYPE=$j;
    } elsif ($headeruc =~ m/^INFO/) {
	print $logfh "Found Information ($header) at column $j\n";
	$locINFO=$j;
    } elsif ($headeruc =~ m/HWE/) {
	print $logfh "Found HWE ($header) at column $j\n";
	$locHWE=$j;
    } elsif ($headeruc =~ m/CALL.*RATE/) {
	print $logfh "Found CALLRATE ($header) at column $j\n";
	$locCALLRATE=$j;
    } else {
	print $logfh "Found unknown header ($header) at column $j\n";
    }
}

if ($locMARKERNAME != -1 
    && $locN != -1 
    && $locEA != -1 
    && $locNEA != -1 
    && $locEAF != -1 
    && $locBETA != -1 
    && $locSE != -1 
    && $locP != -1){
    $fileOK=1;
} else {
    die "Required columns missing, cannot proceed.\n";
}

if ($locSTRAND == -1) {
    print $logfh "WARNING: Strand column missing\n";
}

if ($locIMPUTATION == -1) {
    print $logfh "WARNING: Imputation column missing\n";
}

if ($locINFO == -1) {
    print $logfh "WARNING: Information column missing\n";
}

if (($locINFOTYPE == -1)  && ($fileinfotype eq $outmissing)) {
    print $logfh "WARNING: Information type column missing\n";
}

if($fileOK==1) {
    print $logfh "Processing data for file $infile...\n";
    while(my $line = <$infh>) {
	chomp $line;
	$line =~ s/\r$//;

	my @data = split(/$insep/, $line, -1);
	
	# required columns
	my $markername = $data[$locMARKERNAME];   
	my $n = recodemissing($data[$locN]);
	my $ea = recodemissing($data[$locEA]);
	my $nea = recodemissing($data[$locNEA]);
	my $eaf = recodemissing($data[$locEAF]);
	my $beta = recodemissing($data[$locBETA]);
	my $se = recodemissing($data[$locSE]);
	my $p = recodemissing($data[$locP]);

	my $imp = my $information = my $infotype = $outmissing;
	
	# strand defaults to +
	my $strand = "+";
	if ($locSTRAND != -1) {
	    $strand = recodemissing($data[$locSTRAND]);
	} 
	
	# Handle missing imputation column
	if ($locIMPUTATION != -1) {  # imputation column not missing
	    $imp = recodemissing($data[$locIMPUTATION]);
	} else { # imputation column is missing
	    $imp = $outmissing;
	}
	
	# Handle missing Information column
	if($locINFO!=-1) { # Information column is present
	    $information = recodemissing($data[$locINFO]);
	} else { # Information column was not specified
	    $information = $outmissing;
	}
	
        # Handle missing Information_type column
	if ($locINFOTYPE!=-1) { # Information_type column is present
	    if(ismissing($data[$locINFOTYPE])) {
		$infotype = $fileinfotype;
	    } else {
		$infotype = $outmissing;
	    }
	} else { # Information_type column was not present
	    $infotype = $fileinfotype;
	}
	
	# Recode numerical alleles to letters
	$ea =~ tr/1234/ACGT/;
        $nea =~ tr/1234/ACGT/;

	# Recode lowercase alleles to uppercase
	$ea = uc($ea);
	$nea = uc($nea);
	
	# Flip Strand
	if ($strand eq "-") {
	    $ea = flipstrand($ea);
	    $nea = flipstrand($nea);
	    $strand = "+";
	}
	
	####
	# Printing out line to the cleaned file
	####
	print $outfh join($outsep,($markername,$strand,$n,$ea,$nea,$eaf,$imp,$infotype,$information,$beta,$se,$p))."\n";
	
    } # while processing each line
} # done processing file
	
$infh->close();
$outfh->close();

$logfh->close();

exit(0);

sub ismissing {
    my $data = shift;
    if($data eq $outmissing) {
	return(1);
    }
    foreach my $missing (@inmissing) {
	if($data eq $missing) {
	    return(1);
	}
    }
    return(0);
}

sub recodemissing {
    my $data = shift;
    if(ismissing($data)) {
	return $outmissing;
    } else {
	return $data;
    }
}

sub flipstrand {
    my $allele = shift;
    $allele =~ tr/ACGT/TGCA/;
    return($allele);
}

