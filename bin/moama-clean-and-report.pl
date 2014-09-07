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
# moama-clean-and-report.pl
# 
# Updated version 21 May 2009 
# This version initially by Joshua Randall, 6 May 2009.
# Based largely on earlier version by Reedik Magi, 2009.
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
my @referencefiles;
my $outfile;
my $excludeoutfile;
my $warnoutfile;
my $reportoutfile;
my $logfile;
my $insep="\t";
my $outsep="\t";
my $reportsep="\t";
my @referenceseps=("\t");
my $outmissing=".";
my @inmissing = (".","NA","","na");
my @inwarn = ("-9","-1");

my @freq_diffs = sort {$b <=> $a} (0.3,0.4,0.5,0.6,0.7,0.8,0.9);

my $result = GetOptions( "in=s" => \$infile,
			 "referencefile=s" => \@referencefiles,
			 "out=s" => \$outfile,
			 "excludeout=s" => \$excludeoutfile,
			 "warnout=s" => \$warnoutfile,
			 "reportout=s" => \$reportoutfile,
			 "insep=s" => \$insep,
			 "referencesep=s" => \@referenceseps,
			 "outsep=s" => \$outsep,
			 "reportsep=s" => \$reportsep,
			 "logfile=s" => \$logfile,
			 "outmissing=s" => \$outmissing,
			 "inmissing=s" => \@inmissing,
			 "inwarn=s" => \@inwarn,
			 "verbose|v+" => \$DEBUG,
			 );


################################################################################
# Open files
################################################################################
my $infh = fzinopen($infile);
my @referencefhs = ();
foreach my $filename (@referencefiles) {
    my $fh = fzinopen($filename);
    push @referencefhs,$fh;
}  
my $outfh = fzoutopen($outfile);
my $excludeoutfh = fzoutopen($excludeoutfile);
my $reportfh = fzoutopen($reportoutfile);
my $warnfh = fzoutopen($warnoutfile);
my $logfh = fzoutopen($logfile);

print $logfh "MOAMA data cleaning\n";
print $logfh "infile: $infile\n";
print $logfh "referencefiles: [@referencefiles]\n";
print $logfh "outfile: $outfile\n";
print $logfh "warnoutfile: $warnoutfile\n";
print $logfh "logfile: $logfile\n";
print $logfh "insep: $insep\n";
print $logfh "outsep: $outsep\n";
print $logfh "reportsep: $reportsep\n";
print $logfh "referenceseps: [@referenceseps]\n";
print $logfh "outmissing: $outmissing\n";
print $logfh "inmissing: [@inmissing]\n";
print $logfh "inwarn: [@inwarn]\n";

################################################################################
# Load reference SNP frequencies / alleles from metadata files
################################################################################
my %snp = ();
my @ref_name;
my @ref_a1;
my @ref_a2;
my @ref_a1f;
my $snp_count = 1;
my $filenum = 0;
foreach my $referencefh (@referencefhs) {
    print $logfh "Processing reference file $referencefiles[$filenum]\n";
    my $snps_in_file = 0;
    my $referencesep = $referenceseps[$filenum];
    # don't worry about header lines, just put them in the hash with everything else
    while(my $line = <$referencefh>) {
	chomp $line;
	my @data = split(/$referencesep/, $line, -1);
	if(exists($snp{$data[0]})) {
	    # this marker has already been processed
	} else {
	    $snps_in_file++;
	    $snp{$data[0]} = $snp_count;
	    $ref_name[$snp_count] = $data[0];
	    $ref_a1[$snp_count] = $data[1];
	    $ref_a2[$snp_count] = $data[2];
	    $ref_a1f[$snp_count] = $data[3];
	    $snp_count++;
	}
    } # while each line
    $referencefh->close();
    print $logfh "Loaded $snps_in_file from $referencefiles[$filenum]\n";
    $filenum++;
} # for each file

################################################################################
# Track values for reporting
################################################################################
my %count;
my %minmax;

################################################################################
# Initialize Count of warnings
################################################################################
foreach my $warnval (@inwarn) {
    $count{"warning_value_".$warnval} = 0;
}
$count{warning_imputation_low} = 0;
$count{warning_infotype_unknown} = 0;
$count{warning_infotype_missing} = 0;
$count{warning_calc_pvalue_low} = 0;
$count{warning_calc_pvalue_high} = 0;
$count{warning_ea_not_ref} = 0;
$count{warning_oa_not_ref} = 0;
$count{warning_eaf_ref_disagree} = 0;
$count{warning_no_reference} = 0;

################################################################################
# Initialize Count of fixed issues
################################################################################
$count{fixed_strand_flipped} = 0;

################################################################################
# Initialize Count of included SNPs
################################################################################
$count{included_snp} = 0;

################################################################################
# Initialize Count of excluded SNPs
################################################################################
$count{excluded_snp} = 0;
$count{excluded_missing_markername} = 0;
$count{excluded_missing_n} = 0;
$count{excluded_missing_ea} = 0;
$count{excluded_missing_nea} = 0;
$count{excluded_missing_eaf} = 0;
$count{excluded_missing_beta} = 0;
$count{excluded_missing_se} = 0;
$count{excluded_missing_p} = 0;
$count{excluded_missing_infotype} = 0;
$count{excluded_infotype_1_low_info} = 0;
$count{excluded_infotype_2_low_info} = 0;
$count{excluded_infotype_3_low_info} = 0;
$count{excluded_low_eaf} = 0;
$count{excluded_high_eaf} = 0;
$count{excluded_low_p} = 0;
$count{excluded_hwe_low} = 0;
$count{excluded_callrate_low} = 0;


################################################################################
# Initialize min and max values
################################################################################
$minmax{n}{min} = $outmissing;
$minmax{n}{max} = $outmissing;
$minmax{beta}{min} = $outmissing;
$minmax{beta}{max} = $outmissing;
$minmax{se}{min} = $outmissing;
$minmax{se}{max} = $outmissing;
$minmax{p}{min} = $outmissing;
$minmax{p}{max} = $outmissing;
$minmax{imputation}{min} = $outmissing;
$minmax{imputation}{max} = $outmissing;
$minmax{info}{min} = $outmissing;
$minmax{info}{max} = $outmissing;


################################################################################
# print header for cleaned output and excluded output
################################################################################
print $outfh join($outsep,("MarkerName","Strand","N","Effect_allele","Other_allele","EAF","Imputation","Information_type","Information","BETA","SE","P"))."\n";
print $excludeoutfh join($outsep,("MarkerName","Strand","N","Effect_allele","Other_allele","EAF","Imputation","Information_type","Information","BETA","SE","P","Exclusion_reasons","File"))."\n";

################################################################################
# print header for warning output
################################################################################
print $warnfh join($outsep,("MarkerName","Warning","Value(s)","File"))."\n";

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
    && $locP != -1) {
    print $logfh "All columns present.\n";
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

print $logfh "Processing data for file $infile...\n";
while(my $line = <$infh>) {
    chomp $line;
    $line =~ s/\r$//;
    
    my @data = split(/$insep/, $line, -1);
    
    # required columns
    my $markername = recodemissing($data[$locMARKERNAME]);   
    my $n = recodemissing($data[$locN]);
    my $ea = recodemissing($data[$locEA]);
    my $nea = recodemissing($data[$locNEA]);
    my $eaf = recodemissing($data[$locEAF]);
    my $oaf = 1 - $eaf;
    my $beta = recodemissing($data[$locBETA]);
    my $se = recodemissing($data[$locSE]);
    my $p = recodemissing($data[$locP]);
    
    my $imp = my $callrate = my $information = my $infotype = my $hwe = $outmissing;
    
    # strand defaults to +
    my $strand = "+";
    if ($locSTRAND != -1) {
	$strand = $data[$locSTRAND];
    } 
    
    # Handle missing imputation column
    if ($locIMPUTATION != -1) {  # imputation column not missing
	$imp = recodemissing($data[$locIMPUTATION]);
    } else { # imputation column is missing
	$imp = $outmissing;
    }
    
    # Handle missing call rate column
    if ($locCALLRATE != -1) { # callrate column not missing
	$callrate = recodemissing($data[$locCALLRATE]);
    } else { # callrate not specified
	$callrate = $outmissing;
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
	    $infotype = $data[$locINFOTYPE];
	}
    } else { # Information_type column was not present
	$infotype = $fileinfotype;
    }
    
    # Optional columns
    if ($locHWE!=-1) {
	$hwe = recodemissing($data[$locHWE]);
    } else {
	$hwe = $outmissing;
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
    
    
################################################################################
# PRINT OUTPUT FILE ACCORDING TO CURRENT QC STANDARDS
################################################################################
    if (
	!ismissing($markername)
	&& !ismissing($n)
	&& !ismissing($ea)
	&& !ismissing($nea)
	&& !ismissing($eaf)
	&& !ismissing($beta)
	&& !ismissing($se)
	&& !ismissing($p)
	&& (
	    ismissing($infotype) 
	    || ($infotype == 1 && $information >= 0.3)
	    || ($infotype == 2 && $information >= 0.4) 
	    || ($infotype == 3 && $information >= 0.3) 
	    || ($infotype < 1)
	    || ($infotype > 3)
	    )
	&& ($eaf > 0) 
	&& ($eaf < 1) 
	&& ($p > 0) 
	&& (ismissing($hwe) || $hwe > 1e-6)
	&& (ismissing($callrate) || $callrate>=0.95)
	)
    { 
	# Compare frequencies to reference
	if (defined($snp{$markername}) && $snp{$markername}>0) {
	    my $z = $snp{$markername};
	    if ($ea eq $ref_a1[$z]) { # Effect_allele is reference allele 1
		if($nea eq $ref_a2[$z]) { # Other_allele is reference allele 2
		    DIFF: foreach my $diff (@freq_diffs) {
			if (abs($eaf-$ref_a1f[$z])>$diff) { # EAF disagrees with reference by at least the given diff
			    $count{"warning_eaf_ref_disagree_gt_".$diff}++;
			    print $warnfh join($outsep,($markername,"EAF_ref_freq_mismatch_".$diff,"EAF:$eaf REF_EA:$ref_a1f[$z]",$infile))."\n";
			    last DIFF;
			}
		    }
		} else { # Other_allele is NOT reference allele 2
		    print $warnfh join($outsep,($markername,"Other_allele_unexpected","Other_allele:$nea REF:$ref_a2[$z] $ref_a1[$z]",$infile))."\n";
		    $count{warning_oa_not_ref}++;
		}
	    } elsif ($ea eq $ref_a2[$z]) { # Effect_allele is reference allele 2
		if($nea eq $ref_a1[$z]) { # Other_allele is reference allele 1
		    # Flip effect to reference
		    $ea = $ref_a1[$z];
		    $nea = $ref_a2[$z];
		    $eaf = 1 - $eaf;
		    $oaf = 1 - $oaf;
		    $beta = $beta * -1;
		    DIFF: foreach my $diff (@freq_diffs) {
			if (abs($eaf-$ref_a1f[$z])>$diff) { # EAF disagrees with reference by at least the given diff
			    $count{"warning_eaf_ref_disagree_gt_".$diff}++;
			    print $warnfh join($outsep,($markername,"EAF_ref_freq_mismatch_".$diff,"EAF:$eaf REF_EA:$ref_a1f[$z]",$infile))."\n";
			    last DIFF;
			}
		    }
		} else { # Unexpected Other_allele 
		    print $warnfh join($outsep,($markername,"Other_allele_unexpected","Other_allele:$nea REF:$ref_a1[$z] $ref_a2[$z]",$infile))."\n";
		    $count{warning_oa_not_ref}++;
		}
	    } else { # Unexpected Effect_allele
		if($nea eq $ref_a1[$z] || $nea eq $ref_a2[$z]) {
		    $count{warning_ea_not_ref}++;
		    print $warnfh join($outsep,($markername,"Effect_allele_unexpected","Effect_allele:$ea Other_allele:$nea REF:$ref_a1[$z] $ref_a2[$z]",$infile))."\n";
		} else { # Unexpected Effect_allele and Other_allele (possible strand issue?)
		    print $warnfh join($outsep,($markername,"Both_alleles_unexpected","Effect_allele:$ea Other_allele:$nea REF:$ref_a1[$z] $ref_a2[$z]",$infile))."\n";
		
		    my $f_ea = flipstrand($ea);
		    my $f_nea = flipstrand($nea);
		    
		    if ($f_ea eq $ref_a1[$z]) {
			if($f_nea eq $ref_a2[$z]) {
			    $count{fixed_strand_flipped}++;
			    $ea = $f_ea;
			    $nea = $f_nea;
			    DIFF: foreach my $diff (@freq_diffs) {
				if (abs($eaf-$ref_a1f[$z])>$diff) { # EAF disagrees with reference by at least the given diff
				    $count{"warning_eaf_ref_disagree_gt_".$diff}++;
				    print $warnfh join($outsep,($markername,"EAF_ref_freq_mismatch_".$diff."_flipped_strand","EAF:$eaf REF_EA:$ref_a1f[$z]",$infile))."\n";
				    last DIFF;
				}
			    }
			} else { # Other_allele is NOT reference allele 2	
			    print $warnfh join($outsep,($markername,"Other_allele_unexpected_flipped_strand","Other_allele:$f_nea REF:$ref_a2[$z] $ref_a1[$z]",$infile))."\n";
			    $count{warning_oa_not_ref}++;
			}
		    } elsif ($f_ea eq $ref_a2[$z]) {
			if($f_nea eq $ref_a1[$z]) {
			    $count{fixed_strand_flipped}++;
			    $ea = $ref_a1[$z];
			    $nea = $ref_a2[$z];
			    $eaf = 1 - $eaf;
			    $oaf = 1 - $oaf;
			    $beta = $beta * -1;
			    DIFF: foreach my $diff (@freq_diffs) {
				if (abs($eaf-$ref_a1f[$z])>$diff) { # EAF disagrees with reference by at least the given diff
				    $count{"warning_eaf_ref_disagree_gt_".$diff}++;
				    print $warnfh join($outsep,($markername,"EAF_ref_freq_mismatch_".$diff."_flipped_strand","EAF:$eaf REF_EA:$ref_a1f[$z]",$infile))."\n";
				    last DIFF;
				}
			    }
			} else { # unexpected other_allele
			    print $warnfh join($outsep,($markername,"Other_allele_unexpected_flipped_strand","Other_allele(flipped):$f_nea REF:$ref_a1[$z] $ref_a2[$z]",$infile))."\n";
			    $count{warning_oa_not_ref}++;
			}
		    } else { # even after strand flip, Effect_allele is not a reference allele
			print $warnfh join($outsep,($markername,"Effect_allele_unexpected_flipped_strand","Effect_allele(flipped):$f_ea REF:$ref_a1[$z] $ref_a2[$z]",$infile))."\n";
			$count{warning_ea_not_ref}++;
		    }
		}
	    }
	} else { # did not have a reference for this marker
	    print $warnfh join($outsep,($markername,"MarkerName_not_in_reference","",$infile))."\n";
	    $count{warning_no_reference}++;
	}
	
	
################################################################################
# COUNT QC WARNINGS
################################################################################
	if (!ismissing($imp) && $imp<0.9) {
	    $count{warning_imputation_low}++;
	    print $warnfh join($outsep,($markername,"Imputation_low","imputation:$imp",$infile))."\n";
	}
	
	if(ismissing($infotype)) {
	    $count{warning_infotype_missing}++;
	    print $warnfh join($outsep,($markername,"Infotype_missing","infotype:$infotype",$infile))."\n";
	} elsif (($infotype < 1) || ($infotype > 3)) {
	    $count{warning_infotype_unknown}++;
	    print $warnfh join($outsep,($markername,"Infotype_unknown","infotype:$infotype",$infile))."\n";
	}
	
	####
	# CHECK IF P = BETA+SE
	####             
	my $calc_z = ($beta / $se);
	my $calc_p = 2 * Statistics::Distributions::uprob(abs($calc_z));
	my $calc_p_ratio = $calc_p / $p;
	if ( $calc_p_ratio <  0.5 ) {
	    $count{warning_calc_pvalue_low}++;
	    print $warnfh join($outsep,($markername,"Calculated_pvalue_low","p:$p calc_p:$calc_p calc_z:$calc_z beta:$beta se:$se calc_p_ratio:$calc_p_ratio",$infile))."\n";
	} elsif( $calc_p_ratio > 2 ) {
	    $count{warning_calc_pvalue_high}++;
	    print $warnfh join($outsep,($markername,"Calculated_pvalue_high","p:$p calc_p:$calc_p calc_z:$calc_z beta:$beta se:$se calc_p_ratio:$calc_p_ratio",$infile))."\n";
	}
	
	
	####
	# finding max and min values
	####
	if ($minmax{n}{min} eq $outmissing || $minmax{n}{min} > $n) {
	    $minmax{n}{min} = $n;
	}
	if ($minmax{n}{max} eq $outmissing || $minmax{n}{max} < $n) {
	    $minmax{n}{max} = $n;
	}
    	
	if ($minmax{beta}{min} eq $outmissing || $minmax{beta}{min} > $beta) {
	    $minmax{beta}{min} = $beta;
	}
	if ($minmax{beta}{max} eq $outmissing || $minmax{beta}{max} < $beta) {
	    $minmax{beta}{max} = $beta;
	}
	
	if ($minmax{se}{min} eq $outmissing || $minmax{se}{min} > $se) {
	    $minmax{se}{min} = $se;
	}
	if ($minmax{se}{max} eq $outmissing || $minmax{se}{max} < $se) {
	    $minmax{se}{max} = $se;
	}
	
	if ($minmax{p}{min} eq $outmissing || $minmax{p}{min} > $p) {
	    $minmax{p}{min} = $p;
	}
	if ($minmax{p}{max} eq $outmissing || $minmax{p}{max} < $p) {
	    $minmax{p}{max} = $p;
	}
	
	if(!ismissing($information)) {
	    if ($minmax{info}{min} eq $outmissing || $minmax{info}{min} > $information) {
		$minmax{info}{min} = $information;
	    }
	    if ($minmax{info}{max} eq $outmissing || $minmax{info}{max} < $information) {
		$minmax{info}{max} = $information;
	    }
	}
        
	
	if (!ismissing($imp)) {
	    if ($minmax{imputation}{min} eq $outmissing || $minmax{imputation}{min} > $imp) {
		$minmax{imputation}{min} = $imp;
	    }
	    if ($minmax{imputation}{max} eq $outmissing || $minmax{imputation}{max} < $imp) {
		$minmax{imputation}{max} = $imp;
	    }
	}
	
	
################################################################################
# Printing out line to the cleaned file
################################################################################
	print $outfh join($outsep,($markername,$strand,$n,$ea,$nea,$eaf,$imp,$infotype,$information,$beta,$se,$p))."\n";
	
	# Track number of SNPs output
	$count{included_snp}++;

    } else { # exclude this SNP
	my $exclude_reason = "";
	# Track number of SNPs excluded
	$count{excluded_snp}++;
	

	if(ismissing($markername)) {
	    $count{excluded_missing_markername}++; 
	    $exclude_reason .= "missing_markername ";
	}
	if(ismissing($n)) {
	    $count{excluded_missing_n}++;
	    $exclude_reason .= "missing_n ";
	}
	if(ismissing($ea)) {
	    $count{excluded_missing_ea}++;
	    $exclude_reason .= "missing_ea ";
	}
	if(ismissing($nea)) {
	    $count{excluded_missing_nea}++;
	    $exclude_reason .= "missing_nea ";
	}
	if(ismissing($eaf)) {
	    $count{excluded_missing_eaf}++;
	    $exclude_reason .= "missing_eaf ";
	}
	if(ismissing($beta)) {
	    $count{excluded_missing_beta}++;
	    $exclude_reason .= "missing_beta ";
	}
	if(ismissing($se)) {
	    $count{excluded_missing_se}++;
	    $exclude_reason .= "missing_se ";
	}
	if(ismissing($p)) {
	    $count{excluded_missing_p}++;
	    $exclude_reason .= "missing_p ";
	}
	
	if(ismissing($infotype)) {
	    # missing infotype allowed
	} else {
	    if($infotype == 1 && $information < 0.3) {
		$count{excluded_infotype_1_low_info}++;
		$exclude_reason .= "infotype_1_low_info ";
	    }
	    if($infotype == 2 && $information < 0.4) {
		$count{excluded_infotype_2_low_info}++;
		$exclude_reason .= "infotype_2_low_info ";
	    }
	    if($infotype == 3 && $information < 0.3) {
		$count{excluded_infotype_3_low_info}++;
		$exclude_reason .= "infotype_3_low_info ";
	    }
	}
	if($eaf <= 0) {
	    $count{excluded_low_eaf}++;
	    $exclude_reason .= "low_eaf ";
	}
	if($eaf >= 1) {
	    $count{excluded_high_eaf}++;
	    $exclude_reason .= "high_eaf ";
	}
	if($p <= 0) {
	    $count{excluded_low_p}++;
	    $exclude_reason .= "low_p ";
	}
	if(!ismissing($hwe)) {
	    if($hwe <= 1e-6) {
		$count{excluded_hwe_low}++;
		$exclude_reason .= "hwe_low ";
	    }
	}
	if(!ismissing($callrate)) {
	    if($callrate<0.95) {
		$count{excluded_callrate_low}++;
		$exclude_reason .= "callrate_low ";
	    }
	}
	print $excludeoutfh join($outsep,($markername,$strand,$n,$ea,$nea,$eaf,$imp,$infotype,$information,$beta,$se,$p,$exclude_reason,$infile))."\n";
	
    } 
    
} # while processing each line

$infh->close();
$outfh->close();
$excludeoutfh->close();
$warnfh->close();

################################################################################
# output report file header and row
################################################################################
my @countkeys = sort keys %count;
my @minmaxkeys = sort keys %minmax;
print $logfh "Printing report: countkeys=[@countkeys] minmaxkeys=[@minmaxkeys]\n";

print $reportfh join($reportsep, (
				  "FILE", 
				  (map {$_."_count"} @countkeys), 
				  (map {($_."_min",$_."_max")} @minmaxkeys),
				  ))."\n";
print $reportfh join($reportsep,(
				 $infile,
				 (map {$count{$_}} @countkeys), 
				 (map{($minmax{$_}{min},$minmax{$_}{max})} @minmaxkeys),
				 ))."\n";

$reportfh->close();
$logfh->close();

exit(0);

sub ismissing {
    my $data = shift;
    if($data eq $outmissing) {
	return(1);
    }
    warnval($data);
    foreach my $missing (@inmissing) {
	if($data eq $missing) {
	    return(1);
	}
    }
    return(0);
}

sub warnval {
    my $data = shift;
    foreach my $warnval (@inwarn) {
	if($data eq $warnval) {
	    $count{"warning_value_".$warnval}++;
	}
    }
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

