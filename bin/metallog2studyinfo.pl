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
# metallog2studyinfo.pl
# 
# Extract study information from metal output log
#
# Joshua Randall, 22 June 2009.
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

my $DEBUG=0;
my $infile;
my $outfile;
my $outsep = "\t";
 
my $result = GetOptions( "in=s" => \$infile,
			 "out=s" => \$outfile,
			 "outsep=s" => \$outsep,
			 );

# Open files
my $infh = fzinopen($infile);
my $outfh = fzoutopen($outfile);


# Output headers
print $outfh join($outsep,("StudyFile","GCLambda","MarkersProcessed","MarkersFiltered","MarkersFilteredByConstraint"))."\n";

# Process input to output
my $input = "";
while(my $line = <$infh>) {
    chomp $line;
    if($line =~ m/Running\ second\ pass\ analysis/) {
	last;
    } elsif($line =~ m/^\#[\#[:space:]]+Processing\ file\ \'(.*)\'[[:space:]]*$/) {
	my $studyfile = $1;
	my $studyfilebasename = $studyfile;
	$studyfilebasename =~ s/.*\///; 
	my $markersprocessed = -1;
	my $gclambda = -1;
	my $markersfiltered = 0;
	my %markersfilteredonconstraint;
	while($markersprocessed < 0) {
	    # grab the rest of the lines for this study
	    my $studyline = <$infh>;
	    if($studyline) {
		chomp $studyline;
		if($studyline =~ m/^\#[\#[:space:]]+([[:digit:]]+)\ lines\ filtered\,\ for\ the.*$/) {
		    $markersfiltered = $1;
		} elsif($studyline =~ m/^\#[\#[:space:]]+([[:digit:]]+)\ lines\ filtered\ due\ to\ constraint\ (.*)$/) {
		    $markersfilteredonconstraint{$2} = $1;
		} elsif($studyline =~ m/^\#[\#[:space:]]+Genomic\ control\ parameter\ is\ ([\.[:digit:]]+)\,.*$/) {
		    $gclambda = $1;
		} elsif($studyline =~ m/^\#[\#[:space:]]+Processed\ (.*)\ markers.*$/) {
		    $markersprocessed = $1;
		}
	    } else {
		last;
	    }
	}
	print $outfh join($outsep,($studyfilebasename,$gclambda,$markersprocessed,$markersfiltered,join(" ",map {$_." : ".$markersfilteredonconstraint{$_}} keys %markersfilteredonconstraint)))."\n";
    } # end of study information (saw "Processed..." line)
}
 


# Close files
$infh->close();
$outfh->close();
