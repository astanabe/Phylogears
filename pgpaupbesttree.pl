#!/usr/bin/perl
my $buildno = '2.0.2016.02.06';
#
# pgpaupbesttree
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
pgpaupbesttree $buildno
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
elsif (scalar(@ARGV) != 2) {
	&errorMessage(__LINE__, "Command line option is invalid.");
}
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
# search scores
unless (open(INTREE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
my %best;
{
	my $blockno = 0;
	my $bestscore;
	my $treesblock = 0;
	while (<INTREE>) {
		if ($treesblock == 0 && /^\s*Begin\s+Trees\s*;/i) {
			$treesblock = 1;
			$blockno ++;
		}
		elsif ($treesblock == 1 && /^\s*End\s*;/i) {
			$treesblock = 0;
		}
		elsif ($treesblock == 1 && /Score of best tree\(s\) found = (\d+(?:\.\d+)?)/) {
			if (!defined($bestscore) || $bestscore > $1) {
				$bestscore = $1;
				undef(%best);
			}
			if ($bestscore == $1) {
				$best{$blockno} = 1;
			}
		}
	}
}
close(INTREE);
# output best score trees
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
print($filehandle "#NEXUS\n\nBegin Trees;\n");
unless (open(INTREE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
{
	my $blockno = 0;
	my $treesblock = 0;
	while (<INTREE>) {
		if ($treesblock == 0 && /^\s*Begin\s+Trees\s*;/i) {
			$treesblock = 1;
			$blockno ++;
		}
		elsif ($treesblock == 1 && /^\s*End\s*;/i) {
			$treesblock = 0;
		}
		elsif ($treesblock == 1 && $best{$blockno}) {
			print($filehandle $_);
		}
	}
}
close(INTREE);
print($filehandle "End;\n");
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
pgpaupbesttree inputfile outputfile

Acceptable input file formats
=============================
NEXUS tree file
_END
	exit;
}
