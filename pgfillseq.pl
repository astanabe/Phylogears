my $buildno = '2.0.2016.04.14';
#
# pgfillseq
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

# input/output
my @inputfiles;
my $outputfolder;

# global variables
my @length;
my %taxa;

# file handles
my $filehandleinput1;
my $filehandleoutput1;

&main();

sub main {
	# print startup messages
	&printStartupMessage();
	# get command line arguments
	&getOptions();
	# check variable consistency
	&checkVariables();
	# check length and store taxon names
	&storeTaxa();
	# output filled sequence files
	&fillSequences();
}

sub printStartupMessage {
	print(<<"_END");
pgfillseq $buildno
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
	# display usage if command line options were not specified
	unless (@ARGV) {
		&helpMessage();
	}
}

sub getOptions {
	$outputfolder = $ARGV[-1];
	my %inputfiles;
	# read command line options
	for (my $i = 0; $i < scalar(@ARGV) - 1; $i ++) {
		my @temp = glob($ARGV[$i]);
		if (scalar(@temp) > 0) {
			foreach (@temp) {
				if (!exists($inputfiles{$_})) {
					$inputfiles{$_} = 1;
					push(@inputfiles, $_);
				}
				else {
					&errorMessage(__LINE__, "\"$_\" is doubly specified.");
				}
			}
		}
		else {
			&errorMessage(__LINE__, "Input file does not exist.");
		}
	}
}

sub checkVariables {
	if (-e $outputfolder) {
		&errorMessage(__LINE__, "The output folder already exists.");
	}
}

sub storeTaxa {
	foreach my $inputfile (@inputfiles) {
		unless (open($filehandleinput1, "< $inputfile")) {
			&errorMessage(__LINE__, "Cannot read \"$inputfile\".");
		}
		local $/ = "\n>";
		my %temptaxa;
		my $templen;
		while (<$filehandleinput1>) {
			if (/^>?\s*(\S[^\r\n]*)\r?\n(.+)/s) {
				my $taxon = $1;
				my $seq = uc($2);
				$seq =~ s/[^A-Z\-\?]//sg;
				my @seq = $seq =~ /\S/g;
				if ($temptaxa{$taxon}) {
					&errorMessage(__LINE__, "The taxon \"$taxon\" is duplicated in \"$inputfile\".");
				}
				else {
					$temptaxa{$taxon} = 1;
					$taxa{$taxon} = 1;
				}
				if (!defined($templen)) {
					$templen = scalar(@seq);
				}
				elsif (scalar(@seq) != $templen) {
					&errorMessage(__LINE__, "The sequence length is not equal among taxa in \"$inputfile\".");
				}
			}
		}
		close($filehandleinput1);
		push(@length, $templen);
	}
}

sub fillSequences {
	unless (mkdir($outputfolder)) {
		&errorMessage(__LINE__, "Cannot make output folder.");
	}
	my @taxa = sort(keys(%taxa));
	foreach my $inputfile (@inputfiles) {
		my $templen = shift(@length);
		unless (open($filehandleinput1, "< $inputfile")) {
			&errorMessage(__LINE__, "Cannot read \"$inputfile\".");
		}
		local $/ = "\n>";
		my %seq;
		while (<$filehandleinput1>) {
			if (/^>?\s*(\S[^\r\n]*)\r?\n(.+)/s) {
				my $taxon = $1;
				my $seq = uc($2);
				$seq =~ s/[^A-Z\-\?]//sg;
				my @seq = $seq =~ /\S/g;
				$seq{$taxon} = join('', @seq);
			}
		}
		close($filehandleinput1);
		unless (open($filehandleoutput1, "> $outputfolder/$inputfile")) {
			&errorMessage(__LINE__, "Cannot write \"$outputfolder/$inputfile\".");
		}
		foreach my $taxon (@taxa) {
			if ($seq{$taxon}) {
				print($filehandleoutput1 ">$taxon\n$seq{$taxon}\n");
			}
			else {
				print($filehandleoutput1 ">$taxon\n");
				for (my $i = 0; $i < $templen; $i ++) {
					print($filehandleoutput1 '?');
				}
				print($filehandleoutput1 "\n");
			}
		}
		close($filehandleoutput1);
	}
}

sub errorMessage {
	my $lineno = shift(@_);
	my $message = shift(@_);
	print(STDERR "ERROR!: line $lineno\n$message\n");
	print(STDERR "If you want to read help message, run this script without options.\n");
	exit(1);
}

sub helpMessage {
	print(STDERR <<"_END");
Usage
=====
pgfillseq options inputfiles outputfolder

Acceptable input file formats
=============================
FASTA
_END
	exit;
}
