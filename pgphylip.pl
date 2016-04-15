my $buildno = '2.0.x';
#
# pgphylip
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

print(<<"_END");
pgphylip $buildno
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

# initialize variables
use File::Spec;
my $devnull = File::Spec->devnull();
my $numthreads = 1;
my $nodel = 0;
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
my $commandfile = $ARGV[-1];
unless (-e $commandfile) {
	&errorMessage(__LINE__, "\"$commandfile\" does not exist.");
}
my $command = $ARGV[0];
my @outfiles;

# get command line options
for (my $i = 1; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:n|numthreads)=(\d+)$/i) {
		$numthreads = $1;
	}
	elsif ($ARGV[$i] =~ /^-+nodel$/i) {
		$nodel = 1;
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

# read command file
my $phylipcommand;
unless (open(CMD, "< $commandfile")) {
	&errorMessage(__LINE__, "Cannot open \"$commandfile\".");
}
while (<CMD>) {
	$phylipcommand .= $_;
	if (/\%OUTFILE\{([^\{\}]+)\}/) {
		push(@outfiles, $1);
	}
}
close(CMD);

# check output files
foreach my $outfile (@outfiles) {
	if (-e "$outfile") {
		&errorMessage(__LINE__, "\"$outfile\" already exists.");
	}
}

# read input file
unless (open(PHYLIP, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
my $nreps = 0;
while (<PHYLIP>) {
	if (/^\s*\d+\s*(?:\d+\s*)?\r?\n?$/i) {
		close(BOOT);
		$nreps ++;
		if (-e "$inputfile.rep$nreps") {
			&errorMessage(__LINE__, "\"$inputfile.rep$nreps\" already exists.");
		}
		unless (open(BOOT, "> $inputfile.rep$nreps")) {
			&errorMessage(__LINE__, "Cannot make \"$inputfile.rep$nreps\".");
		}
		print(BOOT $_);
	}
	else {
		print(BOOT);
	}
}
close(BOOT);
close(PHYLIP);

# make outfile and outtree
my $deloutfile;
if (!-e 'outfile') {
	unless (open(OUT, '> outfile')) {
		&errorMessage(__LINE__, 'Cannot make "outfile".');
	}
	close(OUT);
	$deloutfile = 1;
}
my $delouttree;
if (!-e 'outtree') {
	unless (open(OUT, '> outtree')) {
		&errorMessage(__LINE__, 'Cannot make "outtree".');
	}
	close(OUT);
	$delouttree = 1;
}

# make command files
foreach my $repno (1 .. $nreps) {
	if (-e "$inputfile.rep$repno.log") {
		&errorMessage(__LINE__, "\"$inputfile.rep$repno.log\" already exists.");
	}
	my $tempcommand = $phylipcommand;
	if ($command =~ /^neighbor/) {
		$tempcommand =~ s/\%DISTFILE/$inputfile.rep$repno/g;
	}
	else {
		$tempcommand =~ s/\%SEQFILE/$inputfile.rep$repno/g;
	}
	foreach my $outfile (@outfiles) {
		$tempcommand =~ s/\%OUTFILE\{\Q$outfile\E\}/$outfile.rep$repno/g;
	}
	unless (open(OUT, "> $inputfile.rep$repno.command")) {
		&errorMessage(__LINE__, "Cannot make \"$inputfile.rep$repno.command\".");
	}
	print(OUT $tempcommand);
	close(OUT);
}

# parallel processing by PHYLIP
{
	my $child = 0;
	$| = 1;
	$? = 0;
	foreach my $repno (1 .. $nreps) {
		if (my $pid = fork()) {
			$child ++;
			if ($child == $numthreads) {
				if (wait == -1) {
					$child = 0;
				} else {
					$child --;
				}
			}
			if ($?) {
				&errorMessage(__LINE__);
			}
			next;
		}
		else {
			print("processing replicate $repno...\n");
			system("$command < $inputfile.rep$repno.command 2> $devnull 1> $devnull");
			unless ($nodel) {
				unlink("$inputfile.rep$repno");
				unlink("$inputfile.rep$repno.command");
			}
			exit(0);
		}
	}
}

# join
while (wait != -1) {
	if ($?) {
		&errorMessage(__LINE__);
	}
}

# combine output files
foreach my $outfile (@outfiles) {
	if (-e "$outfile") {
		&errorMessage(__LINE__, "\"$outfile\" already exists.");
	}
	unless (open(OUTFILE, "> $outfile")) {
		&errorMessage(__LINE__, "Cannot make \"$outfile\".");
	}
	foreach my $repno (1 .. $nreps) {
		unless (open(INFILE, "< $outfile.rep$repno")) {
			&errorMessage(__LINE__, "Cannot open \"$outfile.rep$repno\".");
		}
		while (<INFILE>) {
			print(OUTFILE);
		}
		close(INFILE);
		unless ($nodel) {
			unlink("$outfile.rep$repno");
		}
	}
	close(OUTFILE);
}

# delete temporary files
if ($deloutfile) {
	unlink('outfile');
}
if ($delouttree) {
	unlink('outtree');
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
pgphylip PHYLIPcommand options inputfile commandfile

Command line options
====================
-n, --numthreads=INTEGER
  Specify the number of threads. (default: 1)

--nodel
  Specify to disable temporary files deletion. (default: off)

Acceptable input file formats
=============================
PHYLIP
(This script does not accept multiple data sets.)
_END
	exit;
}
