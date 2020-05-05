my $buildno = '2.0.x';
#
# pgcomptree
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

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgcomptree $buildno
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
}

# display usage if command line options were not specified
unless (@ARGV) {
	&helpMessage();
}

# initialize variables
my $inputfile = $ARGV[-2];
if (!-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $rooted = 0;
my $outformat = 'Column';
my $pair = 'All';
my $treefile;
my %format;

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:o|output)=(.+)$/i) {
		if ($1 =~ /^Matrix$/i) {
			$outformat = 'Matrix';
		}
		elsif ($1 =~ /^Column$/i) {
			$outformat = 'Column';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:c|compare)=(.+)$/i) {
		if ($1 =~ /^All$/i) {
			$pair = 'All';
		}
		elsif ($1 =~ /^Top$/i) {
			$pair = 'Top';
		}
		elsif ($1 =~ /^Adjacent$/i) {
			$pair = 'Adjacent';
		}
		elsif ($1 =~ /^Correspond$/i) {
			$pair = 'Correspond';
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:t|treefile)=(.+)$/i) {
		if (-e $1) {
			$treefile = $1;
		}
		else {
			&errorMessage(__LINE__, "Specified tree file \"$1\" does not exist.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:r|rooted)$/i) {
		$rooted = 1;
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

if ($outformat eq 'Matrix' && $pair ne 'All') {
	&errorMessage(__LINE__, "Matrix output requires all pair comparison.");
}
if ($pair eq 'Correspond' && !$treefile) {
	&errorMessage(__LINE__, "Corresponding comparison requires another tree file.");
}
if ($treefile && $pair eq 'Adjacent') {
	&errorMessage(__LINE__, "Adjacent comparison requires only one tree file.");
}

$format{$inputfile} = &recognizeFormat($inputfile);

my @distmatrix = &readInputFile($inputfile);

my @distmatrix2;
if ($treefile) {
	$format{$treefile} = &recognizeFormat($treefile);
	@distmatrix2 = &readInputFile($treefile);
	if (scalar(@distmatrix2) == 0) {
		&errorMessage(__LINE__, "\"$treefile\" does not contain tree.");
	}
	if ($pair eq 'Correspond' && scalar(@distmatrix) == scalar(@distmatrix2)) {
		&errorMessage(__LINE__, "The number of trees are different between the tree files.");
	}
}

if (scalar(@distmatrix) + scalar(@distmatrix2) > 1) {
	my $matrix;
	if (@distmatrix2) {
		$matrix = &makeMatrix(\@distmatrix, \@distmatrix2);
	}
	else {
		$matrix = &makeMatrix(\@distmatrix);
	}
	&printoutMatrix($matrix);
}
else {
	&errorMessage(__LINE__, "\"$inputfile\" does not contain multiple trees.");
}

# print out result
sub printoutMatrix {
	my %output;
	{
		my $output = shift(@_);
		%output = %{$output}
	}
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
	print($filehandle "# 0: same topology\n# 1: different topology\n\n");
	if ($outformat eq 'Matrix') {
		print($filehandle "source\\input\t" . join("\t", sort({$a <=> $b} keys(%{$output{1}}))) . "\n");
		foreach my $source (sort({$a <=> $b} keys(%output))) {
			print($filehandle $source);
			foreach my $input (sort({$a <=> $b} keys(%{$output{$source}}))) {
				print($filehandle "\t" . $output{$source}{$input});
			}
			print($filehandle "\n");
		}
	}
	else {
		print($filehandle "source\tinput\tsame or not\n");
		foreach my $source (sort({$a <=> $b} keys(%output))) {
			foreach my $input (sort({$a <=> $b} keys(%{$output{$source}}))) {
				print($filehandle $source . "\t" . $input . "\t" . $output{$source}{$input} . "\n");
			}
		}
	}
	close($filehandle);
}

# make matrix of same or not
sub makeMatrix {
	my @acrossdist;
	{
		my $acrossdist = shift(@_);
		@acrossdist = @{$acrossdist};
	}
	my @acrossdist2;
	{
		my $acrossdist2 = shift(@_);
		if ($acrossdist2) {
			@acrossdist2 = @{$acrossdist2};
		}
	}
	my %output;
	# all, top, correspond
	if (@acrossdist2) {
		my $limit;
		if ($pair eq 'Top') {
			$limit = 1;
		}
		else {
			$limit = scalar(@acrossdist2);
		}
		for (my $i = 0; $i < $limit; $i ++) {
			my $same = 0;
			for (my $j = 0; $j < scalar(@acrossdist); $j ++) {
				if ($pair ne 'Correspond' || $i == $j) {
					my $diff = 0;
					foreach my $otu1 (keys(%{$acrossdist[$j]})) {
						foreach my $otu2 (keys(%{$acrossdist[$j]})) {
							if ($otu1 ne $otu2) {
								if (exists($acrossdist[$j]->{$otu1}->{$otu2}) && exists($acrossdist2[$i]->{$otu1}->{$otu2})) {
									if ($acrossdist[$j]->{$otu1}->{$otu2} != $acrossdist2[$i]->{$otu1}->{$otu2}) {
										$diff = 1;
										last;
									}
								}
								else {
									&errorMessage(__LINE__, "Trees are not compatible.");
								}
							}
						}
						if ($diff) {
							last;
						}
					}
					if ($diff) {
						$output{$i + 1}{$j + 1} = 1;
					}
					else {
						$output{$i + 1}{$j + 1} = 0;
					}
				}
			}
		}
	}
	# all, top, adjacent
	else {
		my $limit;
		if ($pair eq 'Top') {
			$limit = 1;
		}
		else {
			$limit = scalar(@acrossdist);
		}
		for (my $i = 0; $i < $limit; $i ++) {
			my $same = 0;
			for (my $j = 0; $j < scalar(@acrossdist); $j ++) {
				if (($pair ne 'Adjacent' && $i != $j) || $pair eq 'Adjacent' && $i == $j - 1) {
					my $diff = 0;
					foreach my $otu1 (keys(%{$acrossdist[$j]})) {
						foreach my $otu2 (keys(%{$acrossdist[$j]})) {
							if ($otu1 ne $otu2) {
								if (exists($acrossdist[$j]->{$otu1}->{$otu2}) && exists($acrossdist[$i]->{$otu1}->{$otu2})) {
									if ($acrossdist[$j]->{$otu1}->{$otu2} != $acrossdist[$i]->{$otu1}->{$otu2}) {
										$diff = 1;
										last;
									}
								}
								else {
									&errorMessage(__LINE__, "Trees are not compatible.");
								}
							}
						}
						if ($diff) {
							last;
						}
					}
					if ($diff) {
						$output{$i + 1}{$j + 1} = 1;
					}
					else {
						$output{$i + 1}{$j + 1} = 0;
					}
				}
				elsif ($outformat eq 'Matrix' && $i == $j) {
					$output{$i + 1}{$j + 1} = 0;
				}
			}
		}
	}
	return(\%output);
}

# file format recognition
sub recognizeFormat {
	my $readfile = shift(@_);
	my $tempformat;
	$tempformat = 'Newick';
	unless (open(INFILE, "< $readfile")) {
		&errorMessage(__LINE__, "Cannot open \"$readfile\".");
	}
	while (<INFILE>) {
		if (/^#NEXUS/i) {
			$tempformat = 'NEXUS';
		}
		last;
	}
	close(INFILE);
	return($tempformat);
}

# read input file
sub readInputFile {
	my $readfile = shift(@_);
	my @dist;
	unless (open(INFILE, "< $readfile")) {
		&errorMessage(__LINE__, "Cannot open \"$readfile\".");
	}
	if ($format{$readfile} eq 'NEXUS') {
		my $treesblock = 0;
		my $translate = 0;
		my %table;
		while (<INFILE>) {
			if ($treesblock != 1 && /^\s*Begin\s+Trees\s*;/i) {
				$treesblock = 1;
			}
			elsif ($treesblock == 1 && /^\s*End\s*;/i) {
				$treesblock = 0;
			}
			elsif ($treesblock == 1 && $translate == 1) {
				if (/^\s*(\S+)\s+([^,;\s]+)\s*([,;])\s*\r?\n?$/) {
					$table{$1} = $2;
					if ($3 eq ';') {
						$translate = 0;
					}
				}
			}
			elsif ($treesblock == 1 && $translate == 0 && !%table && /^\s*Translate/i) {
				$translate = 1;
			}
			elsif ($treesblock == 1 && $translate == 0 && /\s*Tree\s*\S+\s*=\s*(?:\[[^\(\):]+\])?\s*(\(.+\))(?:\:0|\:0\.0)?;/i) {
				my $tree = $1;
				foreach my $from (keys(%table)) {
					$tree =~ s/([\(,])$from([:,\)])/$1$table{$from}$2/;
				}
				$tree =~ s/^\((.+)\)$/$1/;
				$tree =~ s/\)[^,:\)]+/)/g;
				$tree =~ s/:\d+\.?\d*(e\D?\d+)?//g;
				if ($rooted) {
					$tree .= ',ROOT';
				}
				push(@dist, &calcDistance($tree, $readfile));
			}
		}
	}
	else {
		local $/ = ";";
		while (<INFILE>) {
			if (/(\(.+\))(?:\:0|\:0\.0)?(?:\s*\[[\d\/\.]+\])?;/s) {
				my $tree = $1;
				$tree =~ s/^\((.+)\)$/$1/s;
				$tree =~ s/\s//sg;
				$tree =~ s/\)[^,:\)]+/)/sg;
				$tree =~ s/:\d+\.?\d*(e\D?\d+)?//sg;
				if ($rooted) {
					$tree .= ',ROOT';
				}
				push(@dist, &calcDistance($tree, $readfile));
			}
		}
	}
	close(INFILE);
	return(@dist);
}

sub calcDistance {
	my $tree = shift(@_);
	my $readfile = shift(@_);
	my %dist;
	my %brlensotu;
	my %brlensclade;
	my @otus = $tree =~ /[^,:\(\)]+/g;
	foreach my $otu (@otus) {
		$brlensotu{$otu} = 1;
	}
	{
		my $num = 0;
		while ($tree =~ s/\(([^:\(\)]+)\)/<$num>$1<\/$num>/) {
			$brlensclade{$num} = 1;
			$num++;
		}
	}
	if (!$rooted) {
		my $temptree = $tree;
		while ($temptree =~ s/<(\d+)>.*<(\d+)>.+<\/\2>.*<\/\1>/<$1>clade<\/$1>/) {}
		my @top = split(/,/, $temptree);
		if (scalar(@top) == 2) {
			foreach my $top (@top) {
				if ($top =~ /^<(\d+)>clade<\/\1>$/) {
					$brlensclade{$1} /= 2;
				}
				else {
					$brlensotu{$top} /= 2;
				}
			}
		}
	}
	while ($tree =~ s/(?:<\/?\d+>|,)*([^,<>\r\n]+),?//) {
		my $otu1 = $1;
		my $temptree = $tree;
		my @branches;
		while ($temptree =~ s/([^,<>\r\n]+|<\/?\d+>),?//) {
			my $temp = $1;
			if ($temp =~ /<(\d+)>/) {
				push(@branches, $1);
			} elsif ($temp =~ /<\/(\d+)>/) {
				if ($branches[-1] eq $1) {
					pop(@branches);
				} else {
					push(@branches, $1);
				}
			} elsif ($temp =~ /([^,<>\r\n]+)/) {
				my $sum;
				foreach (@branches) {
					$sum += $brlensclade{$_};
				}
				$dist{$otu1}{$1} = $brlensotu{$otu1} + $sum + $brlensotu{$1};
				$dist{$1}{$otu1} = $dist{$otu1}{$1};
			} else {
				&errorMessage(__LINE__, "\"$readfile\" is invalid tree file.");
			}
		}
	}
	return(\%dist);
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
pgcomptree options inputfile outputfile

Command line options
====================
-o, --output=Column|Matrix
  Specify the output file format. (default: Column)

-c, --compare=All|Top|Adjacent
  Specify comparing pair setting. (default: All)

-t, --treefile=FILENAME
  Specify the source tree file of comparison. (default: none)

-r, --rooted
  If this is specified, this program presumes that trees are rooted.
(default: Disabled)

Acceptable input file formats
=============================
Newick
NEXUS
PHYLIP
_END
	exit;
}
