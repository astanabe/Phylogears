#!/usr/bin/perl
my $buildno = '2.0.2016.02.06';
#
# pgpauplscores2lset
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
pgpauplscores2lset $buildno
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
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
# check options
my $outformat;
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:o|output)=(.+)$/i) {
		my $outoption = $1;
		if ($outoption =~ /^NEXUS$/i) {
			unless ($outformat) {
				$outformat = 'NEXUS';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^LSET$/i) {
			unless ($outformat) {
				$outformat = 'LSET';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}
unless ($outformat) {
	&errorMessage(__LINE__, 'Output option is not specified.');
}
# read score file
unless (open(SCORE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
my @params;
my @models;
{
	my @tempparams;
	my $tempno = 0;
	while (<SCORE>) {
		if (/^(Tree\t.*?)\r?\n?$/) {
			@tempparams = split(/\t/, $1);
			shift(@tempparams);
			shift(@tempparams);
		}
		elsif (/^(\d+\t.*?)\r?\n?$/) {
			my @values = split(/\t/, $1);
			shift(@values);
			shift(@values);
			if (scalar(@tempparams) == scalar(@values)) {
				for (my $i = 0; $i < scalar(@tempparams); $i ++) {
					$params[$tempno][$i] = $tempparams[$i];
					$models[$tempno]{$tempparams[$i]} = $values[$i];
				}
			}
			else {
				&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
			}
			$tempno ++;
		}
	}
}
close(SCORE);
# make LSet commands
my @outputs;
for (my $i = 0; $i < scalar(@params); $i ++) {
	my @lset;
	my $nst = 1;
	my %rateset;
	my @charset;
	my $heterogeneity;
	foreach my $param (@{$params[$i]}) {
		if ($param eq 'freqA') {
			push(@lset, 'BaseFreq=(' . $models[$i]{'freqA'} . ' ' . $models[$i]{'freqC'} . ' ' . $models[$i]{'freqG'} . ')');
		}
		elsif ($param =~ /^freq[CGT]$/) {
			next;
		}
		elsif ($param eq 'ti/tv ratio') {
			if ($nst == 1) {
				$nst = 2;
			}
			else {
				&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
			}
			push(@lset, 'TRatio=' . $models[$i]{'ti/tv ratio'});
		}
		elsif ($param eq 'R(a)') {
			if ($nst == 1) {
				$nst = 6;
			}
			else {
				&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
			}
			push(@lset, 'RMatrix=(' . $models[$i]{'R(a)'} . ' ' . $models[$i]{'R(b)'} . ' ' . $models[$i]{'R(c)'} . ' ' . $models[$i]{'R(d)'} . ' ' . $models[$i]{'R(e)'} . ')');
		}
		elsif ($param =~ /^R\([bcde]\)$/) {
			next;
		}
		elsif ($param eq 'p-inv') {
			$heterogeneity = 1;
			push(@lset, 'PInvar=' . $models[$i]{'p-inv'});
		}
		elsif ($param eq 'gamma shape') {
			$heterogeneity = 1;
			push(@lset, 'Rates=Gamma Shape=' . $models[$i]{'gamma shape'});
		}
		elsif ($param =~ /^Rate\((.+)\)$/) {
			if ($heterogeneity) {
				&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
			}
			else {
				push(@charset, $1);
				$rateset{$1} = $models[$i]{$param};
			}
		}
	}
	my $lset;
	if (@charset) {
		$lset .= 'RateSet OptimumRateRatio=';
		for (my $j = 0; $j < scalar(@charset); $j ++) {
			$lset .= $rateset{$charset[$j]} . ':' . $charset[$j];
			if ($j == scalar(@charset) - 1) {
				$lset .= "; ";
			}
			else {
				$lset .= ',';
			}
		}
		push(@lset, 'Rates=SiteSpec SiteRates=RateSet:OptimumRateRatio');
	}
	$lset .= 'LSet Nst=' . $nst;
	if (@lset) {
		$lset .= ' ' . join(' ', @lset);
	}
	$lset .= ";\n";
	push(@outputs, $lset);
}
# output
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
if ($outformat eq 'NEXUS') {
	print($filehandle "#NEXUS\n\nBegin PAUP;\n");
}
for (my $i = 0; $i < scalar(@outputs); $i ++) {
	if ($outformat eq 'NEXUS') {
		print($filehandle "\t");
	}
	print($filehandle $outputs[$i]);
}
if ($outformat eq 'NEXUS') {
	print($filehandle "End;\n");
}
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
pgpauplscores2lset inputfile outputfile

Command line options
====================
-o, --output=NEXUS|LSET
  Specify output file format.

Acceptable input file formats
=============================
PAUP* LScores score file
(\"Defaults LScores LongFmt=Yes;\" must be enabled.)
_END
	exit;
}
