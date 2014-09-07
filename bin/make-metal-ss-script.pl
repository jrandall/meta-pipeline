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

my $outfile = shift @ARGV;
my $outsuffix = shift @ARGV;
my @infiles = @ARGV;

print STDERR "processing [@infiles] to make $outfile $outsuffix\n";

print<<EOF;
SEPARATOR	TAB
COLUMNCOUNTING	STRICT
MARKERLABEL	MarkerName
ALLELELABELS	Effect_allele Other_allele
EFFECTLABEL	BETA
WEIGHTLABEL	N
PVALUELABEL	P
STDERRLABEL	SE

GENOMICCONTROL ON
SCHEME SAMPLESIZE

EOF

foreach(@infiles) {
    print "PROCESSFILE\t$_\n";
}

print "OUTFILE $outfile $outsuffix\n";

print<<EOF;
VERBOSE		ON
ANALYZE
QUIT
EOF

