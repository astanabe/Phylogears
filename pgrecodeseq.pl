my $buildno = '2.0.2016.04.14';
#
# pgrecodeseq
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

# To do: partition setting

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgrecodeseq $buildno
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
my %target;
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
my $taxnamelength;
if ($format ne 'FASTA') {
	foreach my $taxon (@taxa) {
		if ($taxnamelength < length($taxon)) {
			$taxnamelength = length($taxon);
		}
	}
}

# get target sites
my $type;
my $from;
my $to;
{
	my @tempsites;
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
			elsif ($1 =~ /^(?:Mix|Any)$/i) {
				$type = 'ANY';
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
			}
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
		elsif ($ARGV[$i] =~ /^(\S+)-(\S+)$/i) {
			$from = uc($1);
			$to = uc($2);
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
	if (!@tempsites) {
		@tempsites = 1 .. $nchar;
	}
	foreach my $siteno (@tempsites) {
		$target{$siteno} = 1;
	}
	my @target = sort({$a <=> $b} keys(%target));
	if ($target[0] < 1) {
		&errorMessage(__LINE__, 'Range specification is not valid.');
	}
	if ($target[-1] > $nchar) {
		&errorMessage(__LINE__, 'Range specification is not valid.');
	}
}

if (!$type) {
	&errorMessage(__LINE__, 'Sequence type is not specified.');
}
if (!$from || !$to) {
	&errorMessage(__LINE__, 'Recoding method is not specified.');
}
if (length($from) != length($to)) {
	&errorMessage(__LINE__, 'Specified recoding method is not valid.');
}
if ($type eq 'DNA' && ($from =~ /[^ACGT]/ || $to =~ /[^ACGT]/)) {
	&errorMessage(__LINE__, 'Specified recoding method is not valid.');
}
if ($type eq 'RNA' && ($from =~ /[^ACGU]/ || $to =~ /[^ACGU]/)) {
	&errorMessage(__LINE__, 'Specified recoding method is not valid.');
}
elsif ($type eq 'AA' && ($from =~ /[^ACGTRNDQEHILKMFPOSUWYV]/ || $to =~ /[^ACGTRNDQEHILKMFPOSUWYV]/)) {
	&errorMessage(__LINE__, 'Specified recoding method is not valid.');
}
my @from = split(/ */, $from);
my @to = split(/ */, $to);

# data recoding
for (my $i = 1; $i <= $nchar; $i ++) {
	if ($target{$i}) {
		for (my $j = 0; $j < $ntax; $j ++) {
			for (my $k = 0; $k < scalar(@from); $k ++) {
				if ($from[$k] ne $to[$k]) {
					if ($from[$k] eq $seqs[$j][$i - 1]) {
						$seqs[$j][$i - 1] = $to[$k];
					}
					elsif (&testCompatibility($from[$k], $seqs[$j][$i - 1]) == 0) {
						if ($type eq 'DNA' || $type eq 'RNA') {
							if ($from[$k] eq 'A' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'M') {
								$seqs[$j][$i - 1] = 'C';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'R') {
								$seqs[$j][$i - 1] = 'S';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'W') {
								$seqs[$j][$i - 1] = 'Y';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'S';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'Y';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'B';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'M') {
								$seqs[$j][$i - 1] = 'S';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'R') {
								$seqs[$j][$i - 1] = 'G';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'W') {
								$seqs[$j][$i - 1] = 'K';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'S';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'B';
							}
							elsif ($from[$k] eq 'A' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'K';
							}
							elsif ($from[$k] eq 'A' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'M') {
								$seqs[$j][$i - 1] = 'Y';
							}
							elsif ($from[$k] eq 'A' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'R') {
								$seqs[$j][$i - 1] = 'K';
							}
							elsif ($from[$k] eq 'A' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'W') {
								$seqs[$j][$i - 1] = $to[$k];
							}
							elsif ($from[$k] eq 'A' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'B';
							}
							elsif ($from[$k] eq 'A' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'Y';
							}
							elsif ($from[$k] eq 'A' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'K';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'M') {
								$seqs[$j][$i - 1] = 'A';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'S') {
								$seqs[$j][$i - 1] = 'R';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'Y') {
								$seqs[$j][$i - 1] = 'W';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'R';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'W';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'D';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'M') {
								$seqs[$j][$i - 1] = 'R';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'S') {
								$seqs[$j][$i - 1] = 'G';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'Y') {
								$seqs[$j][$i - 1] = 'K';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'R';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'D';
							}
							elsif ($from[$k] eq 'C' && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'K';
							}
							elsif ($from[$k] eq 'C' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'M') {
								$seqs[$j][$i - 1] = 'W';
							}
							elsif ($from[$k] eq 'C' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'S') {
								$seqs[$j][$i - 1] = 'K';
							}
							elsif ($from[$k] eq 'C' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'Y') {
								$seqs[$j][$i - 1] = $to[$k];
							}
							elsif ($from[$k] eq 'C' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'D';
							}
							elsif ($from[$k] eq 'C' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'W';
							}
							elsif ($from[$k] eq 'C' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'K';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'R') {
								$seqs[$j][$i - 1] = 'A';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'S') {
								$seqs[$j][$i - 1] = 'M';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'K') {
								$seqs[$j][$i - 1] = 'W';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'M';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'W';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'H';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'R') {
								$seqs[$j][$i - 1] = 'M';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'S') {
								$seqs[$j][$i - 1] = 'C';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'K') {
								$seqs[$j][$i - 1] = 'Y';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'M';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'H';
							}
							elsif ($from[$k] eq 'G' && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'Y';
							}
							elsif ($from[$k] eq 'G' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'R') {
								$seqs[$j][$i - 1] = 'W';
							}
							elsif ($from[$k] eq 'G' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'S') {
								$seqs[$j][$i - 1] = 'Y';
							}
							elsif ($from[$k] eq 'G' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'K') {
								$seqs[$j][$i - 1] = $to[$k];
							}
							elsif ($from[$k] eq 'G' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'V') {
								$seqs[$j][$i - 1] = 'H';
							}
							elsif ($from[$k] eq 'G' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'W';
							}
							elsif ($from[$k] eq 'G' && $to[$k] =~ /^[TU]$/ && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'Y';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'W') {
								$seqs[$j][$i - 1] = 'A';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'Y') {
								$seqs[$j][$i - 1] = 'M';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'K') {
								$seqs[$j][$i - 1] = 'R';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'M';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'R';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'A' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'V';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'W') {
								$seqs[$j][$i - 1] = 'M';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'Y') {
								$seqs[$j][$i - 1] = 'C';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'K') {
								$seqs[$j][$i - 1] = 'S';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'M';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'V';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'C' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'S';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'W') {
								$seqs[$j][$i - 1] = 'R';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'Y') {
								$seqs[$j][$i - 1] = 'S';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'K') {
								$seqs[$j][$i - 1] = 'G';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'H') {
								$seqs[$j][$i - 1] = 'V';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'D') {
								$seqs[$j][$i - 1] = 'R';
							}
							elsif ($from[$k] =~ /^[TU]$/ && $to[$k] eq 'G' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'S';
							}
							else {
								$seqs[$j][$i - 1] = 'N';
							}
						}
						elsif ($type eq 'AA') {
							if ($from[$k] eq 'N' && $to[$k] ne 'D' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'X';
							}
							elsif ($from[$k] eq 'D' && $to[$k] ne 'N' && $seqs[$j][$i - 1] eq 'B') {
								$seqs[$j][$i - 1] = 'X';
							}
							elsif ($from[$k] eq 'Q' && $to[$k] ne 'E' && $seqs[$j][$i - 1] eq 'Z') {
								$seqs[$j][$i - 1] = 'X';
							}
							elsif ($from[$k] eq 'E' && $to[$k] ne 'Q' && $seqs[$j][$i - 1] eq 'Z') {
								$seqs[$j][$i - 1] = 'X';
							}
							elsif ($from[$k] eq 'I' && $to[$k] ne 'L' && $seqs[$j][$i - 1] eq 'J') {
								$seqs[$j][$i - 1] = 'X';
							}
							elsif ($from[$k] eq 'L' && $to[$k] ne 'I' && $seqs[$j][$i - 1] eq 'J') {
								$seqs[$j][$i - 1] = 'X';
							}
							else {
								$seqs[$j][$i - 1] = $to[$k];
							}
						}
					}
				}
			}
		}
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

sub testCompatibility {
	# 0: compatible
	# 1: incompatible
	my ($seq1, $seq2) = @_;
	my $compatibility = 0;
	if ($seq1 eq $seq2) {
		$compatibility = 0;
	}
	elsif ($type eq 'DNA' || $type eq 'RNA') {
		# M and R is compatible
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
	elsif ($type eq 'AA') {
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
	else {
		$compatibility = 1;
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
pgrecodeseq options inputfile outputfile

Command line options
====================
-t, --type=DNA|RNA|AA|ANY
  Specify sequence type.

INTEGER
INTEGER-INTEGER (start-end)
INTEGER-. (start-last)
INTEGER-INTEGER\\INTEGER (start-end\\skip)
  Specify output positions of sites.

FROMchars-TOchars
  Specify recoding method.

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
