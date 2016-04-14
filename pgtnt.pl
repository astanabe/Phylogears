my $buildno = '2.0.2016.04.14';
#
# pgtnt
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
pgtnt $buildno
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
my $treewts;
my $nummxram = 512;
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
my $tntcommand;
my @trees;
my @outfiles;

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:n|numthreads)=(\d+)$/i) {
		$numthreads = $1;
	}
	elsif ($ARGV[$i] =~ /^-+treewts$/i) {
		$treewts = 1;
	}
	elsif ($ARGV[$i] =~ /^-+mxram=(\d+)$/i) {
		$nummxram = $1;
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

# notice for MacOSX
if ($numthreads > 1 && $^O eq 'darwin') {
	errorMessage(__LINE__, "You specified to execute tnt in parallel. However, this command does not support parallel execution of TNT on MacOS X.");
}

# read command file
unless (open(NEXUS, "< $commandfile")) {
	&errorMessage(__LINE__, "Cannot open \"$commandfile\".");
}
while (<NEXUS>) {
	$tntcommand .= $_;
	if (/\%OUTFILE\{([^\{\}]+)\}/) {
		push(@outfiles, $1);
	}
}
close(NEXUS);

# check output files
foreach my $outfile (@outfiles) {
	if (-e "$outfile") {
		&errorMessage(__LINE__, "\"$outfile\" already exists.");
	}
}

# read tree file
if ($treefile) {
	unless (open(NEXUS, "< $treefile")) {
		&errorMessage(__LINE__, "Cannot open \"$treefile\".");
	}
	{
		my $treesblock = 0;
		while (<NEXUS>) {
			if ($treesblock == 0 && /^\s*(Begin\s+Trees\s*;.*\r?\n?)$/i) {
				$treesblock = 1;
			}
			elsif ($treesblock == 1 && /^(\s*End\s*;)/i) {
				$treesblock = 0;
			}
			elsif ($treesblock == 1 && /\s*Tree\s+\S+\s*=\s*(\[[^\[\]]+\]\s*)?(\(.+\))(?:\:0|\:0\.0)?;/i) {
				my $treeopt = $1;
				my $tree = $2;
				unless ($treeopt) {
					$treeopt = '[&U] ';
				}
				push(@trees, $treeopt . $tree);
			}
		}
	}
	close(NEXUS);
}

# read input file
my $nreps = 0;
my $searchperrep;
{
	my $datanum = 0;
	my $tntnum = 0;
	my $datablock = 0;
	my $tntblock = 0;
	my @datablock;
	my @tntblock;
	{
		my $tntnum = 0;
		my $datablock = 0;
		my $tntblock = 0;
		my @datablock;
		my @tntblock;
		unless (open(INFILE, "< $inputfile")) {
			&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
		}
		while (<INFILE>) {
			if ($datablock == 0 && $tntblock == 0 && /^\s*(Begin\s+Data\s*;.*\r?\n?)$/i) {
				$datablock = 1;
				$datablock[$datanum] = $1;
			}
			elsif ($datablock == 0 && $tntblock == 0 && /^\s*(Begin\s+TNT\s*;.*\r?\n?)$/i) {
				$tntblock = 1;
				$tntblock[$tntnum] = $1;
			}
			elsif ($datablock == 1 && /^(\s*End\s*;)/i) {
				$datablock[$datanum] .= $1 . "\n";
				$datablock = 0;
				$datanum ++;
			}
			elsif ($tntblock == 1 && /^(\s*End\s*;)/i) {
				$tntblock[$tntnum] .= $1 . "\n";
				$tntblock = 0;
				$tntnum ++;
			}
			elsif ($datablock == 1) {
				$datablock[$datanum] .= $_;
			}
			elsif ($tntblock == 1) {
				$tntblock[$tntnum] .= $_;
			}
		}
		close(INFILE);
		if ($tntnum && $tntnum != $datanum) {
			&errorMessage(__LINE__, 'TNT block is not valid.');
		}
		for (my $i = 0; $i < $datanum; $i ++) {
			my $repno = $i + 1;
			if (-e "$inputfile.rep$repno.nex") {
				&errorMessage(__LINE__, "\"$inputfile.rep$repno.nex\" already exists.");
			}
			unless (open(REP, "> $inputfile.rep$repno.nex")) {
				&errorMessage(__LINE__, "Cannot make \"$inputfile.rep$repno.nex\".");
			}
			print(REP "#NEXUS\n\n" . $datablock[$i]);
			if ($tntnum == $datanum) {
				print(REP $tntblock[$i]);
			}
			close(REP);
		}
	}
	unless (@trees) {
		$searchperrep = 1;
		$nreps = $datanum;
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
			if (-e "$inputfile.rep$repno.tre") {
				&errorMessage(__LINE__, "\"$inputfile.rep$repno.tre\" already exists.");
			}
			unless (open(REP, "> $inputfile.rep$repno.tre")) {
				&errorMessage(__LINE__, "Cannot make \"$inputfile.rep$repno.tre\".");
			}
			print(REP "#NEXUS\n\nBegin Trees;\n\tTree tree_$repno = " . $trees[$repno - 1] . ";\nEnd;\n");
			close(REP);
		}
		my $tempcommand = $tntcommand;
		$tempcommand =~ s/\%SEQFILE/..\/$inputfile.rep$datano.nex/g;
		$tempcommand =~ s/\%STARTTREE/..\/$inputfile.rep$repno.tre/g;
		foreach my $outfile (@outfiles) {
			if (-e "$outfile.rep$repno") {
				&errorMessage(__LINE__, "\"$outfile.rep$repno\" already exists.");
			}
			$tempcommand =~ s/\%OUTFILE\{\Q$outfile\E\}/$outfile.rep$repno/g;
		}
		if (-e "$inputfile.rep$repno.tnt") {
			&errorMessage(__LINE__, "\"$inputfile.rep$repno.tnt\" already exists.");
		}
		if ($tempcommand =~ /(?:Force|Outgroup)/i) {
			my $datablock = 0;
			my $matrix = 0;
			my $seqno = 0;
			my %taxa;
			unless (open(NEX, "< $inputfile.rep$datano.nex")) {
				&errorMessage(__LINE__, "Cannot open \"$inputfile.rep$datano.nex\".");
			}
			while (<NEX>) {
				if ($datablock == 0 && /^\s*Begin\s+Data\s*;/i) {
					$datablock = 1;
				}
				elsif ($datablock == 1 && /^(\s*End\s*;)/i) {
					$datablock = 0;
				}
				elsif ($datablock == 1 && $matrix == 1 && /;/) {
					$matrix = 0;
				}
				elsif ($datablock == 1 && $matrix == 1) {
					if (/^\s*(\S+)\s+\S.*?\s*\r?\n?$/) {
						my $taxon = $1;
						unless (defined($taxa{$taxon})) {
							$taxa{$taxon} = $seqno;
							$seqno ++;
						}
					}
				}
				elsif ($datablock == 1 && $matrix == 0 && /^\s*Matrix/i) {
					$matrix = 1;
				}
			}
			close(NEX);
			foreach my $taxon (sort({$b cmp $a} keys(%taxa))) {
				$tempcommand =~ s/(Force|Outgroup)([^;]*)$taxon([^;]*;)/$1$2$taxa{$taxon}$3/g;
			}
		}
		unless (open(REP, "> $inputfile.rep$repno.tnt")) {
			&errorMessage(__LINE__, "Cannot make \"$inputfile.rep$repno.tnt\".");
		}
		print(REP $tempcommand);
		close(REP);
	}
}

# parallel processing by TNT
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
			unless (mkdir("tnt$repno")) {
				&errorMessage(__LINE__, "Cannot make temporary directory \"tnt$repno\".");
			}
			unless (chdir("tnt$repno")) {
				&errorMessage(__LINE__, "Cannot change directory to \"tnt$repno\".");
			}
			system("tnt \"Mxram $nummxram; Procedure ../$inputfile.rep$repno.tnt;\" 2> $devnull 1> $devnull");
			foreach my $outfile (@outfiles) {
				unless (rename("$outfile.rep$repno", "../$outfile.rep$repno")) {
					&errorMessage(__LINE__, "Cannot move \"$outfile.rep$repno\".");
				}
			}
			unless (chdir('..')) {
				&errorMessage(__LINE__, "Cannot change directory.");
			}
			unless (rmdir("tnt$repno")) {
				&errorMessage(__LINE__, "Cannot remove temporary directory \"tnt$repno\".");
			}
			unless ($nodel) {
				unlink("$inputfile.rep$repno.tnt");
				unlink("$inputfile.rep$repno.tre");
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
		unlink("$inputfile.rep$repno.nex");
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
		if ($repno != $nreps) {
			print(OUTFILE "\n");
		}
		unless ($nodel) {
			unlink("$outfile.rep$repno");
		}
	}
	close(OUTFILE);
}
foreach my $outfile (@outfiles) {
	unless (open(INFILE, "< $outfile")) {
		&errorMessage(__LINE__, "Cannot open \"$outfile\".");
	}
	my $treesnum = 0;
	my $treesblock = 0;
	my @treesblock;
	while (<INFILE>) {
		if ($treesblock == 0 && /^\s*Begin\s+Trees\s*;/i) {
			$treesblock = 1;
		}
		elsif ($treesblock == 1 && /^\s*End\s*;/i) {
			$treesblock = 0;
			$treesnum ++;
		}
		elsif ($treesblock == 1) {
			$treesblock[$treesnum] .= $_;
		}
	}
	close(INFILE);
	if (@treesblock) {
		for (my $i = 0; $i < scalar(@treesblock); $i ++) {
			$treesblock[$i] =~ s/[\r\n]//g;
			my $numtree = $treesblock[$i] =~ s/;/;\n/g;
			if ($treewts && $numtree > 1) {
				$treesblock[$i] =~ s/\s*Tree\s+\S+\s*=/$& [&W 1\/$numtree]/ig;
			}
		}
		unless (@trees) {
			unless (open(OUTFILE, "> $outfile")) {
				&errorMessage(__LINE__, "Cannot make \"$outfile\".");
			}
			print(OUTFILE "#NEXUS\n\n");
			foreach my $treesblock (@treesblock) {
				print(OUTFILE "Begin Trees;\n$treesblock" . "End;\n");
			}
			close(OUTFILE);
		}
		else {
			unless (open(OUTFILE, "> $outfile")) {
				&errorMessage(__LINE__, "Cannot make \"$outfile\".");
			}
			print(OUTFILE "#NEXUS\n");
			for (my $i = 0; $i < scalar(@treesblock); $i ++) {
				if ($i % $searchperrep == 0) {
					print(OUTFILE "\nBegin Trees;\n");
				}
				print(OUTFILE "$treesblock[$i]");
				if ($i % $searchperrep == $searchperrep - 1) {
					print(OUTFILE "End;\n");
				}
			}
			close(OUTFILE);
		}
	}
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
pgtnt options inputfile commandfile

Command line options
====================
-n, --numthreads=INTEGER
  Specify the number of threads. (default: 1)

-t, --treefile=FILENAME
  Specify the name of the file containing starting trees.
(default: none)

--treewts
  If this option is specified, tree weights will be saved to tree file.

--mxram=INTEGER
  Specify maximum size (megabytes) of memory allocation per process.
(default: 512)

--nodel
  Specify to disable temporary files deletion. (default: off)

Acceptable input file formats
=============================
NEXUS

Acceptable command file formats
===============================
NEXUS or plain text

Acceptable tree file formats
===============================
NEXUS
_END
	exit;
}
