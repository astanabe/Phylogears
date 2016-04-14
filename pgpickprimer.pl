my $buildno = '2.0.2016.02.06';
#
# pgpickprimer
# 
# Official web site of this script is
# http://www.fifthdimension.jp/products/phylogears/ .
# To know script details, see above URL.
# 
# Copyright (C) 2008-2015  Akifumi S. Tanabe
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
pgpickprimer $buildno
=======================================================================

Official web site of this script is
http://www.fifthdimension.jp/products/phylogears/ .
To know script details, see above URL.

Copyright (C) 2008-2015  Akifumi S. Tanabe

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
my $maxpick = 25;
my $consensus = 95;
my $perfectmatch = 10;
my $sizerange = '300-1000';
my $mintm = 45;
my $maxtm = 60;
my $target;
my $exclude;
my %thirdcodonpos;
my @taxa;
my @seqs;
my $outputinput = 1;

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	# maximum number of primers picked
	if ($ARGV[$i] =~ /^-+maxpick=(\d+)$/i) {
		if ($1 > 0 && $1 < 100) {
			$maxpick = $1;
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
	# percent threshold for degeneration
	elsif ($ARGV[$i] =~ /^-+consensus=(\d+)$/i) {
		if ($1 > 50 && $1 <= 100) {
			$consensus = $1;
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
	# maximum number of degenerate character
	elsif ($ARGV[$i] =~ /^-+perfectmatch=(\d+)$/i) {
		if ($1 > 0 && $1 <= 100) {
			$perfectmatch = $1;
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
	# size range of PCR product
	elsif ($ARGV[$i] =~ /^-+sizerange=(\d+)\-(\d+)$/i) {
		if ($1 < $2) {
			$sizerange = $1 . '-' . $2;
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
	# Tm range of primer
	elsif ($ARGV[$i] =~ /^-+tmrange=(\d+(?:\.\d+)?)\-(\d+(?:\.\d+)?)$/i) {
		if ($1 < $2) {
			$mintm = $1;
			$maxtm = $2;
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
	# target range
	elsif ($ARGV[$i] =~ /^-+target=(.+)$/i) {
		my @temp = split(/,/, $1);
		foreach my $temp (@temp) {
			if ($target) {
				$target .= ' ';
			}
			if ($temp =~ /^(\d+)\-(\d+)$/ && $1 <= $2) {
				$target .= ($1 - 1) . ',' . ($2 - $1);
			}
			elsif ($temp =~ /^(\d+)$/) {
				$target .= ($1 - 1) . ',' . 1;
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
		}
	}
	# exclude range
	elsif ($ARGV[$i] =~ /^-+exclude=(.+)$/i) {
		my @temp = split(/,/, $1);
		foreach my $temp (@temp) {
			if ($exclude) {
				$exclude .= ' ';
			}
			if ($temp =~ /^(\d+)\-(\d+)$/ && $1 <= $2) {
				$exclude .= ($1 - 1) . ',' . ($2 - $1);
			}
			elsif ($temp =~ /^(\d+)$/) {
				$exclude .= ($1 - 1) . ',' . 1;
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
		}
	}
	# coding range
	elsif ($ARGV[$i] =~ /^-+coding=(.+)$/i) {
		my @temp = split(/,/, $1);
		foreach my $temp (@temp) {
			if ($temp =~ /^(\d+)\-(\d+)$/ && $1 <= $2) {
				foreach my $thirdcodonpos (&range2list($1,$2,3)) {
					$thirdcodonpos{($thirdcodonpos - 1)} = 1;
				}
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
		}
	}
	# output input alignment or not
	elsif ($ARGV[$i] =~ /^-+outputinput=(enable|disable|yes|no|true|false|E|D|Y|N|T|F)$/i) {
		my $temp = $1;
		if ($temp =~ /^(?:E|Y|T)/i) {
			$outputinput = 1;
		}
		else {
			$outputinput = 0;
		}
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
	}
}

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
				$seq =~ s/U/T/g;
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
					$seq =~ s/U/T/g;
					push(@taxa, $taxon);
					my @seq = $seq =~ /\S/g;
					push(@{$seqs[$num]}, @seq);
					$num ++;
				}
			}
			else {
				if (/^\s+(\S.*?)\s*\r?\n?$/) {
					my $seq = uc($1);
					$seq =~ s/U/T/g;
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
			$seq =~ s/U/T/g;
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
			$seq =~ s/U/T/g;
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
if ($format ne 'FASTA' && $format ne 'PHYLIP') {
	foreach my $taxon (@taxa) {
		if ($taxnamelength < length($taxon)) {
			$taxnamelength = length($taxon);
		}
	}
}

# make consensus sequence
my @consensusseq;
{
	my %state;
	$state{'A'} = 1;
	$state{'C'} = 1;
	$state{'G'} = 1;
	$state{'T'} = 1;
	$state{'-'} = 1;
	$state{'M'} = 2;
	$state{'R'} = 2;
	$state{'W'} = 2;
	$state{'S'} = 2;
	$state{'Y'} = 2;
	$state{'K'} = 2;
	$state{'V'} = 3;
	$state{'H'} = 3;
	$state{'D'} = 3;
	$state{'B'} = 3;
	$state{'N'} = 4;
	$state{'?'} = 5;
	my $tempconsensus = $ntax * $consensus / 100;
	for (my $i = 0; $i < $nchar; $i ++) {
		my %num;
		for (my $j = 0; $j < $ntax; $j ++) {
			if ($seqs[$j][$i] eq 'A') {
				$num{'A'} ++;
			}
			elsif ($seqs[$j][$i] eq 'C') {
				$num{'C'} ++;
			}
			elsif ($seqs[$j][$i] eq 'G') {
				$num{'G'} ++;
			}
			elsif ($seqs[$j][$i] eq 'T' || $seqs[$j][$i] eq 'U') {
				$num{'T'} ++;
			}
			elsif ($seqs[$j][$i] eq 'M') {
				$num{'A'} ++;
				$num{'C'} ++;
				$num{'M'} ++;
			}
			elsif ($seqs[$j][$i] eq 'R') {
				$num{'A'} ++;
				$num{'G'} ++;
				$num{'R'} ++;
			}
			elsif ($seqs[$j][$i] eq 'W') {
				$num{'A'} ++;
				$num{'T'} ++;
				$num{'W'} ++;
			}
			elsif ($seqs[$j][$i] eq 'S') {
				$num{'C'} ++;
				$num{'G'} ++;
				$num{'S'} ++;
			}
			elsif ($seqs[$j][$i] eq 'Y') {
				$num{'C'} ++;
				$num{'T'} ++;
				$num{'Y'} ++;
			}
			elsif ($seqs[$j][$i] eq 'K') {
				$num{'G'} ++;
				$num{'T'} ++;
				$num{'K'} ++;
			}
			elsif ($seqs[$j][$i] eq 'V') {
				$num{'A'} ++;
				$num{'C'} ++;
				$num{'G'} ++;
				$num{'M'} ++;
				$num{'R'} ++;
				$num{'S'} ++;
				$num{'V'} ++;
			}
			elsif ($seqs[$j][$i] eq 'H') {
				$num{'A'} ++;
				$num{'C'} ++;
				$num{'T'} ++;
				$num{'M'} ++;
				$num{'W'} ++;
				$num{'Y'} ++;
				$num{'H'} ++;
			}
			elsif ($seqs[$j][$i] eq 'D') {
				$num{'A'} ++;
				$num{'G'} ++;
				$num{'T'} ++;
				$num{'R'} ++;
				$num{'W'} ++;
				$num{'K'} ++;
				$num{'D'} ++;
			}
			elsif ($seqs[$j][$i] eq 'B') {
				$num{'C'} ++;
				$num{'G'} ++;
				$num{'T'} ++;
				$num{'S'} ++;
				$num{'Y'} ++;
				$num{'K'} ++;
				$num{'B'} ++;
			}
			elsif ($seqs[$j][$i] eq 'N') {
				$num{'A'} ++;
				$num{'C'} ++;
				$num{'G'} ++;
				$num{'T'} ++;
				$num{'M'} ++;
				$num{'R'} ++;
				$num{'W'} ++;
				$num{'S'} ++;
				$num{'Y'} ++;
				$num{'K'} ++;
				$num{'V'} ++;
				$num{'H'} ++;
				$num{'D'} ++;
				$num{'B'} ++;
				$num{'N'} ++;
			}
			elsif ($seqs[$j][$i] eq '?') {
				$num{'A'} ++;
				$num{'C'} ++;
				$num{'G'} ++;
				$num{'T'} ++;
				$num{'M'} ++;
				$num{'R'} ++;
				$num{'W'} ++;
				$num{'S'} ++;
				$num{'Y'} ++;
				$num{'K'} ++;
				$num{'V'} ++;
				$num{'H'} ++;
				$num{'D'} ++;
				$num{'B'} ++;
				$num{'N'} ++;
				$num{'-'} ++;
				$num{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq '-') {
				$num{'-'} ++;
			}
		}
		my %sub;
		for (my $j = 0; $j < $ntax; $j ++) {
			if ($seqs[$j][$i] eq 'A') {
				$sub{'A'} ++;
				$sub{'M'} ++;
				$sub{'R'} ++;
				$sub{'W'} ++;
				$sub{'V'} ++;
				$sub{'H'} ++;
				$sub{'D'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'C') {
				$sub{'C'} ++;
				$sub{'M'} ++;
				$sub{'S'} ++;
				$sub{'Y'} ++;
				$sub{'V'} ++;
				$sub{'H'} ++;
				$sub{'B'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'G') {
				$sub{'G'} ++;
				$sub{'R'} ++;
				$sub{'S'} ++;
				$sub{'K'} ++;
				$sub{'V'} ++;
				$sub{'D'} ++;
				$sub{'B'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'T' || $seqs[$j][$i] eq 'U') {
				$sub{'T'} ++;
				$sub{'W'} ++;
				$sub{'Y'} ++;
				$sub{'K'} ++;
				$sub{'H'} ++;
				$sub{'D'} ++;
				$sub{'B'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'M') {
				$sub{'M'} ++;
				$sub{'V'} ++;
				$sub{'H'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'R') {
				$sub{'R'} ++;
				$sub{'V'} ++;
				$sub{'D'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'W') {
				$sub{'W'} ++;
				$sub{'H'} ++;
				$sub{'D'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'S') {
				$sub{'S'} ++;
				$sub{'V'} ++;
				$sub{'B'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'Y') {
				$sub{'Y'} ++;
				$sub{'H'} ++;
				$sub{'B'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'K') {
				$sub{'K'} ++;
				$sub{'D'} ++;
				$sub{'B'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'V') {
				$sub{'V'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'H') {
				$sub{'H'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'D') {
				$sub{'D'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'B') {
				$sub{'B'} ++;
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq 'N') {
				$sub{'N'} ++;
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq '?') {
				$sub{'?'} ++;
			}
			elsif ($seqs[$j][$i] eq '-') {
				$sub{'-'} ++;
				$sub{'?'} ++;
			}
		}
		my @temp1 = sort({$num{$b} <=> $num{$a} || $sub{$b} <=> $sub{$a} || $state{$a} <=> $state{$b}} ('A', 'C', 'G', 'T', '-', 'M', 'R', 'W', 'S', 'Y', 'K', 'V', 'H', 'D', 'B', 'N', '?'));
		while (@temp1 && $num{$temp1[0]} < $tempconsensus && $sub{$temp1[0]} < $tempconsensus) {
			shift(@temp1);
		}
		if (@temp1) {
			$consensusseq[$i] = shift(@temp1);
		}
		else {
			$consensusseq[$i] = '?';
		}
	}
}

# pick primer by primer3
my @primers;
my @primerseqs;
{
	my $consensusseq = join('', @consensusseq);
	$consensusseq =~ s/\-//g;
	my $tempfile = 0;
	while (-e ".tempfile$tempfile") {
		$tempfile ++;
	}
	$tempfile = ".tempfile$tempfile";
	my $pipe;
	unless (open($pipe, "| primer3_core -output=$tempfile")) {
		&errorMessage(__LINE__, "Cannot run \"primer3_core -output=$tempfile\".");
	}
	print($pipe "SEQUENCE_ID=pgpickprimer\nSEQUENCE_TEMPLATE=$consensusseq\nSEQUENCE_TARGET=$target\nSEQUENCE_INTERNAL_EXCLUDED_REGION=$exclude\nPRIMER_TASK=pick_detection_primers\nPRIMER_NUM_RETURN=$maxpick\nPRIMER_MAX_NS_ACCEPTED=6\nPRIMER_LIBERAL_BASE=1\nPRIMER_FIRST_BASE_INDEX=0\nPRIMER_PRODUCT_SIZE_RANGE=$sizerange\nPRIMER_TM_FORMULA=1\nPRIMER_MIN_TM=$mintm\nPRIMER_MAX_TM=$maxtm\nPRIMER_OPT_TM=" . sprintf("%.1f", (($maxtm + $mintm) / 2)) . "\n=\n");
	close($pipe);
	if ($?) {
		unlink($tempfile);
		&errorMessage(__LINE__, "Cannot run \"primer3_core -output=$tempfile\".");
	}
	my @forwardprimers;
	my @forwardpositions;
	my @forwardtm;
	my @reverseprimers;
	my @reversepositions;
	my @reversetm;
	my $tempfh;
	unless (open($tempfh, "< $tempfile")) {
		&errorMessage(__LINE__, "Cannot open \"$tempfile\".");
	}
	while (<$tempfh>) {
		if (/^PRIMER_LEFT_(\d+)_SEQUENCE=(\S+)\r?\n?$/) {
			$forwardprimers[$1] = $2;
		}
		elsif (/^PRIMER_RIGHT_(\d+)_SEQUENCE=(\S+)\r?\n?$/) {
			$reverseprimers[$1] = $2;
		}
		elsif (/^PRIMER_LEFT_(\d+)=(\d+),\d+\r?\n?$/) {
			$forwardpositions[$1] = $2;
		}
		elsif (/^PRIMER_RIGHT_(\d+)=(\d+),(\d+)\r?\n?$/) {
			$reversepositions[$1] = $2 - $3 + 1;
		}
		elsif (/^PRIMER_LEFT_(\d+)_TM=(\d+(?:\.\d+)?)\r?\n?$/) {
			$forwardtm[$1] = $2;
		}
		elsif (/^PRIMER_RIGHT_(\d+)_TM=(\d+(?:\.\d+)?)\r?\n?$/) {
			$reversetm[$1] = $2;
		}
	}
	close($tempfh);
	unlink($tempfile);
	my $numprimerset = 1;
	for (my $i = 0; $i < scalar(@forwardprimers); $i ++) {
		if ($forwardprimers[$i] !~ /\?/ && $reverseprimers[$i] !~ /\?/) {
			my @numlv2f = $forwardprimers[$i] =~ /[MRWSYK]/g;
			my @numlv3f = $forwardprimers[$i] =~ /[VHDB]/g;
			my @numlv4f = $forwardprimers[$i] =~ /N/g;
			my @numlv2r = $reverseprimers[$i] =~ /[MRWSYK]/g;
			my @numlv3r = $reverseprimers[$i] =~ /[VHDB]/g;
			my @numlv4r = $reverseprimers[$i] =~ /N/g;
			if ($perfectmatch <= 100 / ((2 ** scalar(@numlv2f)) * (3 ** scalar(@numlv3f)) * (4 ** scalar(@numlv4f))) && $perfectmatch <= 100 / ((2 ** scalar(@numlv2r)) * (3 ** scalar(@numlv3r)) * (4 ** scalar(@numlv4r)))) {
				my @forwardprimer = split(/ */, $forwardprimers[$i]);
				my @reverseprimer = split(/ */, $reverseprimers[$i]);
				my $forwardprimerseq;
				my $reverseprimerseq;
				for (my $j = 0; $j < $nchar; $j ++) {
					if ($forwardpositions[$i]) {
						$forwardprimerseq .= '-';
						if (!$gappos{$j}) {
							$forwardpositions[$i] --;
						}
					}
					else {
						if ($gappos{$j}) {
							$forwardprimerseq .= '-';
						}
						elsif (@forwardprimer) {
							$forwardprimerseq .= shift(@forwardprimer);
							if (!@forwardprimer && $thirdcodonpos{$j}) {
								undef($forwardprimerseq);
								undef($reverseprimerseq);
								last;
							}
						}
						else {
							$forwardprimerseq .= '-';
						}
					}
					if ($reversepositions[$i]) {
						$reverseprimerseq .= '-';
						if (!$gappos{$j}) {
							$reversepositions[$i] --;
						}
					}
					else {
						if ($gappos{$j}) {
							$reverseprimerseq .= '-';
						}
						elsif (@reverseprimer) {
							if (scalar(@reverseprimer) + 1 == length($reverseprimers[$i]) && $thirdcodonpos{$j}) {
								undef($forwardprimerseq);
								undef($reverseprimerseq);
								last;
							}
							$reverseprimerseq .= pop(@reverseprimer);
						}
						else {
							$reverseprimerseq .= '-';
						}
					}
				}
				if ($forwardprimerseq && $reverseprimerseq) {
					push(@primers, "F$numprimerset\_Tm" . sprintf("%.1f", $forwardtm[$i]));
					push(@primers, "R$numprimerset\_Tm" . sprintf("%.1f", $reversetm[$i]));
					push(@primerseqs, $forwardprimerseq);
					push(@primerseqs, $reverseprimerseq);
					$numprimerset ++;
				}
			}
		}
	}
}
if ($format ne 'FASTA' && $format ne 'PHYLIP') {
	foreach my $primer (@primers) {
		if ($taxnamelength < length($primer)) {
			$taxnamelength = length($primer);
		}
	}
}

# output input alignment and primer sequence
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
my $tempntax;
if ($outputinput) {
	$tempntax = $ntax + 1 + scalar(@primers);
}
else {
	$tempntax = 1 + scalar(@primers);
}
if ($format eq 'NEXUS') {
	print($filehandle "#NEXUS\n\nBegin Data;\n\tDimensions NTax=$tempntax NChar=$nchar;\n\t$nexusformat\n\tMatrix\n");
}
elsif ($format eq 'PHYLIP' || $format eq 'PHYLIPex') {
	print($filehandle "$tempntax $nchar\n");
}
my $consensussequencename;
if (int($ntax * ($consensus / 100) + 0.5) == $ntax) {
	$consensussequencename = 'strict_consensus';
}
else {
	$consensussequencename = $consensus . '%_majority_rule_consensus';
}
if ($format ne 'FASTA' && $format ne 'PHYLIP') {
	if ($taxnamelength < length($consensussequencename)) {
		$taxnamelength = length($consensussequencename);
	}
}
if ($outputinput) {
	for (my $i = 0; $i < $ntax; $i ++) {
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
}
# output consensus sequence
if ($format eq 'NEXUS' || $format eq 'PHYLIPex') {
	printf($filehandle "%-*s ", $taxnamelength, $consensussequencename);
}
elsif ($format eq 'PHYLIP') {
	printf($filehandle "%-10s ", 'Consensus');
}
elsif ($format eq 'FASTA') {
	print($filehandle ">$consensussequencename\n");
}
elsif ($format eq 'TF') {
	printf($filehandle "%-*s ", $taxnamelength + 2, '"' . $consensussequencename . '"');
}
print($filehandle join('', @consensusseq) . "\n");
# output primer sequences
for (my $i = 0; $i < scalar(@primers); $i ++) {
	if ($format eq 'NEXUS' || $format eq 'PHYLIPex') {
		printf($filehandle "%-*s ", $taxnamelength, $primers[$i]);
	}
	elsif ($format eq 'PHYLIP') {
		printf($filehandle "%-10s ", $primers[$i]);
	}
	elsif ($format eq 'FASTA') {
		print($filehandle ">$primers[$i]\n");
	}
	elsif ($format eq 'TF') {
		printf($filehandle "%-*s ", $taxnamelength + 2, '"' . $primers[$i] . '"');
	}
	print($filehandle $primerseqs[$i]);
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
pgpickprimer options inputfile outputfile

Command line options
====================
--maxpick=INTEGER
  Specify maximum number of primers picked. (default: 25)

--consensus=INTEGER
  Specify consensus threshold as percent. (default: 95)

--perfectmatch=INTEGER
  Specify perfect match threshold as percent. (default: 10)

--sizerange=INTEGER-INTEGER
  Specify size range of PCR product. (default: 300-1000)

--tmrange=INTEGER-INTEGER
  Specify Tm range as degrees Celsius. (default: 45-60)

--target=INTEGER-INTEGER,INTEGER-INTEGER...
  Specify amplification target ranges.
. is treated as last character. (default: none)

--exclude=INTEGER-INTEGER,INTEGER-INTEGER...
  Specify excluded ranges.
. is treated as last character. (default: none)

--coding=INTEGER-INTEGER,INTEGER-INTEGER...
  Specify protein-coding ranges starting from 1st codon position.
. is treated as last character. (default: none)

--outputinput=ENABLE|DISABLE
  Specify outputting input alignment or not. (default: enable)

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
