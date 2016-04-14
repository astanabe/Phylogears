my $buildno = '2.0.2016.04.14';
#
# pgstripcolumn
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

# To do: NEXUS PHYLIP TF
# see pgspliceseq

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgstripcolumn $buildno
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
my $gap = 0;
my $miss = 0;
my $ambig = 0;
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:t|target)=(.+)$/i) {
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
				&errorMessage(__LINE__, "\"$target\" is unknown target.");
			}
		}
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}
if ($gap == 0 && $miss == 0 && $ambig == 0) {
	&errorMessage(__LINE__, "All stripping options are disabled.");
}
my @taxa;
my %target;
my @seqs;
# read input files
unless (open(FASTA, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
{
	my $taxon;
	my $seqno = -1;
	while (<FASTA>) {
		if (/^>\s*(\S.*?)\s*\r?\n?$/) {
			$seqno ++;
			$taxon = $1;
			push(@taxa, $taxon);
		}
		elsif ($taxon) {
			my @seq = /\S/g;
			foreach my $seq (@seq) {
				push(@{$seqs[$seqno]}, $seq);
			}
		}
	}
	close(FASTA);
}
if (scalar(@taxa) != scalar(@seqs)) {
	&errorMessage(__LINE__, "Input file is invalid.");
}
# search columns containing deletion targets
for (my $i = 0; $i < scalar(@seqs); $i ++) {
	for (my $j = 0; $j < scalar(@{$seqs[$i]}); $j ++) {
		if (($gap && $seqs[$i][$j] eq '-') || 
		($miss && $seqs[$i][$j] eq '?') || 
		($ambig && $seqs[$i][$j] =~ /^(?:N|M|R|W|S|Y|K|V|H|D|B)$/i)) {
			$target{$j} = 1;
		}
		elsif ($seqs[$i][$j] !~ /^(?:A|C|G|T|-|N|\?|M|R|W|S|Y|K|V|H|D|B)$/i) {
			&errorMessage(__LINE__, '"' . $seqs[$i][$j] . '" (site ' . ($j + 1) . ' of ' . $taxa[$i] . ') is invalid character.');
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
for (my $i = 0; $i < scalar(@taxa); $i ++) {
	print($filehandle ">$taxa[$i]\n");
	for (my $j = 0; $j < scalar(@{$seqs[$i]}); $j ++) {
		unless ($target{$j}) {
			print($filehandle $seqs[$i][$j]);
		}
	}
	print($filehandle "\n");
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
pgstripcolumn options inputfile outputfile

Command line options
====================
-t, --target=Gap|Miss|Ambig
  Specify target data types. (default: Gap,Miss,Ambig)

Acceptable input file formats
=============================
FASTA
(This script does not accept multiple data sets.)
_END
	exit;
}
