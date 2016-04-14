my $buildno = '2.0.2016.02.06';
#
# pgconvtree
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
pgconvtree $buildno
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
my $tablefile;
my $format;
my $outformat;
my @trees;

# check options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:o|output)=(.+)$/i) {
		my $outoption = $1;
		if ($outoption =~ /^NEXUS$/i) {
			unless ($outformat) {
				$outformat = 'NEXUS';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^Newick$/i) {
			unless ($outformat) {
				$outformat = 'Newick';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:t|table)=(.+)$/i && -f $1 && !-z $1) {
		$tablefile = $1;
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
	if (/^#NEXUS/i) {
		$format = 'NEXUS';
	}
	elsif (/^\{/) {
		$format = 'TF';
	}
	else {
		$format = 'Newick'
	}
	last;
}
close(INFILE);

# read input files
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
if ($format eq 'NEXUS') {
	my $treesblock = 0;
	my $translate = 0;
	my $tnt;
	my %table;
	while (<INFILE>) {
		if ($treesblock != 1 && /^\s*Begin\s+Trees\s*;/i) {
			$treesblock = 1;
		}
		elsif ($treesblock == 1 && /^\s*End\s*;/i) {
			$treesblock = 0;
		}
		elsif ($treesblock == 1 && $translate == 1) {
			if (/^\s*(\S+)\s+([^,;\s]+)\s*([,;])\s*\r?\n?$/) {
				$table{$1} = $2;
				if ($3 eq ';') {
					$translate = 0;
				}
			}
		}
		elsif ($treesblock == 1 && $translate == 0 && !%table && /^\s*Translate/i) {
			$translate = 1;
		}
		elsif ($treesblock == 1 && $translate == 0 && /\s*Tree\s*\S+\s*=\s*(?:\[[^\(\):]+\])?\s*(\(.+\))(?:\:0|\:0\.0)?;/i) {
			my $tree = $1;
			foreach my $from (keys(%table)) {
				$tree =~ s/([\(,])$from([:,\)])/$1$table{$from}$2/;
			}
			push(@trees, $tree);
		}
		elsif ($treesblock == 1 && $translate == 0 && /\s*Tree\s*\S+\s*=\s*(?:\[[^\(\):]+\])?\s*/i) {
			$tnt = 1;
		}
		elsif ($tnt == 1 && $treesblock == 1 && $translate == 0 && /(\(.+\))(?:\:0|\:0\.0)?;/i) {
			my $tree = $1;
			foreach my $from (keys(%table)) {
				$tree =~ s/([\(,])$from([:,\)])/$1$table{$from}$2/;
			}
			push(@trees, $tree);
			$tnt = 0;
		}
	}
}
elsif ($format eq 'Newick') {
	local $/ = ';';
	while (<INFILE>) {
		if (/(\(.+\))(?:\:0|\:0\.0)?(?:\s*\[([\d\/\.]+)\])?;/s) {
			my $tree = $1;
			$tree =~ s/\s//sg;
			push(@trees, $tree);
		}
	}
}
elsif ($format eq 'TF') {
	while (<INFILE>) {
		if (/Phylogeny->(\{.+?\}),/) {
			my $tree = $1;
			$tree =~ tr/\{\}"/\(\)/d;
			push(@trees, $tree);
		}
	}
}
close(INFILE);

# convert sequence names
if ($tablefile) {
	my %replace;
	unless (open(INFILE, "< $tablefile")) {
		&errorMessage(__LINE__, "Cannot open \"$tablefile\".");
	}
	while (<INFILE>) {
		if (/^(\S+) +\"(.+)\"\r?\n?$/) {
			my $taxon = $1;
			my $temp = $2;
			$taxon =~ s/\s//g;
			$replace{$taxon} = $temp;
		}
	}
	close(INFILE);
	for (my $i = 0; $i < scalar(@trees); $i ++) {
		foreach my $taxon (sort({$b cmp $a} keys(%replace))) {
			$trees[$i] =~ s/$taxon/$replace{$taxon}/g;
		}
	}
}

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
if ($outformat eq 'NEXUS') {
	print($filehandle "#NEXUS\n\nBegin Trees;\n");
}
for (my $i = 0; $i < scalar(@trees); $i ++) {
	if ($outformat eq 'NEXUS') {
		print($filehandle "\t" . 'Tree tree_' . ($i + 1) . ' = ');
	}
	print($filehandle $trees[$i] . ";\n");
}
if ($outformat eq 'NEXUS') {
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
pgconvtree options inputfile outputfile

Command line options
====================
-o, --output=Newick|NEXUS
  Specify output file format.

Acceptable input file formats
=============================
Newick
NEXUS
PHYLIP
TL Report
_END
	exit;
}
