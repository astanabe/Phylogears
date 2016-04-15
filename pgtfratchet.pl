my $buildno = '2.0.x';
#
# pgtfratchet
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
# display usage if command line options were not specified

use strict;
use File::Spec;

print(<<"_END");
pgtfratchet $buildno
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

# initialize variables
my $numthreads = 1;
my $inputfile;
my $modelfile;
my $ratesfile;
my $constraintfile;
my $prefix;
my $nreps = 100;
my $percent = 25;
my $startmaker = 'TNT';
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
		$modelfile = $partname . '_' . $criterion . '_' . $suffix2 . '.model';
		$prefix = $partname . '_' . $criterion . '_' . $suffix1;
		if ($suffix1 ne 'codonnonpartitioned' && $suffix1 ne 'nonpartitioned') {
			$ratesfile = $prefix . '.rates';
			unless (-e $ratesfile) {
				&errorMessage(__LINE__, "\"$ratesfile\" does not exist.");
			}
		}
		while ($loop) {
			my $response;
			print("Which do you want to use the program for generation of starting trees? (paup/poy/tf/tnt)\n(default: poy)\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			if ($response =~ /^\s*tnt\s*$/i || $response =~ /^\s*$/) {
				$startmaker = 'TNT';
				print("OK. The starting trees will be made by random sequence addition of TNT.\n\n");
				last;
			}
			elsif ($response =~ /^\s*poy\s*$/i) {
				$startmaker = 'POY';
				print("OK. The starting trees will be made by random sequence addition of POY.\n\n");
				last;
			}
			elsif ($response =~ /^\s*paup\s*$/i) {
				$startmaker = 'PAUP';
				print("OK. The starting trees will be made by random sequence addition of PAUP.\n\n");
				last;
			}
			elsif ($response =~ /^\s*tf\s*$/i) {
				$startmaker = 'TF';
				print("OK. The starting trees will be made by ML tree search of Treefinder.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
		while ($loop) {
			my $response;
			print("How many percentages of sites do you want to upweight? (integer)\n(default: 25)\n");
			$response = <STDIN>;
			$response =~ s/\r?\n?$//;
			unless ($response) { $response = 25; }
			if ($response =~ /^(\d+)$/) {
				if ($1 < 1) {
					&errorMessage(__LINE__, 'The number of percentages is not valid.');
				}
				else {
					$percent = $1;
				}
				print("OK. The number of percentages is set to $1.\n\n");
				last;
			}
			else {
				print("Cannot understand your answer.\n\n");
			}
		}
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
		if (-e "$prefix\_ratchetsearch_sorted.log" && -e "$prefix\_starttrees_duplicates_eliminated.nwk") {
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
	elsif ($ARGV[$i] =~ /^-+(?:p|percent)=(\d+)$/i) {
		$percent = $1;
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
	elsif ($ARGV[$i] =~ /^-+(?:s|startmaker)=(\S+)$/i) {
		if ($1 =~ /^TF$/i) {
			$startmaker = 'TF';
		}
		elsif ($1 =~ /^POY$/i) {
			$startmaker = 'POY';
		}
		elsif ($1 =~ /^PAUP$/i) {
			$startmaker = 'PAUP';
		}
		elsif ($1 =~ /^TNT$/i) {
			$startmaker = 'TNT';
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
my $combine;
if ($mode eq 'Combine' && -e "$prefix\_starttrees_duplicates_eliminated.nwk") {
	if (!-e "$prefix\_ratchetsearch_sorted.log") {
		&errorMessage(__LINE__, "The operation mode is \"combine\" and previous start trees exists, but previous ratchet log does not exist.");
	}
	$combine = 1;
}

&checkFiles();

# make starting trees
if ($startmaker eq 'POY') {
	if (system("pgconvseq --output=NEXUS $inputfile $prefix.nex")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix.nex\".");
	}
	if (system("pgresampleseq --nreps=$nreps --percent=$percent $prefix.nex $prefix\_weighted.nex")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_weighted.nex\".");
	}
	unless (open(POY, "> $prefix\_makestarttrees.poy")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_makestarttrees.poy\".");
	}
	print(POY "read(prealigned: (\"\%SEQFILE\", tcm: (1,0), gap_opening: 0))\n");
	if ($constraintfile) {
		print(POY "build(trees: 1, as_is, constraint: \"$constraintfile\")\n");
	}
	else {
		print(POY "build(trees: 1, as_is)\n");
	}
	print(POY "report(\"\%OUTFILE{$prefix\_starttrees.nwk}\", trees:(newick, nomargin, collapse: false))\nexit()\n");
	close(POY);
	if (system("pgpoy --numthreads=$numthreads $prefix\_weighted.nex $prefix\_makestarttrees.poy")) {
		&errorMessage(__LINE__, 'Cannot run pgpoy.');
	}
	unlink("$prefix.nex");
	unlink("$prefix\_weighted.nex");
	unlink("$prefix\_makestarttrees.poy");
}
elsif ($startmaker eq 'TNT') {
	if (system("pgconvseq --output=NEXUS $inputfile $prefix.nex")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix.nex\".");
	}
	if (system("pgresampleseq --nreps=$nreps --percent=$percent $prefix.nex $prefix\_weighted.nex")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_weighted.nex\".");
	}
	unless (open(TNT, "> $prefix\_makestarttrees.tnt")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_makestarttrees.tnt\".");
	}
	print(TNT "Procedure \%SEQFILE;\nNstates NOGAPS;\nCollapse 0;\n");
	if ($constraintfile) {
		my $topocon;
		my $outgroup;
		unless (open(TREE, "< $constraintfile")) {
			&errorMessage(__LINE__, "Cannot read \"$constraintfile\".");
		}
		{
			local $/ = ';';
			while (<TREE>) {
				if (/\((.+)\)/s) {
					$topocon = $1;
					$topocon =~ s/\s//sg;
					$topocon =~ s/\)[^:,\)]+/)/sg;
					$topocon =~ s/:[^,\)]+//sg;
					my @otus = $topocon =~ /[^:,\(\)]+/g;
					foreach my $otu (@otus) {
						if (length($otu) > 31) {
							&errorMessage(__LINE__, "The length of OTU name is larger than 31.");
						}
					}
					$outgroup = $otus[0];
					my $cladeno = 1;
					while ($topocon =~ s/\(([^\(\)]+)\)/<$cladeno>$1<\/$cladeno>/) {
						$cladeno ++;
					}
					while ($topocon =~ s/<(\d+)>($outgroup,.+)<\/\1>/$2/) { }
					$topocon =~ s/<\d+>/(/g;
					$topocon =~ s/<\/\d+>/)/g;
					$topocon =~ s/,/ /sg;
					$topocon = '(' . $topocon . ')';
					last;
				}
			}
		}
		close(TREE);
		print("Enforced topological constraint for TNT is\n$topocon\n");
		print(TNT "Outgroup $outgroup;\nForce / $topocon;;\nConstrain =;\n");
	}
	print(TNT "Mult = wagner replic 1;\nTaxName =;\nExport - \%OUTFILE{$prefix\_starttrees.tre};\nQuit;\n");
	close(TNT);
	if ($^O eq 'darwin') {
		if (system("pgtnt --numthreads=1 $prefix\_weighted.nex $prefix\_makestarttrees.tnt")) {
			&errorMessage(__LINE__, 'Cannot run pgtnt.');
		}
	}
	else {
		if (system("pgtnt --numthreads=$numthreads $prefix\_weighted.nex $prefix\_makestarttrees.tnt")) {
			&errorMessage(__LINE__, 'Cannot run pgtnt.');
		}
	}
	if (system("pgconvtree --output=Newick $prefix\_starttrees.tre $prefix\_starttrees.nwk")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_starttrees.nwk\".");
	}
	unlink("$prefix.nex");
	unlink("$prefix\_weighted.nex");
	unlink("$prefix\_makestarttrees.tnt");
	unlink("$prefix\_starttrees.tre");
}
elsif ($startmaker eq 'PAUP') {
	my $nexusseq = 'pgpauptemp1.nex';
	{
		my $tempnum = 2;
		while (-e $nexusseq) {
			$nexusseq = "pgpauptemp$tempnum.nex";
			$tempnum ++;
		}
	}
	my $weightedseq = 'pgpaupweighted1.nex';
	{
		my $tempnum = 2;
		while (-e $weightedseq) {
			$weightedseq = "pgpaupweighted$tempnum.nex";
			$tempnum ++;
		}
	}
	my $paupcommand = 'pgpaupmaketrees1.paup';
	{
		my $tempnum = 2;
		while (-e $paupcommand) {
			$paupcommand = "pgpaupmaketrees$tempnum.nex";
			$tempnum ++;
		}
	}
	my $starttrees = 'pgpaupstarttrees1.tre';
	{
		my $tempnum = 2;
		while (-e $starttrees) {
			$starttrees = "pgpaupstarttrees$tempnum.nex";
			$tempnum ++;
		}
	}
	if (system("pgconvseq --output=NEXUS $inputfile $nexusseq")) {
		&errorMessage(__LINE__, "Cannot make \"$nexusseq\".");
	}
	if (system("pgresampleseq --nreps=$nreps --percent=$percent $nexusseq $weightedseq")) {
		&errorMessage(__LINE__, "Cannot make \"$weightedseq\".");
	}
	unless (open(PAUP, "> $paupcommand")) {
		&errorMessage(__LINE__, "Cannot make \"$paupcommand\".");
	}
	print(PAUP "#NEXUS\n\nBegin PAUP;\nExecute \%SEQFILE;\nSet Criterion=Parsimony;\nPSet Collapse=No;\n");
	if ($constraintfile) {
		my $topocon;
		unless (open(TREE, "< $constraintfile")) {
			&errorMessage(__LINE__, "Cannot read \"$constraintfile\".");
		}
		{
			local $/ = ';';
			while (<TREE>) {
				if (/(\(.+\))/s) {
					$topocon = $1;
					$topocon =~ s/\s//sg;
					$topocon =~ s/\)\d+\.?\d*([:,\)])/)$1/sg;
					$topocon =~ s/:\d+\.?\d*([,\)])/$1/sg;
					last;
				}
			}
		}
		close(TREE);
		print(PAUP "Constraints constr (monophyly)=$topocon;\nHSearch Start=Stepwise AddSeq=AsIs Swap=None Enforce=Yes Constraints=constr;\n");
	}
	else {
		print(PAUP "HSearch Start=Stepwise AddSeq=AsIs Swap=None;\n");
	}
	print(PAUP "SaveTrees Format=AltNEXUS File=\%OUTFILE{$starttrees};\nEnd;\n");
	close(PAUP);
	if (system("pgpaup --numthreads=$numthreads $weightedseq $paupcommand")) {
		&errorMessage(__LINE__, 'Cannot run pgpaup.');
	}
	if (system("pgconvtree --output=Newick $starttrees $prefix\_starttrees.nwk")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_starttrees.nwk\".");
	}
	unlink("$nexusseq");
	unlink("$weightedseq");
	unlink("$paupcommand");
	unlink("$starttrees");
}
else {
	if (system("pgresampleseq --nreps=$nreps --percent=$percent $inputfile $prefix\_weighted.tf")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_weighted.tf\".");
	}
	unless (open(TL, "> $prefix\_makestarttrees.tl")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_makestarttrees.tl\".");
	}
	print(TL << "_END");
report:=ReconstructPhylogeny[
	\"\%SEQFILE\",
	SubstitutionModel->Load[
		\"$modelfile\"
	],
$rates$constraint	WithEdgeSupport->False,
	SearchDepth->1,
	Verbose->False,
	AcceptFlatness->True
],
Oprec[
	20,
	SaveTree[
		RemoveEdgeData[
			AsTree[
				report|1|Phylogeny
			]
		],
		\"\%OUTFILE{$prefix\_starttrees.nwk}\",
		Format->\"NEWICK\"
	]
]
_END
	close(TL);
	if (system("pgtf --numthreads=$numthreads $prefix\_weighted.tf $prefix\_makestarttrees.tl")) {
		&errorMessage(__LINE__, 'Cannot run pgtf.');
	}
	unlink("$prefix\_weighted.tf");
	unlink("$prefix\_makestarttrees.tl");
}

# eliminate duplicate trees
{
	my $tempoption;
	if ($combine) {
		$combine = 1;
		unless (rename("$prefix\_starttrees_duplicates_eliminated.nwk", "$prefix\_starttrees_duplicates_eliminated_previous.nwk")) {
			&errorMessage(__LINE__, "Cannot rename \"$prefix\_starttrees_duplicates_eliminated.nwk\" to \"$prefix\_starttrees_duplicates_eliminated_previous.nwk\".");
		}
		$tempoption = " --treefile=$prefix\_starttrees_duplicates_eliminated_previous.nwk";
	}
	elsif (-e "$prefix\_starttrees_duplicates_eliminated.nwk") {
		unlink("$prefix\_starttrees_duplicates_eliminated.nwk");
	}
	if (system("pgelimduptree$tempoption $prefix\_starttrees.nwk $prefix\_starttrees_duplicates_eliminated.nwk")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_starttrees_duplicates_eliminated.nwk\".");
	}
	unlink("$prefix\_starttrees.nwk");
	if (-z "$prefix\_starttrees_duplicates_eliminated.nwk") {
		rename("$prefix\_starttrees_duplicates_eliminated_previous.nwk", "$prefix\_starttrees_duplicates_eliminated.nwk");
		&errorMessage(__LINE__, "Generated starting trees does not contain new topologies.");
	}
}

# run ratchet search
unless (open(TL, "> $prefix\_singlesearch_from_given_tree.tl")) {
	&errorMessage(__LINE__, "Cannot make \"$prefix\_singlesearch_from_given_tree.tl\".");
}
print(TL << "_END");
report:=ReconstructPhylogeny[
	\"\%SEQFILE\",
	SubstitutionModel->Load[
		\"$modelfile\"
	],
$rates$constraint	StartTrees->\"\%STARTTREE\",
	WithEdgeSupport->False,
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
		\"\%OUTFILE{$prefix\_ratchetsearch.log}\"
	]
]
_END
close(TL);
if (system("pgtf --numthreads=$numthreads --treefile=$prefix\_starttrees_duplicates_eliminated.nwk $inputfile $prefix\_singlesearch_from_given_tree.tl")) {
	&errorMessage(__LINE__, 'Cannot run pgtf.');
}
unlink("$prefix\_singlesearch_from_given_tree.tl");
if ($combine) {
	unless (rename("$prefix\_starttrees_duplicates_eliminated.nwk", "$prefix\_starttrees_duplicates_eliminated_new.nwk")) {
		&errorMessage(__LINE__, "Cannot rename \"$prefix\_starttrees_duplicates_eliminated.nwk\" to \"$prefix\_starttrees_duplicates_eliminated_new.nwk\".");
	}
	if (system("pgjointree $prefix\_starttrees_duplicates_eliminated_previous.nwk $prefix\_starttrees_duplicates_eliminated_new.nwk $prefix\_starttrees_duplicates_eliminated.nwk")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_starttrees_duplicates_eliminated.nwk\".");
	}
	unlink("$prefix\_starttrees_duplicates_eliminated_previous.nwk");
	unlink("$prefix\_starttrees_duplicates_eliminated_new.nwk");
}

# make log files
if ($combine) {
	unless (open(NEWLOG, "> $prefix\_ratchetsearch_new.log")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_ratchetsearch_new.log\".");
	}
	print(NEWLOG "{\n");
	unless (open(LOG, "< $prefix\_ratchetsearch.log")) {
		&errorMessage(__LINE__, "Cannot read \"$prefix\_ratchetsearch.log\".");
	}
	while (<LOG>) {
		if (/^ \{Likelihood->/) {
			print(NEWLOG);
		}
	}
	close(LOG);
	unless (open(LOG, "< $prefix\_ratchetsearch_sorted.log")) {
		&errorMessage(__LINE__, "Cannot make \"$prefix\_ratchetsearch_sorted.log\".");
	}
	while (<LOG>) {
		if (/^ \{Likelihood->/) {
			print(NEWLOG);
		}
	}
	close(LOG);
	print(NEWLOG " ()\n}\n");
	close(NEWLOG);
	unlink("$prefix\_ratchetsearch.log");
	unless (rename("$prefix\_ratchetsearch_new.log", "$prefix\_ratchetsearch.log")) {
		&errorMessage(__LINE__, "Cannot rename \"$prefix\_ratchetsearch_new.log\" to \"$prefix\_ratchetsearch.log\".");
	}
}
if ($ratesfile) {
	$rates = "\tSave[\n\t\treport|1|PartitionRates,\n\t\t\"$prefix\_optimum.rates\"\n\t],\n";
}
unless (open(TL, "> $prefix\_extract_optimum_from_ratchetlog.tl")) {
	&errorMessage(__LINE__, "Cannot make \"$prefix\_extract_optimum_from_ratchetlog.tl\".");
}
print(TL << "_END");
report:=SortHypotheses[
	LoadReport[
		\"$prefix\_ratchetsearch.log\"
	],
	\"Likelihood\"
],
Oprec[
	20,
	SaveReport[
		AsReport[
			report
		],
		\"$prefix\_ratchetsearch_sorted.log\"
	],
	SaveTreeList[
		AsTreeList[
			report
		],
		\"$prefix\_ratchetsearch_sorted.nwk\",
		Format->\"NEWICK\"
	],
	SaveReport[
		AsReport[
			report|1
		],
		\"$prefix\_optimum_from_ratchet.log\"
	],
	Save[
		report|1|SubstitutionModel,
		\"$prefix\_optimum.model\"
	],
$rates	SaveTree[
		AsTree[
			report|1|Phylogeny
		],
		\"$prefix\_optimum.nwk\",
		Format->\"NEWICK\"
	]
]
_END
close(TL);
unlink("$prefix\_ratchetsearch_sorted.log");
unlink("$prefix\_ratchetsearch_sorted.nwk");
unlink("$prefix\_optimum_from_ratchet.log");
unlink("$prefix\_optimum.model");
unlink("$prefix\_optimum.rates");
unlink("$prefix\_optimum.nwk");
if (system("tf $prefix\_extract_optimum_from_ratchetlog.tl")) {
	&errorMessage(__LINE__, 'Cannot run tf.');
}
unlink("$prefix\_ratchetsearch.log");
unlink("$prefix\_extract_optimum_from_ratchetlog.tl");

# make coverage index
if (-e "$prefix\_ratchetsearch_checkcoverage.txt") {
	unlink("$prefix\_ratchetsearch_checkcoverage.txt");
}
if (system("pgcomptree --output=Column --compare=Top $prefix\_ratchetsearch_sorted.nwk $prefix\_ratchetsearch_checkcoverage.txt")) {
	&errorMessage(__LINE__, "Cannot make \"$prefix\_ratchetsearch_checkcoverage.txt\".");
}

# display message and exit
print("The ratchet search has been finished.\n");

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
	if ($startmaker eq 'POY') {
		unless (open(CMD, '> exit.poy')) {
			&errorMessage(__LINE__, 'Cannot make file.');
		}
		print(CMD "exit()\n");
		close(CMD);
		if (system("seq_poy exit.poy 2> " . $devnull . ' 1> ' . $devnull)) {
			&errorMessage(__LINE__, "Cannot run seq_poy. Please check seq_poy.");
		}
		unlink('exit.poy');
		if (system("pgpoy 2> " . $devnull . ' 1> ' . $devnull)) {
			&errorMessage(__LINE__, "Cannot run pgpoy. Please check pgpoy.");
		}
	}
	elsif ($startmaker eq 'PAUP') {
		unless (open(NEXUS, '> NEXUS.nex')) {
			&errorMessage(__LINE__, 'Cannot make file.');
		}
		print(NEXUS "#NEXUS\nBegin PAUP;\nQuit;\nEnd;\n");
		close(NEXUS);
		if (system("paup -u -n NEXUS.nex 2> " . $devnull . ' 1> ' . $devnull)) {
			&errorMessage(__LINE__, "Cannot run paup. Please check paup.");
		}
		unlink('NEXUS.nex');
		if (system("pgpaup 2> " . $devnull . ' 1> ' . $devnull)) {
			&errorMessage(__LINE__, "Cannot run pgpaup. Please check pgpaup.");
		}
	}
	elsif ($startmaker eq 'TNT') {
		if (system("tnt \"Quit;\" 2> " . $devnull . ' 1> ' . $devnull)) {
			&errorMessage(__LINE__, "Cannot run tnt. Please check tnt.");
		}
		if (system("pgtnt 2> " . $devnull . ' 1> ' . $devnull)) {
			&errorMessage(__LINE__, "Cannot run pgtnt. Please check pgtnt.");
		}
	}
	if ($startmaker ne 'TF' && system("pgconvseq 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgconvseq. Please check pgconvseq.");
	}
	if (system("pgresampleseq 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgresampleseq. Please check pgresampleseq.");
	}
	if (system("pgelimduptree 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgelimduptree. Please check pgelimduptree.");
	}
	if (system("pgtf 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgtf. Please check pgtf.");
	}
	if (system("pgcomptree 2> " . $devnull . ' 1> ' . $devnull)) {
		&errorMessage(__LINE__, "Cannot run pgcomptree. Please check pgcomptree.");
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
pgtfratchet options inputfile modelfile

Command line options
====================
-m, --mode=Combine|Replace
  Specify the behavior if the files of previous analysis already exist.
(default: Combine)

-n, --numthreads=INTEGER
  Specify the number of threads. (default: 1)

-p, --percent=INTEGER
  Specify the number of percentages for random site weighting.
(default: 25)

-r, --nreps=INTEGER
  Specify the number of replicates. (default: 100)

-s, --startmaker=PAUP|POY|TF|TNT
  Specify the software to make starting trees. (default: POY)

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
