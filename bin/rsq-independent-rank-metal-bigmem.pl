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

my $verbose;

my $metalfile;
my $rsqfile;
my $outfile;
my $cutoff="0.8";

my $result = GetOptions( "metalfile=s" => \$metalfile,
			 "rsqfile=s" => \$rsqfile,
			 "outfile=s" => \$outfile,
			 "cutoff=s" => \$cutoff,
			 "verbose" => \$verbose,
			 );


my $metalfh = fzinopen($metalfile);
my $outfh = fzoutopen($outfile);

# pass header line through
my $header = <$metalfh>;
chomp $header;
$| = 1; # autoflush
print $outfh "$header\tTagLoci\tTagRank\tTagRsq\n";

# attempt to load entire rsq database into hash
my %rsq = {};
my $rsqfh = fzinopen($rsqfile);
print "processing rsq entries into hash\n" if($verbose);
while(my $line = <$rsqfh>) {
    chomp $line;
    my ($rsid1, $rsid2, $rsq) = split(/[[:space:]]/,$line);
    if($rsq >= $cutoff) {
	$rsq{$rsid1}{$rsid2} = $rsq;
	$rsq{$rsid2}{$rsid1} = $rsq;
    } else {
	print STDERR "rsq below cutoff for $rsid1==$rsid2 (rsq=$rsq)\n" if($verbose); 
    }
    undef $rsid1;
    undef $rsid2;
    undef $rsq;
}
$rsqfh->close();
undef $rsqfh;
print "done processing rsq entries into hash\n" if($verbose);

my %seen;
my %loci;
my %rank;
my $nindsnps=0;
foreach my $line (<$metalfh>) {
    chomp $line;
    my ($rsid,$chaff) = split(/\t/,$line);
    print "processing $rsid\n" if($verbose);
    if(!defined($seen{$rsid})) {
	# increment counter
	$nindsnps++;
	# record seeing this SNP
	$seen{$rsid} = 1.0;
	$loci{$rsid} = $rsid;
	$rank{$rsid} = 1;	
        # print this line
	print $outfh "$line\t$rsid\t$rank{$rsid}\t$seen{$rsid}\n";
	# look up proxies for this SNP and record seeing them as well
#	my $rsqfh = fzinopen($rsqfile);
	print "processing rsq entries to find proxies for $rsid\n" if($verbose);
	foreach my $rsid2 (keys %{$rsq{$rsid}}) {
#	while(my $line = <$rsqfh>) {
#	    if($line =~ m/$rsid[^[:alnum:]]/) {
#		chomp $line;
#		my ($rsid1, $rsid2, $rsq) = split(/[[:space:]]/,$line);
	    my $rsid1 = $rsid;
	    my $rsq = $rsq{$rsid1}{$rsid2};
#		if($rsq >= $cutoff) {
#		    print STDERR "storing $rsid1==$rsid2 with rsq=$rsq\n" if($verbose); 
#		    if($rsid eq $rsid1) {
	    $seen{$rsid2} = $rsq;
	    $loci{$rsid2} = $rsid;
#		    } elsif($rsid eq $rsid2) {
#			$seen{$rsid1} = $rsq;
#			$loci{$rsid1} = $rsid;
#		    } else {
#			die "error!  saw $rsid1 and $rsid2 when looking for $rsid\n";
#		    }
#		} else {
#		    print STDERR "rsq below cutoff for $rsid1==$rsid2 (rsq=$rsq)\n" if($verbose); 
#		}
		undef $rsid1;
		undef $rsid2;
		undef $rsq;
#	}
#	    undef $line;
	}
#	$rsqfh->close();
#	undef $rsqfh;
    } else {
	print STDERR "already saw $rsid represented by $loci{$rsid} with rsq = $seen{$rsid}\n" if($verbose); 
	if($loci{$rsid} eq $rsid) {
	    # this SNP has already been output
	    print STDERR "skipping $rsid since it has already been output\n" if($verbose); 
	} else {
	    $rank{$loci{$rsid}} = $rank{$loci{$rsid}} + 1;
	    print $outfh "$line\t$loci{$rsid}\t$rank{$loci{$rsid}}\t$seen{$rsid}\n";
	}
    }
}
$metalfh->close();

my $nsnps = keys %seen;
print STDERR "Output $nindsnps independent SNPs representing $nsnps total SNPs\n";
exit(0);


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
