my $buildno = '2.0.x';
#
# pgconcatseq
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
pgconcatseq $buildno
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

# display usage if command line options were not specified
unless (@ARGV) {
	&helpMessage();
}

# initialize variables
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $criterion = 'name';
my @inputfiles;
{
	my %inputfiles;
	for (my $i = 0; $i < scalar(@ARGV) - 1; $i ++) {
		if ($ARGV[$i] =~ /^-+(?:c|criterion)=(name|order)$/i) {
			$criterion = $1;
		}
		else {
			foreach (glob($ARGV[$i])) {
				if ($inputfiles{$_}) {
					&errorMessage(__LINE__, "\"$_\" is doubly specified.");
				}
				elsif (-e $_ && !-d $_ && !-z $_) {
					$inputfiles{$_} = 1;
					push(@inputfiles, $_);
				}
				else {
					&errorMessage(__LINE__, "\"$_\" does not exist or this is not a file.");
				}
			}
		}
	}
}
my %format;
my @taxa;
my %taxa;
my %seqs;
my $nexusformat;

# file format recognition
foreach my $inputfile (@inputfiles) {
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	{
		my $lineno = 1;
		while (<INFILE>) {
			if ($lineno == 1 && /^#NEXUS/i) {
				$format{$inputfile} = 'NEXUS';
				last;
			}
			elsif ($lineno == 1 && /^\s*\d+\s+\d+\s*/) {
				$format{$inputfile} = 'PHYLIP';
			}
			elsif ($lineno == 1 && /^>/) {
				$format{$inputfile} = 'FASTA';
				last;
			}
			elsif ($lineno == 1) {
				$format{$inputfile} = 'TF';
				last;
			}
			elsif ($lineno > 1 && /^\S{11,}\s+\S.*/) {
				$format{$inputfile} = 'PHYLIPex';
			}
			$lineno ++;
		}
	}
	close(INFILE);
}

# read input files
foreach my $inputfile (@inputfiles) {
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	my $seqno = 0;
	my %check;
	if ($format{$inputfile} eq 'NEXUS') {
		my $datablock = 0;
		my $matrix = 0;
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
					unless ($check{$taxon}) {
						$seqno ++;
						$check{$taxon} = $seqno;
					}
					unless ($taxa{$taxon}) {
						$taxa{$taxon} = $seqno;
						push(@taxa, $taxon);
					}
					my @seq = $seq =~ /\S/g;
					if ($criterion =~ /^name$/i) {
						$seqs{$taxon}{$inputfile} .= join('', @seq);
					}
					else {
						$seqs{$seqno}{$inputfile} .= join('', @seq);
					}
				}
			}
			elsif ($datablock == 1 && $matrix == 0 && !$nexusformat && /^\s*(Format.+)\r?\n?/i) {
				$nexusformat = $1;
			}
			elsif ($datablock == 1 && $matrix == 0 && /^\s*Matrix/i) {
				$matrix = 1;
			}
		}
	}
	elsif ($format{$inputfile} eq 'PHYLIP' || $format{$inputfile} eq 'PHYLIPex') {
		my $num = -1;
		my $ntax;
		my @temptaxa;
		while (<INFILE>) {
			if ($num == -1) {
				if (/^\s*(\d+)\s+\d+/) {
					$ntax = $1;
					$num ++;
				}
				else {
					&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
				}
			}
			else {
				if ($num < $ntax) {
					if ($format{$inputfile} eq 'PHYLIP' && /^(..........)\s*(\S.*?)\s*\r?\n?$/ || $format{$inputfile} eq 'PHYLIPex' && /^(\S+)\s+(\S.*?)\s*\r?\n?$/) {
						$seqno ++;
						my $taxon = $1;
						my $seq = $2;
						$taxon =~ s/\s//g;
						unless ($taxa{$taxon}) {
							$taxa{$taxon} = $seqno;
							push(@taxa, $taxon);
						}
						if ($criterion =~ /^name$/i) {
							push(@temptaxa, $taxon);
						}
						else {
							push(@temptaxa, $seqno);
						}
						unless ($check{$taxon}) {
							$check{$taxon} = 1;
						}
						elsif ($criterion =~ /^name$/i) {
							&errorMessage(__LINE__, "\"$taxon\" is duplicaed in \"$inputfile\".");
						}
						my @seq = $seq =~ /\S/g;
						if ($criterion =~ /^name$/i) {
							$seqs{$taxon}{$inputfile} .= join('', @seq);
						}
						else {
							$seqs{$seqno}{$inputfile} .= join('', @seq);
						}
						$num ++;
					}
				}
				else {
					if (/^\s+(\S.*?)\s*\r?\n?$/) {
						my $seq = $1;
						my @seq = $seq =~ /\S/g;
						$seqs{$temptaxa[$num % $ntax]}{$inputfile} .= join('', @seq);
						$num ++;
					}
				}
			}
		}
	}
	elsif ($format{$inputfile} eq 'FASTA') {
		my $taxon;
		while (<INFILE>) {
			if (/^>\s*(\S.*?)\s*\r?\n?$/) {
				$seqno ++;
				$taxon = $1;
				unless ($taxa{$taxon}) {
					$taxa{$taxon} = $seqno;
					push(@taxa, $taxon);
				}
				unless ($check{$taxon}) {
					$check{$taxon} = 1;
				}
				elsif ($criterion =~ /^name$/i) {
					&errorMessage(__LINE__, "\"$taxon\" is duplicaed in \"$inputfile\".");
				}
			}
			elsif ($taxon) {
				my @seq = $_ =~ /\S/g;
				if ($criterion =~ /^name$/i) {
					$seqs{$taxon}{$inputfile} .= join('', @seq);
				}
				else {
					$seqs{$seqno}{$inputfile} .= join('', @seq);
				}
			}
		}
	}
	elsif ($format{$inputfile} eq 'TF') {
		while (<INFILE>) {
			if (/^\"([^\"]+)\"\s*(\S.*?)\s*\r?\n?$/) {
				my $taxon = $1;
				my $seq = $2;
				if ($seq =~ /^[\d\s]+$/) {
					next;
				}
				unless ($check{$taxon}) {
					$seqno ++;
					$check{$taxon} = $seqno;
				}
				unless ($taxa{$taxon}) {
					$taxa{$taxon} = $seqno;
					push(@taxa, $taxon);
				}
				my @seq = $seq =~ /\S/g;
				if ($criterion =~ /^name$/i) {
					$seqs{$taxon}{$inputfile} .= join('', @seq);
				}
				else {
					$seqs{$seqno}{$inputfile} .= join('', @seq);
				}
			}
		}
	}
	close(INFILE);
}
my $taxnamelength = 0;
my %replace;
foreach my $inputfile (@inputfiles) {
	my $maxlength;
	foreach my $taxon (@taxa) {
		if ($criterion =~ /^name$/i) {
			if ($seqs{$taxon}{$inputfile} && $maxlength < length($seqs{$taxon}{$inputfile})) {
				$maxlength = length($seqs{$taxon}{$inputfile});
			}
		}
		else {
			if ($seqs{$taxa{$taxon}}{$inputfile} && $maxlength < length($seqs{$taxa{$taxon}}{$inputfile})) {
				$maxlength = length($seqs{$taxa{$taxon}}{$inputfile});
			}
		}
		if ($taxnamelength < length($taxon)) {
			$taxnamelength = length($taxon);
		}
	}
	foreach my $taxon (@taxa) {
		if ($criterion =~ /^name$/i) {
			while (!$seqs{$taxon}{$inputfile} || $maxlength > length($seqs{$taxon}{$inputfile})) {
				$seqs{$taxon}{$inputfile} .= '?';
			}
		}
		else {
			while (!$seqs{$taxa{$taxon}}{$inputfile} || $maxlength > length($seqs{$taxa{$taxon}}{$inputfile})) {
				$seqs{$taxa{$taxon}}{$inputfile} .= '?';
			}
		}
	}
}
my $maxseqlength = 0;
foreach my $taxon (@taxa) {
	my $templength;
	foreach my $inputfile (@inputfiles) {
		if ($criterion =~ /^name$/i) {
			if ($seqs{$taxon}{$inputfile}) {
				$templength += length($seqs{$taxon}{$inputfile});
			}
		}
		else {
			if ($seqs{$taxa{$taxon}}{$inputfile}) {
				$templength += length($seqs{$taxa{$taxon}}{$inputfile});
			}
		}
	}
	if ($maxseqlength < $templength) {
		$maxseqlength = $templength;
	}
}
if ($format{$inputfiles[0]} eq 'PHYLIP' && $taxnamelength > 10 && $outputfile !~ /^stdout$/i) {
	print("Sequence names are too long for PHYLIP format.\nSequence names will be replace and table file will be output.\n");
	my $temp = 1;
	foreach my $taxon (@taxa) {
		$replace{$taxon} = "Tax$temp";
		$temp ++;
	}
	if (-e "$outputfile.table") {
		&errorMessage(__LINE__, "\"$outputfile.table\" already exists.");
	}
	unless (open(OUTFILE, "> $outputfile.table")) {
		&errorMessage(__LINE__, "Cannot make \"$outputfile.table\".");
	}
	foreach my $taxon (@taxa) {
		printf(OUTFILE "%-10s ", $replace{$taxon});
		print(OUTFILE "\"$taxon\"\n");
	}
	close(OUTFILE);
}
elsif ($format{$inputfiles[0]} eq 'PHYLIP' && $taxnamelength > 10 && $outputfile =~ /^stdout$/i) {
	&errorMessage(__LINE__, "Sequence names are too long to output in PHYLIP format.");
}
elsif ($format{$inputfiles[0]} eq 'PHYLIP') {
	foreach my $taxon (@taxa) {
		$replace{$taxon} = $taxon;
	}
}

# output combined sequence file
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
if ($format{$inputfiles[0]} eq 'NEXUS') {
	print($filehandle "#NEXUS\n\nBegin Data;\n\tDimensions NTax=" . scalar(@taxa) . " NChar=$maxseqlength;\n\t$nexusformat\n\tMatrix\n");
}
elsif ($format{$inputfiles[0]} eq 'PHYLIP' || $format{$inputfiles[0]} eq 'PHYLIPex') {
	print($filehandle scalar(@taxa) . ' ' . $maxseqlength . "\n");
}
for (my $i = 0; $i < scalar(@taxa); $i ++) {
	if ($format{$inputfiles[0]} eq 'NEXUS' || $format{$inputfiles[0]} eq 'PHYLIPex') {
		printf($filehandle "%-*s ", $taxnamelength, $taxa[$i]);
	}
	elsif ($format{$inputfiles[0]} eq 'PHYLIP') {
		printf($filehandle "%-10s ", $replace{$taxa[$i]});
	}
	elsif ($format{$inputfiles[0]} eq 'FASTA') {
		print($filehandle ">$taxa[$i]\n");
	}
	elsif ($format{$inputfiles[0]} eq 'TF') {
		printf($filehandle "%-*s ", $taxnamelength + 2, '"' . $taxa[$i] . '"');
	}
	if ($criterion =~ /^name$/i) {
		for (my $j = 0; $j < scalar(@inputfiles); $j ++) {
			if ($j + 1 == scalar(@inputfiles)) {
				print($filehandle $seqs{$taxa[$i]}{$inputfiles[$j]});
			}
			else {
				print($filehandle $seqs{$taxa[$i]}{$inputfiles[$j]} . " ");
			}
		}
	}
	else {
		for (my $j = 0; $j < scalar(@inputfiles); $j ++) {
			if ($j + 1 == scalar(@inputfiles)) {
				print($filehandle $seqs{$i + 1}{$inputfiles[$j]});
			}
			else {
				print($filehandle $seqs{$i + 1}{$inputfiles[$j]} . " ");
			}
		}
	}
	print($filehandle "\n");
}
if ($format{$inputfiles[0]} eq 'NEXUS') {
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
pgconcatseq options inputfile inputfile .. outputfile

Command line options
====================
-c, --criterion=Name|Order
  Specify concatenation criterion. (default: Name)

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
