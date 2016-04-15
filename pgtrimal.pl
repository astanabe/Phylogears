my $buildno = '2.0.x';
#
# pgtrimal
# 
# Official web site of this script is
# http://www.fifthdimension.jp/products/phylogears/ .
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

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgtrimal $buildno
=======================================================================

Official web site of this script is
http://www.fifthdimension.jp/products/phylogears/ .
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

unless (@ARGV) {
	&helpMessage();
}

# initialize variables
my $method = '-gappyout';
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $ntax;
my $nchar;
my $datatype;
my $taxnamelength = 0;
my @taxa;
my %seqs;
my $frame;

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:m|method)=(.+)$/i) {
		if ($1 =~ /^GAPPYOUT$/i || $1 =~ /^GAPPY$/i) {
			$method = '-gappyout';
		}
		elsif ($1 =~ /^STRICT$/i) {
			$method = '-strict';
		}
		elsif ($1 =~ /^STRICTPLUS$/i) {
			$method = '-strictplus';
		}
		elsif ($1 =~ /^AUTOMATED1$/i || $1 =~ /^AUTOMATED$/i) {
			$method = '-automated1';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:f|frame)=([1-3])$/i) {
		$frame = $1;
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

# file format recognition
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
while (<INFILE>) {
	unless (/^#NEXUS/i) {
		&errorMessage(__LINE__, "\"$inputfile\" is not NEXUS format.");
	}
	last;
}
close(INFILE);

# read input file
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
{
	my $datablock = 0;
	my $matrix = 0;
	while (<INFILE>) {
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
				unless ($seqs{$taxon}) {
					push(@taxa, $taxon);
				}
				my @seq = $seq =~ /\S/g;
				push(@{$seqs{$taxon}}, @seq);
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
		elsif ($datablock == 1 && $matrix == 0 && /DataType\s*=\s*(\S+)/i) {
			$datatype = $1;
		}
		elsif ($datablock == 1 && $matrix == 0 && /^\s*Matrix/i) {
			$matrix = 1;
		}
	}
}
close(INFILE);

if ($datatype ne 'DNA' && $datatype ne 'RNA' && $frame) {
	&errorMessage(__LINE__, "Frame to translate was specified, but data is not DNA or RNA.");
}
if (scalar(@taxa) != $ntax) {
	&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
}
foreach my $taxon (@taxa) {
	if (scalar(@{$seqs{$taxon}}) != $nchar) {
		&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
	}
	if ($taxnamelength < length($taxon)) {
		$taxnamelength = length($taxon);
	}
}

# get conserved blocks
my @outputsites;
{
	my @conserved;
	{
		my $tempnum = 0;
		while (-e $inputfile . ".$tempnum") {
			$tempnum ++;
		}
		my $temp = `trimal -in $inputfile -out $inputfile.$tempnum $method -colnumbering`;
		unlink("$inputfile.$tempnum");
		@conserved = $temp =~ /(\d+)/g;
		@conserved = sort({$a <=> $b} @conserved);
	}
	{
		my $tempnum = 0;
		for (my $i = 0; $i < scalar(@conserved); $i ++) {
			push(@{$outputsites[$tempnum]}, $conserved[$i]);
			if ($conserved[($i + 1)] > $conserved[$i] + 1) {
				$tempnum ++;
			}
		}
	}
}
# if data is protein-coding
if ($frame) {
	# delete blocks shorter than 3
	{
		my @delete;
		for (my $i = 0; $i < scalar(@outputsites); $i ++) {
			if (scalar(@{$outputsites[$i]}) < 3) {
				push(@delete, $i);
			}
		}
		foreach my $delete (sort({$b <=> $a} @delete)) {
			splice(@outputsites, $delete, 1);
		}
	}
	# grind blocks
	for (my $i = 0; $i < scalar(@outputsites); $i ++) {
		my %delete;
		if ($i != 0) {
			my $start = $outputsites[$i][0] % 3;
			# 0, 1, 2 means that start position is 1st, 2nd, 3rd codon position, respectively, when frame is 1.
			# 0, 1, 2 means that start position is 2nd, 3rd, 1st codon position, respectively, when frame is 2.
			# 0, 1, 2 means that start position is 3rd, 1st, 2nd codon position, respectively, when frame is 3.
			if ($frame == 1 && $start == 2 || $frame == 2 && $start == 1 || $frame == 3 && $start == 0) { # if start position is 3rd codon position
				$delete{0} = 1;
			}
			elsif ($frame == 1 && $start == 1 || $frame == 2 && $start == 0 || $frame == 3 && $start == 2) { # if start position is 2nd codon position
				$delete{0} = 1;
				$delete{1} = 1;
			}
		}
		if ($i != scalar(@outputsites) - 1) {
			my $end = $outputsites[$i][-1] % 3;
			# 0, 1, 2 means that end position is 1st, 2nd, 3rd codon position, respectively, when frame is 1.
			# 0, 1, 2 means that end position is 2nd, 3rd, 1st codon position, respectively, when frame is 2.
			# 0, 1, 2 means that end position is 3rd, 1st, 2nd codon position, respectively, when frame is 3.
			if ($frame == 1 && $end == 1 || $frame == 2 && $end == 0 || $frame == 3 && $end == 2) { # if end position is 2nd codon position
				$delete{(scalar(@{$outputsites[$i]}) - 1)} = 1;
				$delete{(scalar(@{$outputsites[$i]}) - 2)} = 1;
			}
			elsif ($frame == 1 && $end == 0 || $frame == 2 && $end == 2 || $frame == 3 && $end == 1) { # if end position is 1st codon position
				$delete{(scalar(@{$outputsites[$i]}) - 1)} = 1;
			}
		}
		foreach my $delete (sort({$b <=> $a} keys(%delete))) {
			splice(@{$outputsites[$i]}, $delete, 1);
		}
	}
}

my $outputnchar = 0;
for (my $i = 0; $i < @outputsites; $i ++) {
	$outputnchar += scalar(@{$outputsites[$i]});
}

# output file
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
print($filehandle "#NEXUS\n");
print($filehandle "\nBegin Data;\n\tDimensions NTax=$ntax NChar=$outputnchar;\n");
print($filehandle "\tFormat DataType=$datatype Gap=- Missing=? Interleave;\n");
print($filehandle "\tMatrix\n");
for (my $i = 0; $i < @outputsites; $i ++) {
	foreach my $taxon (@taxa) {
		printf($filehandle "%-*s ", $taxnamelength, $taxon);
		foreach my $site (@{$outputsites[$i]}) {
			print($filehandle $seqs{$taxon}[$site]);
		}
		print($filehandle "\n");
	}
}
print($filehandle "\t;\nEnd;\n");

sub errorMessage {
	my $lineno = shift(@_);
	my $message = shift(@_);
	print("ERROR!: line $lineno\n$message\n");
	print("If you want to read help message, run this script without options.\n");
	exit(1);
}

sub helpMessage {
	print(<<"_END");
Usage
=====
pgtrimal options inputfile outputfile

Command line options
====================
-m, --method=GAPPYOUT|STRICT|STRICTPLUS|AUTOMATED1
  Specify the method to trim alignments. (default: GAPPYOUT)

-f, --frame=1|2|3
  Specify the frame to translate, if data is protein-coding nucleotide.
(default: none)

Acceptable input file formats
=============================
NEXUS
_END
	exit;
}
