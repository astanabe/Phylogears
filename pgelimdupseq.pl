my $buildno = '2.0.x';
#
# pgelimdupseq
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
pgelimdupseq $buildno
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
my $format;
my $type;
my $prefer = 'unambiguous';
my $gap = 'missing';
my @taxa;
my @seqs;

# check options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:t|type)=(.+)$/i) {
		if ($1 =~ /^DNA$/i) {
			$type = 'DNA';
		}
		elsif ($1 =~ /^RNA$/i) {
			$type = 'RNA';
		}
		elsif ($1 =~ /^(?:AA|AminoAcid|Protein|Peptide)$/i) {
			$type = 'AA';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:p|prefer)=(.+)$/i) {
		if ($1 =~ /^(?:unambiguous|unambig|uambig|unam|uam|u)$/i) {
			$prefer = 'unambiguous';
		}
		elsif ($1 =~ /^(?:degenerate|degen|deg|d|ambiguous|ambig|ambig|am|a)$/i) {
			$prefer = 'degenerate';
		}
		elsif ($1 =~ /^(?:both|b)$/i) {
			$prefer = 'both';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:g|gap)=(.+)$/i) {
		if ($1 =~ /^(?:missing|miss|m)$/i) {
			$gap = 'missing';
		}
		elsif ($1 =~ /^(?:another|anot|a)$/i) {
			$gap = 'another';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

if (!$type) {
	&errorMessage(__LINE__, 'Sequence type is not specified.');
}

# file format recognition
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
				my $seq = uc($2);
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
					my $seq = uc($2);
					push(@taxa, $taxon);
					my @seq = $seq =~ /\S/g;
					push(@{$seqs[$num]}, @seq);
					$num ++;
				}
			}
			else {
				if (/^\s+(\S.*?)\s*\r?\n?$/) {
					my $seq = uc($1);
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
			my $seq = uc($_);
			my @seq = $seq =~ /\S/g;
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
			my $seq = uc($2);
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

# make new sequences
for (my $i = 0; $i < scalar(@taxa) - 1; $i ++) {
	for (my $j = $i + 1; $j < scalar(@taxa); $j ++) {
		if (!$taxa[$j] && !$seqs[$j]) {
			last;
		}
		elsif (!$taxa[$j] || !$seqs[$j]) {
			&errorMessage(__LINE__, "Unknown error.");
		}
		my $dist = 0;
		for (my $k = 0; $k < $nchar; $k ++) {
			if ($prefer eq 'both') {
				if ($seqs[$i][$k] ne $seqs[$j][$k]) {
					$dist ++;
				}
			}
			else {
				$dist += &testCompatibility($seqs[$i][$k], $seqs[$j][$k]);
			}
		}
		if ($dist == 0) {
			my $newtaxon = "$taxa[$i]__$taxa[$j]";
			my @newseq;
			for (my $k = 0; $k < $nchar; $k ++) {
				if ($seqs[$i][$k] ne $seqs[$j][$k]) {
					if ($type eq 'DNA' || $type eq 'RNA') {
						if ($prefer eq 'unambiguous') {
							if ($gap eq 'another') {
								if ($seqs[$i][$k] =~ /^[ACGTU\-]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[ACGTU\-]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$i][$k] eq '?') {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] eq '?') {
									push(@newseq, $seqs[$i][$k]);
								}
							}
							elsif ($gap eq 'missing') {
								if ($seqs[$i][$k] =~ /^[ACGTU]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[ACGTU]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$i][$k] =~ /^[\?\-]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[\?\-]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
							}
							if (!$newseq[$k]) {
								if ($seqs[$i][$k] eq 'N') {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] eq 'N') {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$i][$k] eq 'M' && $seqs[$j][$k] eq 'R' || $seqs[$i][$k] eq 'R' && $seqs[$j][$k] eq 'M') {
									push(@newseq, 'A');
								}
								elsif ($seqs[$i][$k] eq 'M' && $seqs[$j][$k] eq 'W' || $seqs[$i][$k] eq 'W' && $seqs[$j][$k] eq 'M') {
									push(@newseq, 'A');
								}
								elsif ($seqs[$i][$k] eq 'M' && $seqs[$j][$k] eq 'S' || $seqs[$i][$k] eq 'S' && $seqs[$j][$k] eq 'M') {
									push(@newseq, 'C');
								}
								elsif ($seqs[$i][$k] eq 'M' && $seqs[$j][$k] eq 'Y' || $seqs[$i][$k] eq 'Y' && $seqs[$j][$k] eq 'M') {
									push(@newseq, 'C');
								}
								elsif ($seqs[$i][$k] eq 'R' && $seqs[$j][$k] eq 'W' || $seqs[$i][$k] eq 'W' && $seqs[$j][$k] eq 'R') {
									push(@newseq, 'A');
								}
								elsif ($seqs[$i][$k] eq 'R' && $seqs[$j][$k] eq 'S' || $seqs[$i][$k] eq 'S' && $seqs[$j][$k] eq 'R') {
									push(@newseq, 'G');
								}
								elsif ($seqs[$i][$k] eq 'R' && $seqs[$j][$k] eq 'K' || $seqs[$i][$k] eq 'K' && $seqs[$j][$k] eq 'R') {
									push(@newseq, 'G');
								}
								elsif ($seqs[$i][$k] eq 'W' && $seqs[$j][$k] eq 'Y' || $seqs[$i][$k] eq 'Y' && $seqs[$j][$k] eq 'W') {
									push(@newseq, 'T');
								}
								elsif ($seqs[$i][$k] eq 'W' && $seqs[$j][$k] eq 'K' || $seqs[$i][$k] eq 'K' && $seqs[$j][$k] eq 'W') {
									push(@newseq, 'T');
								}
								elsif ($seqs[$i][$k] eq 'S' && $seqs[$j][$k] eq 'Y' || $seqs[$i][$k] eq 'Y' && $seqs[$j][$k] eq 'S') {
									push(@newseq, 'C');
								}
								elsif ($seqs[$i][$k] eq 'S' && $seqs[$j][$k] eq 'K' || $seqs[$i][$k] eq 'K' && $seqs[$j][$k] eq 'S') {
									push(@newseq, 'G');
								}
								elsif ($seqs[$i][$k] eq 'Y' && $seqs[$j][$k] eq 'K' || $seqs[$i][$k] eq 'K' && $seqs[$j][$k] eq 'Y') {
									push(@newseq, 'T');
								}
								elsif ($seqs[$i][$k] eq 'V' && $seqs[$j][$k] =~ /^[MRS]$/ || $seqs[$i][$k] eq 'H' && $seqs[$j][$k] =~ /^[MWY]$/ || $seqs[$i][$k] eq 'D' && $seqs[$j][$k] =~ /^[RWK]$/ || $seqs[$i][$k] eq 'B' && $seqs[$j][$k] =~ /^[SYK]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$i][$k] =~ /^[MRS]$/ && $seqs[$j][$k] eq 'V' || $seqs[$i][$k] =~ /^[MWY]$/ && $seqs[$j][$k] eq 'H' || $seqs[$i][$k] =~ /^[RWK]$/ && $seqs[$j][$k] eq 'D' || $seqs[$i][$k] =~ /^[SYK]$/ && $seqs[$j][$k] eq 'B') {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$i][$k] eq 'V' && $seqs[$j][$k] eq 'H' || $seqs[$i][$k] eq 'H' && $seqs[$j][$k] eq 'V') {
									push(@newseq, 'M');
								}
								elsif ($seqs[$i][$k] eq 'V' && $seqs[$j][$k] eq 'D' || $seqs[$i][$k] eq 'D' && $seqs[$j][$k] eq 'V') {
									push(@newseq, 'R');
								}
								elsif ($seqs[$i][$k] eq 'V' && $seqs[$j][$k] eq 'B' || $seqs[$i][$k] eq 'B' && $seqs[$j][$k] eq 'V') {
									push(@newseq, 'S');
								}
								elsif ($seqs[$i][$k] eq 'H' && $seqs[$j][$k] eq 'D' || $seqs[$i][$k] eq 'D' && $seqs[$j][$k] eq 'H') {
									push(@newseq, 'W');
								}
								elsif ($seqs[$i][$k] eq 'H' && $seqs[$j][$k] eq 'B' || $seqs[$i][$k] eq 'B' && $seqs[$j][$k] eq 'H') {
									push(@newseq, 'Y');
								}
								elsif ($seqs[$i][$k] eq 'D' && $seqs[$j][$k] eq 'B' || $seqs[$i][$k] eq 'B' && $seqs[$j][$k] eq 'D') {
									push(@newseq, 'K');
								}
								else {
									&errorMessage(__LINE__, "Unknown error.");
								}
							}
						}
						elsif ($prefer eq 'degenerate') {
							if ($gap eq 'another') {
								if ($seqs[$i][$k] =~ /^[ACGTU\-]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[ACGTU\-]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$i][$k] eq '?') {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] eq '?') {
									push(@newseq, $seqs[$j][$k]);
								}
							}
							elsif ($gap eq 'missing') {
								if ($seqs[$i][$k] =~ /^[ACGTU]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[ACGTU]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$i][$k] =~ /^[\?\-]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[\?\-]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
							}
							if (!$newseq[$k]) {
								if ($seqs[$i][$k] eq 'N') {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] eq 'N') {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$i][$k] eq 'M' && $seqs[$j][$k] eq 'R' || $seqs[$i][$k] eq 'R' && $seqs[$j][$k] eq 'M') {
									push(@newseq, 'V');
								}
								elsif ($seqs[$i][$k] eq 'M' && $seqs[$j][$k] eq 'W' || $seqs[$i][$k] eq 'W' && $seqs[$j][$k] eq 'M') {
									push(@newseq, 'H');
								}
								elsif ($seqs[$i][$k] eq 'M' && $seqs[$j][$k] eq 'S' || $seqs[$i][$k] eq 'S' && $seqs[$j][$k] eq 'M') {
									push(@newseq, 'V');
								}
								elsif ($seqs[$i][$k] eq 'M' && $seqs[$j][$k] eq 'Y' || $seqs[$i][$k] eq 'Y' && $seqs[$j][$k] eq 'M') {
									push(@newseq, 'H');
								}
								elsif ($seqs[$i][$k] eq 'R' && $seqs[$j][$k] eq 'W' || $seqs[$i][$k] eq 'W' && $seqs[$j][$k] eq 'R') {
									push(@newseq, 'D');
								}
								elsif ($seqs[$i][$k] eq 'R' && $seqs[$j][$k] eq 'S' || $seqs[$i][$k] eq 'S' && $seqs[$j][$k] eq 'R') {
									push(@newseq, 'V');
								}
								elsif ($seqs[$i][$k] eq 'R' && $seqs[$j][$k] eq 'K' || $seqs[$i][$k] eq 'K' && $seqs[$j][$k] eq 'R') {
									push(@newseq, 'D');
								}
								elsif ($seqs[$i][$k] eq 'W' && $seqs[$j][$k] eq 'Y' || $seqs[$i][$k] eq 'Y' && $seqs[$j][$k] eq 'W') {
									push(@newseq, 'H');
								}
								elsif ($seqs[$i][$k] eq 'W' && $seqs[$j][$k] eq 'K' || $seqs[$i][$k] eq 'K' && $seqs[$j][$k] eq 'W') {
									push(@newseq, 'D');
								}
								elsif ($seqs[$i][$k] eq 'S' && $seqs[$j][$k] eq 'Y' || $seqs[$i][$k] eq 'Y' && $seqs[$j][$k] eq 'S') {
									push(@newseq, 'B');
								}
								elsif ($seqs[$i][$k] eq 'S' && $seqs[$j][$k] eq 'K' || $seqs[$i][$k] eq 'K' && $seqs[$j][$k] eq 'S') {
									push(@newseq, 'B');
								}
								elsif ($seqs[$i][$k] eq 'Y' && $seqs[$j][$k] eq 'K' || $seqs[$i][$k] eq 'K' && $seqs[$j][$k] eq 'Y') {
									push(@newseq, 'B');
								}
								elsif ($seqs[$i][$k] eq 'V' && $seqs[$j][$k] =~ /^[MRS]$/ || $seqs[$i][$k] eq 'H' && $seqs[$j][$k] =~ /^[MWY]$/ || $seqs[$i][$k] eq 'D' && $seqs[$j][$k] =~ /^[RWK]$/ || $seqs[$i][$k] eq 'B' && $seqs[$j][$k] =~ /^[SYK]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$i][$k] =~ /^[MRS]$/ && $seqs[$j][$k] eq 'V' || $seqs[$i][$k] =~ /^[MWY]$/ && $seqs[$j][$k] eq 'H' || $seqs[$i][$k] =~ /^[RWK]$/ && $seqs[$j][$k] eq 'D' || $seqs[$i][$k] =~ /^[SYK]$/ && $seqs[$j][$k] eq 'B') {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$i][$k] eq 'V' && $seqs[$j][$k] eq 'H' || $seqs[$i][$k] eq 'H' && $seqs[$j][$k] eq 'V') {
									push(@newseq, 'N');
								}
								elsif ($seqs[$i][$k] eq 'V' && $seqs[$j][$k] eq 'D' || $seqs[$i][$k] eq 'D' && $seqs[$j][$k] eq 'V') {
									push(@newseq, 'N');
								}
								elsif ($seqs[$i][$k] eq 'V' && $seqs[$j][$k] eq 'B' || $seqs[$i][$k] eq 'B' && $seqs[$j][$k] eq 'V') {
									push(@newseq, 'N');
								}
								elsif ($seqs[$i][$k] eq 'H' && $seqs[$j][$k] eq 'D' || $seqs[$i][$k] eq 'D' && $seqs[$j][$k] eq 'H') {
									push(@newseq, 'N');
								}
								elsif ($seqs[$i][$k] eq 'H' && $seqs[$j][$k] eq 'B' || $seqs[$i][$k] eq 'B' && $seqs[$j][$k] eq 'H') {
									push(@newseq, 'N');
								}
								elsif ($seqs[$i][$k] eq 'D' && $seqs[$j][$k] eq 'B' || $seqs[$i][$k] eq 'B' && $seqs[$j][$k] eq 'D') {
									push(@newseq, 'N');
								}
								else {
									&errorMessage(__LINE__, "Unknown error.");
								}
							}
						}
					}
					else {
						if ($prefer eq 'unambiguous') {
							if ($gap eq 'another') {
								if ($seqs[$i][$k] =~ /^[ARNDCQEGHILKMFPOSUTWYV\-\*]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[ARNDCQEGHILKMFPOSUTWYV\-\*]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$i][$k] eq '?') {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] eq '?') {
									push(@newseq, $seqs[$i][$k]);
								}
							}
							elsif ($gap eq 'missing') {
								if ($seqs[$i][$k] =~ /^[ARNDCQEGHILKMFPOSUTWYV\*]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[ARNDCQEGHILKMFPOSUTWYV\*]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$i][$k] =~ /^[\?\-]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[\?\-]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
							}
							if (!$newseq[$k]) {
								if ($seqs[$i][$k] eq 'X') {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] eq 'X') {
									push(@newseq, $seqs[$i][$k]);
								}
								else {
									&errorMessage(__LINE__, "Unknown error.");
								}
							}
						}
						elsif ($prefer eq 'degenerate') {
							if ($gap eq 'another') {
								if ($seqs[$i][$k] =~ /^[ARNDCQEGHILKMFPOSUTWYV\-\*]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[ARNDCQEGHILKMFPOSUTWYV\-\*]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$i][$k] eq '?') {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] eq '?') {
									push(@newseq, $seqs[$j][$k]);
								}
							}
							elsif ($gap eq 'missing') {
								if ($seqs[$i][$k] =~ /^[ARNDCQEGHILKMFPOSUTWYV\*]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[ARNDCQEGHILKMFPOSUTWYV\*]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$i][$k] =~ /^[\?\-]$/) {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] =~ /^[\?\-]$/) {
									push(@newseq, $seqs[$j][$k]);
								}
							}
							if (!$newseq[$k]) {
								if ($seqs[$i][$k] eq 'X') {
									push(@newseq, $seqs[$i][$k]);
								}
								elsif ($seqs[$j][$k] eq 'X') {
									push(@newseq, $seqs[$j][$k]);
								}
								else {
									&errorMessage(__LINE__, "Unknown error.");
								}
							}
						}
					}
				}
				else {
					push(@newseq, $seqs[$i][$k]);
				}
			}
			splice(@taxa, $i, 1, $newtaxon);
			splice(@taxa, $j, 1);
			splice(@seqs, $i, 1, \@newseq);
			splice(@seqs, $j, 1);
			redo;
		}
	}
}

my $taxnamelength;
if ($format ne 'FASTA') {
	foreach my $taxon (@taxa) {
		if ($taxnamelength < length($taxon)) {
			$taxnamelength = length($taxon);
		}
	}
}
if ($format eq 'PHYLIP' && $outputfile !~ /^stdout$/i) {
	print("Sequence names will be replace and table file will be output.\n");
	my $temp = 1;
	my @newtaxa;
	foreach my $taxon (@taxa) {
		push(@newtaxa, "Tax$temp");
		$temp ++;
	}
	if (-e "$outputfile.table") {
		&errorMessage(__LINE__, "\"$outputfile.table\" already exists.");
	}
	unless (open(OUTFILE, "> $outputfile.table")) {
		&errorMessage(__LINE__, "Cannot make \"$outputfile.table\".");
	}
	for (my $i = 0; $i < scalar(@taxa); $i ++) {
		printf(OUTFILE "%-10s ", $newtaxa[$i]);
		print(OUTFILE "\"$taxa[$i]\"\n");
	}
	close(OUTFILE);
	@taxa = @newtaxa;
}
elsif ($format eq 'PHYLIP' && $outputfile =~ /^stdout$/i) {
	&errorMessage(__LINE__, "Cannot output to STDOUT.");
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
	print($filehandle "#NEXUS\n\nBegin Data;\n\tDimensions NTax=$ntax NChar=$nchar;\n\t$nexusformat\n\tMatrix\n");
}
elsif ($format eq 'PHYLIP' || $format eq 'PHYLIPex') {
	print($filehandle $ntax . ' ' . $nchar . "\n");
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
	print($filehandle join('', @{$seqs[$i]}));
	print($filehandle "\n");
}
if ($format eq 'NEXUS') {
	print($filehandle "\t;\nEnd;\n");
}
close($filehandle);

sub testCompatibility {
	# 0: compatible
	# 1: incompatible
	my ($seq1, $seq2) = @_;
	my $compatibility = 0;
	if ($seq1 eq $seq2) {
		$compatibility = 0;
	}
	elsif ($gap eq 'another' && $seq1 eq '-' && $seq2 ne '-' && $seq2 ne '?') {
		$compatibility = 1;
	}
	elsif ($gap eq 'another' && $seq2 eq '-' && $seq1 ne '-' && $seq1 ne '?') {
		$compatibility = 1;
	}
	elsif ($type eq 'DNA' || $type eq 'RNA') {
		if ($seq1 eq 'A' && $seq2 =~ /^[CGTUSYKB]$/ ||
			$seq1 eq 'C' && $seq2 =~ /^[AGTURWKD]$/ ||
			$seq1 eq 'G' && $seq2 =~ /^[ACTUMWYH]$/ ||
			$seq1 =~ /^[TU]$/ && $seq2 =~ /^[ACGMRSV]$/ ||
			$seq1 eq 'M' && $seq2 =~ /^[KGT]$/ ||
			$seq1 eq 'R' && $seq2 =~ /^[YCT]$/ ||
			$seq1 eq 'W' && $seq2 =~ /^[SCG]$/ ||
			$seq1 eq 'S' && $seq2 =~ /^[WAT]$/ ||
			$seq1 eq 'Y' && $seq2 =~ /^[RAG]$/ ||
			$seq1 eq 'K' && $seq2 =~ /^[MAC]$/ ||
			$seq1 eq 'B' && $seq2 eq 'A' ||
			$seq1 eq 'D' && $seq2 eq 'C' ||
			$seq1 eq 'H' && $seq2 eq 'G' ||
			$seq1 eq 'V' && $seq2 =~ /^[TU]$/) {
			$compatibility = 1;
		}
	}
	else {
		if ($seq1 eq 'A' && $seq2 =~ /^[CGTRNDQEHILKMFPOSUWYVBZJ]$/ ||
			$seq1 eq 'C' && $seq2 =~ /^[AGTRNDQEHILKMFPOSUWYVBZJ]$/ ||
			$seq1 eq 'G' && $seq2 =~ /^[ACTRNDQEHILKMFPOSUWYVBZJ]$/ ||
			$seq1 eq 'T' && $seq2 =~ /^[ACGRNDQEHILKMFPOSUWYVBZJ]$/ ||
			$seq1 eq 'R' && $seq2 =~ /^[ACGTNDQEHILKMFPOSUWYVBZJ]$/ ||
			$seq1 eq 'N' && $seq2 =~ /^[ACGTRDQEHILKMFPOSUWYVZJ]$/ ||
			$seq1 eq 'D' && $seq2 =~ /^[ACGTRNQEHILKMFPOSUWYVZJ]$/ ||
			$seq1 eq 'Q' && $seq2 =~ /^[ACGTRNDEHILKMFPOSUWYVBJ]$/ ||
			$seq1 eq 'E' && $seq2 =~ /^[ACGTRNDQHILKMFPOSUWYVBJ]$/ ||
			$seq1 eq 'H' && $seq2 =~ /^[ACGTRNDQEILKMFPOSUWYVBZJ]$/ ||
			$seq1 eq 'I' && $seq2 =~ /^[ACGTRNDQEHLKMFPOSUWYVBZ]$/ ||
			$seq1 eq 'L' && $seq2 =~ /^[ACGTRNDQEHIKMFPOSUWYVBZ]$/ ||
			$seq1 eq 'K' && $seq2 =~ /^[ACGTRNDQEHILMFPOSUWYVBZJ]$/ ||
			$seq1 eq 'M' && $seq2 =~ /^[ACGTRNDQEHILKFPOSUWYVBZJ]$/ ||
			$seq1 eq 'F' && $seq2 =~ /^[ACGTRNDQEHILKMPOSUWYVBZJ]$/ ||
			$seq1 eq 'P' && $seq2 =~ /^[ACGTRNDQEHILKMFOSUWYVBZJ]$/ ||
			$seq1 eq 'O' && $seq2 =~ /^[ACGTRNDQEHILKMFPSUWYVBZJ]$/ ||
			$seq1 eq 'S' && $seq2 =~ /^[ACGTRNDQEHILKMFPOUWYVBZJ]$/ ||
			$seq1 eq 'U' && $seq2 =~ /^[ACGTRNDQEHILKMFPOSWYVBZJ]$/ ||
			$seq1 eq 'W' && $seq2 =~ /^[ACGTRNDQEHILKMFPOSUYVBZJ]$/ ||
			$seq1 eq 'Y' && $seq2 =~ /^[ACGTRNDQEHILKMFPOSUWVBZJ]$/ ||
			$seq1 eq 'V' && $seq2 =~ /^[ACGTRNDQEHILKMFPOSUWYBZJ]$/ ||
			$seq1 eq 'B' && $seq2 =~ /^[ACGTRQEHILKMFPOSUWYV]$/ || # N or D
			$seq1 eq 'Z' && $seq2 =~ /^[ACGTRNDHILKMFPOSUWYV]$/ || # Q or E
			$seq1 eq 'J' && $seq2 =~ /^[ACGTRNDQEHKMFPOSUWYV]$/) { # I or L
			$compatibility = 1;
		}
	}
	return($compatibility);
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
pgelimdupseq options inputfile outputfile

Command line options
====================
-t, --type=DNA|RNA|AA
  Specify sequence type.

-p, --prefer=UNAMBIGUOUS|DEGENERATE|BOTH
  Specify which sequence will be remained.

-g, --gap=MISSING|ANOTHER
  Specify gap handling setting.

Acceptable input file formats
=============================
FASTA
NEXUS
PHYLIP
PHYLIPex
TF (Treefinder)
(This script does not accept multiple data sets.)
_END
	exit;
}
