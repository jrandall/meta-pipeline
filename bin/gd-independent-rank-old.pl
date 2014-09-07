#!/usr/bin/perl -w 

use strict;

use IO::File;
use IO::Uncompress::Gunzip;
use IO::Compress::Gzip;

use Tree::Binary::Search;

use Getopt::Long;

my $DEBUG=0;

my $metalfile;
my $outfile;
my $cutoff="0.1";
my $gmheader="Genetic_Map_cM_rel22";
my $chrheader;

my $tagrankheader="TagRank";
my $taglociheader="TagLoci";
my $tagdistheader="TagGD";

my $result = GetOptions( "metalfile=s" => \$metalfile,
			 "outfile=s" => \$outfile,
			 "cutoff=s" => \$cutoff,
			 "chrheader=s" => \$chrheader,
			 "gmheader=s" => \$gmheader,
			 "taglociheader=s" => \$taglociheader,
			 "tagrankheader=s" => \$tagrankheader,
			 "tagdistheader=s" => \$tagdistheader,
			 "verbose|v+" => \$DEBUG,
			 );


my $metalfh = fzinopen($metalfile);
my $outfh = fzoutopen($outfile);

# pass header line through
my $header = <$metalfh>;
chomp $header;
$| = 1; # autoflush
print $outfh "$header\t$taglociheader\t$tagrankheader\t$tagdistheader\n";

# find genetic distance column
my @headers = split(/\t/,$header);
my $n = 0;
my $gmheaderindex = -1;
my $chrheaderindex = -1;
foreach my $header (@headers) { 
    if($header eq "$gmheader") {
	$gmheaderindex = $n;
    }
    if($header eq "$chrheader") {
	$chrheaderindex = $n;
    }
    $n++;
}

if($gmheaderindex < 0) {
    die "could not find required header $gmheader!\n";
}

if($chrheaderindex < 0) {
    die "could not find required header $chrheader!\n";
}

my %chrleadsnps; # HoBTrees
my %locusgpos;
my %locusrank;
my $nindsnps=0;
my $nsnps=0;


my $compare_within_cutoff = sub { if(abs($_[0]-$_[1]) < $cutoff){return 0;} else {return ($_[0] <=> $_[1]);}};

LINE: foreach my $line (<$metalfh>) {
    chomp $line;
    my @data = split(/\t/,$line);
    if(!($#data >= $chrheaderindex && $#data >= $gmheaderindex)) {
	die "error reading line from input file -- only ".scalar(@data)." entries, but expecting column ".($chrheaderindex+1)." and ".($gmheaderindex+1)." saw [@data] for line [$line]\n";
    } else { # have enough columns on this line to work with
	my $rsid = $data[0];
	my $chr = $data[$chrheaderindex];
	my $gpos = $data[$gmheaderindex];
	
	print "processing $rsid\n" if($DEBUG>0);
	$nsnps++;
	
	if($gpos eq "." || $chr eq ".") {
	    # snp is missing gm info, just output it
	    print $outfh "$line\t.\t.\t.\n";
	    next LINE;
	}
	
	if(exists($chrleadsnps{$chr}) && $chrleadsnps{$chr}->exists($gpos)) {
	    my $leadsnp = $chrleadsnps{$chr}->select($gpos);
	    my $leadsnpgpos = $locusgpos{$leadsnp};
	    my $gdist = abs($leadsnpgpos-$gpos);
	    print STDERR "found leadsnp $leadsnp in tree: $gdist away from $rsid\n" if ($DEBUG>0);
	    $locusrank{$leadsnp}++;
	    print $outfh "$line\t$leadsnp\t$locusrank{$leadsnp}\t$gdist\n";
	} else {
	    # this is a new lead snp (on a new chr)
	    $nindsnps++;
	    
	    # check if this chromosome already has a search tree
	    if(! exists($chrleadsnps{$chr})) {
		# it does not, create tree
		print STDERR "creating binary search tree for chr $chr\n" if($DEBUG>1);
		my $btree = Tree::Binary::Search->new();
		$btree->setComparisonFunction($compare_within_cutoff);
		$chrleadsnps{$chr} = $btree;
	    }
	    
	    print STDERR "inserting $rsid at $gpos onto tree for chr $chr\n" if($DEBUG>1);
	    $chrleadsnps{$chr}->insert($gpos => $rsid);
	    $locusgpos{$rsid} = $gpos;
	    
	    #push @{$chrleadsnps{$chr}},$rsid;
	    $locusrank{$rsid} = 1;
	    print $outfh "$line\t$rsid\t1\t0\n";
	}
    }
}
$metalfh->close();

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

