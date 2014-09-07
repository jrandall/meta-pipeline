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

my $verbose=0;

my $infile;
my $outfile;
my $insep="\t";
my $outsep="\t";
my $relabelsep=":";
my $missing=".";
my $colorder;
my $onlylisted=0;
my $allrequired=0;
my @excludeheaders;
my @excludeheaderpats;
my @excludeheaderinvpats;
my @excludecolnums;

my $result = GetOptions( "in=s" => \$infile,
			 "out=s" => \$outfile,
			 "insep=s" => \$insep,
			 "outsep=s" => \$outsep,
			 "relabelsep=s" => \$relabelsep,
			 "colorder=s" => \$colorder,
			 "onlylisted=i" => \$onlylisted,
			 "allrequired=i" => \$allrequired,
			 "excludeheader=s" => \@excludeheaders,
			 "excludeheaderpat=s" => \@excludeheaderpats,
			 "excludeheaderinvpat=s" => \@excludeheaderinvpats,
			 "excludecolnum=s" => \@excludecolnums,
			 "missing=s" => \$missing,
			 "verbose+" => \$verbose,
			 );

if($missing =~ m/^[0-9]+$/) {
    die "Cannot use digits for missing string.\n";
}

my %excludecolheader;
foreach my $header (@excludeheaders) {
    $excludecolheader{$header} = 1;
}

my %excludecolnum;
foreach my $colnum (@excludecolnums) {
    $excludecolnum{$colnum} = 1;
}

# open files
my $infh = fzinopen($infile);
my $outfh = fzoutopen($outfile);

# process headers
my $headerline = <$infh>;
chomp $headerline;
$headerline =~ s/\r$//;
my @headers = split /$insep/,$headerline,-1;
my %headercol;
my %colheader;
my $col=0;
my %have;
foreach my $header (@headers) {
    $have{$col}=1;
    $colheader{$col} = $header;
    $headercol{$header} = $col;
    $col++;
    foreach my $headerpat (@excludeheaderpats) {
	if($header =~ m/$headerpat/) {
	    print STDERR "excluding $header based on headerpat $headerpat\n";
	    $excludecolheader{$header} = 1;
	}
    }
    foreach my $headerpat (@excludeheaderinvpats) {
	if(!($header =~ m/$headerpat/)) {
	    print STDERR "excluding $header based on headerinvpat $headerpat\n";
	    $excludecolheader{$header} = 1;
	}
    }
}
my $numcols = $col;

# parse requested column order and renaming
my @columns = split /\,/,$colorder,-1;
my @oldcolorder;
my @newheaders;
foreach my $oldnewheader (@columns) {
    my $oldheader;
    my $newheader;
    if($oldnewheader =~ m/$relabelsep/) {
	($oldheader, $newheader) = split /$relabelsep/,$oldnewheader,-1;
    } else {
	$oldheader = $oldnewheader;
	$newheader = $oldnewheader;
    }
    if(exists($headercol{$oldheader})) {
	my $oldcol = $headercol{$oldheader};
	$have{$oldcol}=0;
	push @oldcolorder,$oldcol;
	push @newheaders,$newheader;
     } elsif($oldheader eq $missing) {
        push @oldcolorder,$missing;
        push @newheaders,$newheader;
    } else {
	if($allrequired > 0) {
	    exit;
	} else {
	    print STDERR "Warning: header $oldheader not found!\n";
	}
    }
}

if($onlylisted == 0) { 
    foreach my $oldcol (sort {$a <=> $b} keys %have) {
	if($have{$oldcol} == 1) {
	    my $newheader = $colheader{$oldcol};
	    if(!exists($excludecolheader{$newheader}) && !exists($excludecolnum{$oldcol})) {
		push @oldcolorder,$oldcol;
		push @newheaders,$newheader;
		$have{$oldcol} = 0;
	    }
	}
    }
}

# output header
print $outfh join($outsep,@newheaders)."\n";

print STDERR "Outputting columns in order [@oldcolorder]\n" if($verbose>0);

# process the rest of the file
my $linenum = 2;
while(my $line = <$infh>) {
    chomp $line;
    $line =~ s/\r$//;
    my @data = split /$insep/,$line,-1;
    die "Line $linenum had unexpected number of entries. Expected $numcols, found ".scalar(@data)."\n" unless(@data == $numcols);
    print $outfh join($outsep,map {if($_ ne $missing) {$data[$_];} else {$_;}} @oldcolorder)."\n";
    $linenum++;
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

