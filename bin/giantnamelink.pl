#!/usr/bin/perl -w
###############################################################################
#
# Copyright 2008, 2009 Joshua Randall
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

use strict;
use warnings;

use File::Basename;

my @names_in = @ARGV;

my %name_in; # hash to store mappings
my %suffix; # hash to store suffixes
foreach my $name_in (@names_in) {
    my ($name, $path) = fileparse($name_in);
    print STDERR "Remapping $name_in (basename $name, path $path)\n";

    # Remove cleaned prefix
    if($name =~ m/^CLEANED(.)/i) {
	if($name =~ s/^CLEANED(.)//i) {
	    #print STDERR "removed cleaned prefix (CLEANED$1) from ($name_in)\n";
	} else {
	    die "ERROR: error removing cleaned prefix ($name_in)\n";
	}
    } else {
	die "ERROR: could not find cleaned prefix in $name ($name_in)\n";
    }
    
    # get suffix
    my $suffix="";
    $name =~ s/csv/txt/g;
    if($name =~ m/.(txt.*)$/i) {
	$suffix = $1;
	$suffix =~ s/txt/txt/i;
	while($suffix =~ s/txt.txt/txt/i) {
	    print STDERR "removing extra txt in suffix ($name_in)\n";
	}
    } else {
	die "ERROR: could not find .txt in $name ($name_in)\n";
    }
    if($suffix eq ".txt" || $suffix eq ".txt.gz" || $suffix eq ".txt.Z" || $suffix eq ".txt.bz2") {
	die "ERROR: unsupported suffix $suffix ($name_in)\n";
    }

    # remove suffix from name
    $name =~ s/.$suffix//;
    
    # recode underscore to . if there are no .'s
    if($name =~ m/\./) {
	
    } else {
	print STDERR "WARNING: recoding _ to . ";
	if($name =~ m/CASE/i) {
	    my ($name1,$name2) = split /CASE/,$name;
	    $name2 =~ s/\_/\./g;
	    $name = $name1."CASE".$name2;
	    print STDERR "recoded only after CASE for filename ($name_in) now ($name)\n";
	} elsif((!$name =~ m/CONTROLBMI/i) && $name =~ m/CONTROL/i) {
	    my ($name1,$name2) = split /CONTROL/,$name;
	    $name2 =~ s/\_/\./g;
	    $name = $name1."CONTROL".$name2;
	    print STDERR "recoded only after CONTROL for filename ($name_in) now ($name)\n";
	} else {
	    $name =~ s/\_/\./g;
	    print STDERR "recoded full filename ($name_in) now ($name)\n";
	}
    }

    # Get study information from filename
    my $study="";
    if($name =~ m/(.*?).(CASE|CONTROL)/i || $name =~ m/(.*?)[\.].+$/) {
	$study = $1;
    } else {
	die "ERROR: separator not found in $name ($name_in), could not find study name!\n";
    }

    # Clean case/control out of study name
    if($study =~ s/[\_\-\.]CASE//i) {
	print STDERR "cleaned CASE out of study name ($name_in)\n";
    } elsif($study =~ s/[\_\-\.]CONTROL//i || $study =~ s/[\_\-\.]CTRL//i) {
	print STDERR "cleaned CONTROL out of study name ($name_in)\n";
    } 

    # special case - clean .HI (remaining from HIPCONTROLBMI for ARIC) out
    if($study =~ s/\.HI$// ) {
	print STDERR "special case for HIPCONTROLBMI ($name_in) is study $study\n";
    }
    # special case - change EPIC_COHORT_* to EPIC
    if($study =~ s/EPIC_COHORT.*/EPIC/) {
	print STDERR "special case for EPIC ($name_in) is study $study\n";
    }
    # special case - change ERF_HI* to ERF
    if($study =~ s/ERF.*/ERF/i) {
	print STDERR "special case for ERF ($name_in) is study $study\n";
    }
    # special case - change RS1 to ROTTERDAM_STUDY_BASE1
    if($study =~ s/RS1/ROTTERDAM_STUDY_BASE1/) {
	print STDERR "special case for rotterdam base 1 ($name_in) is study $study\n";
    }
    
    # Get case/control status from filename
    my $cc = "";
    if($name =~ m/CASE/i && $name =~ m/CONTROL/i) {
	print STDERR "WARNING: both case and control present in filename, attempting to differentiate ($name_in)\n";
    }
    if($name =~ m/[\_\-\.]CASE/i && $name =~ m/[\_\-\.]CONTROL/i) {
	die "ERROR: both case and control present in filename without clear indication ($name_in)\n";
    } elsif($name =~ m/[\_\-\.]CASE/i) {
	$cc = "CASE";
    } elsif($name =~ m/[\_\-\.]CONTROL/i) {
	$cc = "CONTROL";
    } elsif($name =~ m/[[:punct:]]NMI[[:punct:]]/i) {
	$cc = "CONTROL";
	print STDERR "WARNING: assigned to CONTROL status based on NMI tag ($name_in)\n";
    } elsif($name =~ m/[[:punct:]]MI[[:punct:]]/i) {
	$cc = "CASE";
	print STDERR "WARNING: assigned to CASE status based on MI tag ($name_in)\n";
    }
    # special case - force T2D to CASE
    if($study =~ m/^T2D$/) {
	$cc = "CASE";
	print STDERR "special case for T2D, forcing CASE status ($name_in)\n";
    }

    # Get trait information from filename
    my $trait="";
    if($name =~ m/WCHipR/i || $name =~ m/WHR/i) {
	print STDERR "have some kind of WHR";
	if($name =~ m/BMI/i) {
	    $trait = "WHRadjBMI";
	} else {
	    $trait = "WHR";
	}
    } elsif($name =~ m/WC/i || $name =~ m/WAIST/i) {
	print STDERR "have some kind of WAIST";
	if($name =~ m/BMI/i) {
	    $trait = "WCadjBMI";
	} else {
	    $trait = "WC";
	}
    } elsif($name =~ m/HC/i || ($name =~ m/HIP/i && !($name =~ m/SHIP/i)) || $name =~ m/SHIP.*HIP/i) {
	print STDERR "have some kind of HIP";
	if($name =~ m/BMI/i) {
	    $trait = "HIPadjBMI";
	} else {
	    $trait = "HIP";
	}
    } elsif($name =~ m/HEIGHT/i) {
	print STDERR "have some kind of HEIGHT";
	if($name =~ m/BMI/i) {
	    $trait = "HEIGHTadjBMI";
	} else {
	    $trait = "HEIGHT";
	}
    } elsif($name =~ m/WEIGHT/i) {
	print STDERR "have some kind of WEIGHT";
	if($name =~ m/BMI/i) {
	    $trait = "WEIGHTadjBMI";
	} else {
	    $trait = "WEIGHT";
	}
    } elsif($name =~ m/BMI/i) {
	print STDERR "have BMI";
	$trait = "BMI";
    } else {
	die "ERROR: could not assign trait for $name ($name_in)\n";
    }
    
    my $gender="";
    if($name =~ m/FEMALE/i || $name =~ m/WOMEN/i) {
	$gender = "WOMEN";
    } elsif($name =~ m/MALE/i || $name =~ m/MEN/i) {
	$gender = "MEN";
    } elsif($name =~ m/COMBINED/i || $name =~ m/ALL/i) {
	if($name =~ m/SEARCH/i) {
	    $gender = "WOMEN";
	} else {
	    $gender = "ALL";
	}
    } else {
	# die "ERROR: could not assign gender for $name ($name_in)\n";
	print STDERR "WARNING: gender not specified, assuming ALL for $name ($name_in)\n";
	$gender = "ALL"; 
    }

    
    # check date
    my $date="";
    if($name =~ m/giant.association.results.([[:digit:]]+)/i || $name =~ m/GWA.([[:digit:]]+)/i || $name =~ m/([[:digit:]]+).$suffix/i) {
	$date = $1;
    } else {
	# die "ERROR: could not find date in $name ($name_in)\n";
	print STDERR "WARNING: date not found in $name ($name_in) -- assuming 31st December 9999\n";
	$date = "99991231";
    }
    
    my $studycc = "";
    if($cc eq "") {
	$studycc = $study;
    } else {
	$studycc = $study."_".$cc;
    }
    
    print STDERR "filing $name_in: belongs to study $studycc, trait $trait, gender $gender, date $date\n";
    push @{$name_in{$studycc}{$trait}{$gender}{$date}},$name_in;
    push @{$suffix{$studycc}{$trait}{$gender}{$date}},$suffix;
}


open LIST, ">giant-v5-filename-clean.txt";
print LIST join("\t","FTPFileName","CleanedFileName")."\n";

# output
foreach my $studycc (keys %name_in) {
    foreach my $trait (keys %{$name_in{$studycc}}) {
	foreach my $gender (keys %{$name_in{$studycc}{$trait}}) {
	    my @dates = sort {$b <=> $a} keys %{$name_in{$studycc}{$trait}{$gender}};
	    my $topdate = $dates[0]; 
	    my $numdates = scalar(@dates);
	    if($numdates > 1) {
		my @samedatefiles = map {$name_in{$studycc}{$trait}{$gender}{$_}[0]} @dates;
		print STDERR "Have $numdates differently dated files for $studycc, $trait, $gender [@samedatefiles] -- using $topdate\n";
	    }
	    my @names_in = @{$name_in{$studycc}{$trait}{$gender}{$topdate}};
	    my @suffixes = @{$suffix{$studycc}{$trait}{$gender}{$topdate}};
	    my $chosen = 0;
	    if(@names_in > 1) {
		die "ERROR:  had multiple options for $studycc, $trait, $gender, $topdate! [@names_in]\n";
	    }	    
	    my $name_in = $names_in[$chosen];
	    my $suffix = $suffixes[$chosen];
	    my $name_out = join(".",$studycc,$trait,$gender,"UNIFORM","giant-association-results",$suffix);
	    print LIST join("\t",basename($name_in),basename($name_out))."\n";
	    print "rm -f $name_out && ln -s $name_in $name_out\n";
	}
    }
}

close LIST;
