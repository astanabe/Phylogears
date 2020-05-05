my $buildno = '2.0.x';
#
# pgencodegap
# 
# Official web site of this script is
# https://www.fifthdimension.jp/products/phylogears/ .
# To know script details, see above URL.
# 
# Copyright (C) 2008-2018  Akifumi S. Tanabe
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
pgencodegap $buildno
=======================================================================

Official web site of this script is
https://www.fifthdimension.jp/products/phylogears/ .
To know script details, see above URL.

Copyright (C) 2008-2018  Akifumi S. Tanabe

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
my $method = 'SIC';
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $ntax;
my $nchar;
my $taxnamelength = 0;
my @taxa;
my %seqs;
my $separation = 0;
my %separator;

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:m|method)=(.+)$/i) {
		if ($1 =~ /^vMCICwoSM$/i) {
			$method = 'vMCICwoSM';
		}
		elsif ($1 =~ /^vMCIC$/i) {
			$method = 'vMCIC';
		}
		elsif ($1 =~ /^FC2001$/i) {
			$method = 'FC2001';
		}
		elsif ($1 =~ /^(?:Simple|SIC)$/i) {
			$method = 'SIC';
		}
		elsif ($1 =~ /^(?:Quasi5th|Q5SC)$/i) {
			$method = 'Q5SC';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:i|interleave)=(.+)$/i) {
		if ($1 =~ /^ignore$/i) {
			$separation = 0;
		}
		elsif ($1 =~ /^separator$/i) {
			$separation = 1;
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
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
				if ($separation) {
					$separator{(scalar(@{$seqs{$taxon}}) - 1)} = 1;
				}
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
		elsif ($datablock == 1 && $matrix == 0 && /^\s*Matrix/i) {
			$matrix = 1;
		}
	}
}
close(INFILE);

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

# gap coding
my %gaps;
my @start;
my @end;
my $gapnchar = 0;
{
	my @position;
	if ($method eq 'SIC') {
		my %gapposition;
		foreach my $taxon (@taxa) {
			my $begin;
			for (my $i = 0; $i < $nchar; $i ++) {
				if (!defined($begin) && $seqs{$taxon}[$i] eq '-') {
					$begin = $i;
				}
				if (defined($begin) && ($seqs{$taxon}[($i + 1)] ne '-' || $separator{$i})) {
					@{$gapposition{$begin . '-' . $i}} = ($begin, $i);
					undef($begin);
				}
			}
		}
		foreach my $gapposition (sort({$gapposition{$a}[0] <=> $gapposition{$b}[0] || $gapposition{$a}[1] <=> $gapposition{$b}[1]} keys(%gapposition))) {
			push(@position, @{$gapposition{$gapposition}});
		}
	}
	else {
		my @motif;
		for (my $i = 0; $i < $nchar; $i ++) {
			foreach my $taxon (@taxa) {
				if ($seqs{$taxon}[$i] eq '-') {
					$motif[$i] .= 1;
				}
				else {
					$motif[$i] .= 0;
				}
			}
		}
		if ($method eq 'Q5SC') {
			for (my $i = 0; $i < $nchar; $i ++) {
				if ($motif[$i] =~ /1/) {
					push(@position, $i, $i);
				}
			}
		}
		elsif ($method eq 'FC2001') {
			my $begin;
			for (my $i = 0; $i < $nchar; $i ++) {
				if (!defined($begin) && $motif[$i] =~ /1/) {
					$begin = $i;
				}
				if (defined($begin) && ($motif[$i] ne $motif[($i + 1)] || $separator{$i})) {
					push(@position, $begin, $i);
					undef($begin);
				}
			}
		}
		elsif ($method =~ /^vMCIC/) {
			my $begin;
			for (my $i = 0; $i < $nchar; $i ++) {
				if (!defined($begin) && $motif[$i] =~ /1/) {
					$begin = $i;
				}
				if (defined($begin)) {
					my $temp = $motif[$i] + $motif[($i + 1)];
					if ($motif[($i + 1)] == 0 || $temp !~ /2/ || $separator{$i}) {
						push(@position, $begin, $i);
						undef($begin);
					}
				}
			}
		}
	}
	# check missing data and delete position if there are missing data
	if ($method =~ /^vMCIC/) {
		my @tempposition;
		for (my $i = 0; $i < scalar(@position); $i += 2) {
			my $missing = 0;
			foreach my $taxon (@taxa) {
				for (my $j = $position[$i]; $j <= $position[($i + 1)]; $j ++) {
					if ($seqs{$taxon}[$j] eq '?') {
						$missing = 1;
						last;
					}
				}
				if ($missing) {
					last;
				}
			}
			unless ($missing) {
				push(@tempposition, $position[$i], $position[($i + 1)]);
			}
		}
		@position = @tempposition;
	}
	# encode
	my @include;
	my %gap2taxa;
	my @stepmatrices;
	for (my $i = 0; $i < scalar(@position); $i += 2) {
		my %states;
		my $state = 0;
		my @motif;
		# make gap sequences
		foreach my $taxon (@taxa) {
			my $gap = 0;
			my $tempseq;
			for (my $j = $position[$i]; $j <= $position[($i + 1)]; $j ++) {
				if ($seqs{$taxon}[$j] eq '-') {
					$tempseq .= 1;
				}
				elsif ($seqs{$taxon}[$j] eq '?') {
					$tempseq .= '?';
				}
				else {
					$tempseq .= 0;
				}
			}
			# SIC, FC2001, and Q5SC
			if ($method eq 'SIC' || $method eq 'FC2001' || $method eq 'Q5SC') {
				if ($tempseq =~ /^1+$/) {
					$gap = 1;
					if ($method eq 'SIC') {
						push(@{$gap2taxa{$i / 2}}, $taxon);
					}
				}
				elsif ($tempseq =~ /^\?+$/) {
					$gap = '?';
				}
			}
			# vMCICwoSM and vMCIC
			elsif ($method =~ /^vMCIC/) {
				if (exists($states{$tempseq})) {
					$gap = $states{$tempseq};
				}
				else {
					$gap = $state;
					$states{$tempseq} = $gap;
					my @tempseq = $tempseq =~ /\S/g;
					push(@motif, \@tempseq);
					$state ++;
				}
			}
			push(@{$gaps{$taxon}}, $gap);
		}
		# make step matrix
		if ($method eq 'vMCIC') {
			my @tempmatrix;
			for (my $j = $state - 1; $j >= 0; $j --) {
				for (my $k = $j - 1; $k >= 0; $k --) {
					my @seqA = @{$motif[$j]};
					my @seqB = @{$motif[$k]};
					my $tempnum = scalar(@seqA) - 1;
					# delete gap-gap
					while ($tempnum >= 0) {
						if ($seqA[$tempnum] == 1 && $seqB[$tempnum] == 1) {
							splice(@seqA, $tempnum, 1);
							splice(@seqB, $tempnum, 1);
						}
						$tempnum --;
					}
					# merge neighboring and identical sites
					$tempnum = scalar(@seqA) - 1;
					while ($tempnum > 0) {
						if ($seqA[$tempnum] == $seqA[($tempnum - 1)] && $seqB[$tempnum] == $seqB[($tempnum - 1)]) {
							splice(@seqA, $tempnum, 1);
							splice(@seqB, $tempnum, 1);
						}
						$tempnum --;
					}
					# delete nongap-nongap
					$tempnum = scalar(@seqA) - 1;
					while ($tempnum >= 0) {
						if ($seqA[$tempnum] == 0 && $seqB[$tempnum] == 0) {
							splice(@seqA, $tempnum, 1);
							splice(@seqB, $tempnum, 1);
						}
						$tempnum --;
					}
					# measure steps by count sites
					$tempmatrix[$j][$k] = scalar(@seqA);
				}
			}
			push(@stepmatrices, \@tempmatrix);
		}
		elsif ($method eq 'vMCICwoSM') {
			my @tempmatrix;
			for (my $j = $state - 1; $j >= 0; $j --) {
				for (my $k = $j - 1; $k >= 0; $k --) {
					$tempmatrix[$j][$k] = 1;
				}
			}
			push(@stepmatrices, \@tempmatrix);
		}
		if ($method eq 'SIC') {
			my @tempinclude;
			for (my $j = 0; $j < scalar(@position); $j += 2) {
				if ($i != $j) {
					if ($position[$j] >= $position[$i] && $position[($j + 1)] <= $position[($i + 1)]) {
						push(@tempinclude, $j / 2);
					}
				}
			}
			if (@tempinclude) {
				push(@include, \@tempinclude);
			}
			else {
				push(@tempinclude, 'N');
				push(@include, \@tempinclude);
			}
		}
	}
	if ($method eq 'SIC') {
		for (my $i = 0; $i < scalar(@include); $i ++) {
			foreach my $includedgap (@{$include[$i]}) {
				if ($includedgap ne 'N') {
					foreach my $taxon (@{$gap2taxa{$i}}) {
						$gaps{$taxon}[$includedgap] = '?';
					}
				}
			}
		}
	}
	elsif ($method =~ /^vMCIC/) {
		# transform multistate character into binary characters
		my $tempnum = scalar(@{$gaps{$taxa[0]}}) - 1;
		while ($tempnum >= 0) {
			my $maxstate = 0;
			# measure the number of character states
			foreach my $taxon (@taxa) {
				if ($gaps{$taxon}[$tempnum] > $maxstate) {
					$maxstate = $gaps{$taxon}[$tempnum];
				}
			}
			# make temporal binary characters
			my %tempseq;
			for (my $i = 0; $i < $maxstate; $i ++) {
				for (my $j = $i + 1; $j <= $maxstate; $j ++) {
					# upweight character sites with reference to step matrices
					for (my $k = 0; $k < $stepmatrices[$tempnum][$j][$i]; $k ++) {
						foreach my $taxon (@taxa) {
							if ($gaps{$taxon}[$tempnum] == $i) {
								push(@{$tempseq{$taxon}}, '0');
							}
							elsif ($gaps{$taxon}[$tempnum] == $j) {
								push(@{$tempseq{$taxon}}, '1');
							}
							else {
								push(@{$tempseq{$taxon}}, '?');
							}
						}
					}
				}
			}
			# update gaps
			foreach my $taxon (@taxa) {
				splice(@{$gaps{$taxon}}, $tempnum, 1, @{$tempseq{$taxon}});
			}
			# update start and end positions
			for (my $i = 0; $i < scalar(@{$tempseq{$taxa[0]}}) - 1; $i ++) {
				splice(@position, ($tempnum * 2), 0, ($position[($tempnum * 2)], $position[($tempnum * 2 + 1)]));
			}
			$tempnum --;
		}
	}
	# save start and end positions
	for (my $i = 0; $i < scalar(@position); $i += 2) {
		my @startpos = split('', sprintf("%*d", length($nchar), $position[$i] + 1));
		for (my $j = 0; $j < length($nchar); $j ++) {
			if (defined($start[$j])) {
				$start[$j] .= ' ' . $startpos[$j];
			}
			else {
				$start[$j] .= $startpos[$j];
			}
		}
		my @endpos = split('', sprintf("%*d", length($nchar), $position[($i + 1)] + 1));
		for (my $j = 0; $j < length($nchar); $j ++) {
			if (defined($end[$j])) {
				$end[$j] .= ' ' . $endpos[$j];
			}
			else {
				$end[$j] .= $endpos[$j];
			}
		}
	}
	$gapnchar = scalar(@{$gaps{$taxa[0]}});
}

if (!$gapnchar) {
	&errorMessage(__LINE__, "The input file does not contain gaps.");
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
print($filehandle "\nBegin Data;\n\tDimensions NTax=$ntax NChar=$gapnchar;\n");
print($filehandle "\tFormat DataType=Standard Symbols=\"01\" Missing=?;\n");
print($filehandle "\tMatrix\n");
if ($method eq 'SIC') {
	print($filehandle "[Gap characters encoded by simple indel coding method (Simmons & Ochoterena, 2000)]\n");
}
elsif ($method eq 'FC2001') {
	print($filehandle "[Gap characters encoded by a method of Freusenstein & Chase (2001)]\n");
}
elsif ($method eq 'Q5SC') {
	print($filehandle "[Gap characters encoded by quasi-5th-state coding (Tanabe, in prep.)]\n");
}
elsif ($method eq 'vMCICwoSM') {
	print($filehandle "[Gap characters encoded by a variant of modified complex indel coding without step matrix (Tanabe, in prep.)]\n");
}
elsif ($method eq 'vMCIC') {
	print($filehandle "[Gap characters encoded by a variant of modified complex indel coding (Tanabe, in prep.)]\n");
}
for (my $i = 0; $i < length($nchar); $i ++) {
	printf($filehandle "%*s[", $taxnamelength, ' ');
	print($filehandle $start[$i] . "]\n");
}
printf($filehandle "%*s[", $taxnamelength, ' ');
foreach (1 .. ($gapnchar * 2 - 1)) {
	print($filehandle ' ');
}
print($filehandle "]\n");
for (my $i = 0; $i < length($nchar); $i ++) {
	printf($filehandle "%*s[", $taxnamelength, ' ');
	print($filehandle $end[$i] . "]\n");
}
foreach my $taxon (@taxa) {
	printf($filehandle "%-*s ", $taxnamelength, $taxon);
	print($filehandle join(' ', @{$gaps{$taxon}}));
	print($filehandle "\n");
}
print($filehandle "\t;\nEnd;\n");
close($filehandle);

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
pgencodegap options inputfile outputfile

Command line options
====================
-m, --method=SIC|FC2001|Q5SC|vMCICwoSM|vMCIC
  Specify the method to encode gap. (default: SIC)

-i, --interleave=IGNORE|SEPARATOR
  Specify handling of interleaving. (default: IGNORE)
If SEPARATOR is specified, interleaving is treated as physical
separator.

Acceptable input file formats
=============================
NEXUS
_END
	exit;
}
