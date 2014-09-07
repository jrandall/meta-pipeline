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
my $dontdelete=0;

my @infiles;
my $outfile;
my @header;

my @colseps;

my @skiprows;
my @colprefix;

my $outsep="\t"; 
my $outheader=1;
my $outnonmatchfile;
my $outmatchfile;
my $missing="";
my $keepall = 0;
my $tmpdir = "/tmp";
my $tmpsuffix = ".txt"; # change to .gz for compressed temp files

my @matchcolnums;
my @matchcolheaders; 
my @matchcols; 

my $matchcolprefix="";

# merges two data files, verifying matching of specified columns and adding columns new to the second file to the end of the columns in the first file
# loads files into memory, so be careful!
# 
# --matchcolnums is used to specify columns to key on for matching.  column numbers are specified for each input file, separated by colons.  if there are more input files than there are column numbers specified, the last specified column number is used for the remaining files.  therefore as a shortcut, one can just say "--matchcolnums=1" to key on the first column for all files.  the first (leftmost) column is number 1.
# --matchcolheaders works in the same way as --matchcolnums except that it takes the values from the first line of the file (header line)
# the file is assumed to have a header line unless --noheader is specified, in which case --matchcolheaders obviously won't work either
# --matchcols is used to specify columns to key on for matching, and works the same way as --matchcolnums or --matchcolheaders except you can use either column numbers or header values.  Program will assume that anything which matches a valid column number is a column number, and anything else is treated as a header value.
# --colsep specifies the column separators (\t by default) for each input file (in order -- note you must specify one for each file if you want to specify one for a later file -- the actual placement on the command line doesn't matter)
# --header specfiies a 0 or a 1 for each input file (1 by default) indicating whether or not a header is present in the file
# --skiprows specifies the number of rows to skip after the header (if present) and before processing the rest of the file. (default is 0 for all files)
# --outheader is a flag indicating whether or not to output a header line
# --colprefix specifies a prefix to prepend to column headers for each input file (as with other options it must be specified for every file if it is specified at all)
# --matchcolprefix specifies a prefix to prepend to column headers for matched columns (overrides colprefix so a value of "" for matchcolprefix (the default) will keep colprefix from affecting matched columns)
# --outnonmatchfile and --outmatchfile set a filename to which to output non-matching and matching keys, respectively.
# --missing specifies a code to use for missing data in a column
# --keepall specifies whether or not we want to keep all data from the first file, no matter what matches (keepall=1). Uses missing values for missing data.
#
# usage example: merge-tsv.pl --in=onefilename.txt --colsep="\t" --in=twofilename.txt --colsep=" " --out=out.txt.gz --matchcolnums=1:1 --matchcolnums=3:3 --matchcolnums=4:4 
#            or: merge-tsv.pl --in=onefilename.txt --in=twofilename.txt --out=out.txt.gz --matchcolheaders=chr:chr --matchcolheaders=rsid:id --matchcolheaders=foo:bar


#
# Known limitations: 
#   - you can't use ':' in column names -- workaround is to match by column number instead in this case.  could add escape handling to allow for this.
#   - memory consumption is high since all files are loaded in memory.  could add option for pre-sorting and then intelligent incremental stepping (a la merge-giant.pl)
#   - there is no facility for subsetting by column (all of the columns are output).  workaround is to cut the file after creating it, but this feature should be added by using similar options to --match* with --skip* and --include*
#   - there is no facility for other-than full matching between columns.  could implement regex matching or allow matching logic that allows a match between one of two or more columns
#   - does not check to make sure the output delimiter does not occur within any of the field.  the output delimiter should probably be escaped (perhaps to it's ascii code?)

my $result = GetOptions( "in=s" => \@infiles,
			 "out=s" => \$outfile,
			 "matchcolnums=s" => \@matchcolnums,
			 "matchcolheaders=s" => \@matchcolheaders,
			 "matchcols=s" => \@matchcols,
			 "colsep=s" => \@colseps,
			 "outsep=s" => \$outsep,
			 "header=s" => \@header,
			 "skiprows=i" => \@skiprows,
			 "outheader=i" =>\$outheader,
			 "colprefix:s" => \@colprefix,
			 "outnonmatchfile=s" => \$outnonmatchfile,
			 "outmatchfile=s" => \$outmatchfile,
			 "missing=s" => \$missing,
			 "keepall=i" => \$keepall,
			 "matchcolprefix=s" => \$matchcolprefix,
			 "tmpdir=s" => \$tmpdir,
			 "dontdelete+" => \$dontdelete,
			 "verbose|v+" => \$DEBUG,
			 );

my $tmpfile = $tmpdir."/merge-col-lowmem.".$$.".DBMDeeplarge";
print STDERR "Using temporary DBM file $tmpfile\n";

# open files
my @infh;
foreach my $filename (@infiles) {
    my $fh = fzinopen($filename);
    push @infh,$fh;
}
my $outfh = fzoutopen($outfile);
my $infile_count = @infh;

my @matchpatterns;
# add specified matchcolnums to matching array, padding them out with the last value as necessary
foreach my $matchcolnums (@matchcolnums) {
    my @colnums = split /\:/,$matchcolnums;
    if(@colnums < $infile_count) {
	my $repeatcolnum = $colnums[$#colnums];
	foreach(@colnums+1..$infile_count) { 
	    push @colnums,$repeatcolnum;
#	    print STDERR "adding $repeatcolnum\n";
	}
    }
    if(@colnums == $infile_count) {
#	print STDERR "have matchpattern @colnums\n";
	push @matchpatterns,[ @colnums ];
    } else {
	die "Tried to use @colnums column numbers for $infile_count files in matching parameter $matchcolnums\n";
    }
}

my %headercols;
my %header2col;
my %col2header;
# first process header line in all files (if the header option is set and equal to 1 for each)
my $filenum=0;
foreach my $fh (@infh) {
    if(!defined($header[$filenum]) || ($header[$filenum] == 1)) {
	print "Processing header line for file $filenum ($infiles[$filenum])...\n";
	my $line = <$fh>;
	my $colsep = $colseps[$filenum] || "\t";
	chomp $line;
	$line =~ s/\r$//g;
	print "Using column separator $colsep [".ord($colsep)."] for input file $filenum.\n";
	my @cols = split /$colsep/,$line;
	$headercols{$filenum} = [ @cols ];
	
	# add each colnum / header value to lookup hashes
	my $colnum = 1;
	foreach my $header (@cols) {
	    $header2col{$filenum}{$header} = $colnum;
	    $col2header{$filenum}{$colnum} = $header;
	    print STDERR "Added $colnum = $header for file number $filenum\n" if($DEBUG);
	    $colnum++;
	}
	
	if($DEBUG) {
	    print STDERR "header to column number mapping for input file $filenum: \n";
	    foreach(keys %{$header2col{$filenum}}) {
		print STDERR "$_ = ".$header2col{$filenum}{$_}."\n";
	    }
	}
	
	# skip rows if skiprows is set for this file
	my $rowstoskip = $skiprows[$filenum] || 0;
	for my $row (1..$rowstoskip) {
	    print "Skipping row in file $filenum!\n";
	    my $line = <$fh>;
	    print STDERR "Row skipped was: $line\n" if($DEBUG);
	}
    } else {
	print "Not parsing header for file $filenum... reading ahead to find number of columns.\n";
	# read ahead to determine number of columns, and insert blanks where headers would be, then rewind file
	my $line = <$fh>;
	my $colsep = $colseps[$filenum] || "\t";
	chomp $line;
	$line =~ s/\r$//g;
	print "Using column separator $colsep [".ord($colsep)."] for input file $filenum.\n";
	my @cols = split /$colsep/,$line;
	my @fakeheadercols = ();
	for my $colnum (1..@cols) {
	    my $fakeheader = "FILE".$filenum."_COL".$colnum;
	    push @fakeheadercols,$fakeheader;
	    $header2col{$filenum}{$colnum} = $colnum;
	    $col2header{$filenum}{$colnum} = $fakeheader;
	}
	$headercols{$filenum} = [ @fakeheadercols ];
	$fh->close();
	$infh[$filenum] = fzinopen($infiles[$filenum]);
    }
    $filenum++;
}

# lookup matchcolheaders arguments and add the column matches to the matchpatterns
foreach my $matchcolheaders (@matchcolheaders) {
    my @colheaders = split /\:/,$matchcolheaders;
    if(@colheaders < $infile_count) {
	my $repeatcolheader = $colheaders[$#colheaders];
	foreach(@colheaders+1..$infile_count) { 
	    push @colheaders,$repeatcolheader;
	}
    }
    if(@colheaders == $infile_count) {
	# map headers to colnums by looking them up
	my $filenum=0;
	my @colnums = map { $header2col{$filenum++}{$_} } @colheaders;
	push @matchpatterns,[ @colnums ];
    } else {
	die "Tried to use @colheaders column headers for $infile_count files in matching parameter $matchcolheaders\n";
    }
}

# lookup matchcols arguments and add the column matches to the matchpatterns
foreach my $matchcols (@matchcols) {
    my @cols = split /\:/,$matchcols;
    if(@cols < $infile_count) {
	my $repeatcolheader = $cols[$#cols];
	foreach(@cols+1..$infile_count) { 
	    push @cols,$repeatcolheader;
	}
    }
    if(@cols == $infile_count) {
	my @colnums;
	for my $filenum (0..$#infh) {
	    my $val = $cols[$filenum];
	    if(defined($header2col{$filenum})) {
		if($header2col{$filenum}{$val}) { 
		    print "Looked up column number $header2col{$filenum}{$val} for $val in input file $filenum\n";
		    push @colnums,$header2col{$filenum}{$val};
		} else { 
		    if($col2header{$filenum}{$val}) {
			print "Found column number $val in input file $filenum\n";
			push @colnums,$val;
		    } else {
			die "Could not find column number for header $val in input file $filenum\n";
		    }
		}
	    }
	}
    	if($DEBUG) {
	    print STDERR "adding ";
	    foreach(@colnums) {
		print STDERR "$_ ";
	    }
	    print STDERR " to matchpatterns\n"; 
	}
	push @matchpatterns,[ @colnums ];
    } else {
	die "Tried to use @cols column headers for $infile_count files in matching parameter $matchcols\n";
    }
}

# Verify we have some patterns and that they all address valid column numbers, and store a list of columns being matched for each file
my $match_count = @matchpatterns;
my %filenummatchcols;
print STDERR "Have $match_count match patterns\n" if($DEBUG);
for my $i (0..$#matchpatterns) {
    for(my $filenum=0; $filenum<@infh; $filenum++) {
	if($matchpatterns[$i][$filenum]) {
	    print STDERR "$matchpatterns[$i][$filenum] " if($DEBUG);
	    if($col2header{$filenum}{$matchpatterns[$i][$filenum]}) {
		print "Found column $matchpatterns[$i][$filenum] for input file number $filenum (header was $col2header{$filenum}{$matchpatterns[$i][$filenum]}\n";
		$filenummatchcols{$filenum}{$matchpatterns[$i][$filenum]} = 1;
	    } else {
		die "No column $matchpatterns[$i][$filenum] found for input file number $filenum\n";
	    }
	} else {
	    die "Have no entry for input file number $filenum.\n";
	}
    }
    print STDERR "\n" if($DEBUG);
}
die "Did not specify key columns for merge!\n" unless $match_count>0;

if($outheader == 1) {
# output header line
# first output the whole header from the first file (but uses matchcolprefix for match columns instead of colprefix) 
    if($colprefix[0] && !($colprefix[0] eq "")) {
	my @headers = @{$headercols{0}};
	my @outheaders;
	for(my $n=0; $n<@headers; $n++) {
	    if($filenummatchcols{0}{$n+1}) {
		print STDERR "have matchcol $n, using matchcolprefix ($matchcolprefix) as prefix for that column ($headers[$n])\n";
		push @outheaders,$matchcolprefix.$headers[$n];
	    } else {
		push @outheaders,$colprefix[0].$headers[$n];
	    }
	}
	print $outfh join($outsep,@outheaders);
    } else {
	my @headers = @{$headercols{0}};
	my @outheaders;
	for(my $n=0; $n<@headers; $n++) {
	    if($filenummatchcols{0}{$n+1}) {
		print STDERR "have matchcol $n, using matchcolprefix ($matchcolprefix) as prefix\n";
		push @outheaders,$matchcolprefix.$headers[$n];
	    } else {
		push @outheaders,$headers[$n];
	    }
	}
	print $outfh join($outsep,@outheaders);
    }
    for my $filenum (1..$#infh) {
	# now output everything that is not a match field for each additional file}
	my @outcols = ();
	for my $colnum (1..@{$headercols{$filenum}}) {
	    if(!$filenummatchcols{$filenum}{$colnum}) { 
		print STDERR "Including column $colnum for file number $filenum\n" if($DEBUG);
		if($colprefix[$filenum] && !($colprefix[$filenum] eq "")) {
		    push @outcols, $colprefix[$filenum].$col2header{$filenum}{$colnum};
		} else {
		    push @outcols, $col2header{$filenum}{$colnum};
		}
	    } else {
		print STDERR "Excluding column $colnum for file number $filenum\n" if($DEBUG);
	    }
	}
	print $outfh $outsep;
	print $outfh join($outsep,@outcols);
    }
    print $outfh "\n";
}    

# remember the first file ordering in an array
my @original_matchhash_order;

# remember what keys we saw in the first file
my %matchhash_in_first_file;
my %matchhash_all;
my @tmpfiles;

# sort all files to disk in matchhash order
for my $filenum(0..$#infh) {
    print STDERR "Sorting input file $filenum...\n";
    my $fh = $infh[$filenum];
    # suck in data for this file only -- used to sort and spit back out
    my %data; 
FILELINE:    while(my $line = <$fh>) {
	chomp $line;
	$line =~ s/\r$//g;
	my $colsep = $colseps[$filenum] || "\t";
	my @cols = split /$colsep/,$line;
	# add this row's data to a hash on the match parameters
	my $matchhash="";
	for my $i (0..$#matchpatterns) {
	    print STDERR "adding $cols[$matchpatterns[$i][$filenum]-1] to hash pattern $matchhash for filenum $filenum pattern $i\n" if($DEBUG>1);
	    $matchhash .= $cols[$matchpatterns[$i][$filenum]-1]."x";
	}
	
	if($filenum==0) {
	    # record seeing this set of keys
	    $matchhash_in_first_file{$matchhash}=1;
	    # save first file ordering
	    push @original_matchhash_order, $matchhash;
	} elsif($filenum>0) {
	    # optimization to check if this match is in file 0 before proceeding (optimize memory for shorter first files, tradeoff is speed of this hash lookup)
	    if(!exists($matchhash_in_first_file{$matchhash})) {
		next FILELINE;
	    }
	}

	$matchhash_all{$matchhash}[$filenum] = 1;
	
	print STDERR "adding match hash $matchhash for filenum $filenum\n" if($DEBUG);
	if(!$data{$matchhash}[0]) {
	    $data{$matchhash}[0] = [ @cols ];
	} else {
	    my $numexisting = @{$data{$matchhash}};
	    print STDERR "Already have $numexisting rows for $matchhash $filenum.  Appending another row to this hash.\n" if($DEBUG);  
	    $data{$matchhash}[$numexisting] = [ @cols ];
	}
    }
    $fh->close();
    # sort and output the data for this file to a temporary file
    $tmpfiles[$filenum] = $tmpdir."/merge-col.$$.file".$filenum.$tmpsuffix;
    print "outputting sorted data from file $filenum to $tmpfiles[$filenum]\n";
    my $sortedfh = fzoutopen($tmpfiles[$filenum]);
    foreach my $matchhash (@original_matchhash_order) {
	if(exists($data{$matchhash})) {
	    if($filenum == 0) {
		if(my $rowdata = shift(@{$data{$matchhash}})) {
#	    print STDERR "have ".scalar(@{$data{$matchhash}})." data rows for matchhash $matchhash in file $filenum\n" if($DEBUG>2);
#	    foreach my $rowdata (@{$data{$matchhash}}) { 
		    print $sortedfh join($outsep, ($matchhash, @{$rowdata}))."\n";
		} else {
		    die "no more data for matchhash $matchhash in file $filenum!\n";
		}
#	    }
	    } else {
		# file other than file 0
		my $rowdata = $data{$matchhash}[0];
		print $sortedfh join($outsep, ($matchhash, @{$rowdata}))."\n";
	    }
	} else {
	    # this file did not have this key, but output just the matchhash anyway
	    print STDERR "did not have match for matchhash $matchhash in file $filenum, outputting key only\n" if($DEBUG>2);
	    print $sortedfh join($outsep, ($matchhash))."\n";
	}
    }
    $sortedfh->close();
}


my $total_records = keys %matchhash_in_first_file;
print STDERR "have $total_records total different records\n";

my %matching_records;
my %nonmatching_records; 
RECORD: foreach my $key (keys %matchhash_all) {
    print STDERR "\nchecking $key for file 0..." if ($DEBUG);
    my $record = $matchhash_in_first_file{$key};
    if(!$record) {
	$nonmatching_records{$key}=1;
	next RECORD;
    } else { # we have a record in file 0
	if($keepall == 1) { 
            # if keepall == 1, we want to keep all from file 0 whether or not they match!
	    $matching_records{$key}=1;
	    next RECORD;
	} 
    }
    print STDERR " have in 0 " if($DEBUG);
    for my $filenum (1..$#infh) {
	print STDERR "checking $filenum..." if($DEBUG);
	if(!($matchhash_all{$key}[$filenum])) {
	    print STDERR "match failed for $filenum " if($DEBUG);
	    $nonmatching_records{$key}=1;
	    next RECORD;	
	} 
	print STDERR " have in $filenum" if($DEBUG); 
    }
    $matching_records{$key}=1;
}

my $matching_record_count = keys %matching_records;
print STDERR "have $matching_record_count matching records\n";

if(defined($outmatchfile) && !($outmatchfile eq "")) {
    my $fh = fzoutopen($outmatchfile);
    foreach(keys %matching_records) {
	print $fh "$_\n";
    }
    $fh->close();
}

my $nonmatching_record_count = keys %nonmatching_records;
print STDERR "have $nonmatching_record_count non-matching records\n";

if(defined($outnonmatchfile) && !($outnonmatchfile eq "")) {
    my $fh = fzoutopen($outnonmatchfile);
    foreach(keys %nonmatching_records) {
	print $fh "$_\n";
    }
    $fh->close();
}


# Open (sorted) temporary files for reading
my @tmpfh;
foreach my $filename (@tmpfiles) {
    my $fh = fzinopen($filename);
    push @tmpfh,$fh;
}


my @current_row;

sub get_next_data {
    my $fn = shift;
    my $fh = $tmpfh[$fn];
    if(my $line = <$fh>) {
	chomp $line;
	my ($matchkey, @cols) = split /$outsep/, $line;
	my %row;
	$row{key} = $matchkey;
	$row{data} = [@cols];
	return(\%row);
    } else {
	return(); 
    }
}    

sub wind_file_to_key {
    my $fn = shift;
    my $key = shift;
    my $rowswound=0;
    while(exists($current_row[$fn]{key}) && ($current_row[$fn]{key} ne $key)) {
	$current_row[$fn] = get_next_data($fn);
	$rowswound++;
    }
    return($rowswound);
}

# process first line from all files
foreach my $filenum (0..$#infh) {
    $current_row[$filenum] = get_next_data($filenum);
    print "have first line from filenum $filenum for key ".$current_row[$filenum]{key}." data is: ".$current_row[$filenum]{data}."\n" if($DEBUG);
}

# start with data from first file (keep multiple rows even if they have the same keys)
while(defined($current_row[0]{key})) {
    my $key = $current_row[0]{key};
    if(!$matching_records{$key}) { # this row does not match, skip it
	$current_row[0] = get_next_data(0);
    } else { # this row does match, assemble and output it
	print STDERR "outputting $key\n" if($DEBUG);
	# output first file data first
	print $outfh join($outsep, @{$current_row[0]{data}});
	# now assemble other file data, or missing values, for requested columns 
	for my $filenum (1..$#infh) {
	    # wind this file forward to this key (or stay where we are if we are already there)
	    my $rowswound = wind_file_to_key($filenum, $key);
	    print STDERR "wound file $filenum ahead $rowswound rows\n" if($DEBUG); 
	    my @outcols = ();
	    for my $colnum (1..@{$headercols{$filenum}}) {
		if(!$filenummatchcols{$filenum}{$colnum}) { # only output columns that were not match columns
		    if(defined($current_row[$filenum]{data}[$colnum-1])) { # changed from nonzero test to defined test
			print STDERR "including $colnum for file $filenum (key $key, row 0) for file $filenum $current_row[$filenum]{data}[$colnum-1]\n" if($DEBUG>1);
			push @outcols, $current_row[$filenum]{data}[$colnum-1];
		    } else {
			print STDERR "including missing value for $colnum for file $filenum (key $key).\n" if($DEBUG>1);
			push @outcols, "$missing";
		    }
		}
	    }
	    print $outfh $outsep;
	    print $outfh join($outsep, @outcols);
	}
	print $outfh "\n";
	# go to next input line
	$current_row[0] = get_next_data(0);
    }
}



# close temporary files
foreach my $fh (@tmpfh) {
    $fh->close();
}

# delete temporary files
if($dontdelete == 0) {
    foreach my $filename (@tmpfiles) {
	unlink($filename);
    }
}

# close output file
$outfh->close();


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

