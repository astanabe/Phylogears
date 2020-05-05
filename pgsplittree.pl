my $buildno = '2.0.x';
#
# pgsplittree
# 
# Official web site of this script is
# https://www.fifthdimension.jp/products/phylogears/ .
# To know script details, see above URL.
# 
# Copyright (C) 2008-2020  Akifumi S. Tanabe
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

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgsplittree $buildno
=======================================================================

Official web site of this script is
https://www.fifthdimension.jp/products/phylogears/ .
To know script details, see above URL.

Copyright (C) 2008-2020  Akifumi S. Tanabe

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

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
}

my @outtreenames;
my @outtrees;

my %format;
$format{$inputfile} = &recognizeFormat($inputfile);
my $outformat = $format{$inputfile};

{
	my @intreenames;
	my @intrees;
	{
		my ($intreenames, $intrees) = &readInputFile($inputfile, $format{$inputfile});
		@intreenames = @{$intreenames};
		@intrees = @{$intrees};
	}
	for (my $i = 0; $i < scalar(@intrees); $i ++) {
		my $hypothesisno = 1;
		foreach my $hypothesis (&splitHypotheses($intrees[$i])) {
			push(@outtreenames, "hypothesis_$hypothesisno\_of_$intreenames[$i]");
			push(@outtrees, $hypothesis);
			$hypothesisno ++;
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
			elsif ($treesblock == 1 && $translate == 0 && /\s*Tree\s*(\S+)\s*=\s*(?:\[[^\(\):]+\])?\s*(\(.+\))(?:\:0|\:0\.0)?;/i) {
				my $treename = $1;
				my $tree = $2;
				foreach my $from (keys(%table)) {
					$tree =~ s/([\(,])$from([:,\)])/$1$table{$from}$2/;
				}
				$tree =~ s/^\((.+)\)$/$1/;
				push(@treenames, $treename);
				push(@trees, $tree);
			}
		}
	}
	else {
		local $/ = ";";
		my $treeno = 1;
		while (<INFILE>) {
			if (/(?:\[(.+?)\])?\s*(\(.+\))(?:\:0|\:0\.0)?\s*(?:\[[\d\/\.]+\])?;/s) {
				my $treename = $1;
				my $tree = $2;
				if (!$treename) {
					$treename = "tree_$treeno";
				}
				$tree =~ s/^\((.+)\)$/$1/s;
				$tree =~ s/\s//sg;
				push(@treenames, $treename);
				push(@trees, $tree);
				$treeno ++;
			}
		}
	}
	close(INFILE);
	return(\@treenames, \@trees);
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
pgsplittree inputfile outputfile

Acceptable input file formats
=============================
Newick
NEXUS
PHYLIP
_END
	exit;
}
