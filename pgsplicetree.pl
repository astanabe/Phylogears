my $buildno = '2.0.2016.04.14';
#
# pgsplicetree
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

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgsplicetree $buildno
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
my $converse = 0;
my @target;
my $format;
my @trees;

# file format recognition
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
while (<INFILE>) {
	if (/^#NEXUS/i) {
		$format = 'NEXUS';
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
close(INFILE);

# get target trees
{
	my $ntrees = scalar(@trees);
	my @temptrees;
	for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
		if ($ARGV[$i] =~ /^-+(?:c|converse)$/i) {
			$converse = 1;
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)\-(\-?\d+)\\(\d+)$/) {
			my $temptree1 = $1;
			my $temptree2 = $2;
			if ($temptree1 < 0) {
				$temptree1 = $ntrees + $temptree1 + 1;
			}
			if ($temptree2 < 0) {
				$temptree2 = $ntrees + $temptree2 + 1;
			}
			if ($temptree1 < 1 || $temptree2 < 1 || $temptree1 > $ntrees || $temptree2 > $ntrees) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			if ($temptree1 < $temptree2) {
				push(@temptrees, &range2list($temptree1, $temptree2, $3));
			}
			elsif ($temptree1 > $temptree2) {
				push(@temptrees, &range2list($temptree2, $temptree1, $3));
			}
			elsif ($temptree1 == $temptree2) {
				push(@temptrees, $temptree1);
			}
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)\-\.\\(\d+)$/) {
			my $temptree = $1;
			if ($temptree < 0) {
				$temptree = $ntrees + $temptree + 1;
			}
			if ($temptree < 1) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			if ($temptree < $ntrees) {
				push(@temptrees, &range2list($temptree, $ntrees, $2));
			}
			elsif ($temptree == $ntrees) {
				push(@temptrees, $temptree);
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)\-(\-?\d+)$/) {
			my $temptree1 = $1;
			my $temptree2 = $2;
			if ($temptree1 < 0) {
				$temptree1 = $ntrees + $temptree1 + 1;
			}
			if ($temptree2 < 0) {
				$temptree2 = $ntrees + $temptree2 + 1;
			}
			if ($temptree1 < 1 || $temptree2 < 1 || $temptree1 > $ntrees || $temptree2 > $ntrees) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			if ($temptree1 < $temptree2) {
				push(@temptrees, $temptree1 .. $temptree2);
			}
			elsif ($temptree1 > $temptree2) {
				push(@temptrees, $temptree2 .. $temptree1);
			}
			elsif ($temptree1 == $temptree2) {
				push(@temptrees, $temptree1);
			}
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)\-\.$/) {
			my $temptree = $1;
			if ($temptree < 0) {
				$temptree = $ntrees + $temptree + 1;
			}
			if ($temptree < 1) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			if ($temptree < $ntrees) {
				push(@temptrees, $temptree .. $ntrees);
			}
			elsif ($temptree == $ntrees) {
				push(@temptrees, $temptree);
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
		}
		elsif ($ARGV[$i] =~ /^(\-?\d+)$/) {
			my $temptree = $1;
			if ($temptree < 0) {
				$temptree = $ntrees + $temptree + 1;
			}
			if ($temptree < 1 || $temptree > $ntrees) {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
			}
			push(@temptrees, $temptree);
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is invalid option.");
		}
	}
	my %target;
	if (@temptrees) {
		foreach my $treeno (@temptrees) {
			$target{$treeno} = 1;
		}
	}
	else {
		&errorMessage(__LINE__, 'Tree specification is not valid.');
	}
	@target = sort({$a <=> $b} keys(%target));
	if ($target[0] < 1) {
		&errorMessage(__LINE__, 'Tree specification is not valid.');
	}
	if ($target[-1] > $ntrees) {
		&errorMessage(__LINE__, 'Tree specification is not valid.');
	}
	if ($converse) {
		my %converse;
		foreach my $treeno (1 .. $ntrees) {
			unless ($target{$treeno}) {
				$converse{$treeno} = 1;
			}
		}
		@target = sort({$a <=> $b} keys(%converse));
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
if ($format eq 'NEXUS') {
	print($filehandle "#NEXUS\n\nBegin Trees;\n");
}
foreach my $treeno (@target) {
	if ($format eq 'NEXUS') {
		print($filehandle "\t" . 'Tree tree_' . $treeno . ' = ');
	}
	print($filehandle $trees[$treeno - 1] . ";\n");
}
if ($format eq 'NEXUS') {
	print($filehandle "End;\n");
}
close($filehandle);

sub range2list {
	# Input: Site of range start, Site of range end, Skip number of sites
	# Output: List of sites which belong to the range
	my ($start, $end, $skip) = @_;
	my @num;
	if ($start != 0 && $skip != 0 && $start <= $end && $skip <= $end - $start) {
		for (my $i = $start; $i <= $end; $i += $skip) {
			push(@num, $i);
		}
	}
	else {
		&errorMessage(__LINE__, 'Number specification is not valid.');
	}
	return(@num);
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
pgsplicetree options inputfile outputfile

Command line options
====================
INTEGER
INTEGER-INTEGER (start-end)
INTEGER-. (start-last)
INTEGER-INTEGER\\INTEGER (start-end\\skip)
  Specify output numbers of trees.

-c, --converse
  If this option is specified, specified positions will be cut off and
nonspecified positions will be saved.

Acceptable input file formats
=============================
Newick
NEXUS
PHYLIP
_END
	exit;
}
