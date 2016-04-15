my $buildno = '2.0.x';
#
# pgaligncodon
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
use File::Spec;

# options
my $table = 0;
my $frame = 1;
my $numthreads = 1;
my $mafftoption;

# input/output
my $inputfile;
my $outputfile;
my $alignment;

# global variables
my $devnull = File::Spec->devnull();
my @aaseqs;

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
	# translate by transeq of EMBOSS
	&translateSequences();
	# align amino-acid sequences by MAFFT
	&alignAminoAcidSequences();
	# align nucleotide sequences based on aligned amino-acid sequences
	&alignNucleotideSequences();
}

sub printStartupMessage {
	print(<<"_END");
pgaligncodon $buildno
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
	# get input file name
	$inputfile = $ARGV[-2];
	# get output file name
	$outputfile = $ARGV[-1];
	# read command line options
	my $mafftmode = 0;
	for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
		if ($ARGV[$i] eq 'end') {
			$mafftmode = 0;
		}
		elsif ($mafftmode) {
			$mafftoption .= " $ARGV[$i]";
		}
		elsif ($ARGV[$i] =~ 'mafft') {
			$mafftmode = 1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:table|t)=(\d+)$/i) {
			$table = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:frame|f)=(\d+)$/i) {
			$frame = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:alignment|a)=(.+)$/i) {
			$alignment = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:n|n(?:um)?threads?)=(\d+)$/i) {
			$numthreads = $1;
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
}

sub checkVariables {
	if (!-e $inputfile) {
		&errorMessage(__LINE__, "The input file does not exist.");
	}
	if (-e $outputfile) {
		&errorMessage(__LINE__, "The output file already exists.");
	}
	if (-e "$outputfile.temp1" || -e "$outputfile.temp2" || -e "$outputfile.temp3") {
		&errorMessage(__LINE__, "The temporary file already exists.");
	}
	if ($alignment && !-e $alignment) {
		&errorMessage(__LINE__, "The alignment file does not exist.");
	}
	unless ($mafftoption) {
		$mafftoption = ' --genafpair --maxiterate 1000';
	}
	if ($frame < 1 || $frame > 3) {
		&errorMessage(__LINE__, "The specified frame is invalid.");
	}
	if ($table !~ /^(?:0|1|2|3|4|5|6|9|10|11|12|13|14|15|16|21|22|23)$/) {
		&errorMessage(__LINE__, "The specified genetic code is invalid.");
	}
	if ($numthreads < 1) {
		&errorMessage(__LINE__, "The specified number of threads is invalid.");
	}
	if (system("transeq -h 1> $devnull 2> $devnull")) {
		&errorMessage(__LINE__, "Cannot find \"transeq\" of EMBOSS.")
	}
	if (system("mafft --version 1> $devnull 2> $devnull")) {
		&errorMessage(__LINE__, "Cannot find MAFFT.")
	}
}

sub translateSequences {
	unless ($alignment) {
		unless (open($filehandleoutput1, "> $outputfile.temp1")) {
			&errorMessage(__LINE__, "Cannot write \"$outputfile.temp1\".");
		}
		unless (open($filehandleinput1, "< $inputfile")) {
			&errorMessage(__LINE__, "Cannot read \"$inputfile\".");
		}
		local $/ = "\n>";
		while (<$filehandleinput1>) {
			if (/^>?\s*(\S[^\r\n]*)\r?\n(.+)/s) {
				my $taxon = $1;
				my $seq = uc($2);
				$seq =~ s/(?:\-|\?)/N/sg;
				$seq =~ s/[^A-Z]//sg;
				print($filehandleoutput1 ">$taxon\n$seq\n");
			}
		}
		close($filehandleinput1);
		close($filehandleoutput1);
		if (system("transeq -table $table -frame $frame -clean $outputfile.temp1 $outputfile.temp2 1> $devnull")) {
			&errorMessage(__LINE__, "Cannot run \"transeq -table $table -frame $frame -clean $outputfile.temp1 $outputfile.temp2\".");
		}
		unlink("$outputfile.temp1");
	}
}

sub alignAminoAcidSequences {
	if ($alignment) {
		unless (open($filehandleinput1, "< $alignment")) {
			&errorMessage(__LINE__, "Cannot read \"$alignment\".");
		}
	}
	else {
		if (system("mafft$mafftoption --inputorder --thread $numthreads $outputfile.temp2 > $outputfile.temp3")) {
			&errorMessage(__LINE__, "Cannot run \"\".");
		}
		unlink("$outputfile.temp2");
		unless (open($filehandleinput1, "< $outputfile.temp3")) {
			&errorMessage(__LINE__, "Cannot read \"$outputfile.temp3\".");
		}
	}
	local $/ = "\n>";
	my %taxa;
	my $ntax = 0;
	while (<$filehandleinput1>) {
		if (/^>?\s*(\S[^\r\n]*)\r?\n(.+)/s) {
			my $taxon = $1;
			my $seq = uc($2);
			$seq =~ s/[^A-Z\-\?]//sg;
			my @seq = $seq =~ /\S/g;
			if ($taxa{$taxon}) {
				&errorMessage(__LINE__, "The taxon \"$taxon\" is duplicated.");
			}
			else {
				push(@{$aaseqs[$ntax]}, @seq);
				$taxa{$taxon} = 1;
				$ntax ++;
			}
		}
	}
	close($filehandleinput1);
	unlink("$outputfile.temp3");
}

sub alignNucleotideSequences {
	unless (open($filehandleoutput1, "> $outputfile")) {
		&errorMessage(__LINE__, "Cannot write \"$outputfile\".");
	}
	unless (open($filehandleinput1, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot read \"$inputfile\".");
	}
	local $/ = "\n>";
	my $ntax = 0;
	while (<$filehandleinput1>) {
		if (/^>?\s*(\S[^\r\n]*)\r?\n(.+)/s) {
			my $taxon = $1;
			my $seq = uc($2);
			$seq =~ s/[^A-Z\-\?]//sg;
			my @seq = $seq =~ /\S/g;
			print($filehandleoutput1 ">$taxon\n");
			if ($frame == 2) {
				print($filehandleoutput1 $seq[0]);
				shift(@seq);
			}
			elsif ($frame == 3) {
				print($filehandleoutput1 $seq[0] . $seq[1]);
				shift(@seq);
				shift(@seq);
			}
			for (my $i = 0; $i < scalar(@{$aaseqs[$ntax]}); $i ++) {
				if ($aaseqs[$ntax][$i] eq '-') {
					print($filehandleoutput1 '---');
				}
				elsif ($seq[0] && $seq[1] && $seq[2]) {
					print($filehandleoutput1 $seq[0] . $seq[1] . $seq[2]);
					shift(@seq);
					shift(@seq);
					shift(@seq);
				}
				elsif ($aaseqs[$ntax][$i] eq 'X' || $aaseqs[$ntax][$i] eq 'x') {
					if ($seq[0] && $seq[1]) {
						print($filehandleoutput1 $seq[0] . $seq[1] . '?');
					}
					elsif ($seq[0]) {
						print($filehandleoutput1 $seq[0] . '??');
					}
					else {
						&errorMessage(__LINE__, "The $i-th amino-acid is \"X\", but there is no nucleotide.");
					}
				}
				elsif ($seq[0] && $seq[1]) {
					print($filehandleoutput1 $seq[0] . $seq[1] . '?');
				}
				else {
					&errorMessage(__LINE__, "The $i-th amino-acid is \"$aaseqs[$ntax][$i]\", and the nucleotide is \"$seq[0]$seq[1]$seq[2]\".");
				}
			}
			print($filehandleoutput1 "\n");
			$ntax ++;
		}
	}
	close($filehandleinput1);
	close($filehandleoutput1);
}

# error message
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
pgaligncodon options inputfile outputfile

Command line options
====================
mafft options end
  Specify commandline options for mafft.
(default: --genafpair --maxiterate 1000)

-f,--frame=1|2|3
  Specify the frame to translate. (default: 1)

-t,--table=INTEGER
  Specify genetic code number. (default: 0)

-n,--numthreads=INTEGER
  Specify the number of threads. (default: 1)

Acceptable input file formats
=============================
FASTA
_END
	exit;
}
