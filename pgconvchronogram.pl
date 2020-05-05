my $buildno = '2.0.x';
#
# pgconvchronogram
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
pgconvchronogram $buildno
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
my $outformat = 'FigTree';
my @trees;

# check options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:o|output)=(.+)$/i) {
		my $outoption = $1;
		if ($outoption =~ /^FigTree$/i || $outoption =~ /^FT$/i) {
			unless ($outformat) {
				$outformat = 'FigTree';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^Treefinder$/i || $outoption =~ /^TF$/i) {
			unless ($outformat) {
				$outformat = 'Treefinder';
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

# file format recognition
$format = 'PhyloBayes';

# read input files
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
{
	local $/ = ';';
	while (<INFILE>) {
		if (/(\(.+\))(?:\:0|\:0\.0)?(?:\s*\[([\d\/\.]+)\])?;/s) {
			my $tree = $1;
			$tree =~ s/\s//sg;
			push(@trees, $tree);
		}
	}
}
close(INFILE);

# output file
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
if ($outformat eq 'FigTree') {
	print($filehandle "#NEXUS\n\nBegin Trees;\n");
}
foreach my $tree (@trees) {
	if ($outformat eq 'FigTree') {
		my $datefile = $inputfile;
		$datefile =~ s/\.chronogram/\.dates/;
		my $rootmin;
		my $rootmax;
		unless (open(DATES, "< $datefile")) {
			&errorMessage(__LINE__, "Cannot open \"$datefile\".");
		}
		while (<DATES>) {
			if (/^\d+\t[\d\.]+\t[\d\.]+\t([\d\.]+)\t([\d\.]+)\t[\d\.]+\t[\d\.]+\t0\t0\r?\n?$/) {
				$rootmin = $1;
				$rootmax = $2;
				last;
			}
		}
		close(DATES);
		if (!$rootmin || !$rootmax) {
			&errorMessage(__LINE__, "Invalid date file.");
		}
		$tree =~ s/\)([\d\.]+)_([\d\.]+):/)[\&height_95\%_HPD={$2,$1}]:/g;
		$tree =~ s/\)$/)[\&height_95\%_HPD={$rootmin,$rootmax}]/;
		print($filehandle "\tTree chronogram = [&R] $tree;\n");
	}
}
if ($outformat eq 'FigTree') {
	print($filehandle "End;\n");
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
pgconvchronogram inputfile outputfile

Acceptable input file formats
=============================
PhyloBayes
_END
	exit;
}
