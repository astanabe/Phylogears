my $buildno = '2.0.x';
#
# pgconcatgap
# 
# Official web site of this script is
# https://www.fifthdimension.jp/products/phylogears/ .
# To know script details, see above URL.
# 
# Copyright (C) 2008-2018  Akifumi S. Tanabe
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
pgconcatgap $buildno
=======================================================================

Official web site of this script is
https://www.fifthdimension.jp/products/phylogears/ .
To know script details, see above URL.

Copyright (C) 2008-2018  Akifumi S. Tanabe

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

unless (@ARGV) {
	&helpMessage();
}

# initialize variables
my $outformat = 'PAUP';
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $ntax;
my @nchar;
my $datatype;
my $mrbayesblock;
my $paupblock;
my @taxa;
my %taxa;
my @seq;
my @inputfiles;

# get command line options
{
	my %inputfiles;
	for (my $i = 0; $i < scalar(@ARGV) - 1; $i ++) {
		if ($ARGV[$i] =~ /^-+(?:o|output)=(.+)$/i) {
			if ($1 =~ /^MrBayes$/i) {
				$outformat = 'MrBayes';
			}
			elsif ($1 =~ /^PAUP$/i) {
				$outformat = 'PAUP';
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
			}
		}
		else {
			foreach (glob($ARGV[$i])) {
				if ($inputfiles{$_}) {
					&errorMessage(__LINE__, "\"$_\" is doubly specified.");
				}
				elsif (-e $_ && !-d $_ && !-z $_) {
					$inputfiles{$_} = 1;
					push(@inputfiles, $_);
				}
				else {
					&errorMessage(__LINE__, "\"$_\" does not exist or this is not a file.");
				}
			}
		}
	}
}

# file format recognition
foreach my $inputfile (@inputfiles) {
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	{
		while (<INFILE>) {
			unless (/^#NEXUS/i) {
				&errorMessage(__LINE__, "\"$inputfile\" is not NEXUS format.");
			}
			last;
		}
	}
	close(INFILE);
}

# read input file
for (my $i = 0; $i < scalar(@inputfiles); $i ++) {
	my $inputfile = $inputfiles[$i];
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	my $datablock = 0;
	my $tempmrbayesblock = 0;
	my $temppaupblock = 0;
	my $matrix = 0;
	while (<INFILE>) {
		if ($datablock != 1 && $tempmrbayesblock != 1 && /^\s*Begin\s+Data\s*;/i) {
			$datablock = 1;
		}
		elsif ($outformat eq 'MrBayes' && $i == 0 && $datablock == 2 && $tempmrbayesblock != 1 && /^\s*Begin\s+MrBayes\s*;/i) {
			$tempmrbayesblock = 1;
		}
		elsif ($outformat eq 'PAUP' && $i == 0 && $datablock == 2 && $temppaupblock != 1 && /^\s*Begin\s+PAUP\s*;/i) {
			$temppaupblock = 1;
		}
		elsif ($datablock == 1 && /^\s*End\s*;/i) {
			$datablock = 2;
		}
		elsif (($tempmrbayesblock == 1 || $temppaupblock == 1) && /^\s*End\s*;/i) {
			last;
		}
		elsif ($datablock == 1 && $matrix == 1 && /;/) {
			$matrix = 0;
		}
		elsif ($datablock == 1 && $matrix == 1) {
			$seq[$i] .= $_;
			s/\[[^\]]+\]//;
			if (/^\s*(\S+)\s+(\S.*?)\s*\r?\n?$/) {
				my $taxon = $1;
				if (!$taxa{$taxon} && $i == 0) {
					push(@taxa, $taxon);
					$taxa{$taxon} = 1;
				}
				elsif (!$taxa{$taxon} && $i > 0) {
					&errorMessage(__LINE__, "\"$inputfile\" has different taxa set from \"$inputfiles[0]\".");
				}
			}
		}
		elsif ($datablock == 1 && $matrix == 0 && /^\s*Dimensions\s+/i) {
			if ($i == 0 && /\s+NTax\s*=\s*(\d+)/i) {
				$ntax = $1;
			}
			elsif ($i > 0 && /\s+NTax\s*=\s*(\d+)/i) {
				if ($1 != $ntax) {
					&errorMessage(__LINE__, "\"$inputfile\" has different taxa set from \"$inputfiles[0]\".");
				}
			}
			if (/\s+NChar\s*=\s*(\d+)/i) {
				$nchar[$i] = $1;
			}
		}
		elsif ($i == 0 && $datablock == 1 && $matrix == 0 && /DataType\s*=\s*(\S+)/i) {
			$datatype = $1;
		}
		elsif ($datablock == 1 && $matrix == 0 && /^\s*Matrix/i) {
			$matrix = 1;
		}
		elsif ($tempmrbayesblock == 1) {
			$mrbayesblock .= $_;
		}
		elsif ($temppaupblock == 1) {
			$paupblock .= $_;
		}
	}
	close(INFILE);
}

# check data
if ($mrbayesblock && $mrbayesblock !~ /Partition\s+\S+\s*=\s*(\d+)\s*:[^;]+;/i) {
	$mrbayesblock = "CharSet Seqs=1-$nchar[0];\nPartition Phylogears=1:Seqs;\nSet Partition=Phylogears;\n" . $mrbayesblock;
}

my $outputnchar;
foreach my $nchar (@nchar) {
	$outputnchar += $nchar;
}
my $startadd = $nchar[0] + 1;

# output file
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
print($filehandle "#NEXUS\n");
print($filehandle "\nBegin Data;\n\tDimensions NTax=$ntax NChar=$outputnchar;\n");
if ($outformat eq 'MrBayes') {
	if ($datatype !~ /^Mixed/i) {
		print($filehandle "\tFormat DataType=Mixed($datatype:1-$nchar[0],Restriction:$startadd\-$outputnchar) Gap=- Missing=? Interleave=Yes;\n");
	}
	else {
		$datatype =~ s/\)$/,Restriction:$startadd\-$outputnchar)/;
		print($filehandle "\tFormat DataType=$datatype Gap=- Missing=? Interleave=Yes;\n");
	}
}
elsif ($outformat eq 'PAUP') {
	print($filehandle "\tFormat DataType=$datatype Symbols=\"01\" Gap=- Missing=? Interleave;\n");
}
print($filehandle "\tMatrix\n");
# output sequences
foreach (@seq) {
	print($filehandle $_);
}
print($filehandle "\t;\nEnd;\n");
if ($outformat eq 'MrBayes' && $mrbayesblock) {
	$mrbayesblock =~ /Partition\s+\S+\s*=\s*(\d+)\s*:[^;]+;/i;
	my $gappartno = $1 + 1;
	$mrbayesblock =~ s/(Partition\s+\S+\s*=\s*)\d+(\s*:[^;]+);/$1$gappartno$2,Gaps;/i;
	$mrbayesblock =~ s/Set\s+Partition\s*=[^;]+;/$&\n\tUnlink BrLens=($gappartno);\n\tLSet ApplyTo=($gappartno) Coding=Variable Rates=Equal;\n\tPrSet ApplyTo=($gappartno) StateFreqPr=Fixed(Equal);/i;
	print($filehandle "\nBegin MrBayes;\n");
	print($filehandle "\tCharSet Gaps=$startadd\-$outputnchar;\n");
	print($filehandle $mrbayesblock);
	print($filehandle "End;\n");
}
elsif ($outformat eq 'MrBayes') {
	print($filehandle "\nBegin MrBayes;\n");
	print($filehandle "\tCharSet Seqs=1-$nchar[0];\n");
	print($filehandle "\tCharSet Gaps=$startadd\-$outputnchar;\n");
	print($filehandle "\tPartition Phylogears=2:Seqs,Gaps;\n");
	print($filehandle "\tSet Partition=Phylogears;\n");
	print($filehandle "\tUnlink BrLens=(2);\n");
	print($filehandle "\tLSet ApplyTo=(2) Coding=Variable Rates=Equal;\n");
	print($filehandle "\tPrSet ApplyTo=(2) StateFreqPr=Fixed(Equal);\n");
	print($filehandle "End;\n");
}
elsif ($outformat eq 'PAUP' && $paupblock) {
	print($filehandle "\nBegin PAUP;\n");
	print($filehandle $paupblock);
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
	print(<<"_END");
Usage
=====
pgconcatgap options seqfile indelfile1 indelfile2 .. outputfile

Command line options
====================
-o, --output=MrBayes|PAUP
  Specify the output format. (default: PAUP)

Acceptable input file formats
=============================
NEXUS
_END
	exit;
}
