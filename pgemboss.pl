my $buildno = '2.0.x';
#
# pgemboss
# 
# Official web site of this script is
# https://www.fifthdimension.jp/products/phylogears/ .
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
pgemboss $buildno
=======================================================================

Official web site of this script is
https://www.fifthdimension.jp/products/phylogears/ .
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
my @argv;
# get output file name
my $command = $ARGV[0];
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
		&errorMessage(__LINE__, "\"$outputfile\" file already exists.");
}
if ($outputfile !~ /^stdout$/i) {
	$outputfile = "stdout >> $outputfile";
}
else {
	$outputfile = "stdout";
}
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
		&errorMessage(__LINE__, "\"$inputfile\" file does not exist.");
}
# get other options
for (my $i = 1; $i < scalar(@ARGV) - 2; $i ++) {
	push(@argv, $ARGV[$i]);
}
unless (@argv) {
		&errorMessage(__LINE__, "Options for EMBOSScommands are not specified.");
}
# begin read input file
unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
my $num = 1;
# make single sequence temporary file
unless (open(OUTFILE, "> $inputfile.$num.gbk")) {
		&errorMessage(__LINE__, "Cannot make temporary file \"$inputfile.$num.gbk\".");
}
while (<INFILE>) {
	if ($_ !~ /^\r?\n?$/) {
		print(OUTFILE);
	}
	if (/^\/\//) {
		close(OUTFILE);
		# extract to output file
		system(join(' ', $command, @argv) . " $inputfile.$num.gbk $outputfile");
		# delete temporary file
		unlink("$inputfile.$num.gbk");
		$num ++;
		# make next temporary file
		unless (open(OUTFILE, "> $inputfile.$num.gbk")) {
				&errorMessage(__LINE__, "Cannot make temporary file \"$inputfile.$num.gbk\".");
		}
	}
}
close(OUTFILE);
# delete temporary file
unlink("$inputfile.$num.gbk");

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
pgemboss EMBOSScommands options inputfile outputfile

Acceptable input file formats
=============================
GenBank
_END
	exit;
}
