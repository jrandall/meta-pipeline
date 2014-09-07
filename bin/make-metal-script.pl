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
# 
# Metal source script generation
#
# Joshua Randall, 6 May 2009.
# 
################################################################################
use strict;

use Getopt::Long;

my $DEBUG=0;
my @infiles=();
my $scheme="se";
my @filters=(); # format for filters: "LABEL CONDITION VALUE"
my $outfile;
my $outsuffix;

my $markerlabel = "MarkerName";
my $ealabel = "Effect_allele";
my $oalabel = "Other_allele";
my $effectlabel = "BETA";
my $weightlabel = "N";
my $pvaluelabel = "P";
my $stderrlabel = "SE";
my $freqlabel = "EAF";
my $strandlabel = "Strand";

my $result = GetOptions( "in=s" => \@infiles,
			 "scheme=s" => \$scheme, # "ss" or "se"
			 "filter=s" => \@filters,
			 "out=s" => \$outfile,
			 "outsuffix=s" => \$outsuffix,
			 "markerlabel=s" => \$markerlabel,
			 "ealabel=s" => \$ealabel,
			 "oalabel=s" => \$oalabel,
			 "effectlabel=s" => \$effectlabel,
			 "weightlabel=s" => \$weightlabel,
			 "pvaluelabel=s" => \$pvaluelabel,
			 "stderrlabel=s" => \$stderrlabel,
			 "freqlabel=s" => \$freqlabel,
			 "strandlabel=s" => \$strandlabel,
			 "verbose|v+" => \$DEBUG,
			 );


$scheme = uc($scheme);
$scheme =~ s/^SS$/SAMPLESIZE/;
$scheme =~ s/^SE$/STDERR/;

print STDERR "processing [@infiles] to make $outfile $outsuffix\n" if($DEBUG>0);

print<<EOF;
CLEAR
SEPARATOR	TAB
COLUMNCOUNTING	STRICT

MARKERLABEL	$markerlabel
ALLELELABELS	$ealabel $oalabel
EFFECTLABEL	$effectlabel
WEIGHTLABEL	$weightlabel
PVALUELABEL	$pvaluelabel
STDERRLABEL	$stderrlabel
FREQLABEL	$freqlabel
STRANDLABEL	$strandlabel

SCHEME		$scheme
GENOMICCONTROL	ON
AVERAGEFREQ	ON
MINMAXFREQ	ON
EOF

foreach my $filter (@filters) {
    $filter =~ s/[[:space:]]lte[[:space:]]/\ \<\=\ /;
    $filter =~ s/[[:space:]]gte[[:space:]]/\ \>\=\ /;
    $filter =~ s/[[:space:]]lt[[:space:]]/\ \<\ /;
    $filter =~ s/[[:space:]]gt[[:space:]]/\ \>\ /;
    $filter =~ s/[[:space:]]eq[[:space:]]/\ \=\ /;
    $filter =~ s/[[:space:]]ne[[:space:]]/\ \!\=\ /;
    # IN needs no recoding
    print<<EOF;
ADDFILTER	$filter
EOF
}

if(@infiles > 1) { # more than one input file, actual meta analysis (not just GC correction)
    print<<EOF;
USESTRAND	ON
EOF
}

if($scheme eq "STDERR") { # add N tracking for stderr analysis
    print<<EOF; 
CUSTOMVARIABLE	$weightlabel
LABEL		$weightlabel AS $weightlabel
EOF
}

if($DEBUG>0) {
print<<EOF;
VERBOSE		ON
EOF
}

foreach(@infiles) {
print<<EOF;
PROCESSFILE	$_
EOF
}

print<<EOF;
OUTFILE		$outfile $outsuffix
EOF

if(@infiles > 1) { # more than one input file, actual meta analysis (not just GC correction)
    print<<EOF;
ANALYZE		HETEROGENEITY
EOF
} else {
    print<<EOF;
ANALYZE
EOF
}

print<<EOF;
QUIT
EOF

