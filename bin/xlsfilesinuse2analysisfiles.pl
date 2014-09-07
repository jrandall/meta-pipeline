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


use Spreadsheet::ParseExcel;
use Data::Dumper;

my $DEBUG=20;

my $excel_file = shift;

print STDERR "parsing excel file $excel_file\n";
my $excel_book = Spreadsheet::ParseExcel::Workbook->Parse($excel_file);

print STDERR "examining sheets in workbook\n";
my %sheets;
foreach my $sheet (@{$excel_book->{Worksheet}}) {
    my $name = $sheet->{Name};
    print STDERR "found worksheet: $name\n" if($DEBUG>0);
    $sheets{$name} = $sheet;
}


foreach my $sheetname (grep {!/FileAttributes/} keys %sheets) {
    my $sheet = $sheets{$sheetname};
    print STDERR "processing worksheet $sheetname\n";
    my @headers = extract_row($sheet, 0);
    my $col=0;
    foreach my $header (@headers) {
	if($header =~ m/^[[:space:]]+$/) {
	    # blank header, skip
	} else {
	    print STDERR "processing $header on worksheet $sheetname\n";
	    my %files;
	    my @coldata = extract_column($sheet, $col);
	    my $cdheader = shift @coldata;
	    print STDERR "have column $cdheader plus ".scalar(@coldata)." cells of data [@coldata]\n" if($DEBUG>30);
	    if($cdheader eq $header) {
		foreach my $filename (@coldata) {
		    if(defined($filename)) {
			if($filename =~ m/^[[:space:]]*$/) {
			    print STDERR "name blank for this row\n" if($DEBUG>30);
			} else {
			    print STDERR "have $filename for $header column $col\n";
			    $files{$filename} = 1;
			}
		    } else {
			print STDERR "name not defined for this row\n" if($DEBUG>30);
		    }
		}
	    } else {
		die "error reading header: coldata[0] $cdheader, header $header\n";
	    }

	    print STDERR "opening $header.inputfiles.list for writing\n";
	    open OUT, ">$header.inputfiles.list";
	    foreach my $filename (sort keys %files) {
		print OUT "$filename\n";
	    }
	    close OUT;

	    print STDERR "opening $header.analysisfiles.list for writing\n";
	    open OUT, ">$header.analysisfiles.list";
	    foreach my $filename (sort keys %files) {
		$filename =~ s/\.txt$/.cleaned.add_maf_mac.txt/;
		print OUT "$filename\n";
	    }
	    close OUT;
	    $col++;
	}
    }
}






sub extract_row { # 0-based indicies
    my $sheet = shift;
    my $row = shift;
    my ($mincol, $maxcol) = $sheet->col_range();
    
    my @rowdata;
    foreach my $col ($mincol .. $maxcol) {
	my $cell = $sheet->get_cell($row,$col);
	if(defined($cell)) {
	    my $data = $cell->unformatted();
	    print STDERR "extract_row($sheet, $row): have data $data at column $col\n" if($DEBUG>30);
	    push @rowdata, $data;
	}
    }
    print STDERR "extract_row($sheet, $row): returning rowdata [@rowdata]\n" if($DEBUG>30);
    return(@rowdata);
}

sub extract_column { # 0-based indicies
    my $sheet = shift;
    my $col = shift;
    my ($minrow, $maxrow) = $sheet->row_range();
    
    my @coldata;
    foreach my $row ($minrow .. $maxrow) {
	my $cell = $sheet->get_cell($row,$col);
	if(defined($cell)) {
	    my $data = $cell->unformatted();
	    print STDERR "extract_column($sheet, $col): have data $data at row $row\n" if($DEBUG>30);
	    push @coldata, $data;
	}
    }

    print STDERR "extract_column($sheet, $col): returning coldata [@coldata]\n" if($DEBUG>30);
    return(@coldata);
}

sub extract_matrix { # 0-based indicies
    my $sheet = shift;
    my $minrow = shift;
    my $mincol = shift;
    my $maxrow = shift;
    my $maxcol = shift;
    
    my @matrix; # AoA [row][col]
    
    foreach my $row ($minrow .. $maxrow) {
	my @rowdata;
	foreach my $col ($mincol .. $maxcol) {
	    push @rowdata, $sheet->{Cells}[$row][$col]->{Val};
	}
	push @matrix, [@rowdata];
    }
    return(@matrix);
}

