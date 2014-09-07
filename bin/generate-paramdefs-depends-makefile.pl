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

use strict;

################################################################################
# generate-paramdefs-depends-makefile.pl
# 
# Joshua Randall, 9 June 2009.
# Earlier version May 2009.
# 
################################################################################
use strict;

use IO::File;
use IO::Uncompress::Gunzip;
use IO::Compress::Gzip;

use Text::EscapeDelimiters;

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
my $cmdgoals="";
my $sortparams="";
my $params="";
my $outfile="";
my $varprefix="";
my $varsuffix="";

my $result = GetOptions( "cmdgoals=s" => \$cmdgoals,
			 "sortparams=s" => \$sortparams,
			 "params=s" => \$params,
			 "varprefix=s" => \$varprefix,
			 "varsuffix=s" => \$varsuffix,
			 "out=s" => \$outfile,
			 "verbose|v+" => \$DEBUG,
			 );

# Open output file
my $outfh = fzoutopen($outfile);

print STDERR "have cmdgoals=[$cmdgoals] sortparams=[$sortparams] params=[$params]\n" if($DEBUG>0);

my $splitter = new Text::EscapeDelimiters(); # default escape is backslash

$cmdgoals =~ s/[[:space:]]+/\ /gs;
$sortparams =~ s/[[:space:]]+/\ /gs;
$params =~ s/[[:space:]]+/\ /gs;

my @cmdgoals = $splitter->split($cmdgoals," ");
my @sortparams = $splitter->split($sortparams," ");
my @params = $splitter->split($params," ");

print STDERR "have arrays cmdgoals=[@cmdgoals] sortparams=[@sortparams] params=[@params]\n" if($DEBUG>0);

# Output var with all bases of sortparams
print $outfh $varprefix."special_sort_base".$varsuffix." := ".join(" ",map {$_ =~ s/([^\\])\[.*$/$1/g; $_;} @sortparams)."\n";

my %param2re; # stores the regular expression pattern for each parameter given
my %param2matchheaders; # stores an array of matchheaders to be used for each matching parameter option ($1, $2, ...)
my %param2base;
foreach my $paramdef (@params) {
    my $repat = $paramdef;
    $repat =~ s/\[(.*?[^\\])\]/\\\[(\?\<$1\>\.\*\?\[\^\\\\\])\\\]/g;

    my $parambase = $paramdef;
    $parambase =~ s/([^\\])\[.*$/$1/g;

    print STDERR "processed paramdef=[$paramdef] parambase=[$parambase] repat=[$repat]\n" if($DEBUG > 0);
    my @matchheaders;
    while($paramdef =~ s/\[(.+?[^\\])\]//) {
	my $matchheader = $1;
	print STDERR "found matchheader=[$matchheader], new paramdef=[$paramdef]\n" if($DEBUG >0);
	push @matchheaders, $matchheader;
    }
    print STDERR "matchheaders=[@matchheaders]\n" if($DEBUG>0);
    $param2re{$paramdef} = $repat;
    $param2base{$paramdef} = $parambase;
    $param2matchheaders{$paramdef} = [ @matchheaders ];
}

# Process each goal separately, searching for the defined parameters and putting them into hash
my %param_header_value;
foreach my $goal (@cmdgoals) {
    print STDERR "processing goal=[$goal]\n" if ($DEBUG > 0);
    foreach my $paramdef (@params) {
	my $repat = $param2re{$paramdef};
	my @matchheaders = $param2matchheaders{$paramdef};
	print STDERR "searching for repat=[$repat] in goal=[$goal]\n" if ($DEBUG > 0);
	my $goalsearch = $goal;
	my $pat = qr/$repat/;
	my $base = $param2base{$paramdef};
	while($goalsearch =~ m/$pat/gc) {
	    print STDERR "have match for base=[$base]: 1:[$1], 2:[$2], 3:[$3], ... \n" if($DEBUG>2);
	    my $matchheaderindex=0;
	    foreach my $matchheadersref (@{$param2matchheaders{$paramdef}}) {
		my $header = $param2matchheaders{$paramdef}[$matchheaderindex];
		$param_header_value{$paramdef}{$header}{$+{$header}} = 1;
		print STDERR "have value for $base -> $header = $+{$header}\n" if($DEBUG>0);
		$matchheaderindex++;
	    }
	}
    }
}

foreach my $paramdef (@params) {
    my $base = $param2base{$paramdef};
    foreach my $header (@{$param2matchheaders{$paramdef}}) {
	print $outfh $varprefix.$base."_".$header.$varsuffix.' := '.join(" ",keys %{$param_header_value{$paramdef}{$header}})."\n";
    }
}


# Close output file
$outfh->close();
