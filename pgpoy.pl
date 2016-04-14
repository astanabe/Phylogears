my $buildno = '2.0.2016.02.06';
#
# pgpoy
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

print(<<"_END");
pgpoy $buildno
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
my $treefile;
my $poycommand;
my @trees;
my @outfiles;

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:n|numthreads)=(\d+)$/i) {
		$numthreads = $1;
	}
	elsif ($ARGV[$i] =~ /^-+nodel$/i) {
		$nodel = 1;
	}
	elsif ($ARGV[$i] =~ /^-+(?:t|treefile)=(.+)$/i) {
		if (-e $1) {
			$treefile = $1;
		}
		else {
			&errorMessage(__LINE__, "Specified tree file \"$1\" does not exist.");
		}
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

# read command file
unless (open(CMD, "< $commandfile")) {
	&errorMessage(__LINE__, "Cannot open \"$commandfile\".");
}
while (<CMD>) {
	$poycommand .= $_;
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

# read tree file
if ($treefile) {
	unless (open(NWK, "< $treefile")) {
		&errorMessage(__LINE__, "Cannot open \"$treefile\".");
	}
	{
		local $/ = ";";
		my $numtree;
		while (<NWK>) {
			if (/^([^;]+;)/s) {
				my $tree = $1;
				$tree =~ s/[\r\n]//g;
				$trees[$numtree] = $tree;
				$numtree ++;
			}
		}
	}
	close(NWK);
}

# read input file
my $nreps = 0;
my @datatype;
my $searchperrep;
{
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	{
		my $datablock = 0;
		while (<INFILE>) {
			if ($datablock == 0 && /^\s*(Begin\s+Data\s*;.*\r?\n?)$/i) {
				$datablock = 1;
				$nreps ++;
				if (-e "$inputfile.rep$nreps.nex") {
					&errorMessage(__LINE__, "\"$inputfile.rep$nreps.nex\" already exists.");
				}
				unless (open(OUTFILE, "> $inputfile.rep$nreps.nex")) {
					&errorMessage(__LINE__, "Cannot make \"$inputfile.rep$nreps.nex\".");
				}
				print(OUTFILE "#NEXUS\n\n" . $1);
			}
			elsif ($datablock == 1 && /^(\s*End\s*;)/i) {
				print(OUTFILE $1 . "\n");
				close(OUTFILE);
				$datablock = 0;
			}
			elsif ($datablock == 1 && /DataType=Protein/i) {
				$datatype[$nreps - 1] = 1;
				print(OUTFILE);
			}
			elsif ($datablock == 1 && /DataType=DNA/i) {
				$datatype[$nreps - 1] = 0;
				print(OUTFILE);
			}
			elsif ($datablock == 1) {
				print(OUTFILE);
			}
		}
	}
	close(INFILE);
	my $datanum = $nreps;
	unless (@trees) {
		$searchperrep = 1;
	}
	elsif (scalar(@trees) % $datanum == 0) {
		$searchperrep = scalar(@trees) / $datanum;
		$nreps = scalar(@trees);
	}
	else {
		&errorMessage(__LINE__, 'Starting tree is not enough.');
	}
	foreach my $repno (1 .. $nreps) {
		my $datano;
		unless (@trees) {
			$datano = $repno;
		}
		else {
			$datano = int(($repno - 1) / $searchperrep) + 1;
		}
		if (@trees) {
			if (-e "$inputfile.rep$repno.nwk") {
				&errorMessage(__LINE__, "\"$inputfile.rep$repno.nwk\" already exists.");
			}
			unless (open(REP, "> $inputfile.rep$repno.nwk")) {
				&errorMessage(__LINE__, "Cannot make \"$inputfile.rep$repno.nwk\".");
			}
			print(REP $trees[$repno - 1] . "\n");
			close(REP);
		}
		my $tempcommand = $poycommand;
		if ($datatype[$datano - 1]) {
			$tempcommand =~ s/"\%SEQFILE"/aminoacids: ("$inputfile.rep$datano.fas")/g;
		}
		$tempcommand =~ s/\%SEQFILE/$inputfile.rep$datano.fas/g;
		$tempcommand =~ s/\%STARTTREE/$inputfile.rep$repno.nwk/g;
		foreach my $outfile (@outfiles) {
			if (-e "$outfile.rep$repno") {
				&errorMessage(__LINE__, "\"$outfile.rep$repno\" already exists.");
			}
			$tempcommand =~ s/\%OUTFILE\{\Q$outfile\E\}/$outfile.rep$repno/g;
		}
		if (-e "$inputfile.rep$repno.poy") {
			&errorMessage(__LINE__, "\"$inputfile.rep$repno.poy\" already exists.");
		}
		unless (open(REP, "> $inputfile.rep$repno.poy")) {
			&errorMessage(__LINE__, "Cannot make \"$inputfile.rep$repno.poy\".");
		}
		print(REP $tempcommand);
		close(REP);
	}
}

# parallel processing by POY
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
			system("pgconvseq --output=FASTA $inputfile.rep$repno.nex $inputfile.rep$repno.fas 2> $devnull 1> $devnull");
			system("seq_poy $inputfile.rep$repno.poy 2> $devnull 1> $devnull");
			unless ($nodel) {
				unlink("$inputfile.rep$repno.nex");
				unlink("$inputfile.rep$repno.poy");
				unlink("$inputfile.rep$repno.nwk");
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

unless ($nodel) {
	foreach my $repno (1 .. ($nreps / $searchperrep)) {
		unlink("$inputfile.rep$repno.fas");
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
pgpoy options inputfile commandfile

Command line options
====================
-n, --numthreads=INTEGER
  Specify the number of threads. (default: 1)

-t, --treefile=FILENAME
  Specify the name of the file containing starting trees.
(default: none)

--nodel
  Specify to disable temporary files deletion. (default: off)

Acceptable input file formats
=============================
NEXUS

Acceptable command file formats
===============================
POY

Acceptable tree file formats
===============================
Newick
PHYLIP
_END
	exit;
}
