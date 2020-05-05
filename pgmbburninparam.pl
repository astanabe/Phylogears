my $buildno = '2.0.x';
#
# pgmbburninparam
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
pgmbburninparam $buildno
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
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
# check options
my $burnin = 0;
my $append;
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:b|burnin)=(\-?\d+)$/i) {
		$burnin = $1;
	}
	elsif ($ARGV[$i] =~ /^-+(?:a|append)$/i) {
		$append = 1;
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}
if ($outputfile !~ /^stdout$/i && $append != 1 && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}

if ($burnin < 0) {
	my $sampleno = 0;
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	while (<INFILE>) {
		if (/^Gen\tLnL\t/ && $sampleno == 0) {
			$sampleno = 1;
		}
		elsif (/^\d+\t-\d+\.?\d*\t/) {
			$sampleno ++;
		}
	}
	close(INFILE);
	$burnin = $sampleno - 1 + $burnin;
}

# read file
my $numstep = 0;
my $interval = 0;
if ($append) {
	unless (open(OUTFILE, "< $outputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$outputfile\".");
	}
	while (<OUTFILE>) {
		if (/^(\d+)\t-\d+\.?\d*\t/) {
			$interval = $1 - $numstep;
			$numstep = $1;
		}
	}
	close(OUTFILE);
}

# output
my $filehandle;
if ($outputfile =~ /^stdout$/i) {
	unless (open($filehandle, '>-')) {
		&errorMessage(__LINE__, "Cannot write STDOUT.");
	}
}
elsif ($append) {
	unless (open($filehandle, ">> $outputfile")) {
		&errorMessage(__LINE__, "Cannot write \"$outputfile\".");
	}
}
else {
	unless (open($filehandle, "> $outputfile")) {
		&errorMessage(__LINE__, "Cannot make \"$outputfile\".");
	}
}

# read file
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
{
	my $sampleno = 0;
	while (<INFILE>) {
		if (/^Gen\tLnL\t/ && $append != 1 && $sampleno == 0) {
			print($filehandle $_);
			$sampleno = 1;
		}
		elsif (/^Gen\tLnL\t/ && $sampleno == 0) {
			$sampleno = 1;
		}
		elsif (/^\d+\t-\d+\.?\d*\t/ && $sampleno > $burnin) {
			if ($append) {
				$numstep += $interval;
				s/^\d+/$numstep/;
			}
			print($filehandle $_);
			$sampleno ++;
		}
		elsif (/^\d+\t-\d+\.?\d*\t/) {
			$sampleno ++;
		}
	}
}
close(INFILE);

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
pgmbburninparam options inputfile outputfile

Command line options
====================
-b, --burnin=INTEGER
  Specify the number of samples of burn-in.
  (not the number of steps)

-a, --append
  Specify this option if you want to append output to existing file.

Acceptable input file formats
=============================
MrBayes .p files
_END
	exit;
}
