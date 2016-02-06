#!/usr/bin/perl
my $buildno = '2.0.2016.02.06';
#
# pgstanstrand
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
pgstanstrand $buildno
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

# get output file name
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
		&errorMessage(__LINE__, "\"$outputfile\" file already exists.");
}
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
		&errorMessage(__LINE__, "\"$inputfile\" file does not exist.");
}

# get command line options
if (scalar(@ARGV) > 2) {
	&errorMessage(__LINE__, "\"$ARGV[0]\" is unknown option.");
}

# begin read input file
unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
my $nseq = 1;
my $nline = 1;
my $outputfilehandle;
my $seqname;
my $sequence;
while (<INFILE>) {
	my $line = $_;
	$line =~ s/\r?\n?$//;
	if ($line =~ /^>/ && $nline != 1) {
		$sequence = uc($sequence);
		# make single sequence temporary file
		unless (open(OUTFILE, "> $inputfile.$nseq.fasta")) {
				&errorMessage(__LINE__, "Cannot make temporary file \"$inputfile.$nseq.fasta\".");
		}
		print(OUTFILE $seqname . "\n" . $sequence . "\n");
		close(OUTFILE);
		if ($nseq == 1) {
			open($outputfilehandle, ">> $outputfile");
			print($outputfilehandle $seqname . "\n" . $sequence . "\n");
			close($outputfilehandle);
		}
		else {
			my $fscore;
			my $rscore;
			open(PIPE, "stretcher -aformat score $inputfile.1.fasta $inputfile.$nseq.fasta stdout |");
			while (<PIPE>) {
				if (/\((\-?\d+(?:\.\d+)?)\)/) {
					$fscore = $1;
					last;
				}
			}
			close(PIPE);
			my $revcomp = &reversecomplement($sequence);
			# make single sequence temporary file
			unless (open(OUTFILE, "> $inputfile.$nseq.fasta")) {
					&errorMessage(__LINE__, "Cannot make temporary file \"$inputfile.$nseq.fasta\".");
			}
			print(OUTFILE $seqname . "\n" . $revcomp . "\n");
			close(OUTFILE);
			open(PIPE, "stretcher -aformat score $inputfile.1.fasta $inputfile.$nseq.fasta stdout |");
			while (<PIPE>) {
				if (/\((\-?\d+(?:\.\d+)?)\)/) {
					$rscore = $1;
					last;
				}
			}
			close(PIPE);
			open($outputfilehandle, ">> $outputfile");
			if ($fscore < $rscore) {
				print($outputfilehandle $seqname . "\n" . $revcomp . "\n");
			}
			else {
				print($outputfilehandle $seqname . "\n" . $sequence . "\n");
			}
			close($outputfilehandle);
			print(STDERR "The $nseq-th sequence\nFscore: $fscore\nRscore: $rscore\n");
			# delete temporary file
			unlink("$inputfile.$nseq.fasta");
			undef($seqname);
			undef($sequence);
		}
		$nseq ++;
	}
	if ($line =~ /^>/) {
		$seqname = $line;
	}
	else {
		$line =~ s/\-//g;
		if ($line =~ /./) {
			$sequence .= $line;
		}
	}
	$nline ++;
}
if ($sequence) {
	$sequence = uc($sequence);
	# make single sequence temporary file
	unless (open(OUTFILE, "> $inputfile.$nseq.fasta")) {
			&errorMessage(__LINE__, "Cannot make temporary file \"$inputfile.$nseq.fasta\".");
	}
	print(OUTFILE $seqname . "\n" . $sequence . "\n");
	close(OUTFILE);
	my $fscore;
	my $rscore;
	open(PIPE, "stretcher -aformat score $inputfile.1.fasta $inputfile.$nseq.fasta stdout |");
	while (<PIPE>) {
		if (/\((\-?\d+(?:\.\d+)?)\)/) {
			$fscore = $1;
			last;
		}
	}
	close(PIPE);
	my $revcomp = &reversecomplement($sequence);
	# make single sequence temporary file
	unless (open(OUTFILE, "> $inputfile.$nseq.fasta")) {
			&errorMessage(__LINE__, "Cannot make temporary file \"$inputfile.$nseq.fasta\".");
	}
	print(OUTFILE $seqname . "\n" . $revcomp . "\n");
	close(OUTFILE);
	open(PIPE, "stretcher -aformat score $inputfile.1.fasta $inputfile.$nseq.fasta stdout |");
	while (<PIPE>) {
		if (/\((\-?\d+(?:\.\d+)?)\)/) {
			$rscore = $1;
			last;
		}
	}
	close(PIPE);
	open($outputfilehandle, ">> $outputfile");
	if ($fscore < $rscore) {
		print($outputfilehandle $seqname . "\n" . $revcomp . "\n");
	}
	else {
		print($outputfilehandle $seqname . "\n" . $sequence . "\n");
	}
	close($outputfilehandle);
	print(STDERR "The $nseq-th sequence\nFscore: $fscore\nRscore: $rscore\n");
	# delete temporary file
	unlink("$inputfile.$nseq.fasta");
	undef($seqname);
	undef($sequence);
}
unlink("$inputfile.1.fasta");

sub reversecomplement {
	my @seq = split(/ */, $_[0]);
	@seq = reverse(@seq);
	my $seq = join('', @seq);
	$seq =~ tr/ACGTMRYKVHDBacgtmrykvhdb/TGCAKYRMBDHVtgcakyrmbdhv/;
	return($seq);
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
pgstanstrand inputfile outputfile

Acceptable input file formats
=============================
FASTA
_END
	exit;
}
