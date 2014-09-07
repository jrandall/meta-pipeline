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

my $DEBUG = 0;

# cut-col-name.pl filename columnname
# returns column number suitable for cut -f

my $filename = shift or die "did not specify filename!\n";
my $columnheader = shift or die "did not specify column name!\n";

my $columnheaderpat = $columnheader;
#my $columnheaderpat = quotemeta($columnheader);

open(IN, "<$filename") or die "could not open file $filename\n";
my $header = <IN>;
chomp $header;
close(IN);

my @headers = split /\t/,$header;

my $col = 1;

CHECK: foreach my $colhead (@headers) {
    if($colhead =~ m/$columnheaderpat/) {
	print STDERR "found $colhead matching $columnheaderpat\n" if($DEBUG>0);
	last CHECK;
    } else {
	print STDERR "$colhead did not match $columnheaderpat\n" if($DEBUG>0);
	$col++;
    }
} 

if($col == scalar(@headers)+1) {
    print STDERR "$columnheaderpat not found!\n" if($DEBUG>0);
    $col = -1;
}
print "$col";

exit(0);
