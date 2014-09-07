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

my %gene; # gene data keyed on symbol

my $header = <>;
chomp $header;

foreach my $line (<>) {
    # NAME     CHR     STRAND  TXSTART TXEND   CDSSTART        CDSEND  EXONCOUNT       EXONSTARTS      EXONENDS        PROTEINID       ALIGNID MRNA    SPID    SPDISPLAYID     SYMBOL  REFSEQ  PROTACC DESCRIPTION
    chomp $line;
    my ($name, $chr, $strand, $txstart, $txend, $cdsstart, $cdsend, $exoncount, $exonstarts, $exonends, $proteinid, $alignid, $mrna, $spid, $spdisplayid, $symbol, $refseq, $protacc, $desc) = split(/\t/,$line);

    my $key = $symbol;

    # check if this key has been seen already
    if(exists($gene{$key})) {
	my $generef = $gene{$key}[0];
	if($generef->{strand} ne $strand) {
	    # make another name for the opposite strand?
	    $key .= $strand;
	}
    }
    
    # check if this (potentially new) key has been seen already 
    if(exists($gene{$key})) {
	my $generef = $gene{$key}[0];
	if($generef->{chr} ne $chr) {
	    $key .= "chr$chr";
	}
    }
    
    # build new record
    my %tmp;
    $tmp{symbol} = $symbol;
    $tmp{chr} = $chr;
    $tmp{txstart} = $txstart;
    $tmp{txend} = $txend;
    $tmp{strand} = $strand;
    $tmp{exonstarts} = $exonstarts;
    $tmp{exonends} = $exonends;
#    my ($name, $chr, $strand, $txstart, $txend, $cdsstart, $cdsend, $exoncount, $exonstarts, $exonends, $proteinid, $alignid, $mrna, $spid, $spdisplayid, $symbol, $refseq, $protacc, $desc)

    # once again check if this (potentially new) key has been seen already
    if(exists($gene{$key})) {
	print STDERR "already have this key ($key), checking for overlap...\n";
	# we've seen this key at least once before, check for overlap with other genes
	foreach my $generef (@{$gene{$key}}) {
	    if(($tmp{txstart} <= $generef->{txend} && $tmp{txend} >= $generef->{txstart}) || ($generef->{txstart} <= $tmp{txend} && $generef->{txend} >= $tmp{txstart})) {
		# this gene (generef) overlaps with generef, suck it in
		print STDERR "have overlap for $key: ".gene2str($generef)." and ".gene2str(\%tmp)."\n";
		if(($tmp{txstart} < $generef->{txstart})) {
		    # start of this gene is before the old one, extend it
		    $generef->{txstart} = $tmp{txstart};
		    # and add exon data (much will overlap, but we don't care)
		    $generef->{exonstarts} .= ",".$tmp{exonstarts};
		    $generef->{exonends} .= ",".$tmp{exonends};
		}
		if(($tmp{txend} > $generef->{txend})) {
		    # end of this gene is after the old one, extend it
		    $generef->{txend} = $tmp{txend};
		    # and add exon data (much will overlap, but we don't care)
		    $generef->{exonstarts} .= ",".$tmp{exonstarts};
		    $generef->{exonends} .= ",".$tmp{exonends};
		}
	    } else {
		# no overlap, add it for now (and re-check later)
		print STDERR "no overlap for $key: ".gene2str($generef)."\n";
		print STDERR "no initial overlap, adding key ($key)\n";
		push @{$gene{$key}},{ %tmp };
	    }
	}
    } else {
	# this is a new key
	print STDERR "adding new key ($key)\n";
	$gene{$key}[0] = { %tmp };
    }
}

print STDERR "\n\n\npruning remaining overlap!\n\n\n";

# now go through each key and prune the overlapping regions to their extents
foreach my $key (keys %gene) { # each of these genes will be unique for strand and chromosome -- we need only to eliminate overlapping genes
    print STDERR "processing key $key\n";
    my @remaininggenes = @{$gene{$key}};
    if(@remaininggenes > 1) {
	print STDERR "processing ".scalar(@remaininggenes)." genes matching $key\n";
	my @outgenes;
	while(my $generef = shift(@remaininggenes)) {
	    print STDERR "have generef $generef from remaininggenes\n";
	    my @othergenes = @remaininggenes;
	    @remaininggenes = ();
	    foreach my $generef2 (@othergenes) {
		print STDERR "have generef2 $generef2 from othergenes\n";
		if(($generef2->{txstart} <= $generef->{txend} && $generef2->{txend} >= $generef->{txstart}) || ($generef->{txstart} <= $generef2->{txend} && $generef->{txend} >= $generef2->{txstart})) {
		    print STDERR "sucking ".gene2str($generef)." into ".gene2str($generef2)."\n";
		    # this gene (generef2) overlaps with generef, suck it in
		    if(($generef2->{txstart} < $generef->{txstart})) {
			# start of this gene is before the old one, extend it
			$generef->{txstart} = $generef2->{txstart};
		    }
		    if(($generef2->{txend} > $generef->{txend})) {
			# end of this gene is after the old one, extend it
			$generef->{txend} = $generef2->{txend};
		    }
		} else {
		    print STDERR gene2str($generef)." does not overlap with ".gene2str($generef2)."\n";
		    # this gene (generef2) does not overlap with generef, put it back on the list of remaining genes
		    print STDERR "pushing generef2 $generef2 onto remaininggenes\n";
		    push(@remaininggenes,$generef2);
		}
	    }
	    # we've now sucked all genes overlapping with generef into it, put it on the output list
	    print STDERR "putting ".gene2str($generef)." on output list\n";
	    push(@outgenes, $generef); 
	    print STDERR "getting next remaininggene from ".scalar(@remaininggenes)." remaininggenes\n";
	}
	$gene{$key} = [ @outgenes ] ;
    }
}

print join("\t",("CHR","TXSTART","TXEND","STRAND","SYMBOL","EXONSTARTS","EXONENDS","uid"))."\n";
foreach my $key (keys %gene) {
    my $index = 0;
    foreach my $generef (@{$gene{$key}}) {
	my $keyandindex = $key."i".$index++;

        # prune the exon data
	my @exonstarts = split /,/,$generef->{exonstarts};
	my @exonends = split /,/,$generef->{exonends};
	my %startendhash;
	if(scalar(@exonstarts) == scalar(@exonends)) {
	    for(my $i=0; $i<=$#exonstarts; $i++) {
		my $startend = $exonstarts[$i].",".$exonends[$i];
		$startendhash{$startend} = 1;
	    }
	    @exonstarts = ();
	    @exonends = ();
	    foreach my $startend (sort keys %startendhash) {
		my ($start,$end) = split /,/,$startend;
		if($start ne "") {
		    push @exonstarts, $start;
		    push @exonends, $end;
		}
	    }
	} else {
	    die "different number of exon starts and ends for $generef->{symbol} ($keyandindex)\n";
	}
	print join("\t",($generef->{chr},$generef->{txstart},$generef->{txend},$generef->{strand},$generef->{symbol},join(",",@exonstarts),join(",",@exonends),$keyandindex))."\n";
    }
}

sub gene2str {
    my $generef = shift;
    return("symbol: $generef->{symbol} strand: $generef->{strand} chr: $generef->{chr} txstart: $generef->{txstart} txend: $generef->{txend}");
}
