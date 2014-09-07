#######################################################################################
# Copyright 2008 Joshua Randall
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
#######################################################################################
#!/usr/bin/perl -w

use strict;
use List::Util qw(max);

use IO::File;
use IO::Uncompress::Gunzip;
use IO::Compress::Gzip;

use Getopt::Long;

my $scriptcentral_path = "/home/jrandall/scriptcentral";
if(exists($ENV{SCRIPTCENTRAL})) {
    $scriptcentral_path = $ENV{SCRIPTCENTRAL};
}
require "$scriptcentral_path/fzinout.pl";

my $DEBUG=0;

my $infile = "";
my $knowngenesfile="";
my $outfile = "";

my $outheaderprefix="NEAREST_GENE_";

my $markerheaderpat = "^Marker";
my $chrheaderpat = "^CHR";
my $posheaderpat = "^POS";

my $insep = "\t";
my $kgsep = "\t";
my $outsep = "\t";

my $missing = ".";

my @avoidres = ();


my $result = GetOptions( "in=s" => \$infile,
			 "knowngenes=s" => \$knowngenesfile,
			 "out=s" => \$outfile,
			 "outheaderprefix=s" => \$outheaderprefix,
			 "markerheaderpat=s" => \$markerheaderpat,
			 "chrheaderpat=s" => \$chrheaderpat,
			 "posheaderpat=s" => \$posheaderpat,
			 "insep=s" => \$insep,
			 "knowngenesep=s" => \$kgsep,
			 "outsep=s" => \$outsep,
			 "missing=s" => \$missing,
			 "avoidre=s" => \@avoidres,
			 "verbose|v+" => \$DEBUG,
			 );

print STDERR "DEBUG level $DEBUG\n" if($DEBUG>0);
print STDERR "have RE's to avoid [@avoidres]\n";

my %map;

# open input files
my $infh = fzinopen($infile);
my $kgfh = fzinopen($knowngenesfile);

# open output file
my $outfh = fzoutopen($outfile);


# load snp positions into hashes
my %snpchr;
my %snppos;

my $headerline = <$infh>;
chomp $headerline;

my %header2index;
my @headers = split /$insep/, $headerline, -1;
for(my $n=0; $n<=$#headers; $n++) {
    $header2index{$headers[$n]} = $n;
}

print STDERR "Found ".scalar(keys %header2index)." column headers in input\n";

my @markerheader = grep {/$markerheaderpat/i} keys %header2index;
my @chrheader = grep {/$chrheaderpat/i} keys %header2index;
my @posheader = grep {/$posheaderpat/i} keys %header2index;

if(@markerheader < 1 || @chrheader < 1 || @posheader < 1) {
    die "Could not find Marker, CHR, and POS in input file $infile\n";
}

if(@markerheader > 1 || @chrheader > 1 || @posheader > 1) {
    die "Found ".scalar(@markerheader)." headers matching $markerheaderpat ".scalar(@chrheader)." headers matching $chrheaderpat and ".scalar(@posheader)." headers matching $posheaderpat\n";
}

my $markercol = $header2index{$markerheader[0]};
my $chrcol = $header2index{$chrheader[0]};
my $poscol = $header2index{$posheader[0]};

print STDERR "Found marker column $markercol, chr column $chrcol, pos column $poscol\n";

my $maxcol = max($markercol, $chrcol, $poscol);

# process metal output
my %metal;
my %metalchrpos;
while(my $line = <$infh>) {
    chomp $line;
    my @data = split /$insep/, $line, $maxcol+1;
    my $snpid = $data[$markercol];
    my $chr = $data[$chrcol];
    my $pos = $data[$poscol];
    $chr =~ s/^chr//i;
    $chr =~ s/^0//;
    if(defined($chr) && defined($pos)) {
	push @{$metal{$snpid}}, $line;
	if(!(($chr eq $missing) || ($pos eq $missing))) {
	    # add if not missing
	    $snppos{$snpid} = $pos;
	    $snpchr{$snpid} = $chr;
	    push @{$metalchrpos{$chr}}, $pos;
	}
    } else {	
	if(!defined($chr)) {
	    print STDERR "could not find chr for snpid $snpid\n";
	} 
	if(!defined($pos)) {
	    print STDERR "could not find pos for snpid $snpid\n";
	} 
	push @{$metal{$snpid}}, $line;
	#die "giving up on snpid $snpid!\n";
    }
}
close $infh;


my @snpids = keys %metal;
my $nsnpids = @snpids;
print STDERR "have $nsnpids snpids from metal\n";
my @chrs = sort keys %metalchrpos;
print STDERR "saw chrs @chrs \n";

foreach my $chr (keys %metalchrpos) {
    print STDERR "have ".scalar(@{$metalchrpos{$chr}}). " snp positions on chr $chr\n";
}

# load known genes
# CHR START STOP STRAND GENE
my %gene;
#my %chrposlist;
my %genepos;
my %gene2description;
my %gene2refseq;
my %gene2strand;
my %gene2genesymbol;
<$kgfh>;
print STDERR "processing known genes file...\n";
 GENE: while(my $line = <$kgfh>) {
     chomp $line;
     # name-chr-txStart-txEnd-strand-geneSymbol-refSeq-description
     my ($gene, $chr, $start, $stop, $strand, $gene_symbol, $refseq_name, $description) = split /$kgsep/, $line; 
     foreach my $avoidre (@avoidres) {
	 if($gene_symbol =~ m/$avoidre/i) {
	     next GENE;
	 }
     }
     $chr =~ s/^chr//g;
     $start+=1;
     $stop+=1;
     
     $gene2strand{$gene} = $strand;
     $gene2genesymbol{$gene} = $gene_symbol;
     $gene2refseq{$gene} = $refseq_name;
     $gene2description{$gene} = $description;
     
     my $numpos;
     if($DEBUG > 0) {
	 if(defined($genepos{$chr})) {
	     $numpos = @{ $genepos{$chr} };
	 } else {
	     $numpos = 0;
	 }
     }
     push @{ $genepos{$chr} }, $start;
     push @{ $genepos{$chr} }, $stop;
     push @{ $gene{$chr}{$start} }, $gene;
     push @{ $gene{$chr}{$stop} }, $gene;
     if($DEBUG > 0) {
	 my $newnumpos;
	 if(defined($genepos{$chr})) {
	     $newnumpos = @{ $genepos{$chr} };
	 } else {
	     $newnumpos = 0;
	 }
	 print STDERR "have gene $gene on $chr from $start to $stop ($strand) (numpos $numpos newnumpos $newnumpos)\n";
     } else {
	 print STDERR "have gene $gene on $chr from $start to $stop ($strand)\n";
     }
     # get snp positions for this chr
     if (defined($metalchrpos{$chr})) {
	 map {push @{$gene{$chr}{$_}}, $gene} grep {(($start < $_) && ($_ < $stop))} @{ $metalchrpos{$chr} };
     }
 }
close $kgfh;
print STDERR "done processing known genes..\n";

foreach my $chr (keys %gene) {
    print STDERR "have ".scalar(keys %{$gene{$chr}})." gene positions on chr $chr\n";
}

print $outfh join($outsep,$headerline,$outheaderprefix."DISTANCE",$outheaderprefix."SYMBOLS",$outheaderprefix."REFSEQS",$outheaderprefix."DESCRIPTIONS")."\n";
foreach my $snpid (keys %metal) {
    print STDERR "processing: $snpid\n" if ($DEBUG > 1);
    foreach my $line (@{$metal{$snpid}}) { # allow multiple lines for the same SNP 
	my $chr = $snpchr{$snpid};
	my $pos = $snppos{$snpid};

	if(!(defined($chr))) {
	    print STDERR "chr not defined for $snpid\n" if($DEBUG > 0); 
	    $chr = $missing;
	}
	
	if(!(defined($pos))) {
	    print STDERR "pos not defined for $snpid\n" if($DEBUG > 0); 
	    $pos = $missing;
	}

	print STDERR "$snpid is at chr $chr, pos $pos\n" if ($DEBUG > 1);
	
	my $nearestdistance = 1000000000000;
	my $nearestpos = 0;
	if(!(($chr eq $missing) || ($pos eq $missing))) {
	    if(defined($gene{$chr}{$pos})) {
		# we are inside a gene
		print STDERR "$snpid is inside a gene: $gene{$chr}{$pos}\n" if ($DEBUG >2);
		$nearestdistance = 0;
		$nearestpos = $pos;
	    } else {
		# find the nearest gene (start/end)
		print STDERR "$snpid is not inside a gene, finding nearest gene\n" if ($DEBUG >2);
		foreach my $geneposition (@{$genepos{$chr}}) {
		    my $distance = abs($geneposition-$pos);
		    if($distance < $nearestdistance) {
			$nearestdistance = $distance;
			$nearestpos = $geneposition;
		    }
		}
	    }
	    
	    print STDERR "nearest gene to $snpid is nearestdistance $nearestdistance, nearestpos $nearestpos\n" if ($DEBUG > 1);
	    
	    
	    if(defined($gene{$chr}{$nearestpos})) {
		my @genelist = @{ $gene{$chr}{$nearestpos} };
		print STDERR "see a list of genes at $chr $pos -- @genelist\n" if($DEBUG > 2);
		
		my $genesymbols="";
		my $generefseqs="";
		my $genedescriptions="";
		my $genecount = 0;
		foreach my $gene (@genelist) {
		    my $genesymbol = $gene2genesymbol{$gene} || $missing;
		    my $generefseq = $gene2refseq{$gene} || $missing;
		    my $genedescription = $gene2description{$gene} || $missing;
		    if($genecount++ == 0) {
			$genesymbols .= $genesymbol;
			$generefseqs .= $generefseq;
			$genedescriptions .= $genedescription;
		    } else {
			$genesymbols .= ",".$genesymbol;
			$generefseqs .= ",".$generefseq;
			$genedescriptions .= ",".$genedescription;
		    }
		}
		print $outfh join($outsep, $line, $nearestdistance, $genesymbols, $generefseqs, $genedescriptions)."\n";
	    } else {
		#die "could not find gene at $chr $nearestpos\n";
		print $outfh join($outsep, $line, $missing, $missing, $missing, $missing)."\n";
	    }
	} else {
	    print $outfh join($outsep, $line, $missing, $missing, $missing, $missing)."\n";
	}
    }
}

