my $buildno = '2.0.2016.04.14';
#
# pgacrosstreedist
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

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgacrosstreedist $buildno
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
my $format = 'Newick';
my $outformat = 'Column';
my $root = 0;
my $repno = 1;

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
	elsif ($ARGV[$i] =~ /^-+(?:r|root)$/i) {
		$root = 1;
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}

# file format recognition
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
while (<INFILE>) {
	if (/^#NEXUS/i) {
		$format = 'NEXUS';
		last;
	}
	elsif (/Phylogeny->\{/) {
		$format = 'TLReport';
		last;
	}
}
close(INFILE);

&readInputFile();

# read input file
sub readInputFile {
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	if ($format eq 'NEXUS') {
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
				if ($root) {
					$tree .= ',ROOT:0';
				}
				&calcDistance($tree);
			}
		}
	}
	elsif ($format eq 'TLReport') {
		while (<INFILE>) {
			if (/Phylogeny->(.+)/) {
				my $temp = $1;
				my $tree;
				my $brace;
				foreach (1 .. length($temp)) {
					my $char = substr($temp, 0, 1, '');
					$tree .= $char;
					if ($char eq '{') {
						$brace ++;
					}
					elsif ($char eq '}') {
						$brace --;
					}
					if (defined($brace) && $brace == 0) {
						last;
					}
				}
				$tree =~ tr/\{\}"/()/d;
				$tree =~ s/(:[^:,\(\)]+):[^:,\(\)]+/$1/g;
				$tree =~ s/^\((.+)\)$/$1/;
				if ($root) {
					$tree .= ',ROOT:0';
				}
				&calcDistance($tree);
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
				if ($root) {
					$tree .= ',ROOT:0';
				}
				&calcDistance($tree);
			}
		}
	}
	close(INFILE);
}

sub calcDistance {
	my $tree = shift(@_);
	my %dist;
	my %brlensotu;
	my %brlensclade;
	my @otus;
	$tree =~ s/\)[^,:\)]+/)/g;
	if ($tree =~ /:\d+\.?\d*(e\D?\d+)?/) {
		while ($tree =~ s/([^,:\(\)]+):(\d+\.?\d*)(e\D?\d+)?/$1/) {
			my $otu = $1;
			my $temp1 = $2;
			$temp1 =~ s/\.$//;
			if ($3 =~ /e(\D)?0*(\d+)/) {
				my $temp2 = $2;
				if ($1 eq '-') {
					$temp1 *= 10 ** ((-1) * $temp2);
				} else {
					$temp1 *= 10 ** $temp2;
				}
			}
			$brlensotu{$otu} = $temp1;
			push(@otus, $otu);
		}
		my $num = 0;
		while ($tree =~ s/\(([^:\(\)]+)\):(\d+\.?\d*)(e\D?\d+)?/<$num>$1<\/$num>/) {
			my $temp1 = $2;
			$temp1 =~ s/\.$//;
			if ($3 =~ /e(\D)?0*(\d+)/) {
				my $temp2 = $2;
				if ($1 eq '-') {
					$temp1 *= 10 ** ((-1) * $temp2);
				} else {
					$temp1 *= 10 ** $temp2;
				}
			}
			$brlensclade{$num} = $temp1;
			$num++;
		}
	}
	else {
		@otus = $tree =~ /[^,:\(\)]+/g;
		foreach my $otu (@otus) {
			$brlensotu{$otu} = 1;
		}
		my $num = 0;
		while ($tree =~ s/\(([^:\(\)]+)\)/<$num>$1<\/$num>/) {
			$brlensclade{$num} = 1;
			$num++;
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
				&errorMessage(__LINE__, "\"$inputfile\" is invalid tree file.");
			}
		}
	}
	my $filehandle;
	if ($outputfile =~ /^stdout$/i) {
		unless (open($filehandle, ">-")) {
			&errorMessage(__LINE__, "Cannot write STDOUT.");
		}
	}
	else {
		unless (open($filehandle, ">> $outputfile")) {
			&errorMessage(__LINE__, "Cannot make \"$outputfile\".");
		}
	}
	if ($outformat eq 'Matrix') {
		print($filehandle $repno);
		foreach my $otu (@otus) {
			print($filehandle "\t$otu");
		}
		print($filehandle "\n");
		foreach my $otu1 (@otus) {
			print($filehandle $otu1);
			foreach my $otu2 (@otus) {
				if ($otu1 eq $otu2) {
					print($filehandle "\t0");
				}
				elsif (exists($dist{$otu1}{$otu2})) {
					print($filehandle "\t$dist{$otu1}{$otu2}");
				}
				else {
					&errorMessage(__LINE__, "\"$inputfile\" is invalid tree file.");
				}
			}
			print($filehandle "\n");
		}
		print($filehandle "\n");
	}
	else {
		if ($repno == 1) {
			print($filehandle "replicate\tfrom\tto\tdistance\n");
		}
		foreach my $otu1 (@otus) {
			foreach my $otu2 (@otus) {
				if ($otu1 ne $otu2) {
					if (exists($dist{$otu1}{$otu2})) {
						print($filehandle "rep$repno\t$otu1\t$otu2\t$dist{$otu1}{$otu2}\n");
					}
					else {
						&errorMessage(__LINE__, "\"$inputfile\" is invalid tree file.");
					}
				}
			}
		}
	}
	close($filehandle);
	$repno ++;
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
pgacrosstreedist options inputfile outputfile

Command line options
====================
-o, --output=Column|Matrix
  Specify the output file format. (default: Column)

-r, --root
  Output root-to-tip distances if this is specified.
(default: Disabled)

Acceptable input file formats
=============================
Newick
NEXUS
PHYLIP
TL Report
_END
	exit;
}
