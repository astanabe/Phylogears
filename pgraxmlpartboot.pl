my $buildno = 0;

#
# pgraxmlpartboot
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

# options
my $nreps;
my $seed;
my $multilevel = 1;

# input/output
my $inputfile;
my $outputfolder;
my $partitionfile;
my $groupfile;

# global variables
my $gen;
my $nrepslen;
my %part2site;
my @site2part;
my @group2part;
my @partition;
my %part2group;
my %part2model;
my $ntax;
my $nchar;
my @taxa;
my %seqs;
my %newseqs;

# file handles
my $filehandleinput1;
my $filehandleinput2;
my $filehandleoutput1;
my $filehandleoutput2;

&main();

sub main {
	# print startup messages
	&printStartupMessage();
	# get command line arguments
	&getOptions();
	# check variable consistency
	&checkVariables();
	# initialize pseudo-random number generator
	&initializePRNG();
	# read partition file
	&readPartitionSetting();
	# read sequence file
	&readSequences();
	# resample sequences
	&resampleGroups();
}

sub printStartupMessage {
	print(<<"_END");
pgraxmlpartboot $buildno
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
}

sub getOptions {
	# get arguments
	$outputfolder = $ARGV[-1];
	$inputfile = $ARGV[-2];
	for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
		if ($ARGV[$i] =~ /^-+(?:r|nreps)=(\d+)$/i) {
			$nreps = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:partitionfile|partition|partfile|part|p)=(.+)$/i) {
			$partitionfile = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:groupfile|group|g)=(.+)$/i) {
			$groupfile = $1;
		}
		elsif ($ARGV[$i] =~ /^-+seed=(\d+)$/i) {
			$seed = $1;
		}
		elsif ($ARGV[$i] =~ /^-+multilevel=(enable|disable|yes|no|true|false|E|D|Y|N|T|F)$/i) {
			if ($1 =~ /^(?:enable|yes|true|E|Y|T)$/i) {
				$multilevel = 1;
			}
			elsif ($1 =~ /^(?:disable|no|false|D|N|F)$/i) {
				$multilevel = 0;
			}
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
}

sub checkVariables {
	unless ($partitionfile) {
		&errorMessage(__LINE__, "The partition file was not given.");
	}
	if (!-e $inputfile) {
		&errorMessage(__LINE__, "The input file \"$inputfile\" does not exist.");
	}
	if (-e $outputfolder) {
		&errorMessage(__LINE__, "The output folder \"$outputfolder\" already exists.");
	}
	if (!-e $partitionfile) {
		&errorMessage(__LINE__, "The partition file \"$partitionfile\" does not exist.");
	}
	if (!-e $groupfile) {
		&errorMessage(__LINE__, "The group file \"$groupfile\" does not exist.");
	}
	$nrepslen = length($nreps);
}

sub initializePRNG {
	unless ($seed) {
		$seed = time^$$;
	}
	eval "use Math::Random::MT::Auto";
	if ($@) {
		eval "use Math::Random::MT::Perl";
		if ($@) {
			&errorMessage(__LINE__, "Perl module \"Math::Random::MT::Auto\" and \"Math::Random::MT:Perl\" is not available.");
		}
		else {
			$gen = Math::Random::MT::Perl->new($seed);
		}
	}
	else {
		$gen = Math::Random::MT::Auto->new();
		$gen->srand($seed);
	}
}

sub readPartitionSetting {
	unless (open($filehandleinput1, "< $partitionfile")) {
		&errorMessage(__LINE__, "Cannot read \"$partitionfile\".");
	}
	while (<$filehandleinput1>) {
		if (/(\S+)\s*,\s*(\S+)\s*=\s*([0-9\-\\]+)/) {
			my $modelname = $1;
			my $partname = $2;
			if ($part2model{$partname}) {
				&errorMessage(__LINE__, "The partition \"$partname\" is doubly defined in partition file.");
			}
			else {
				$part2model{$partname} = $modelname;
				push(@partition, $partname);
			}
			my $range = $3;
			my @sites;
			if ($range =~ /^(\d+)\-(\d+)\\(\d+)$/) {
				@sites = &range2list($1, $2, $3);
			}
			elsif ($range =~ /^(\d+)\-(\d+)$/) {
				@sites = &range2list($1, $2, 1);
			}
			else {
				&errorMessage(__LINE__, 'Partition specification is not valid.');
			}
			$part2site{$partname} = \@sites;
			for (my $i = 0; $i < scalar(@sites); $i ++) {
				if ($site2part[$sites[$i] - 1]) {
					&errorMessage(__LINE__, "The $sites[$i]-th site is doubly used in partition \"" . $site2part[$sites[$i] - 1] . "\" and \"$partname\".");
				}
				else {
					$site2part[$sites[$i] - 1] = $partname;
				}
			}
		}
	}
	close($filehandleinput1);
	if ($groupfile) {
		my $ngroup = 0;
		unless (open($filehandleinput1, "< $groupfile")) {
			&errorMessage(__LINE__, "Cannot read \"$groupfile\".");
		}
		while (<$filehandleinput1>) {
			if (/[,\t]/) {
				my @parts = split(/[,\t]/, $_);
				$group2part[$ngroup] = \@parts;
				for (my $i = 0; $i < scalar(@parts); $i ++) {
					if ($part2group{$parts[$i]}) {
						&errorMessage(__LINE__, "The partition \"$parts[$i]\" is doubly used in group $part2group{$parts[$i]} and $ngroup.");
					}
					else {
						$part2group{$parts[$i]} = $ngroup;
					}
				}
				$ngroup ++;
			}
		}
		close($filehandleinput1);
	}
}

sub readSequences {
	my $num = -1;
	unless (open($filehandleinput1, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	while (<$filehandleinput1>) {
		if ($num == -1) {
			if (/^\s*(\d+)\s+(\d+)/) {
				$ntax = $1;
				$nchar = $2;
				$num ++;
			}
			else {
				&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
			}
		}
		else {
			if ($num < $ntax) {
				if (/^(\S+)\s+(\S.*?)\s*\r?\n?$/) {
					my $taxon = $1;
					my $seq = $2;
					unless ($seqs{$taxon}) {
						push(@taxa, $taxon);
					}
					else {
						&errorMessage(__LINE__, "\"$taxon\" is duplicaed in \"$inputfile\".");
					}
					my @seq = $seq =~ /\S/g;
					push(@{$seqs{$taxon}}, @seq);
					$num ++;
				}
			}
			else {
				if (/^\s+(\S.*?)\s*\r?\n?$/) {
					my $seq = $1;
					my @seq = $seq =~ /\S/g;
					push(@{$seqs{$taxa[$num % $ntax]}}, @seq);
					$num ++;
				}
			}
		}
	}
	close($filehandleinput1);
	if (scalar(@taxa) != $ntax) {
		&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
	}
	if (scalar(@site2part) != $nchar) {
		&errorMessage(__LINE__, 'Partition specification is not valid.');
	}
}

sub resampleGroups {
	my $ngroup = scalar(@group2part);
	my %part2size;
	# resample groups
	{
		my @newgroup;
		foreach (1 .. $ngroup) {
			push(@newgroup, int($gen->rand($ngroup)));
		}
		my @groupsize;
		for (my $i = 0; $i < scalar(@newgroup); $i ++) {
			$groupsize[$newgroup[$i]] ++;
		}
		for (my $i = 0; $i < scalar(@groupsize); $i ++) {
			for (my $j = 0; $j < $groupsize[$i]; $j ++) {
				foreach my $partname (@{$group2part[$i]}) {
					$part2size{$partname} ++;
				}
			}
		}
	}
	# resample seqs within group
	foreach my $partname (@partition) {
		$part2site{$partition}
	}
}

sub resamplewithingroup {
	
}

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
		&errorMessage(__LINE__, 'Partition specification is not valid.');
	}
	return(@num);
}

# error message
sub errorMessage {
	my $lineno = shift(@_);
	my $message = shift(@_);
	print(STDERR "ERROR!: line $lineno\n$message\n");
	print(STDERR "If you want to read help message, run this script without options.\n");
	exit(1);
}

sub helpMessage {
	print(STDERR <<"_END");
Usage
=====
pgraxmlpartboot options inputfile outputfolder

Command line options
====================
--nreps=INTEGER
  Specify the number of replices. (default: 100)

--seed=INTEGER
  Specify seed for pseudo-random number generator. (default: auto)

--partitionfile=FILENAME
  Specify the partition setting file for RAxML. (default: none)

--groupfile=FILENAME
  Specify the group setting file. (default: none)

--multilevel=ENABLE|DISABLE
  Specify enable multi-level bootstrapping or not. (default: ENABLE)

Acceptable input file formats
=============================
extended PHYLIP
_END
	exit;
}
