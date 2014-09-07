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
# detect-sep.pl
# 
# Automatically detect the separator in tabular data
#
# Joshua Randall, 6 May 2009.
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

my @seps = ('\t',
	    '\,',
	    '\ ',
	    '\;',
	    '\:',
	    '\|',
	    '[[:space:]]+');

my @seps2 = ();

my $DEBUG=0;
my $infile;

my $result = GetOptions( "in=s" => \$infile,
			 "verbose|v+" => \$DEBUG,
			 );

# Open file
my $infh = fzinopen($infile);

my @lines;
for(my $i=0; $i<10; $i++) {
    $lines[$i] = <$infh>;
    chomp $lines[$i];
}


print STDERR "have ".scalar(@seps)." separators to try [@seps]\n" if($DEBUG>0);
 SEP: foreach my $sep (@seps) {
     my $sepre = qr/$sep/;
     my $sepcols = -1;
     my $i = 0;
   LINE: foreach my $line (@lines) {
       $i++;
       my @cells = split(/$sepre/, $line, -1);
       print STDERR "$sep split line $i into [@cells]\n" if($DEBUG>1);
       my $cols = scalar(@cells);
       if($cols < 3) {
	   print STDERR "ruling out sep $sep -- too few columns\n" if($DEBUG>0);
	   next SEP;
       }
       if($sepcols == -1) {
	   $sepcols = $cols;
       } else {
	   if($cols != $sepcols) {
	       print STDERR "ruling out sep $sep -- different number of columns in line $i\n" if($DEBUG>0);
	       next SEP;
	   }
       }
   }
     # this sep made it through
     push @seps2, $sep;
 }

print STDERR "have ".scalar(@seps2)." valid separators [@seps2]\n" if($DEBUG>0);

if(@seps2 >= 1) {
    print $seps2[0];
}

