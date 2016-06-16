my $buildno = '2.0.x';
#
# pgtfboot
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
# display usage if command line options were not specified

use strict;
use File::Spec;

print(<<"_END");
pgtfboot $buildno
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

# initialize variables
my $numthreads = 1;
my $inputfile;
my $modelfile;
my $ratesfile;
my $constraintfile;
my $prefix;
my $nreps = 100;
my $treefile;
my $mode = 'Combine';

# display usage if command line options were not specified
unless (@ARGV) {
	my %suffix2;
	while (glob("*.model")) {
		if (/^(.+)_(?:AIC|AICc[1-6]|BIC[1-6])_(.+)\.model$/) {
			my $partname = $1;
			my $suffix2 = $2;
			if (-e $partname . '_' . $suffix2 . '.tf') {
				$suffix2{$partname}{$suffix2} = 1;
			}
		}
	}
	if (%suffix2) {
		my $partname;
		my $suffix1;
		my $suffix2;
		my $criterion;
		print("Model and TF files were found. Entering interactive mode...\n\n");
		my $loop = 1;
		while ($loop) {
			my $response;
			print("Which do you want to analyze? (name/number)\n");
			my $temp = 1;
			my %temp;
			foreach (sort(keys(%suffix2))) {
				print("  $temp: $_\n");
				$temp{$temp} = $_;
				$temp ++;
			}
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			$response =~ s/^\s*(.+?)\s*$/$1/;
			if ($suffix2{$response}) {
				$partname = $response;
				print("OK. \"$partname\" will be analyzed.\n\n");
				last;
			}
			elsif ($suffix2{$temp{$response}}) {
				$partname = $temp{$response};
				print("OK. \"$partname\" will be analyzed.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		while ($loop) {
			my $response;
			print("Which model do you want to apply to the data? (name/number)\n");
			my $temp = 1;
			my %temp;
			my %temp2;
			foreach (sort(keys(%{$suffix2{$partname}}))) {
				if (/^partitioned_codonpartitioned$/) {
					print("  $temp: proportional_codonproportional\n");
					$temp{$temp} = 'proportional_codonproportional';
					$temp2{'proportional_codonproportional'} = $_;
					$temp ++;
					print("  $temp: separate_codonproportional\n");
					$temp{$temp} = 'separate_codonproportional';
					$temp2{'separate_codonproportional'} = $_;
					$temp ++;
					print("  $temp: separate_codonseparate\n");
					$temp{$temp} = 'separate_codonseparate';
					$temp2{'separate_codonseparate'} = $_;
					$temp ++;
				}
				elsif (/^partitioned$/) {
					print("  $temp: proportional\n");
					$temp{$temp} = 'proportional';
					$temp2{'proportional'} = $_;
					$temp ++;
					print("  $temp: separate\n");
					$temp{$temp} = 'separate';
					$temp2{'separate'} = $_;
					$temp ++;
				}
				elsif (/^codonpartitioned$/) {
					print("  $temp: codonproportional\n");
					$temp{$temp} = 'codonproportional';
					$temp2{'codonproportional'} = $_;
					$temp ++;
					print("  $temp: codonseparate\n");
					$temp{$temp} = 'codonseparate';
					$temp2{'codonseparate'} = $_;
					$temp ++;
				}
				elsif (/^partitioned_codonnonpartitioned$/) {
					print("  $temp: proportional_codonnonpartitioned\n");
					$temp{$temp} = 'proportional_codonnonpartitioned';
					$temp2{'proportional_codonnonpartitioned'} = $_;
					$temp ++;
					print("  $temp: separate_codonnonpartitioned\n");
					$temp{$temp} = 'separate_codonnonpartitioned';
					$temp2{'separate_codonnonpartitioned'} = $_;
					$temp ++;
				}
				else {
					print("  $temp: $_\n");
					$temp{$temp} = $_;
					$temp2{$_} = $_;
					$temp ++;
				}
			}
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			$response =~ s/^\s*(.+?)\s*$/$1/;
			if ($temp2{$response}) {
				$suffix1 = $response;
				$suffix2 = $temp2{$response};
				print("OK. \"$suffix1\" model will be applied.\n\n");
				last;
			}
			elsif ($temp{$response}) {
				$suffix1 = $temp{$response};
				$suffix2 = $temp2{$temp{$response}};
				print("OK. \"$suffix1\" model will be applied.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		while ($loop) {
			my $response;
			print("Which criterion do you want to use? (name/number)\n");
			my $temp = 1;
			my %temp;
			my %temp2;
			while (glob("$partname\_*\_$suffix2.model")) {
				if (/^$partname\_(AIC|AICc[1-6]|BIC[1-6])\_$suffix2\.model$/) {
					print("  $temp: $1\n");
					$temp{$temp} = $1;
					$temp2{$1} = 1;
					$temp ++;
				}
			}
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			$response =~ s/^\s*(.+?)\s*$/$1/;
			if ($temp2{$response}) {
				$criterion = $response;
				print("OK. The models selected by $criterion will be applied.\n\n");
				last;
			}
			elsif ($temp{$response}) {
				$criterion = $temp{$response};
				print("OK. The models selected by $criterion will be applied.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		$inputfile = $partname . '_' . $suffix2 . '.tf';
		$prefix = $partname . '_' . $criterion . '_' . $suffix1;
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
			print("If you want to give topological constraint, specify an input file name.\nOtherwise, just press enter.\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			$response =~ s/^\s*(.+?)\s*$/$1/;
			$response =~ s/^"(.+)"$/$1/;
			if ($response =~ /^\s*$/) {
				print("OK. No topological constraint will be used in tree search.\n\n");
				last;
			}
			elsif (-e $response) {
				$constraintfile = $response;
				$prefix .= '_' . $constraintfile;
				if ($constraintfile =~ /\.[^\.]+/) {
					$prefix =~ s/\.[^\.]+$//;
				}
				print("OK. Topological constraint in the specified file will be used in tree search.\n\n");
				last;
			}
			else {
				print("The specified file does not exist.\n\n");
			}
		}
		while ($loop) {
			my $response;
			print("Which do you want to use as starting tree? (RAWML/NJ/FILENAME)\n(default: RAWML)\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			if ($response =~ /^\s*RAWML\s*$/i || $response =~ /^\s*$/) {
				if (-e "$prefix\_optimum.nwk") {
					$treefile = "$prefix\_optimum.nwk";
				}
				else {
					&errorMessage(__LINE__, 'The ML tree does not exist.');
				}
				print("OK. The RAWML tree will be used as starting tree.\n\n");
				last;
			}
			elsif ($response =~ /^\s*NJ\s*$/i) {
				print("OK. The NJ tree will be used as starting tree.\n\n");
				last;
			}
			elsif ($response =~ /^\s*(\S+)\s*$/) {
				if (-e $1) {
					$treefile = $1;
					print("OK. The tree which is contained in the specified file will be used as starting tree.\n\n");
					last;
				}
				else {
					print("The specified file does not exist.\n\n");
				}
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		while ($loop) {
			my $response;
			print("Which value do you want to use to the parameters? (RAWML/OPTIMIZE/FILENAME)\n(default: RAWML)\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			if ($response =~ /^\s*RAWML\s*$/i || $response =~ /^\s*$/) {
				if (-e "$prefix\_optimum.model") {
					$modelfile = "$prefix\_optimum.model";
					if ($suffix1 ne 'codonnonpartitioned' && $suffix1 ne 'nonpartitioned') {
						if (-e "$prefix\_optimum.rates") {
							$ratesfile = "$prefix\_optimum.rates";
						}
						else {
							&errorMessage(__LINE__, 'The RAWML model does not exist.');
						}
					}
				}
				else {
					&errorMessage(__LINE__, 'The RAWML model does not exist.');
				}
				print("OK. The parameters will be fixed to RAWML model.\n\n");
				last;
			}
			elsif ($response =~ /^\s*OPTIMIZE\s*$/i) {
				if (-e "$partname\_$criterion\_$suffix2.model") {
					$modelfile = "$partname\_$criterion\_$suffix2.model";
					if ($suffix1 ne 'codonnonpartitioned' && $suffix1 ne 'nonpartitioned') {
						if (-e "$prefix.rates") {
							$ratesfile = "$prefix.rates";
						}
						else {
							&errorMessage(__LINE__, 'The OPTIMIZE model does not exist.');
						}
					}
				}
				else {
					&errorMessage(__LINE__, 'The OPTIMIZE model does not exist.');
				}
				print("OK. The parameters will be optimized in all replicates.\n\n");
				last;
			}
			elsif ($response =~ /^\s*(\S+)\s*$/) {
				if (-e $1) {
					$modelfile = $1;
					print("OK. The model which is contained in the specified file will be used.\n\n");
					if ($suffix1 ne 'codonnonpartitioned' && $suffix1 ne 'nonpartitioned') {
						my $response2;
						print("This model requires rates file.\nSpecify a rates file to apply.\n");
						$response2 = <STDIN>;
						$response2 =~ s/\r?\n?$//;
						$response2 =~ s/^\s*(\S+)\s*$/$1/;
						if (-e $response2) {
							$ratesfile = $response2;
							last;
						}
						else {
							&errorMessage(__LINE__, 'The specified rates file does not exist.');
						}
					}
					last;
				}
				else {
					print("The specified file does not exist.\n\n");
				}
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
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
		if (-e "$prefix\_bootstrap.log") {
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
if (!$modelfile && $ARGV[-1]) {
	$modelfile = $ARGV[-1];
}
unless (-e $modelfile) {
	&errorMessage(__LINE__, "\"$modelfile\" does not exist.");
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
	elsif ($ARGV[$i] =~ /^-+(?:m|mode)=(\S+)$/i) {
		if ($1 =~ /^Combine$/i) {
			$mode = 'Combine';
		}
		elsif ($1 =~ /^Replace$/i) {
			$mode = 'Replace';
		}
	}
	elsif ($ARGV[$i] =~ /^-+ratesfile=(\S+)$/i) {
		$ratesfile = $1;
		unless (-e $ratesfile) {
			&errorMessage(__LINE__, "\"$ratesfile\" does not exist.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:c|constraint)=(\S+)$/i) {
		$constraintfile = $1;
		unless (-e $constraintfile) {
			&errorMessage(__LINE__, "\"$constraintfile\" does not exist.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:t|treefile)=(\S+)$/i) {
		$treefile = $1;
		unless (-e $treefile) {
			&errorMessage(__LINE__, "\"$treefile\" does not exist.");
		}
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

my $constraint;
if ($constraintfile) {
	$constraint = "\tTree->\"$constraintfile\",\n\tResolveMultifurcations->True,\n";
}
my $rates;
if ($ratesfile) {
	$rates = "\tPartitionRates->Load[\n\t\t\"$ratesfile\"\n\t],\n";
}
my $starttrees;
if ($treefile) {
	$starttrees = "\tStartTrees->\"$treefile\",\n";
}
my $combine;
if ($mode eq 'Combine' && -e "$prefix\_bootstrap.log") {
	$combine = 1;
}

&checkFiles();

# resample sequences
if (system("pgresampleseq --nreps=$nreps $inputfile $prefix\_bootstrap.tf")) {
	&errorMessage(__LINE__, "Cannot make \"$prefix\_bootstrap.tf\".");
}

# run bootstrap analysis
unless (open(TL, "> $prefix\_singlesearch_for_bootstrap.tl")) {
	&errorMessage(__LINE__, "Cannot make \"$prefix\_singlesearch_for_bootstrap.tl\".");
}
print(TL << "_END");
report:=ReconstructPhylogeny[
	\"\%SEQFILE\",
	SubstitutionModel->Load[
		\"$modelfile\"
	],
$rates$constraint$starttrees	WithEdgeSupport->False,
	SearchDepth->2,
	Verbose->False,
	AcceptFlatness->True
],
Oprec[
	20,
	SaveReport[
		AsReport[
			report
		],
		\"\%OUTFILE{$prefix\_bootstrap.log}\"
	]
]
_END
close(TL);
if ($combine) {
	unless (rename("$prefix\_bootstrap.log", "$prefix\_bootstrap_previous.log")) {
		&errorMessage(__LINE__, "Cannot rename \"$prefix\_bootstrap.log\" to \"$prefix\_bootstrap_previous.log\".");
	}
}
else {
	unlink("$prefix\_bootstrap.log");
}
if (system("pgtf --numthreads=$numthreads $prefix\_bootstrap.tf $prefix\_singlesearch_for_bootstrap.tl")) {
	&errorMessage(__LINE__, 'Cannot run pgtf.');
}
unlink("$prefix\_bootstrap.tf");
unlink("$prefix\_singlesearch_for_bootstrap.tl");

# combine log files
if ($combine) {
	unless (open(NEWLOG, "> $prefix\_bootstrap_new.log")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_bootstrap_new.log\".");
	}
	print(NEWLOG "{\n");
	unless (open(LOG, "< $prefix\_bootstrap.log")) {
		&errorMessage(__LINE__, "Cannot read \"$prefix\_bootstrap.log\".");
	}
	while (<LOG>) {
		if (/^ \{Likelihood->/) {
			print(NEWLOG);
		}
	}
	close(LOG);
	unless (open(LOG, "< $prefix\_bootstrap_previous.log")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_bootstrap_previous.log\".");
	}
	while (<LOG>) {
		if (/^ \{Likelihood->/) {
			print(NEWLOG);
		}
	}
	close(LOG);
	print(NEWLOG " ()\n}\n");
	close(NEWLOG);
	unlink("$prefix\_bootstrap.log");
	unlink("$prefix\_bootstrap_previous.log");
	unless (rename("$prefix\_bootstrap_new.log", "$prefix\_bootstrap.log")) {
		&errorMessage(__LINE__, "Cannot rename \"$prefix\_bootstrap_new.log\" to \"$prefix\_bootstrap.log\".");
	}
}

# make summary
unless (open(TL, "> $prefix\_convert_log_to_tree.tl")) {
	&errorMessage(__LINE__, "Cannot make \"$prefix\_convert_log_to_tree.tl\".");
}
print(TL << "_END");
boottreelist:=LoadReport[
	\"$prefix\_bootstrap.log\"
],
Oprec[
	20,
	SaveTreeList[
		AsTreeList[
			boottreelist
		],
		\"$prefix\_bootstrap.nwk\",
		Format->\"NEWICK\"
	],
]
_END
close(TL);
unlink("$prefix\_bootstrap.nwk");
if (system("tf $prefix\_convert_log_to_tree.tl")) {
	&errorMessage(__LINE__, 'Cannot run tf.');
}
unlink("$prefix\_convert_log_to_tree.tl");
unlink("$prefix\_consensus.nwk");
if (system("pgsumtree --mode=CONSENSE $prefix\_bootstrap.nwk $prefix\_consensus.nwk")) {
	&errorMessage(__LINE__, 'Cannot run pgsumtree.');
}
unlink("$prefix\_allhypotheses.nwk");
if (system("pgsumtree --mode=ALL $prefix\_bootstrap.nwk $prefix\_allhypotheses.nwk")) {
	&errorMessage(__LINE__, 'Cannot run pgsumtree.');
}
if (-e "$prefix\_optimum.nwk") {
	unlink("$prefix\_optimum_with_supportvalues.nwk");
	if (system("pgsumtree --mode=MAP --treefile=$prefix\_optimum.nwk $prefix\_bootstrap.nwk $prefix\_optimum_with_supportvalues.nwk")) {
		&errorMessage(__LINE__, 'Cannot run pgsumtree.');
	}
}

# display message and exit
print("The bootstrap analysis has been finished.\n");

sub checkFiles {
	my $devnull = File::Spec->devnull();
	unless (open(CMD, '> quit.tl')) {
		&errorMessage(__LINE__, 'Cannot make file.');
	}
	print(CMD "Quit\n");
	close(CMD);
	if (system("tf quit.tl 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run tf. Please check tf.");
	}
	unlink('quit.tl');
	if (system("pgresampleseq 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgresampleseq. Please check pgresampleseq.");
	}
	if (system("pgtf 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgtf. Please check pgtf.");
	}
	if (system("pgsumtree 2> " . $devnull . ' 1> ' . $devnull)) {
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
pgtfboot options inputfile modelfile

Command line options
====================
-m, --mode=Combine|Replace
  Specify the behavior if the files of previous analysis already exist.
(default: Combine)

-n, --numthreads=INTEGER
  Specify the number of threads. (default: 1)

-r, --nreps=INTEGER
  Specify the number of replicates. (default: 100)

-t, --treefile=FILENAME
  Specify the tree file name of starting tree. (default: none)

-c, --constraint=FILENAME
  Specify the tree file name of topological constraint. (default: none)

--ratesfile=RATESFILE
  Specify the rates file for Treefinder (default: none)

--prefix=PREFIX
  Specify the prefix of the name of output files.
(default: inputfile)

Acceptable input file formats
=============================
TF (Treefinder)

Acceptable model file formats
=============================
TF (Treefinder)

Acceptable rates file formats
=============================
TF (Treefinder)

Acceptable tree file formats
============================
Newick
NEXUS
PHYLIP
_END
	exit;
}
