my $buildno = '2.0.x';
#
# pgspliceseq
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
pgspliceseq $buildno
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
my $converse = 0;
my @target;
my @taxa;
my @seqs;

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

# get target sites
{
	my @tempsites;
	for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
		if ($ARGV[$i] =~ /^-+(?:c|converse)$/i) {
			$converse = 1;
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)\-(\-?\d+)\\(\d+)$/) {
			my $temppos1 = $1;
			my $temppos2 = $2;
			if ($temppos1 < 0) {
				$temppos1 = $nchar + $temppos1 + 1;
			}
			if ($temppos2 < 0) {
				$temppos2 = $nchar + $temppos2 + 1;
			}
			if ($temppos1 < 1 || $temppos2 < 1 || $temppos1 > $nchar || $temppos2 > $nchar) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			if ($temppos1 < $temppos2) {
				push(@tempsites, &range2list($temppos1, $temppos2, $3));
			}
			elsif ($temppos1 > $temppos2) {
				push(@tempsites, &range2list($temppos2, $temppos1, $3));
			}
			elsif ($temppos1 == $temppos2) {
				push(@tempsites, $temppos1);
			}
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)\-\.\\(\d+)$/) {
			my $temppos = $1;
			if ($temppos < 0) {
				$temppos = $nchar + $temppos + 1;
			}
			if ($temppos < 1) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			if ($temppos < $nchar) {
				push(@tempsites, &range2list($temppos, $nchar, $2));
			}
			elsif ($temppos == $nchar) {
				push(@tempsites, $temppos);
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)\-(\-?\d+)$/) {
			my $temppos1 = $1;
			my $temppos2 = $2;
			if ($temppos1 < 0) {
				$temppos1 = $nchar + $temppos1 + 1;
			}
			if ($temppos2 < 0) {
				$temppos2 = $nchar + $temppos2 + 1;
			}
			if ($temppos1 < 1 || $temppos2 < 1 || $temppos1 > $nchar || $temppos2 > $nchar) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			if ($temppos1 < $temppos2) {
				push(@tempsites, $temppos1 .. $temppos2);
			}
			elsif ($temppos1 > $temppos2) {
				push(@tempsites, $temppos2 .. $temppos1);
			}
			elsif ($temppos1 == $temppos2) {
				push(@tempsites, $temppos1);
			}
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)\-\.$/) {
			my $temppos = $1;
			if ($temppos < 0) {
				$temppos = $nchar + $temppos + 1;
			}
			if ($temppos < 1) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			if ($temppos < $nchar) {
				push(@tempsites, $temppos .. $nchar);
			}
			elsif ($temppos == $nchar) {
				push(@tempsites, $temppos);
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)$/) {
			my $temppos = $1;
			if ($temppos < 0) {
				$temppos = $nchar + $temppos + 1;
			}
			if ($temppos < 1 || $temppos > $nchar) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			push(@tempsites, $temppos);
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
	my %target;
	if (@tempsites) {
		foreach my $siteno (@tempsites) {
			$target{$siteno} = 1;
		}
	}
	else {
		&errorMessage(__LINE__, 'Range specification is not valid.');
	}
	@target = sort({$a <=> $b} keys(%target));
	if ($target[0] < 1) {
		&errorMessage(__LINE__, 'Range specification is not valid.');
	}
	if ($target[-1] > $nchar) {
		&errorMessage(__LINE__, 'Range specification is not valid.');
	}
	if ($converse) {
		my %converse;
		foreach my $siteno (1 .. $nchar) {
			unless ($target{$siteno}) {
				$converse{$siteno} = 1;
			}
		}
		@target = sort({$a <=> $b} keys(%converse));
	}
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
		print($filehandle $seqs[$i][$site - 1]);
	}
	print($filehandle "\n");
}
if ($format eq 'NEXUS') {
	print($filehandle "\t;\nEnd;\n");
}
close($filehandle);

sub range2list {
	# Input: Site of range start, Site of range end, Skip number of sites
	# Output: List of sites which belong to the range
	my ($start, $end, $skip) = @_;
	my @num;
	if ($start != 0 && $skip != 0 && $start <= $end && $skip <= $end - $start) {
		for (my $i = $start; $i <= $end; $i += $skip) {
			push(@num, $i);
		}
	}
	else {
		&errorMessage(__LINE__, 'Partition specification is not valid.');
	}
	return(@num);
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
pgspliceseq options inputfile outputfile

Command line options
====================
INTEGER
INTEGER-INTEGER (start-end)
INTEGER-. (start-last)
INTEGER-INTEGER\\INTEGER (start-end\\skip)
  Specify output positions of sites.

-c, --converse
  If this option is specified, specified positions will be cut off and
nonspecified positions will be saved.

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
