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

################################################################################
# generate-paramdefs-makefile.pl
# 
# Processes specified goals and list of parameter definitions to create lists of values
#
# Original version: Joshua Randall, 6 May 2009.
# Last modified: 6 December 2009
# 
################################################################################
use strict;

use IO::File;
use IO::Uncompress::Gunzip;
use IO::Compress::Gzip;

use Text::EscapeDelimiters;
use Text::DelimMatch;

use Getopt::Long;

use Data::Dumper;

my $scriptcentral_path = "/home/jrandall/scriptcentral";
if(exists($ENV{PIPELINE_HOME})) {
    $scriptcentral_path = $ENV{PIPELINE_HOME}."/bin";
}
if(exists($ENV{SCRIPTCENTRAL})) {
    $scriptcentral_path = $ENV{SCRIPTCENTRAL};
}
require "$scriptcentral_path/fzinout.pl";

my $DEBUG=0;
my $cmdgoals="";
my $mappings="";
my $params="";
my $outfile="";
my $varprefix="";
my $varsuffix="";

my $result = GetOptions( "cmdgoals=s" => \$cmdgoals,
			 "mappings=s" => \$mappings,
			 "params=s" => \$params,
			 "varprefix=s" => \$varprefix,
			 "varsuffix=s" => \$varsuffix,
			 "out=s" => \$outfile,
			 "verbose|v+" => \$DEBUG,
			 );

# Open output file
my $outfh = fzoutopen($outfile);

print STDERR "have cmdgoals=[$cmdgoals] mappings=[$mappings] params=[$params]\n" if($DEBUG>0);

my $splitter = new Text::EscapeDelimiters(); # default escape is backslash
my $squarebracketmatcher = new Text::DelimMatch;
$squarebracketmatcher->delim('\\[', '\\]');
$squarebracketmatcher->quote('"','"');
$squarebracketmatcher->escape('\\');
$squarebracketmatcher->double_escape();
$squarebracketmatcher->keep(1);
$squarebracketmatcher->returndelim(0);

$cmdgoals =~ s/[[:space:]]+/\ /gs;
$mappings =~ s/[[:space:]]+/\ /gs;
$params =~ s/[[:space:]]+/\ /gs;

my @cmdgoals = $splitter->split($cmdgoals," ");
my @mappings = $splitter->split($mappings," ");
my @params = $splitter->split($params," ");

print STDERR "have arrays cmdgoals=[@cmdgoals] mappings=[@mappings] params=[@params]\n" if($DEBUG>0);

# Output var with all bases of sortparams
#print $outfh $varprefix."special_sort_base".$varsuffix." := ".join(" ",map {$_ =~ s/([^\\])\[.*$/$1/g; $_;} @sortparams)."\n";


# Process mappings 
my %param_mappings;
foreach my $mapping (@mappings) {
    # apply this mapping to all matching params
    if(my ($in, $out) = $splitter->split($mapping,":")) {
	my $inindex = 0;
	my %inparamtags;
	my ($inbase,$outbase,$foo);
	if(($inbase,$foo,$foo) = $squarebracketmatcher->match($in)) {
	    my $inparam="";
	    my $pre="";
	    my $remaining = $in;
	    while($remaining ne "") {
		if(($pre,$inparam,$remaining) = $squarebracketmatcher->match($remaining)) {
		    print STDERR "in input $in ($inbase), param $inindex is $inparam (pre: $pre, remaining: $remaining)\n" if($DEBUG>1);
		    if($inparam =~ m/^\_.*\_$/) {
			$inparamtags{$inparam} = $inindex;
			print STDERR "set input paramtag $inparam to index $inindex\n" if($DEBUG>1);
		    } else {
			print STDERR "have no paramtag for input index $inindex ($inparam)\n" if($DEBUG>1);
		    }
		} else {
		    # match failed
		    die "match failed on $remaining -- error:".$squarebracketmatcher->error()."\n";
		}
		$inindex++;
	    }
	} else {
	    # could not find any bracket pairs
	    die "match failed on $in -- error:".$squarebracketmatcher->error()."\n";
	}
	my $insig = $inbase."|".$inindex;
	
	my $outindex = 0;
	my %outparamtags;
	my %outvalues;
	if(($outbase,$foo,$foo) = $squarebracketmatcher->match($out)) {
	    my $outparam="";
	    my $pre="";
	    my $remaining = $out;
	    while($remaining ne "") {
		if(($pre,$outparam,$remaining) = $squarebracketmatcher->match($remaining)) {
		    print STDERR "in output $out ($outbase), param $outindex is $outparam (pre: $pre, remaining: $remaining)\n" if($DEBUG>1);
		    if($outparam =~ m/^\_.*\_$/) {
			$outparamtags{$outparam} = $outindex;
			print STDERR "set output paramtag $outparam to index $outindex\n" if($DEBUG>1);
		    } else {
			$outvalues{$outindex} = $outparam;
			print STDERR "have no paramtag for output index $outindex ($outparam)\n" if($DEBUG>1);
		    }
		} else {
		    # match failed
		    die "match failed on $remaining -- error:".$squarebracketmatcher->error()."\n";
		}
		$outindex++;
	    }
	} else {
	    # could not find any bracket pairs
	    die "match failed on $out -- error:".$squarebracketmatcher->error()."\n";
	}
	my $outsig = $outbase."|".$outindex;
	
	# store mapping in global hash on insig
	my %temp_mapping;
	$temp_mapping{base} = $outbase;
	$temp_mapping{sig} = $outsig;
	print STDERR "have mapping for outsig $outsig, searching for insig...\n" if($DEBUG>0); 
	foreach my $paramtag (keys %inparamtags) {
	    print STDERR "\tchecking paramtag $paramtag\n" if($DEBUG>0); 
	    if(exists($inparamtags{$paramtag}) && exists($outparamtags{$paramtag})) {
		my $inindex = $inparamtags{$paramtag};
		my $outindex = $outparamtags{$paramtag};
		print STDERR "found mapping $insig=>$outsig, $outindex comes from $inindex for $paramtag\n" if($DEBUG>0); 
		$temp_mapping{indices}{$outindex} = $inindex;
	    } else {
		die "could not find mapping indices for $insig $paramtag\n";
	    }
	}
	print STDERR "adding constants to mapping\n" if($DEBUG>0); 
	foreach my $outindex (keys %outvalues) {
	    my $value = $outvalues{$outindex};
	    print STDERR "adding value $value for outindex $outindex\n" if($DEBUG>2);
	    $temp_mapping{values}{$outindex} = $value;
	}
	push @{$param_mappings{$insig}}, { %temp_mapping };
    }
}

my %param_matchheaders; # HoA stores an array of matchheaders to be used for each matching parameter option
my %param_base;
my %param_nargs;
foreach my $paramdef (@params) {
    if($paramdef =~ m/^[[:space:]]*$/) {
	# paramdef is blank
	#print STDERR "had blank paramdef\n";
    } else {
	#print STDERR "processing paramdef $paramdef\n";
	my ($parambase,$foo);
	my $paramindex = 0;
	my @matchheaders;
	if((($parambase,$foo,$foo) = $squarebracketmatcher->match($paramdef)) && defined($parambase)) {
	    print STDERR "have parambase $parambase for paramdef $paramdef\n" if($DEBUG > 0);
	    my $param="";
	    my $pre="";
	    my $remaining = $paramdef;
	    while($remaining ne "") {
		if(($pre,$param,$remaining) = $squarebracketmatcher->match($remaining)) {
		print STDERR "in paramdef $paramdef ($parambase), param $paramindex is $param (pre: $pre, remaining: $remaining)\n" if($DEBUG>1);
		$matchheaders[$paramindex] = $param;
		$paramindex++;
		} else {
		    die "had remaining text after last param in paramdef $paramdef\n";
		}
	    }
	    my $signature = $parambase."|".$paramindex;
	    print STDERR "storing param list for function signature $signature (have ".scalar(@matchheaders)." matchheaders)\n" if($DEBUG>0);
	    $param_matchheaders{$signature} = [ @matchheaders ];
	    $param_base{$signature} = $parambase;
	    $param_nargs{$signature} = $paramindex;
	} else {
	    print STDERR "could not find parambase in paramdef $paramdef, match error:".$squarebracketmatcher->error()."\n";
	}
    }
}

# Process each goal separately, searching for the defined parameters and putting them into hash
my %param_header_value;
while(my $goal = shift @cmdgoals) {
    print STDERR "processing goal=[$goal]\n" if($DEBUG > 0);
    my ($goalbase,$foo,$bar);
    my @paramvalues;
    my $goalremaining = $goal;
    while(($goalremaining ne "") && (($goalbase,$foo,$bar) = $squarebracketmatcher->match($goalremaining)) && defined($foo) && ($foo ne "")) {
	my $goalindex = 0;
	$goalbase =~ s/.*\.//;
	print STDERR "have base $goalbase for goal $goal\n" if($DEBUG > 0);
	my $paramvalue="";
	my $pre="";
	my $remaining = $goalremaining;
	while(($remaining ne "") && ($remaining =~ m/^[^.]/)) {
	    if(($pre,$paramvalue,$remaining) = $squarebracketmatcher->match($remaining)) {
		print STDERR "in goal $goal ($goalbase), param value $goalindex is $paramvalue (pre: $pre, remaining: $remaining)\n" if($DEBUG>1);
		$paramvalues[$goalindex] = $paramvalue;
		$goalindex++;
	    } else {
		die "had remaining text after last param in goal $goal (goalremaining $goalremaining)\n";
	    }
	}
	my $goalsig = $goalbase."|".$goalindex;
	print STDERR "have goal with signature $goalsig, looking up function for this param\n" if($DEBUG>1);
	if(exists($param_matchheaders{$goalsig})) {
	    print STDERR "have function definition matching signature $goalsig -- found ".scalar(@{$param_matchheaders{$goalsig}})." matchheaders\n" if($DEBUG>0);
	    for( my $index = 0; $index < $param_nargs{$goalsig}; $index++) {
		my $header = $param_matchheaders{$goalsig}[$index];
		my $value = $paramvalues[$index];
		$param_header_value{$goalbase}{$header}{$value} = 1;
		print STDERR "have value for $goalbase -> $header = $value\n" if($DEBUG>0);
	    }
	    
	    # check for mappings and add fake goal with remapped terms to the end of cmdgoals (for recursive processing)
	    if(exists($param_mappings{$goalsig})) {
		my @mappings = @{$param_mappings{$goalsig}};
		print STDERR "have ".scalar(@mappings)." mappings for $goalsig\n" if($DEBUG>1);
		# process mappings
		foreach my $mapping (@mappings) {
		    my $outsig = $mapping->{sig};
		    my $outbase = $mapping->{base};
		    print STDERR "processing mapping from $goalsig to outsig $outsig\n" if($DEBUG>1);
		    if(exists($param_matchheaders{$outsig})) {
			my @orderedoutvalues = ();
			print STDERR "adding remapped variable terms\n" if($DEBUG>0);
			if($DEBUG>2) {
			    print STDERR "mapping: ".Dumper($mapping)."\n";
			}
			foreach my $outindex (keys %{$mapping->{indices}}) {
			    my $inindex = $mapping->{indices}{$outindex};
			    print STDERR "mapping for $goalsig to $outsig -- outindex $outindex comes from inindex $inindex\n" if($DEBUG>1);
			    my $header = $param_matchheaders{$outsig}[$outindex];
			    my $value = $paramvalues[$inindex];
			    $param_header_value{$outbase}{$header}{$value} = 1;
			    print STDERR "adding value $value to dummy output list at index $outindex\n" if($DEBUG>1);
			    $orderedoutvalues[$outindex] = $value;
			    print STDERR "have (mapped) value for dummy param $outindex $outbase -> $header = $value\n" if($DEBUG>0);
			}
			# add constants 
			print STDERR "adding remapped constant terms\n" if($DEBUG>0);
			foreach my $outindex (keys %{$mapping->{values}}) {
			    my $header = $param_matchheaders{$outsig}[$outindex];
			    my $value = $mapping->{values}{$outindex};
#			    $param_header_value{$outbase}{$header}{$value} = 1;
			    $orderedoutvalues[$outindex] = $value;
			    print STDERR "have (constant) value for dummy param $outindex $outbase -> $header = $value\n" if($DEBUG>0);
			}
			# make sure all orderedoutvalues are specified
			for(my $n=0; $n<$#orderedoutvalues; $n++) {
			    if(!exists($orderedoutvalues[$n])) {
				print STDERR "WARNING: value at index $n for orderedoutvalues was never initialized!\n";
				$orderedoutvalues[$n] = "UNDEFINED";
			    }
			}
			
			# add dummy cmdgoal for recursive processing of mapped values
			my $dummycmdgoal = "DUMMY.".$outbase."[".join('][',@orderedoutvalues)."]";
			print STDERR "adding dummy cmdgoal: $dummycmdgoal for recursive processing\n" if($DEBUG>1);
			push @cmdgoals, $dummycmdgoal;
		    } else {
			print STDERR "can't find any matchheaders for outsig $outsig\n";
			# add constants 
			#print STDERR "adding remapped constant terms\n" if($DEBUG>0);
			#foreach my $outindex (keys %{$mapping->{values}}) {
			#    my $header = $param_matchheaders{$outsig}[$outindex];
			#    my $value = $mapping->{values}{$outindex};
			#    $orderedoutvalues[$outindex] = $value;
			#    print STDERR "have (constant) value for dummy param $outindex $outbase -> $header = $value\n" if($DEBUG>0);
			#}
			# make sure all orderedoutvalues are specified
			#for(my $n=0; $n<$#orderedoutvalues; $n++) {
			#    if(!exists($orderedoutvalues[$n])) {
			#	print STDERR "WARNING: value at index $n for orderedoutvalues was never initialized!\n";
			#	$orderedoutvalues[$n] = "UNDEFINED";
			#    }
			#}
			
			# add dummy cmdgoal for recursive processing of mapped values
			#my $dummycmdgoal = "DUMMY.".$outbase."[".join('][',@orderedoutvalues)."]";
			#print STDERR "adding dummy cmdgoal: $dummycmdgoal for recursive processing\n" if($DEBUG>1);
			#push @cmdgoals, $dummycmdgoal;
		    }
		}
	    } else {
		print STDERR "no mappings apply to $goalsig\n" if($DEBUG>1);
	    }
	    
	} else {
	    die "could not find function definition matching signature $goalsig for $goal\n";
	}
	$remaining =~ s/^\.//;
	print STDERR "moving to next function in goal $goal (updating goalremaining from $goalremaining to $remaining)\n" if($DEBUG>0);
	$goalremaining = $remaining;
    } # end while goalremaining
}

foreach my $paramsig (keys %param_matchheaders) {
    foreach my $header (@{$param_matchheaders{$paramsig}}) {
	my $base = $param_base{$paramsig};
	print $outfh $varprefix.$base."_".$header.$varsuffix.' := '.join(" ",keys %{$param_header_value{$base}{$header}})."\n";
    }
}


# Close output file
$outfh->close();

