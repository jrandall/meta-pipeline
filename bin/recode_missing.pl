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

use IO::File;
use IO::Uncompress::Gunzip;
use IO::Compress::Gzip;

use Getopt::Long;

my $DEBUG=0;

my $infile;
my $outfile;
my $insep="\t";
my $outsep="\t";
my $inmissingpat="$^";
my $outmissing=".";

my $result = GetOptions( "in=s" => \$infile,
			 "out=s" => \$outfile,
			 "insep=s" => \$insep,
			 "outsep=s" => \$outsep,
			 "inmissingpat=s" => \$inmissingpat,
			 "outmissing=s" => \$outmissing,
			 );

# open files
my $infh = fzinopen($infile);
my $outfh = fzoutopen($outfile);

# process headers
my $headerline = <$infh>;
chomp $headerline;
print $outfh $headerline."\n";


# process the rest of the file
while(my $line = <$infh>) {
    chomp $line;
    my @data = split /$insep/,$line;
    for(my $i=0; $i<=$#data; $i++) {
	if($data[$i] =~ $inmissingpat) {
	    $data[$i] = $outmissing;
	}
    }
    print $outfh join($outsep,@data)."\n";
}


sub fzinopen {
    my $filename = shift || "";
    my $fh;
    if($filename && ($filename =~ m/gz$/)) {
	$fh = new IO::Uncompress::Gunzip $filename or die "Could not open $filename using gzip for input\n";
    } else {
	$fh = new IO::File;
	$fh->open("<$filename") or die "Could not open $filename for input\n";
    }
    return $fh;
}

sub fzoutopen {
    my $filename = shift || "";
    my $fh;
    if($filename && ($filename =~ m/gz$/)) {
	$fh = new IO::Compress::Gzip $filename or die "Could not open $filename using gzip for output\n";
    } else {
	$fh = new IO::File;
	$fh->open(">$filename") or die "Could not open $filename for output\n";
    }
    return $fh;
}

