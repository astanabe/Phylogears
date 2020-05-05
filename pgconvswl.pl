my $buildno = '2.0.x';
#
# pgconvswl
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

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgconvswl $buildno
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
my $format;
my $outformat;
my $numdataset = 0;

# check options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:o|output)=(.+)$/i) {
		my $outoption = $1;
		if ($outoption =~ /^PAML$/i) {
			unless ($outformat) {
				$outformat = 'PAML';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^PUZZLE$/i) {
			unless ($outformat) {
				$outformat = 'PUZZLE';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^MOLPHY$/i) {
			unless ($outformat) {
				$outformat = 'MOLPHY';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^PAUP$/i) {
			unless ($outformat) {
				$outformat = 'PAUP';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^CONSEL$/i) {
			unless ($outformat) {
				$outformat = 'CONSEL';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^TF$/i) {
			unless ($outformat) {
				$outformat = 'TF';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}
unless ($outformat) {
	&errorMessage(__LINE__, 'Output option is not specified.');
}

# file format recognition
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
while (<INFILE>) {
	if (/^ *\d+ +\d+ +\d+ *\r?\n?$/) {
		$format = 'PAML';
	}
	elsif (/^ *\d+ +\d+ *\r?\n?$/) {
		$format = 'PUZZLE';
	}
	elsif (/^\d+ \d+\r?\n?$/) {
		$format = 'MOLPHY';
	}
	elsif (/^Tree\t-lnL\tSite\t-lnL\r?\n?$/) {
		$format = 'PAUP';
	}
	elsif (/^#!MAT:\r?\n?$/) {
		$format = 'CONSEL';
	}
	elsif (/^\{\r?\n?$/) {
		$format = 'TF';
	}
	else {
		&errorMessage(__LINE__, "\"$inputfile\" is written in unknown format.");
	}
	last;
}
close(INFILE);

&readInputFile();

# read input file
sub readInputFile {
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	my $ntree;
	my $nchar;
	my $treename;
	my @treename;
	my @LnLs;
	if ($format eq 'PAML') {
		while (<INFILE>) {
			if (/^\s*(\d+)\s+(\d+)\s+\d+\s*\r?\n?$/ && !$ntree && !$nchar) {
				$ntree = $1;
				$nchar = $2;
			}
			elsif (/^\s*(\d+)\s*\r?\n?$/ && $ntree && $nchar) {
				$treename = $1;
				push(@treename, $treename);
			}
			elsif (/^\s*\d+\s+(\d+)\s+(\S+)\s+\S+\s+\S+\s+\S+\r?\n?$/ && $treename) {
				my $repeat = $1;
				my $LnL = $2;
				for (my $i = 0; $i < $repeat; $i ++) {
					push(@{$LnLs[scalar(@treename) - 1]}, $LnL);
				}
			}
		}
	}
	elsif ($format eq 'PUZZLE') {
		while (<INFILE>) {
			if (/^\s*(\d+)\s+(\d+)\s*\r?\n?$/ && !$ntree && !$nchar) {
				$ntree = $1;
				$nchar = $2;
			}
			elsif (/^(\S+)\s+((?:\S+\s+){1,$nchar})\n?$/ && $ntree && $nchar) {
				$treename = $1;
				push(@treename, $treename);
				my @lnL = split(/\s+/, $2);
				push(@{$LnLs[scalar(@treename) - 1]}, @lnL);
			}
		}
	}
	elsif ($format eq 'MOLPHY') {
		while (<INFILE>) {
			if (/^(\d+) (\d+)\r?\n?$/ && !$ntree && !$nchar) {
				$ntree = $1;
				$nchar = $2;
			}
			elsif (/^# (\d+)\r?\n?$/ && $ntree && $nchar) {
				$treename = $1;
				push(@treename, $treename);
			}
			elsif (/^((?:\S+\s)+)\n?$/ && $treename) {
				my @lnL = split(/\s+/, $1);
				push(@{$LnLs[scalar(@treename) - 1]}, @lnL);
			}
		}
	}
	elsif ($format eq 'PAUP') {
		$treename = 0;
		while (<INFILE>) {
			if (/^\t\t1\t(\S+)\r?\n?$/) {
				$treename ++;
				push(@treename, $treename);
				push(@{$LnLs[scalar(@treename) - 1]}, $1 * (-1));
			}
			elsif (/^\t\t\d+\t(\S+)\r?\n?$/) {
				push(@{$LnLs[scalar(@treename) - 1]}, $1 * (-1));
			}
		}
		$ntree = scalar(@treename);
		$nchar = scalar(@{$LnLs[0]});
	}
	elsif ($format eq 'CONSEL') {
		while (<INFILE>) {
			if (/^(\d+) (\d+)\r?\n?$/ && !$ntree && !$nchar) {
				$ntree = $1;
				$nchar = $2;
			}
			elsif (/^# row: (\d+)\r?\n?$/ && $ntree && $nchar) {
				$treename = $1 + 1;
				push(@treename, $treename);
			}
			elsif (/^\s+((?:\S+\s+)+)\r?\n?$/ && $treename) {
				my @lnL = split(/\s+/, $1);
				push(@{$LnLs[scalar(@treename) - 1]}, @lnL);
			}
		}
	}
	elsif ($format eq 'TF') {
		$treename = 0;
		while (<INFILE>) {
			if (/\{([^,]+(?:,[^,]+)*)\}/) {
				$treename ++;
				push(@treename, $treename);
				my @lnL = split(/,/, $1);
				push(@{$LnLs[scalar(@treename) - 1]}, @lnL);
			}
		}
		$ntree = scalar(@treename);
		$nchar = scalar(@{$LnLs[0]});
	}
	close(INFILE);
	&makeOutputFile($ntree, $nchar, \@treename, \@LnLs);
}

sub makeOutputFile {
	my $ntree = shift(@_);
	my $nchar = shift(@_);
	my @treename = @{shift(@_)};
	my @LnLs = @{shift(@_)};
	# check data
	if (scalar(@LnLs) != $ntree || scalar(@treename) != $ntree) {
		&errorMessage(__LINE__, "The number of trees is not equal to that of header.");
	}
	for (my $i = 0; $i < $ntree; $i ++) {
		if (scalar(@{$LnLs[$i]}) != $nchar) {
			&errorMessage(__LINE__, "The number of sites is not equal to that of header.");
		}
	}
	# output processed sitewise likelihoods file
	my $filehandle;
	if ($outputfile =~ /^stdout$/i) {
		unless (open($filehandle, '>-')) {
			&errorMessage(__LINE__, "Cannot write STDOUT.");
		}
	}
	else {
		unless (open($filehandle, "> $outputfile")) {
			&errorMessage(__LINE__, "Cannot write \"$outputfile\".");
		}
	}
	if ($outformat eq 'PUZZLE') {
		print($filehandle ' ' . $ntree . ' ' . $nchar . " \n");
	}
	elsif ($outformat eq 'MOLPHY') {
		print($filehandle $ntree . ' ' . $nchar . "\n");
	}
	elsif ($outformat eq 'CONSEL') {
		print($filehandle "#!MAT:\n$ntree $nchar\n");
	}
	elsif ($outformat eq 'PAUP') {
		print($filehandle "Tree\t-lnL\tSite\t-lnL\n");
	}
	elsif ($outformat eq 'TF') {
		print($filehandle "{\n");
	}
	for (my $i = 0; $i < $ntree; $i ++) {
		if ($outformat eq 'PUZZLE') {
			my $treename = $treename[$i];
			if ($treename =~ /^\d+$/) {
				$treename = 'tree' . $treename;
			}
			print($filehandle $treename . '     ');
		}
		elsif ($outformat eq 'MOLPHY') {
			print($filehandle '# ' . ($i + 1) . "\n");
		}
		elsif ($outformat eq 'CONSEL') {
			print($filehandle "\n# row: $i\n");
		}
		elsif ($outformat eq 'TF') {
			print($filehandle ' {');
		}
		my $sumLnLs = 0;
		for (my $j = 0; $j < $nchar; $j ++) {
			if ($outformat eq 'PUZZLE') {
				printf($filehandle " %.5f", $LnLs[$i][$j]);
			}
			elsif ($outformat eq 'MOLPHY') {
				printf($filehandle "%.8e", $LnLs[$i][$j]);
				if (($j + 1) % 5 == 0 || $j + 1 == $nchar) {
					print($filehandle "\n");
				}
				else {
					print($filehandle ' ');
				}
			}
			elsif ($outformat eq 'CONSEL') {
				printf($filehandle "%14.5f ", $LnLs[$i][$j]);
				if (($j + 1) % 5 == 0 || $j + 1 == $nchar) {
					print($filehandle "\n");
				}
			}
			elsif ($outformat eq 'PAUP') {
				printf($filehandle "\t\t%d\t%.8f\n", ($j + 1), ($LnLs[$i][$j] * (-1)));
				$sumLnLs += $LnLs[$i][$j];
			}
			elsif ($outformat eq 'TF') {
				printf($filehandle "%.7f", $LnLs[$i][$j]);
				if ($j + 1 == $nchar) {
					print($filehandle '}');
				}
				else {
					print($filehandle ',');
				}
			}
		}
		if ($outformat eq 'PUZZLE') {
			print($filehandle "\n");
		}
		elsif ($outformat eq 'PAUP') {
			printf($filehandle "%d\t%.8f\n", ($i + 1), ($sumLnLs * (-1)));
		}
		elsif ($outformat eq 'TF') {
			if ($i + 1 == $ntree) {
				print($filehandle "\n");
			}
			else {
				print($filehandle ",\n");
			}
		}
	}
	if ($outformat eq 'TF') {
		print($filehandle "}\n");
	}
	close($filehandle);
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
pgconvswl options inputfile outputfile

Command line options
====================
-o, --output=PUZZLE|MOLPHY|CONSEL|PAUP|TF
  Specify output file format.

Acceptable input file formats
=============================
PAML/lnf
PUZZLE/sitelh
MOLPHY/lls
CONSEL/mt
PAUP
TF (Treefinder)
_END
	exit;
}
