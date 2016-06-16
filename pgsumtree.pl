my $buildno = '2.0.x';
#
# pgsumtree
# 
# Official web site of this script is
# https://www.fifthdimension.jp/products/phylogears/ .
# To know script details, see above URL.
# 
# Copyright (C) 2008-2016  Akifumi S. Tanabe
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# To Do : mode tree search

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgsumtree $buildno
=======================================================================

Official web site of this script is
https://www.fifthdimension.jp/products/phylogears/ .
To know script details, see above URL.

Copyright (C) 2008-2016  Akifumi S. Tanabe

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

_END
}

# display usage if command line options were not specified
unless (@ARGV) {
	&helpMessage();
}

# initialize variables
my $inputfile = $ARGV[-2];
if (!-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $mode = 'ALL';
my $supportvalue = 'PERCENT';
my $treefile;
my $threshold = 0;
my $ignoreweight = 0;
my %support;

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:m|mode)=(.+)$/i) {
		if ($1 =~ /^(?:CONSENSE|CON)$/i) {
			$mode = 'CONSENSE';
		}
		elsif ($1 =~ /^MODE$/i) {
			$mode = 'MODE';
		}
		elsif ($1 =~ /^MAP$/i) {
			$mode = 'MAP';
		}
		elsif ($1 =~ /^MAJ$/i) {
			$mode = 'MAJ';
		}
		elsif ($1 =~ /^MAJi$/i) {
			$mode = 'MAJi';
		}
		elsif ($1 =~ /^ALLi$/i) {
			$mode = 'ALLi';
		}
		elsif ($1 =~ /^ALL$/i) {
			$mode = 'ALL';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:s|supportvalue)=(.+)$/i) {
		if ($1 =~ /^PERCENT$/i) {
			$supportvalue = 'PERCENT';
		}
		elsif ($1 =~ /^NUMBER$/i) {
			$supportvalue = 'NUMBER';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:t|treefile)=(.+)$/i) {
		if (-e $1) {
			$treefile = $1;
		}
		else {
			&errorMessage(__LINE__, "Specified tree file \"$1\" does not exist.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+threshold=(\d+)$/i) {
		$threshold = $1;
	}
	elsif ($ARGV[$i] =~ /^-+(?:i|ignoreweight)$/i) {
		$ignoreweight = 1;
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

# validate options
if ($threshold && $mode ne 'ALLi' && $mode ne 'ALL') {
	&errorMessage(__LINE__, "Threshold is specified, but mode is not ALLi or ALL.");
}
if (!$treefile && ($mode eq 'MAP' || $mode eq 'ALLi' || $mode eq 'MAJi')) {
	&errorMessage(__LINE__, "Mode is $mode, but tree file is not given.");
}
if ($treefile && $mode ne 'MAP' && $mode ne 'ALLi' && $mode ne 'MAJi') {
	&errorMessage(__LINE__, "Mode is $mode, but tree file is given.");
}

my @outtreenames;
my @outtrees;

my %format;
$format{$inputfile} = &recognizeFormat($inputfile);
#if ($outputfile !~ /^stdout$/i) {
#	print("Input file format: $format{$inputfile}\n");
#}
if ($treefile) {
	$format{$treefile} = &recognizeFormat($treefile);
}
my $outformat = $format{$inputfile};

if ($mode eq 'MODE') {
	&errorMessage(__LINE__, "This mode is not implemented yet.");
}
else {
	# get support values
	my @intreenames;
	my @intrees;
	my @intreeweights;
	{
		my ($intreenames, $intrees, $intreeweights) = &readInputFile($inputfile, $format{$inputfile});
		@intreenames = @{$intreenames};
		@intrees = @{$intrees};
		@intreeweights = @{$intreeweights};
	}
	#if ($outputfile !~ /^stdout$/i) {
	#	my $temp = scalar(@intreenames);
	#	print("Number of trees in input file: $temp\n");
	#}
	my $total;
	for (my $i = 0; $i < scalar(@intrees); $i ++) {
		foreach my $hypothesis (&splitHypotheses($intrees[$i])) {
			$support{$hypothesis} += $intreeweights[$i];
		}
		$total += $intreeweights[$i];
	}
	if ($supportvalue eq 'PERCENT') {
		foreach my $hypothesis (keys(%support)) {
			$support{$hypothesis} = ($support{$hypothesis} / $total) * 100;
		}
		$total = 100;
	}
	else {
		$threshold = $total * $threshold;
	}
	if ($mode eq 'ALL' || $mode eq 'MAJ' || $mode eq 'CONSENSE') {
		my @majorhypothesisnames;
		my @majorhypotheses;
		my $majorhypothesisno = 1;
		my @minorhypothesisnames;
		my @minorhypotheses;
		my $minorhypothesisno = 1;
		foreach my $hypothesis (sort({$support{$b} <=> $support{$a}} keys(%support))) {
			if ($mode eq 'ALL' && $support{$hypothesis} < $threshold) {
				last;
			}
			my $majorornot = 1;
			if ($support{$hypothesis} / $total < 0.5) {
				foreach my $majorhypothesis (@majorhypotheses) {
					my $compatibility = &testCompatibility($hypothesis, $majorhypothesis);
					if ($compatibility == 2) {
						$majorornot = 0;
						last;
					}
					elsif ($compatibility == 0) {
						&errorMessage(__LINE__, "Unknown error.");
					}
				}
			}
			if ($majorornot) {
				push(@majorhypothesisnames, "majorhypothesis_$majorhypothesisno");
				push(@majorhypotheses, $hypothesis);
				$majorhypothesisno ++;
			}
			elsif ($mode eq 'ALL') {
				push(@minorhypothesisnames, "minorhypothesis_$minorhypothesisno");
				push(@minorhypotheses, $hypothesis);
				$minorhypothesisno ++;
			}
		}
		if ($mode eq 'ALL' || $mode eq 'MAJ') {
			my @temphypothesisnames = (@majorhypothesisnames, @minorhypothesisnames);
			my @temphypotheses = (@majorhypotheses, @minorhypotheses);
			for (my $i = 0; $i < scalar(@temphypotheses); $i ++) {
				my $hypothesis = $temphypotheses[$i];
				my $support = sprintf("%.1f", $support{$hypothesis});
				$hypothesis =~ s/\),/)$support,/;
				push(@outtreenames, $temphypothesisnames[$i]);
				push(@outtrees, $hypothesis);
			}
		}
		else {
			my %majorhypotheses;
			foreach my $majorhypothesis (@majorhypotheses) {
				if ($majorhypothesis =~ /\(([^\(\)]+)\),\(([^\(\)]+)\)/) {
					my $group0 = $1;
					my $group1 = $2;
					my @group0 = split(/,/, $group0);
					my @group1 = split(/,/, $group1);
					if (scalar(@group0) < scalar(@group1)) {
						$majorhypotheses{$majorhypothesis} = scalar(@group0);
					}
					else {
						$majorhypotheses{$majorhypothesis} = scalar(@group1);
					}
				}
			}
			my $consensustree;
			foreach my $majorhypothesis (sort({$majorhypotheses{$b} <=> $majorhypotheses{$a}} keys(%majorhypotheses))) {
				$majorhypothesis =~ /\(([^\(\)]+)\),\(([^\(\)]+)\)/;
				my $group0 = $1;
				my $group1 = $2;
				my @group0 = split(/,/, $group0);
				my @group1 = split(/,/, $group1);
				my @larger;
				my @smaller;
				if (scalar(@group0) < scalar(@group1)) {
					@larger = @group1;
					@smaller = @group0;
				}
				else {
					@larger = @group0;
					@smaller = @group1;
				}
				my $support = sprintf("%.1f", $support{$majorhypothesis});
				if (!$consensustree) {
					$consensustree = '(' . join(',', @larger) . ',(' . join(',', @smaller) . ')' . $support . ')';
				}
				else {
					$consensustree =~ s/([\(,])$smaller[0]([,\)])/$1<CLADE>$2/;
					for (my $i = 1; $i < scalar(@smaller); $i ++) {
						$consensustree =~ s/([\(,])$smaller[$i]([,\)])/$1$2/;
					}
					$consensustree =~ s/,,/,/g;
					$consensustree =~ s/,\)/)/g;
					$consensustree =~ s/\(,/(/g;
					my $clade = join(',', @smaller);
					$consensustree =~ s/([\(,])<CLADE>([,\)])/$1($clade)$support$2/;
				}
			}
			$consensustree =~ s/^\((.+)\)$/$1/;
			push(@outtreenames, "consensustree");
			push(@outtrees, $consensustree);
		}
	}
	elsif ($mode eq 'ALLi' || $mode eq 'MAJi') {
		my @reftreenames;
		my @reftrees;
		{
			my ($reftreenames, $reftrees, $refweights) = &readInputFile($treefile, $format{$treefile});
			@reftreenames = @{$reftreenames};
			@reftrees = @{$reftrees};
		}
		my @hypotheses = sort({$support{$b} <=> $support{$a}} keys(%support));
		for (my $i = 0; $i < scalar(@reftrees); $i ++) {
			my @refhypotheses = &splitHypotheses($reftrees[$i]);
			my @majorhypothesisnames;
			my @majorhypotheses;
			my $majorhypothesisno = 1;
			my @minorhypothesisnames;
			my @minorhypotheses;
			my $minorhypothesisno = 1;
			foreach my $hypothesis (@hypotheses) {
				if ($mode eq 'ALLi' && $support{$hypothesis} < $threshold) {
					last;
				}
				my $incompatibleornot = 0;
				foreach my $refhypothesis (@refhypotheses) {
					my $compatibility = &testCompatibility($hypothesis, $refhypothesis);
					if ($compatibility == 0) {
						$incompatibleornot = 0;
						last;
					}
					elsif ($compatibility == 2) {
						$incompatibleornot = 1;
						last;
					}
				}
				my $majorornot = 1;
				if ($support{$hypothesis} / $total < 0.5) {
					foreach my $majorhypothesis (@majorhypotheses) {
						my $compatibility = &testCompatibility($hypothesis, $majorhypothesis);
						if ($compatibility == 2) {
							$majorornot = 0;
							last;
						}
						elsif ($compatibility == 0) {
							&errorMessage(__LINE__, "Unknown error.");
						}
					}
				}
				if ($incompatibleornot) {
					if ($majorornot) {
						push(@majorhypothesisnames, "majorincompatible_$majorhypothesisno\_of_$reftreenames[$i]");
						push(@majorhypotheses, $hypothesis);
						$majorhypothesisno ++;
					}
					elsif ($mode eq 'ALLi') {
						push(@minorhypothesisnames, "minorincompatible_$minorhypothesisno\_of_$reftreenames[$i]");
						push(@minorhypotheses, $hypothesis);
						$minorhypothesisno ++;
					}
				}
			}
			my @temphypothesisnames = (@majorhypothesisnames, @minorhypothesisnames);
			my @temphypotheses = (@majorhypotheses, @minorhypotheses);
			for (my $i = 0; $i < scalar(@temphypotheses); $i ++) {
				my $hypothesis = $temphypotheses[$i];
				my $support = sprintf("%.1f", $support{$hypothesis});
				$hypothesis =~ s/\),/)$support,/;
				push(@outtreenames, $temphypothesisnames[$i]);
				push(@outtrees, $hypothesis);
			}
		}
	}
	elsif ($mode eq 'MAP') {
		my @maptreenames;
		my @maptrees;
		{
			my ($maptreenames, $maptrees, $mapweights) = &readInputFile($treefile, $format{$treefile});
			@maptreenames = @{$maptreenames};
			@maptrees = @{$maptrees};
		}
		for (my $i = 0; $i < scalar(@maptrees); $i ++) {
			my $tree = $maptrees[$i];
			my @otus;
			{
				my $temptree = $tree;
				$temptree =~ s/\)[^,:\)]+/)/g;
				$temptree =~ s/:\d+\.?\d*(e\D?\d+)?//g;
				@otus = $temptree =~ /[^,:\(\)]+/g;
			}
			my $cladeno = 0;
			my @tempsupport;
			while ($tree =~ s/\(([^\(\)]+)\)/<$cladeno>$1<\/$cladeno>/) {
				my $temp = $1;
				$temp =~ s/\)[^,:\)]+/)/g;
				$temp =~ s/:\d+\.?\d*(e\D?\d+)?//g;
				$temp =~ s/<\/?\d+>//g;
				my @followers = split(/,/, $temp);
				my %followers;
				foreach (@followers) {
					$followers{$_} = 1;
				}
				my @others;
				foreach (@otus) {
					if (!$followers{$_}) {
						push(@others, $_);
					}
				}
				if (scalar(@followers) != 1 && scalar(@others) != 1) {
					my $followers = join(',', sort(@followers));
					my $others = join(',', sort(@others));
					$tempsupport[$cladeno] = $support{'(' . join('),(', sort($followers, $others)) . ')'};
				}
				$cladeno ++;
			}
			while ($tree =~ /<(\d+)>.+<\/\1>/) {
				my $j = $1;
				if (defined($tempsupport[$j])) {
					my $support = sprintf("%.1f", $tempsupport[$j]);
					$tree =~ s/<$j>(.+)<\/$j>/($1)$support/;
				}
				else {
					$tree =~ s/<$j>(.+)<\/$j>/($1)/;
				}
			}
			push(@outtreenames, $maptreenames[$i]);
			push(@outtrees, $tree);
		}
	}
}

# output trees
{
	my $filehandle;
	if ($outputfile =~ /^stdout$/i) {
		unless (open($filehandle, '>-')) {
			&errorMessage(__LINE__, "Cannot write STDOUT.");
		}
	}
	else {
		unless (open($filehandle, "> $outputfile")) {
			&errorMessage(__LINE__, "Cannot make \"$outputfile\".");
		}
	}
	if ($outformat eq 'NEXUS') {
		print($filehandle "#NEXUS\n\nBegin Trees;\n");
	}
	for (my $i = 0; $i < scalar(@outtreenames); $i ++) {
		if ($outformat eq 'NEXUS') {
			print($filehandle "\tTree $outtreenames[$i] = ($outtrees[$i]);\n");
		}
		else {
			print($filehandle "[$outtreenames[$i]] ($outtrees[$i]);\n");
		}
	}
	if ($outformat eq 'NEXUS') {
		print($filehandle "End;\n");
	}
	close($filehandle);
}

# file format recognition
sub recognizeFormat {
	my $readfile = shift(@_);
	my $tempformat;
	$tempformat = 'Newick';
	unless (open(INFILE, "< $readfile")) {
		&errorMessage(__LINE__, "Cannot open \"$readfile\".");
	}
	while (<INFILE>) {
		if (/^#NEXUS/i) {
			$tempformat = 'NEXUS';
		}
		last;
	}
	close(INFILE);
	return($tempformat);
}

# read input file
sub readInputFile {
	my $readfile = shift(@_);
	my $format = shift(@_);
	my @treenames;
	my @trees;
	my @treeweights;
	unless (open(INFILE, "< $readfile")) {
		&errorMessage(__LINE__, "Cannot open \"$readfile\".");
	}
	if ($format eq 'NEXUS') {
		my $treesblock = 0;
		my $translate = 0;
		my %table;
		while (<INFILE>) {
			if ($treesblock != 1 && /^\s*Begin\s+Trees\s*;/i) {
				$treesblock = 1;
			}
			elsif ($treesblock == 1 && /^\s*End\s*;/i) {
				$treesblock = 0;
			}
			elsif ($treesblock == 1 && $translate == 1) {
				if (/^\s*(\S+)\s+([^,;\s]+)\s*([,;])\s*\r?\n?$/) {
					$table{$1} = $2;
					if ($3 eq ';') {
						$translate = 0;
					}
				}
			}
			elsif ($treesblock == 1 && $translate == 0 && !%table && /^\s*Translate/i) {
				$translate = 1;
			}
			elsif ($treesblock == 1 && $translate == 0 && /\s*Tree\s*(\S+)\s*=\s*(\[[^\(\):]+\])?\s*(\(.+\))(?:\:0|\:0\.0)?;/i) {
				my $treename = $1;
				my $treeproperty = $2;
				my $tree = $3;
				foreach my $from (keys(%table)) {
					$tree =~ s/([\(,])$from([:,\)])/$1$table{$from}$2/;
				}
				$tree =~ s/^\((.+)\)$/$1/;
				my $treeweight;
				if (!$ignoreweight && $treeproperty =~ /\[\&W\s*([\d\/\.]+)\]/i) {
					$treeweight = eval($1);
				}
				else {
					$treeweight = 1;
				}
				push(@treenames, $treename);
				push(@trees, $tree);
				push(@treeweights, $treeweight);
			}
		}
	}
	else {
		local $/ = ";";
		my $treeno = 1;
		while (<INFILE>) {
			if (/(?:\[(.+?)\])?\s*(\(.+\))(?:\:0|\:0\.0)?\s*(?:\[([\d\/\.]+)\])?;/s) {
				my $treename = $1;
				my $tree = $2;
				my $treeweight = eval($3);
				if (!$treename) {
					$treename = "tree_$treeno";
				}
				$tree =~ s/^\((.+)\)$/$1/s;
				$tree =~ s/\s//sg;
				if (!$treeweight || $ignoreweight) {
					$treeweight = 1;
				}
				push(@treenames, $treename);
				push(@trees, $tree);
				push(@treeweights, $treeweight);
				$treeno ++;
			}
		}
	}
	close(INFILE);
	return(\@treenames, \@trees, \@treeweights);
}

sub splitHypotheses {
	my $tree = shift(@_);
	$tree =~ s/\)[^,:\)]+/)/g;
	$tree =~ s/:\d+\.?\d*(e\D?\d+)?//g;
	my @otus = $tree =~ /[^,:\(\)]+/g;
	my @hypotheses;
	my %hypotheses;
	while ($tree =~ s/\(([^:\(\)]+)\)/$1/) {
		my $clade = $1;
		my @followers = split(/,/, $clade);
		my %followers;
		foreach (@followers) {
			$followers{$_} = 1;
		}
		my @others;
		foreach (@otus) {
			if (!$followers{$_}) {
				push(@others, $_);
			}
		}
		if (scalar(@followers) == 1 || scalar(@others) == 1) {
			next;
		}
		else {
			my $followers = join(',', sort(@followers));
			my $others = join(',', sort(@others));
			my $hypothesis = '(' . join('),(', sort($followers, $others)) . ')';
			if (!$hypotheses{$hypothesis}) {
				push(@hypotheses, $hypothesis);
				$hypotheses{$hypothesis} = 1;
			}
		}
	}
	return(@hypotheses);
}

sub testCompatibility {
	# state == 0 : Same topology
	# state == 1 : Different compatible topology
	# state == 2 : Different incompatible topology
	my $split1 = shift(@_);
	my $split2 = shift(@_);
	my $state = 0;
	my %group;
	if ($split1 =~ /\(([^\(\)]+)\),\(([^\(\)]+)\)/) {
		my $group0 = $1;
		my $group1 = $2;
		my @group0 = split(/,/, $group0);
		my @group1 = split(/,/, $group1);
		foreach my $otu (@group0) {
			$group{$otu} = 0;
		}
		foreach my $otu (@group1) {
			$group{$otu} = 1;
		}
	}
	if ($split2 =~ /\(([^\(\)]+)\),\(([^\(\)]+)\)/) {
		my $group0 = $1;
		my $group1 = $2;
		my @group0 = split(/,/, $group0);
		my @group1 = split(/,/, $group1);
		{
			my $state0 = 0;
			foreach my $otu (@group0) {
				$state0 += $group{$otu};
			}
			if ($state0 != 0 && $state0 != scalar(@group0)) {
				$state ++;
			}
		}
		{
			my $state1 = 0;
			foreach my $otu (@group1) {
				$state1 += $group{$otu};
			}
			if ($state1 != 0 && $state1 != scalar(@group1)) {
				$state ++;
			}
		}
	}
	return($state);
}

sub errorMessage {
	my $lineno = shift(@_);
	my $message = shift(@_);
	print("ERROR!: line $lineno\n$message\n");
	print("If you want to read help message, run this script without options.\n");
	exit(1);
}

sub helpMessage {
	print <<"_END";
Usage
=====
pgsumtree options inputfile outputfile

Command line options
====================
-i, --ignoreweight
  If this option is specified, tree weight will be ignored.

-m, --mode=CONSENSE|MAP|MAJ|MAJi|ALLi|ALL
  Specify the operation mode. (default: ALL)

-t, --treefile=FILENAME
  Specify the source tree file for support value mapping or incompatible
hypotheses exploration.
(default: none)

--threshold=INTEGER (0-100)
  Specify the lower threshold of support value as percent for all hypotheses
exploration or all incompatible hypotheses exploration. (default: 0)

-s, --supportvalue=PERCENT|NUMBER
  Specify the output format for support values. (default: PERCENT)

Acceptable input file formats
=============================
Newick
NEXUS
PHYLIP
_END
	exit;
}
