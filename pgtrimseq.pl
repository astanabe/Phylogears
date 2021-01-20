my $buildno = '2.0.x';
#
# pgtrimseq
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

# To do: partition setting

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgtrimseq $buildno
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
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
my $gap = 0;
my $miss = 0;
my $ambig = 0;
my $head = 0;
my $tail = 0;
my @target;
my %target;
my @taxa;
my @seqs;
my $minpcoverage = 0.5;
my $minncoverage;

# file format recognition
my $format;
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
{
	my $lineno = 1;
	while (<INFILE>) {
		if ($lineno == 1 && /^#NEXUS/i) {
			$format = 'NEXUS';
			last;
		}
		elsif ($lineno == 1 && /^\s*\d+\s+\d+\s*/) {
			$format = 'PHYLIP';
		}
		elsif ($lineno == 1 && /^>/) {
			$format = 'FASTA';
			last;
		}
		elsif ($lineno == 1) {
			$format = 'TF';
			last;
		}
		elsif ($lineno > 1 && /^\S{11,}\s+\S.*/) {
			$format = 'PHYLIPex';
		}
		$lineno ++;
	}
}
close(INFILE);

# read input file
my $ntax;
my $nchar;
my $nexusformat;
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
if ($format eq 'NEXUS') {
	my $datablock = 0;
	my $matrix = 0;
	my $seqno = 0;
	my %taxa;
	while (<INFILE>) {
		s/\[.*\]//g;
		if ($datablock != 1 && /^\s*Begin\s+Data\s*;/i) {
			$datablock = 1;
		}
		elsif ($datablock == 1 && /^\s*End\s*;/i) {
			last;
		}
		elsif ($datablock == 1 && $matrix == 1 && /;/) {
			$matrix = 0;
		}
		elsif ($datablock == 1 && $matrix == 1) {
			if (/^\s*(\S+)\s+(\S.*?)\s*\r?\n?$/) {
				my $taxon = $1;
				my $seq = $2;
				unless (defined($taxa{$taxon})) {
					push(@taxa, $taxon);
					$taxa{$taxon} = $seqno;
					$seqno ++;
				}
				my @seq = $seq =~ /\S/g;
				push(@{$seqs[$taxa{$taxon}]}, @seq);
			}
		}
		elsif ($datablock == 1 && $matrix == 0 && /^\s*Dimensions\s+/i) {
			if (/\s+NTax\s*=\s*(\d+)/i) {
				$ntax = $1;
			}
			if (/\s+NChar\s*=\s*(\d+)/i) {
				$nchar = $1;
			}
		}
		elsif ($datablock == 1 && $matrix == 0 && /^\s*(Format.+)\r?\n?/i) {
			$nexusformat = $1;
		}
		elsif ($datablock == 1 && $matrix == 0 && /^\s*Matrix/i) {
			$matrix = 1;
		}
	}
}
elsif ($format eq 'PHYLIP' || $format eq 'PHYLIPex') {
	my $num = -1;
	while (<INFILE>) {
		if ($num == -1) {
			if (/^\s*(\d+)\s+(\d+)/) {
				$ntax = $1;
				$nchar = $2;
				$num ++;
			}
			else {
				&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
			}
		}
		else {
			if ($num < $ntax) {
				if ($format eq 'PHYLIP' && /^(..........)\s*(\S.*?)\s*\r?\n?$/ || $format eq 'PHYLIPex' && /^(\S+)\s+(\S.*?)\s*\r?\n?$/) {
					my $taxon = $1;
					my $seq = $2;
					push(@taxa, $taxon);
					my @seq = $seq =~ /\S/g;
					push(@{$seqs[$num]}, @seq);
					$num ++;
				}
			}
			else {
				if (/^\s+(\S.*?)\s*\r?\n?$/) {
					my $seq = $1;
					my @seq = $seq =~ /\S/g;
					push(@{$seqs[$num % $ntax]}, @seq);
					$num ++;
				}
			}
		}
	}
}
elsif ($format eq 'FASTA') {
	my $taxon;
	while (<INFILE>) {
		if (/^>\s*(\S.*?)\s*\r?\n?$/) {
			$taxon = $1;
			push(@taxa, $taxon);
		}
		elsif ($taxon) {
			my @seq = $_ =~ /\S/g;
			push(@{$seqs[scalar(@taxa) - 1]}, @seq);
		}
	}
	$ntax = scalar(@taxa);
	foreach my $seqs (@seqs) {
		if ($nchar < scalar(@{$seqs})) {
			$nchar = scalar(@{$seqs});
		}
	}
}
elsif ($format eq 'TF') {
	my $seqno = 0;
	my %taxa;
	while (<INFILE>) {
		if (/^\"([^\"]+)\"\s*(\S.*?)\s*\r?\n?$/i) {
			my $taxon = $1;
			my $seq = $2;
			unless (defined($taxa{$taxon})) {
				push(@taxa, $taxon);
				$taxa{$taxon} = $seqno;
				$seqno ++;
			}
			my @seq = $seq =~ /\S/g;
			push(@{$seqs[$taxa{$taxon}]}, @seq);
		}
	}
	$ntax = scalar(@taxa);
	$nchar = scalar(@{$seqs[0]});
}
close(INFILE);

# check data
if (scalar(@taxa) != scalar(@seqs) || scalar(@taxa) != $ntax) {
	&errorMessage(__LINE__, "Input file is invalid.");
}
my $taxnamelength;
if ($format ne 'FASTA') {
	foreach my $taxon (@taxa) {
		if ($taxnamelength < length($taxon)) {
			$taxnamelength = length($taxon);
		}
	}
}

# get options
{
	my @tempsites;
	for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
		if ($ARGV[$i] =~ /^-+restrict=(.+)$/i) {
			foreach my $restrict (split(',', $1)) {
				if ($restrict =~ /^head$/i) {
					$head = 1;
				}
				elsif ($restrict =~ /^tail$/i) {
					$tail = 1;
				}
				elsif ($restrict =~ /^disable$/i) {
					undef($head);
					undef($tail);
				}
				else {
					&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
				}
			}
		}
		elsif ($ARGV[$i] =~ /^-+(?:t|target)=(.+)$/i) {
			foreach my $target (split(',', $1)) {
				if ($target =~ /^gaps?$/i) {
					$gap = 1;
				}
				elsif ($target =~ /^miss(?:ing)?$/i) {
					$miss = 1;
				}
				elsif ($target =~ /^ambig(?:uous)?$/i) {
					$ambig = 1;
				}
				else {
					&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
				}
			}
		}
		elsif ($ARGV[$i] =~ /^-+minpcoverage=(\d+(?:\.\d+)?)$/i) {
			$minpcoverage = $1;
			if ($minpcoverage < 0 || $minpcoverage > 1) {
				&errorMessage(__LINE__, "Percent coverage cutoff value is invalid.");
			}
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
}
if ($gap == 0 && $miss == 0 && $ambig == 0) {
	$gap = 1;
	$miss = 1;
}
if (!defined($head) && !defined($tail)) {
	$head = 0;
	$tail = 0;
}
elsif (defined($head) && $head == 0 && defined($tail) && $tail == 0) {
	$head = 1;
	$tail = 1;
}
$minncoverage = $ntax * $minpcoverage;

# search columns containing deletion targets
if ($head == 0 && $tail == 0 || $head) {
	for (my $j = 0; $j < $nchar; $j ++) {
		my $temp;
		for (my $i = 0; $i < $ntax; $i ++) {
			if (($gap && $seqs[$i][$j] eq '-') || 
			($miss && $seqs[$i][$j] eq '?') || 
			($ambig && $seqs[$i][$j] =~ /^(?:N|M|R|W|S|Y|K|V|H|D|B)$/i)) {
				$temp ++;
			}
			elsif ($seqs[$i][$j] !~ /^(?:A|C|G|T|-|N|\?|M|R|W|S|Y|K|V|H|D|B)$/i) {
				&errorMessage(__LINE__, '"' . $seqs[$i][$j] . '" (site ' . ($j + 1) . ' of ' . $taxa[$i] . ') is invalid character.');
			}
		}
		if (($ntax - $temp) < $minncoverage) {
			$target{$j} = 1;
		}
		elsif ($head) {
			last;
		}
	}
}
if ($tail) {
	for (my $j = -1; ($j * (-1)) <= $nchar; $j --) {
		my $temp;
		for (my $i = 0; $i < $ntax; $i ++) {
			if (($gap && $seqs[$i][$j] eq '-') || 
			($miss && $seqs[$i][$j] eq '?') || 
			($ambig && $seqs[$i][$j] =~ /^(?:N|M|R|W|S|Y|K|V|H|D|B)$/i)) {
				$temp ++;
			}
			elsif ($seqs[$i][$j] !~ /^(?:A|C|G|T|-|N|\?|M|R|W|S|Y|K|V|H|D|B)$/i) {
				&errorMessage(__LINE__, '"' . $seqs[$i][$j] . '" (site ' . ($j + 1) . ' of ' . $taxa[$i] . ') is invalid character.');
			}
		}
		if (($ntax - $temp) < $minncoverage) {
			$target{($nchar + $j)} = 1;
		}
		else {
			last;
		}
	}
}
{
	my %converse;
	for (my $j = 0; $j < $nchar; $j ++) {
		if (!defined($target{$j})) {
			$converse{$j} = 1;
		}
	}
	@target = sort({$a <=> $b} keys(%converse));
	#print(STDERR "@target\n");
}

# output processed sequence file
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
if ($format eq 'NEXUS') {
	print($filehandle "#NEXUS\n\nBegin Data;\n\tDimensions NTax=$ntax NChar=" . scalar(@target) . ";\n\t$nexusformat\n\tMatrix\n");
}
elsif ($format eq 'PHYLIP' || $format eq 'PHYLIPex') {
	print($filehandle $ntax . ' ' . scalar(@target) . "\n");
}
for (my $i = 0; $i < scalar(@taxa); $i ++) {
	if ($format eq 'NEXUS' || $format eq 'PHYLIPex') {
		printf($filehandle "%-*s ", $taxnamelength, $taxa[$i]);
	}
	elsif ($format eq 'PHYLIP') {
		printf($filehandle "%-10s ", $taxa[$i]);
	}
	elsif ($format eq 'FASTA') {
		print($filehandle ">$taxa[$i]\n");
	}
	elsif ($format eq 'TF') {
		printf($filehandle "%-*s ", $taxnamelength + 2, '"' . $taxa[$i] . '"');
	}
	foreach my $site (@target) {
		print($filehandle $seqs[$i][$site]);
	}
	print($filehandle "\n");
}
if ($format eq 'NEXUS') {
	print($filehandle "\t;\nEnd;\n");
}
close($filehandle);

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
pgtrimseq options inputfile outputfile

Command line options
====================
--minpcoverage=DECIMAL
  Specify percent coverage cutoff. Sites containing (1 - cutoff) or more target
data types will be eliminated from output. (default: 0.5)

-t, --target=Gap|Miss|Ambig
  Specify target data types. (default: Gap,Miss)

--restrict=Head|Tail|Head,Tail|Disable
  Specify trimming range restriction. (default: Head,Tail)

Acceptable input file formats
=============================
FASTA
NEXUS
PHYLIP
TF (Treefinder)
(This script does not accept multiple data sets.)
_END
	exit;
}
