my $buildno = '2.0.x';
#
# pgtestcomposition
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
use Statistics::ChisqIndep;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgtestcomposition $buildno
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
my @target;
my @taxa;
my %seqs;

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
					push(@{$seqs{$taxon}}, @seq);
					$num ++;
				}
			}
			else {
				if (/^\s+(\S.*?)\s*\r?\n?$/) {
					my $seq = $1;
					my @seq = $seq =~ /\S/g;
					push(@{$seqs{$taxa[$num % $ntax]}}, @seq);
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
			push(@{$seqs{$taxa[-1]}}, @seq);
		}
	}
	$ntax = scalar(@taxa);
	foreach my $taxon (@taxa) {
		if ($nchar < scalar(@{$seqs{$taxon}})) {
			$nchar = scalar(@{$seqs{$taxon}});
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
			push(@{$seqs{$taxon}}, @seq);
		}
	}
	$ntax = scalar(@taxa);
	$nchar = scalar(@{$seqs{$taxa[0]}});
}
close(INFILE);

# check data
if (scalar(@taxa) != scalar(keys(%seqs)) || scalar(@taxa) != $ntax) {
	&errorMessage(__LINE__, "Input file is invalid.");
}
my $taxnamelength;
foreach my $taxon (@taxa) {
	if ($taxnamelength < length($taxon)) {
		$taxnamelength = length($taxon);
	}
}

# get target sites
my $type;
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
	@target = sort({$a <=> $b} keys(%target));
	if (!@target) {
		@target = 1 .. $nchar;
	}
	if ($target[0] < 1) {
		&errorMessage(__LINE__, 'Range specification is not valid.');
	}
	if ($target[-1] > $nchar) {
		&errorMessage(__LINE__, 'Range specification is not valid.');
	}
}

# test compositional homogeneity
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
if ($type eq 'DNA' || $type eq 'RNA') {
	my @obs;
	my @temptaxa;
	foreach my $taxon (@taxa) {
		my @taxobs = (0, 0, 0, 0);
		foreach my $site (@target) {
			if ($seqs{$taxon}[$site - 1] =~ /^A$/i) {
				$taxobs[0] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^C$/i) {
				$taxobs[1] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^G$/i) {
				$taxobs[2] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^[TU]$/i) {
				$taxobs[3] ++;
			}
		}
		if ($taxobs[0] + $taxobs[1] + $taxobs[2] + $taxobs[3] > 0) {
			push(@obs, \@taxobs);
			push(@temptaxa, $taxon);
		}
	}
	my @nucleotide;
	if ($type eq 'DNA') {
		@nucleotide = ('         A', '         C', '         G', '         T');
	}
	else {
		@nucleotide = ('         A', '         C', '         G', '         U');
	}
	for (my $i = 3; $i >= 0; $i --) {
		my $sum = 0;
		for (my $j = 0; $j < scalar(@obs); $j ++) {
			$sum += $obs[$j][$i];
		}
		if ($sum == 0) {
			for (my $j = 0; $j < scalar(@obs); $j ++) {
				splice(@{$obs[$j]}, $i, 1);
				splice(@nucleotide, $i, 1);
			}
		}
	}
	my $chi = new Statistics::ChisqIndep;
	$chi->load_data(\@obs);
	if ($chi->{valid}) {
		#output the contingency table
		my $obs = $chi->{obs}; # observed values
		my $exp = $chi->{expected}; # expected values
		my $rtotals = $chi->{rtotals}; # row totals
		my $ctotals = $chi->{ctotals}; # column totals
		my $p_value = $chi->{p_value}; # p value
		print($filehandle "Type of Nucleotides: " . $chi->{cols} . "\n");
		print($filehandle "Number of Taxa: " . $chi->{rows} . "\n"); 
		print($filehandle "Degree of Freedom: " . $chi->{df} . "\n");
		print($filehandle "Total Count: " . $chi->{total} . "\n");
		print($filehandle "Chi-square Statistic: " . $chi->{chisq_statistic} . "\n");
		print($filehandle "p-value: " . $p_value . "\n");
		print($filehandle "\n");
		printf($filehandle "%*s ", $taxnamelength, ' ');
		foreach (@nucleotide) {
			print($filehandle "\t$_");
		}
		print($filehandle "\t    rtotal\n");
		my $warning1 = 0;
		my $warning2 = 0;
		for (my $i = 0; $i < $chi->{rows}; $i ++) {
			printf($filehandle "%-*s \t", $taxnamelength, $temptaxa[$i]);
			for (my $j = 0; $j < $chi->{cols}; $j ++) {
				printf($filehandle "%10d\t", $obs->[$i]->[$j]);
			}
			printf($filehandle "%10d\n", $rtotals->[$i]);
			printf($filehandle "%*s ", $taxnamelength, ' ');
			for (my $j = 0; $j < $chi->{cols}; $j ++) {
				printf($filehandle "\t%10f", $exp->[$i]->[$j]);
				if ($exp->[$i]->[$j] < 1) {
					$warning1 ++;
				}
				elsif ($exp->[$i]->[$j] < 5) {
					$warning2 ++;
				}
			}
			print($filehandle "\n"); 
		}
		printf($filehandle "%-*s \t", $taxnamelength, 'ctotal');
		for (my $j = 0; $j < $chi->{cols}; $j ++) {
			printf($filehandle "%10d\t", $ctotals->[$j]);
		}
		#output total counts
		printf($filehandle "%10d\n", $chi->{total});
		if ($warning1) {
			print($filehandle "Because expected values of one or more cells are lower than 1, p-value may be unreliable (Cochran, 1954).\n");
		}
		if ($warning2 >= (scalar(@obs) * scalar(@{$obs[0]})) / 5) {
			print($filehandle "Because expected values of over 20 % cells are lower than 5, p-value may be unreliable (Cochran, 1954).\n");
		}
	}
	else {
		&errorMessage(__LINE__, 'Cannot run chi-square test.');
	}
}
else {
	my @obs;
	my @temptaxa;
	foreach my $taxon (@taxa) {
		my @taxobs = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		foreach my $site (@target) {
			if ($seqs{$taxon}[$site - 1] =~ /^A$/i) {
				$taxobs[0] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^R$/i) {
				$taxobs[1] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^N$/i) {
				$taxobs[2] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^D$/i) {
				$taxobs[3] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^C$/i) {
				$taxobs[4] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^Q$/i) {
				$taxobs[5] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^E$/i) {
				$taxobs[6] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^G$/i) {
				$taxobs[7] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^H$/i) {
				$taxobs[8] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^I$/i) {
				$taxobs[9] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^L$/i) {
				$taxobs[10] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^K$/i) {
				$taxobs[11] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^M$/i) {
				$taxobs[12] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^F$/i) {
				$taxobs[13] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^P$/i) {
				$taxobs[14] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^S$/i) {
				$taxobs[15] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^T$/i) {
				$taxobs[16] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^W$/i) {
				$taxobs[17] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^Y$/i) {
				$taxobs[18] ++;
			}
			elsif ($seqs{$taxon}[$site - 1] =~ /^V$/i) {
				$taxobs[19] ++;
			}
		}
		if ($taxobs[0] + $taxobs[1] + $taxobs[2] + $taxobs[3] + $taxobs[4] + $taxobs[5] + $taxobs[6] + $taxobs[7] + $taxobs[8] + $taxobs[9] + $taxobs[10] + $taxobs[11] + $taxobs[12] + $taxobs[13] + $taxobs[14] + $taxobs[15] + $taxobs[16] + $taxobs[17] + $taxobs[18] + $taxobs[19] > 0) {
			push(@obs, \@taxobs);
			push(@temptaxa, $taxon);
		}
	}
	my @aminoacid = ('         A', '         R', '         N', '         D', '         C', '         Q', '         E', '         G', '         H', '         I', '         L', '         K', '         M', '         F', '         P', '         S', '         T', '         W', '         Y', '         V');
	for (my $i = 19; $i >= 0; $i --) {
		my $sum = 0;
		for (my $j = 0; $j < scalar(@obs); $j ++) {
			$sum += $obs[$j][$i];
		}
		if ($sum == 0) {
			for (my $j = 0; $j < scalar(@obs); $j ++) {
				splice(@{$obs[$j]}, $i, 1);
				splice(@aminoacid, $i, 1);
			}
		}
	}
	my $chi = new Statistics::ChisqIndep;
	$chi->load_data(\@obs);
	if ($chi->{valid}) {
		#output the contingency table
		my $obs = $chi->{obs}; # observed values
		my $exp = $chi->{expected}; # expected values
		my $rtotals = $chi->{rtotals}; # row totals
		my $ctotals = $chi->{ctotals}; # column totals
		my $p_value = $chi->{p_value}; # p value
		print($filehandle "Type of Amino Acids: " . $chi->{cols} . "\n");
		print($filehandle "Number of Taxa: " . $chi->{rows} . "\n"); 
		print($filehandle "Degree of Freedom: " . $chi->{df} . "\n");
		print($filehandle "Total Count: " . $chi->{total} . "\n");
		print($filehandle "Chi-square Statistic: " . $chi->{chisq_statistic} . "\n");
		print($filehandle "p-value: " . $p_value . "\n");
		print($filehandle "\n");
		printf($filehandle "%*s ", $taxnamelength, ' ');
		foreach (@aminoacid) {
			print($filehandle "\t$_");
		}
		print($filehandle "\t    rtotal\n");
		my $warning1 = 0;
		my $warning2 = 0;
		for (my $i = 0; $i < $chi->{rows}; $i ++) {
			printf($filehandle "%-*s \t", $taxnamelength, $temptaxa[$i]);
			for (my $j = 0; $j < $chi->{cols}; $j ++) {
				printf($filehandle "%10d\t", $obs->[$i]->[$j]);
			}
			printf($filehandle "%10d\n", $rtotals->[$i]);
			printf($filehandle "%*s ", $taxnamelength, ' ');
			for (my $j = 0; $j < $chi->{cols}; $j ++) {
				printf($filehandle "\t%10f", $exp->[$i]->[$j]);
				if ($exp->[$i]->[$j] < 1) {
					$warning1 ++;
				}
				elsif ($exp->[$i]->[$j] < 5) {
					$warning2 ++;
				}
			}
			print($filehandle "\n"); 
		}
		printf($filehandle "%-*s \t", $taxnamelength, 'ctotal');
		for (my $j = 0; $j < $chi->{cols}; $j ++) {
			printf($filehandle "%10d\t", $ctotals->[$j]);
		}
		#output total counts
		printf($filehandle "%10d\n", $chi->{total});
		if ($warning1) {
			print($filehandle "Because expected values of one or more cells are lower than 1, p-value may be unreliable (Cochran, 1954).\n");
		}
		if ($warning2 >= (scalar(@obs) * scalar(@{$obs[0]})) / 5) {
			print($filehandle "Because expected values of over 20 % cells are lower than 5, p-value may be unreliable (Cochran, 1954).\n");
		}
	}
	else {
		&errorMessage(__LINE__, 'Cannot run chi-square test.');
	}
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
pgtestcomposition options inputfile outputfile

Command line options
====================
-t, --type=DNA|RNA|AA
  Specify sequence type.

INTEGER
INTEGER-INTEGER (start-end)
INTEGER-. (start-last)
INTEGER-INTEGER\\INTEGER (start-end\\skip)
  Specify output positions of sites.

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
