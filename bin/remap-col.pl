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

my $scriptcentral_path = "/home/jrandall/scriptcentral";
if(exists($ENV{SCRIPTCENTRAL})) {
    $scriptcentral_path = $ENV{SCRIPTCENTRAL};
}
require "$scriptcentral_path/fzinout.pl";

my $infile = "";
my $mapfile = "";
my $outfile = "";
my $logfile = "";

my $insep = "\t";
my $mapsep = "\t";
my $outsep = "\t";

my $colnum = 1;

my $result = GetOptions( "in=s" => \$infile,
			 "map=s" => \$mapfile,
			 "out=s" => \$outfile,
			 "log=s" => \$logfile,
			 "insep=s" => \$insep,
			 "mapsep=s" => \$mapsep,
			 "outsep=s" => \$outsep,
			 "colnum=i" => \$colnum,
			 );

my %map;

# open input file
my $infh = fzinopen($infile);
my $mapfh = fzinopen($mapfile);

# open output file
my $outfh = fzoutopen($outfile);
my $logfh;
if(!$logfile eq "") {
    $logfh = fzoutopen($logfile);
}

my $nmappings = 0;
foreach my $line (<$mapfh>) {
    chomp $line;
    my ($key, $value) = split $mapsep, $line;
    if(defined($key)) {
	$key =~ s/\"//g;
	$value =~ s/\"//g;
	$map{$key} = $value;
	$nmappings++;
    }
}
$mapfh->close();
logprint("Loaded $nmappings mappings from $mapfile\n");

my $nremapped = 0;
foreach my $line (<$infh>) {
    chomp $line;
    my @cols = split $insep, $line, $colnum+1;
    if($map{$cols[$colnum-1]}) {
	$cols[$colnum-1] = $map{$cols[$colnum-1]};
	$nremapped++;
    }
    print $outfh join($outsep, @cols)."\n";
}
logprint("Remapped $nremapped values in $infile and output to $outfile\n");

$infh->close();
$outfh->close();
if(!$logfile eq "") {
    $logfh->close();
}

sub logprint {
    my $text = shift;
    if($logfile eq "") {
	print STDERR $text;
    } else {
	print $logfh $text;
    }
}
