my $buildno = '2.0.x';
#
# pgtntboot
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
# display usage if command line options were not specified

use strict;
use File::Spec;

print(<<"_END");
pgtntboot $buildno
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

# initialize variables
my $numthreads = 1;
my $inputfile;
#my $constraintfile;
my $prefix;
my $nreps = 100;
my $niter = 10;
my $mode = 'Combine';
my $nummxram = 512;
my $numhold = 10000;

# display usage if command line options were not specified
unless (@ARGV) {
	my %nexus;
	while (glob("*.nex*")) {
		if (/^(.+\.(?:nex|nexus))$/i) {
			$nexus{$1} = 1;
		}
	}
	if (%nexus) {
		my $suffix1;
		my $suffix2;
		print("NEXUS files were found. Entering interactive mode...\n\n");
		my $loop = 1;
		while ($loop) {
			my $response;
			print("Which do you want to analyze? (name/number)\n");
			my $temp = 1;
			my %temp;
			foreach (sort(keys(%nexus))) {
				print("  $temp: $_\n");
				$temp{$temp} = $_;
				$temp ++;
			}
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			$response =~ s/^\s*(.+?)\s*$/$1/;
			if ($nexus{$response}) {
				$inputfile = $response;
				print("OK. \"$inputfile\" will be analyzed.\n\n");
				last;
			}
			elsif ($nexus{$temp{$response}}) {
				$inputfile = $temp{$response};
				print("OK. \"$inputfile\" will be analyzed.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		$prefix = $inputfile;
		$prefix =~ s/\.(?:nex|nexus)$//i;
		while ($loop) {
			my $response;
			print("How many replicates do you want to run? (integer)\n(default: 100)\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			unless ($response) { $response = 100; }
			if ($response =~ /^(\d+)$/) {
				if ($1 < 1) {
					&errorMessage(__LINE__, 'The number of replicates is not valid.');
				}
				else {
					$nreps = $1;
				}
				print("OK. The number of replicates is set to $1.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		while ($loop) {
			my $response;
			print("How many iterations per replicate do you want to run? (integer)\n(default: 10)\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			unless ($response) { $response = 10; }
			if ($response =~ /^(\d+)$/) {
				if ($1 < 1) {
					&errorMessage(__LINE__, 'The number of iterations is not valid.');
				}
				else {
					$niter = $1;
				}
				print("OK. The number of iterations is set to $1.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		#while ($loop) {
		#	my $response;
		#	print("If you want to give topological constraint, specify an input file name.\nOtherwise, just press enter.\n");
		#	$response = <STDIN>;
		#	$response =~ s/\r?\n?$//;
		#	$response =~ s/^\s*(.+?)\s*$/$1/;
		#	$response =~ s/^"(.+)"$/$1/;
		#	if ($response =~ /^\s*$/) {
		#		print("OK. No topological constraint will be used in tree search.\n\n");
		#		last;
		#	}
		#	elsif (-e $response) {
		#		$constraintfile = $response;
		#		$prefix .= '_' . $constraintfile;
		#		if ($constraintfile =~ /\.[^\.]+/) {
		#			$prefix =~ s/\.[^\.]+$//;
		#		}
		#		print("OK. Topological constraint in the specified file will be used in tree search.\n\n");
		#		last;
		#	}
		#	else {
		#		print("The specified file does not exist.\n\n");
		#	}
		#}
		while ($loop) {
			my $response;
			print("How many processes do you want to run simultaneously? (integer)\n(default: 1)\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			unless ($response) { $response = 1; }
			if ($response =~ /^\s*(\d+)\s*$/) {
				if ($1 == 0) {
					&errorMessage(__LINE__, 'The number of threads is not valid.');
				}
				else {
					$numthreads = $1;
				}
				print("OK. The number of processes is set to $1.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		if (-e "$prefix\_bootstrap.tre") {
			while ($loop) {
				my $response;
				print("The results of previous analysis already exists.\nWhich do you prefer, combine or replace?\n(default: combine)\n");
				$response = <STDIN>;
				$response =~ s/\r?\n?$//;
				if ($response =~ /^\s*combine\s*$/i || $response =~ /^\s*$/) {
					$mode = 'Combine';
					print("OK. The results will be combined.\n\n");
					last;
				}
				elsif ($response =~ /^\s*replace\s*$/i) {
					$mode = 'Replace';
					print("OK. The results will be replaced.\n\n");
					last;
				}
				else {
					print("Cannot understand your answer.\n\n");
				}
			}
		}
		while ($loop) {
			my $response;
			print("All configurations have been completed.\nJust press enter to run!\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			if ($response =~ /^\s*$/) {
				print("OK. Please wait a while.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
	}
	else {
		&helpMessage();
	}
}
if (!$inputfile && $ARGV[-2]) {
	$inputfile = $ARGV[-2];
}
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
unless ($prefix) {
	$prefix = $inputfile;
	$prefix =~ s/\.[^\.]+$//;
}
# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:n|numthreads)=(\d+)$/i) {
		$numthreads = $1;
	}
	elsif ($ARGV[$i] =~ /^-+prefix=(\S+)$/i) {
		$prefix = $1;
	}
	elsif ($ARGV[$i] =~ /^-+(?:r|nreps)=(\d+)$/i) {
		$nreps = $1;
	}
	elsif ($ARGV[$i] =~ /^-+(?:i|niter)=(\d+)$/i) {
		$niter = $1;
	}
	elsif ($ARGV[$i] =~ /^-+mxram=(\d+)$/i) {
		$nummxram = $1;
	}
	elsif ($ARGV[$i] =~ /^-+hold=(\d+)$/i) {
		$numhold = $1;
	}
	elsif ($ARGV[$i] =~ /^-+(?:m|mode)=(\S+)$/i) {
		if ($1 =~ /^Combine$/i) {
			$mode = 'Combine';
		}
		elsif ($1 =~ /^Replace$/i) {
			$mode = 'Replace';
		}
	}
	#elsif ($ARGV[$i] =~ /^-+(?:c|constraint)=(\S+)$/i) {
	#	$constraintfile = $1;
	#	unless (-e $constraintfile) {
	#		&errorMessage(__LINE__, "\"$constraintfile\" does not exist.");
	#	}
	#}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

# notice for MacOSX
if ($numthreads > 1 && $^O eq 'darwin') {
	errorMessage(__LINE__, "You specified to execute tnt in parallel. However, this command does not support parallel execution of TNT on MacOS X.");
}

#my $constraint;
#if ($constraintfile) {
#	$constraint = "";
#}
my $combine;
if ($mode eq 'Combine' && -e "$prefix\_bootstrap.tre") {
	$combine = 1;
}

&checkFiles();

# resample sequences
if (system("pgresampleseq --nreps=$nreps $inputfile $prefix\_bootstrap.nex")) {
	&errorMessage(__LINE__, "Cannot make \"$prefix\_bootstrap.nex\".");
}

# run bootstrap analysis
unless (open(TNT, "> $prefix\_singlesearch_for_bootstrap.tnt")) {
	&errorMessage(__LINE__, "Cannot make \"$prefix\_singlesearch_for_bootstrap.tnt\".");
}
print(TNT << "_END");
Procedure \%SEQFILE;
Nstates NOGAPS;
Collapse [;
Hold $numhold;
Mult = tbr replic $niter;
TaxName =;
Export - \%OUTFILE{$prefix\_bootstrap.tre};
Quit;
_END
close(TNT);
if ($combine) {
	unless (rename("$prefix\_bootstrap.tre", "$prefix\_bootstrap_previous.tre")) {
		&errorMessage(__LINE__, "Cannot rename \"$prefix\_bootstrap.tre\" to \"$prefix\_bootstrap_previous.tre\".");
	}
}
else {
	unlink("$prefix\_bootstrap.tre");
}
if (system("pgtnt --treewts --mxram=$nummxram --numthreads=$numthreads $prefix\_bootstrap.nex $prefix\_singlesearch_for_bootstrap.tnt")) {
	&errorMessage(__LINE__, 'Cannot run pgtnt.');
}
unlink("$prefix\_bootstrap.nex");
unlink("$prefix\_singlesearch_for_bootstrap.tnt");

# combine tree files
if ($combine) {
	unless (open(NEWTREE, "> $prefix\_bootstrap_new.tre")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_bootstrap_new.tre\".");
	}
	print(NEWTREE "#NEXUS\n\n");
	unless (open(TREE, "< $prefix\_bootstrap.tre")) {
		&errorMessage(__LINE__, "Cannot read \"$prefix\_bootstrap.tre\".");
	}
	my $lineno = 1;
	while (<TREE>) {
		if ($lineno > 2 && /^.+\r?\n?$/) {
			print(NEWTREE);
		}
		$lineno ++;
	}
	close(TREE);
	unless (open(TREE, "< $prefix\_bootstrap_previous.tre")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_bootstrap_previous.tre\".");
	}
	$lineno = 1;
	while (<TREE>) {
		if ($lineno > 2 && /^.+\r?\n?$/) {
			print(NEWTREE);
		}
		$lineno ++;
	}
	close(TREE);
	close(NEWTREE);
	unlink("$prefix\_bootstrap.tre");
	unlink("$prefix\_bootstrap_previous.tre");
	unless (rename("$prefix\_bootstrap_new.tre", "$prefix\_bootstrap.tre")) {
		&errorMessage(__LINE__, "Cannot rename \"$prefix\_bootstrap_new.tre\" to \"$prefix\_bootstrap.tre\".");
	}
}

# make summary
unlink("$prefix\_consensus.tre");
if (system("pgsumtree --mode=CONSENSE $prefix\_bootstrap.tre $prefix\_consensus.tre")) {
	&errorMessage(__LINE__, 'Cannot run pgsumtree.');
}
unlink("$prefix\_allhypotheses.tre");
if (system("pgsumtree --mode=ALL $prefix\_bootstrap.tre $prefix\_allhypotheses.tre")) {
	&errorMessage(__LINE__, 'Cannot run pgsumtree.');
}

# display message and exit
print("The bootstrap analysis has been finished.\n");

sub checkFiles {
	my $devnull = File::Spec->devnull();
	if (system("pgresampleseq 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgresampleseq. Please check pgresampleseq.");
	}
	if (system("pgtnt 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgtnt. Please check pgtnt.");
	}
	if (system("pgsumtree 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgsumtree. Please check pgsumtree.");
	}
	if (system("tnt \"Quit;\" 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgsumtree. Please check pgsumtree.");
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
pgtntboot options inputfile

Command line options
====================
-m, --mode=Combine|Replace
  Specify the behavior if the files of previous analysis already exist.
(default: Combine)

-n, --numthreads=INTEGER
  Specify the number of threads. (default: 1)

-r, --nreps=INTEGER
  Specify the number of replicates. (default: 100)

-i, --niter=INTEGER
  Specify the number of iterations per replicate. (default: 10)

--prefix=PREFIX
  Specify the prefix of the name of output files.
(default: inputfile)

--mxram=INTEGER
  Specify maximum size (megabytes) of memory allocation per process.
(default: 512)

--hold=INTEGER
  Specify maximum number of keeping trees. (default: 10000)

Acceptable input file formats
=============================
NEXUS
_END
	exit;
}
