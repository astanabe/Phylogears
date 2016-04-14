my $buildno = '2.0.2016.02.06';
#
# pgtranseq
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
use File::Spec;
use Digest::MD5;

# options
my $table = 0;

# input/output
my $inputfile;
my $outputprefix;

# global variables
my $devnull = File::Spec->devnull();
my @taxa;
my %bestframe;
my %minstop;

# file handles
my $filehandleinput1;
my $filehandleoutput1;
my $filehandleoutput2;
my $pipehandleinput1;

&main();

sub main {
	# print startup messages
	&printStartupMessage();
	# get command line arguments
	&getOptions();
	# check variable consistency
	&checkVariables();
	# explore best frame for translation
	&exploreBestFrame();
	# save nucleotide and amino-acid sequences
	&joinSequences();
}

sub printStartupMessage {
	print(<<"_END");
pgtranseq $buildno
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
	# display usage if command line options were not specified
	unless (@ARGV) {
		&helpMessage();
	}
}

sub getOptions {
	# get input file name
	$inputfile = $ARGV[-2];
	# get output file prefix
	$outputprefix = $ARGV[-1];
	# read command line options
	for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
		if ($ARGV[$i] =~ /^-+(?:table|t)=(\d+)$/i) {
			$table = $1;
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
	if (-e "$outputprefix\_nuc.fasta" || -e "$outputprefix\_aa.fasta") {
		&errorMessage(__LINE__, "The output file already exists.");
	}
	if (-e "$outputprefix.temp1") {
		&errorMessage(__LINE__, "The temporary file already exists.");
	}
	if ($table !~ /^(?:0|1|2|3|4|5|6|9|10|11|12|13|14|15|16|21|22|23)$/) {
		&errorMessage(__LINE__, "The specified genetic code is invalid.");
	}
	if (system("transeq -h 1> $devnull 2> $devnull")) {
		&errorMessage(__LINE__, "Cannot find \"transeq\" of EMBOSS.")
	}
}

sub exploreBestFrame {
	unless (open($filehandleinput1, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot read \"$inputfile\".");
	}
	local $/ = "\n>";
	while (<$filehandleinput1>) {
		if (/^>?\s*(\S[^\r\n]*)\r?\n(.+)/s) {
			my $taxon = $1;
			my $seq = uc($2);
			my $md5 = Digest::MD5->new->add($taxon)->hexdigest;
			if ($bestframe{$taxon}) {
				&errorMessage(__LINE__, "\"$taxon\" is duplicated.");
			}
			else {
				push(@taxa, $taxon);
			}
			$seq =~ s/\-//sg;
			$seq =~ s/\?/N/sg;
			$seq =~ s/[^A-Z]//sg;
			unless (open($filehandleoutput1, "> $outputprefix.temp1")) {
				&errorMessage(__LINE__, "Cannot write \"$outputprefix.temp1\".");
			}
			print($filehandleoutput1 ">$taxon\n$seq\n");
			close($filehandleoutput1);
			foreach my $i (1, 2, 3, -1, -2, -3) {
				unless (open($pipehandleinput1, "transeq -table $table -frame $i $outputprefix.temp1 stdout |")) {
					&errorMessage(__LINE__, "Cannot run \"transeq -table $table -frame $i $outputprefix.temp1 stdout\".");
				}
				my $tempaaseq;
				while (<$pipehandleinput1>) {
					if (/^>?\s*\S[^\r\n]*\r?\n(.+)/s) {
						$tempaaseq = $1;
						$tempaaseq =~ s/\r?\n?$//;
						$tempaaseq =~ s/\*$//;
					}
				}
				close($pipehandleinput1);
				my @stop = $tempaaseq =~ /\*/g;
				my $nstop = scalar(@stop);
				if (!exists($minstop{$taxon}) || $nstop < $minstop{$taxon}) {
					$minstop{$taxon} = $nstop;
					$bestframe{$taxon} = $i;
					my $tempnucseq = $seq;
					if ($i < 0) {
						$tempnucseq = &reversecomplement($tempnucseq);
					}
					if ($i == 2 || $i == -2) {
						$tempnucseq = 'NN' . $tempnucseq;
						$tempaaseq = 'X' . $tempaaseq;
					}
					elsif ($i == 3 || $i == -3) {
						$tempnucseq = 'N' . $tempnucseq;
						$tempaaseq = 'X' . $tempaaseq;
					}
					unless (open($filehandleoutput1, "> $outputprefix\_nuc_$md5.fasta")) {
						&errorMessage(__LINE__, "Cannot write \"$outputprefix\_nuc_$md5.fasta\".");
					}
					print($filehandleoutput1 ">$taxon\n$tempnucseq\n");
					close($filehandleoutput1);
					unless (open($filehandleoutput1, "> $outputprefix\_aa_$md5.fasta")) {
						&errorMessage(__LINE__, "Cannot write \"$outputprefix\_aa_$md5.fasta\".");
					}
					print($filehandleoutput1 ">$taxon\n$tempaaseq\n");
					close($filehandleoutput1);
					if ($nstop == 0) {
						last;
					}
				}
			}
			unlink("$outputprefix.temp1");
		}
	}
	close($filehandleinput1);
}

sub joinSequences {
	unless (open($filehandleoutput1, "> $outputprefix\_nuc.fasta")) {
		&errorMessage(__LINE__, "Cannot write \"$outputprefix\_nuc.fasta\".");
	}
	unless (open($filehandleoutput2, "> $outputprefix\_aa.fasta")) {
		&errorMessage(__LINE__, "Cannot write \"$outputprefix\_aa.fasta\".");
	}
	foreach my $taxon (@taxa) {
		my $md5 = Digest::MD5->new->add($taxon)->hexdigest;
		if ($minstop{$taxon} > 0) {
			print(STDERR "\"$taxon\" contains stop codon.\n");
		}
		# read nucleotide sequence
		unless (open($filehandleinput1, "< $outputprefix\_nuc_$md5.fasta")) {
			&errorMessage(__LINE__, "Cannot read \"$outputprefix\_nuc_$md5.fasta\".");
		}
		my $tempnucseq;
		while (<$filehandleinput1>) {
			s/\r?\n?$//;
			unless (/^>/) {
				$tempnucseq .= $_;
			}
		}
		close($filehandleinput1);
		unlink("$outputprefix\_nuc_$md5.fasta");
		# save nucleotide sequence
		print($filehandleoutput1 ">$taxon\n$tempnucseq\n");
		# read amino-acid sequence
		unless (open($filehandleinput1, "< $outputprefix\_aa_$md5.fasta")) {
			&errorMessage(__LINE__, "Cannot read \"$outputprefix\_aa_$md5.fasta\".");
		}
		my $tempaaseq;
		while (<$filehandleinput1>) {
			s/\r?\n?$//;
			unless (/^>/) {
				$tempaaseq .= $_;
			}
		}
		close($filehandleinput1);
		unlink("$outputprefix\_aa_$md5.fasta");
		# save amino-acid sequence
		$tempaaseq =~ s/\*/X/g;
		print($filehandleoutput2 ">$taxon\n$tempaaseq\n");
	}
	close($filehandleoutput1);
	close($filehandleoutput2);
}

sub reversecomplement {
	my @temp = split('', $_[0]);
	my @seq;
	foreach my $seq (reverse(@temp)) {
		$seq =~ tr/ACGTMRYKVHDBacgtmrykvhdb/TGCAKYRMBDHVtgcakyrmbdhv/;
		push(@seq, $seq);
	}
	return(join('', @seq));
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
pgtranseq options inputfile outputprefix

Command line options
====================
-t,--table=INTEGER
  Specify genetic code number. (default: 0)

Acceptable input file formats
=============================
FASTA
_END
	exit;
}
