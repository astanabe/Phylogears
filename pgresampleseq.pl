#
# pgresampleseq
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

# To do: multiple data sets

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgresampleseq $buildno
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

unless (@ARGV) {
	&helpMessage();
}

# initialize variables
my $nreps;
my $mode;
my $percent;
my $scale;
my $seed;
my $gen;
my $format;
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}

# get command line options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:r|nreps)=(\d+)$/i) {
		$nreps = $1;
	}
	elsif ($ARGV[$i] =~ /^-+(?:m|mode)=(.+)$/i) {
		unless ($mode) {
			if ($1 =~ /^bootstrap$/i) {
				$mode = 'bootstrap';
			}
			elsif ($1 =~ /^seqpermute$/i) {
				$mode = 'seqpermute';
			}
			elsif ($1 =~ /^charpermute$/i) {
				$mode = 'charpermute';
			}
			elsif ($1 =~ /^destroy1$/i) {
				$mode = 'destroy1';
			}
			elsif ($1 =~ /^destroy2$/i) {
				$mode = 'destroy2';
			}
			else {
				&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
			}
		}
		else {
			&errorMessage(__LINE__, "Resample mode is already specified.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:p|percent)=(\d+)$/i) {
		unless ($mode) {
			$mode = 'siteweighting';
			$percent = $1;
		}
		else {
			&errorMessage(__LINE__, "Resample mode is already specified.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:s|scale)=(\d+(?:\.\d+)?)$/i) {
		unless ($mode) {
			$mode = 'scaledbootstrap';
			$scale = $1;
		}
		else {
			&errorMessage(__LINE__, "Resample mode is already specified.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+seed=(\d+)$/i) {
		$seed = $1;
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}
unless ($nreps) {
	&errorMessage(__LINE__, "The number of replicates is not specified.");
}
unless ($mode) {
	$mode = 'bootstrap';
}
unless ($seed) {
	$seed = time^$$;
}

if ($outputfile !~ /^stdout$/i) {
	print("Seed was set to \"$seed\".\n");
}

# load module and initialize random number generator
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

# file format recognition
unless (open(INFILE, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}
{
	my $lineno = 1;
	while (<INFILE>) {
		if ($lineno == 1 && /^#NEXUS/i) {
			$format = 'NEXUS';
			last;
		}
		elsif ($lineno == 1 && /^\s*\d+\s+\d+\s*/) {
			$format = 'PHYLIP';
		}
		elsif ($lineno == 1 && /^>/) {
			$format = 'FASTA';
			last;
		}
		elsif ($lineno == 1) {
			$format = 'TF';
			last;
		}
		elsif ($lineno > 1 && /^\S{11,}\s+\S.*/) {
			$format = 'PHYLIPex';
		}
		$lineno ++;
	}
}
close(INFILE);

&readInputFile();

# read input file
sub readInputFile {
	my $ntax;
	my $nchar;
	my $nexusformat;
	my $taxnamelength = 0;
	my @taxa;
	my %part2site;
	my @site2part;
	my %seqs;
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	if ($format eq 'NEXUS') {
		my $datablock = 0;
		my $paupblock = 0;
		my $setsblock = 0;
		my $matrix = 0;
		while (<INFILE>) {
			s/\[.*\]//g;
			if ($datablock != 1 && $paupblock != 1 && $setsblock != 1 && /^\s*Begin\s+Data\s*;/i && $ntax && $nchar && @taxa && %seqs && $nexusformat) {
				&resampleSequence($ntax, $nchar, \@taxa, \%part2site, \@site2part, \%seqs, $taxnamelength, $nexusformat);
				undef($ntax);
				undef($nchar);
				undef(@taxa);
				undef(%part2site);
				undef(@site2part);
				undef(%seqs);
				undef($nexusformat);
				$taxnamelength = 0;
				$datablock = 1;
			}
			elsif ($datablock != 1 && $paupblock != 1 && $setsblock != 1 && /^\s*Begin\s+Data\s*;/i) {
				$datablock = 1;
			}
			elsif ($datablock == 2 && $paupblock != 1 && $setsblock != 1 && /^\s*Begin\s+PAUP\s*;/i) {
				$paupblock = 1;
			}
			elsif ($datablock == 2 && $paupblock != 1 && $setsblock != 1 && /^\s*Begin\s+Sets\s*;/i) {
				$setsblock = 1;
			}
			elsif ($datablock == 1 && /^\s*End\s*;/i) {
				$datablock = 2;
			}
			elsif ($paupblock == 1 || $setsblock == 1 && /^\s*End\s*;/i) {
				last;
			}
			elsif ($datablock == 1 && $matrix == 1 && /;/) {
				$matrix = 0;
			}
			elsif ($datablock == 1 && $matrix == 1) {
				if (/^\s*(\S+)\s+(\S.*?)\s*\r?\n?$/) {
					my $taxon = $1;
					my $seq = $2;
					unless ($seqs{$taxon}) {
						push(@taxa, $taxon);
					}
					my @seq = $seq =~ /\S/g;
					push(@{$seqs{$taxon}}, @seq);
				}
			}
			elsif ($datablock == 1 && $matrix == 0 && /^\s*Dimensions\s+/i) {
				if (/\s+NTax\s*=\s*(\d+)/i) {
					$ntax = $1;
				}
				if (/\s+NChar\s*=\s*(\d+)/i) {
					$nchar = $1;
				}
			}
			elsif ($datablock == 1 && $matrix == 0 && /^\s*(Format.+)\r?\n?/i) {
				$nexusformat = $1;
			}
			elsif ($datablock == 1 && $matrix == 0 && /^\s*Matrix/i) {
				$matrix = 1;
			}
			elsif ($paupblock == 1 || $setsblock == 1 && /^\s*CharSet\s+(\S+)\s*=\s*(\S.*?)\s*;/i) {
				my $partname = $1;
				my $tempsites = $2;
				my @tempsites;
				foreach my $sites (split(/\s+/, $tempsites)) {
					if ($sites =~ /^(\d+)\-(\d+)\\(\d+)$/) {
						push(@tempsites, &range2list($1, $2, $3));
					}
					elsif ($sites =~ /^(\d+)\-\.\\(\d+)$/) {
						push(@tempsites, &range2list($1, $nchar, $2));
					}
					elsif ($sites =~ /^(\d+)\-(\d+)$/) {
						if ($1 < $2) {
							push(@tempsites, $1 .. $2);
						}
						else {
							&errorMessage(__LINE__, 'Partition specification is not valid.');
						}
					}
					elsif ($sites =~ /^(\d+)\-\.$/) {
						if ($1 < $nchar) {
							push(@tempsites, $1 .. $nchar);
						}
						else {
							&errorMessage(__LINE__, 'Partition specification is not valid.');
						}
					}
					elsif ($sites =~ /^(\d+)$/) {
						push(@tempsites, $1);
					}
					else {
						&errorMessage(__LINE__, 'Partition specification is not valid.');
					}
				}
				if (@tempsites) {
					foreach my $siteno (@tempsites) {
						push(@{$part2site{$partname}}, $siteno);
						unless (defined($site2part[$siteno - 1])) {
							$site2part[$siteno - 1] = $partname;
						}
						else {
							&errorMessage(__LINE__, "Site $siteno is doubly specified.");
						}
					}
				}
				else {
					&errorMessage(__LINE__, 'Partition specification is not valid.');
				}
			}
		}
		if ($ntax && $nchar && @taxa && %seqs && $nexusformat) {
			&resampleSequence($ntax, $nchar, \@taxa, \%part2site, \@site2part, \%seqs, $taxnamelength, $nexusformat);
		}
	}
	elsif ($format eq 'PHYLIP' || $format eq 'PHYLIPex') {
		my $num;
		while (<INFILE>) {
			if (/^\s*(\d+)\s+(\d+)/ && defined($num) && $ntax && $nchar && @taxa && %seqs) {
				&resampleSequence($ntax, $nchar, \@taxa, \%part2site, \@site2part, \%seqs, $taxnamelength, $nexusformat);
				undef($ntax);
				undef($nchar);
				undef(@taxa);
				undef(%part2site);
				undef(@site2part);
				undef(%seqs);
				undef($nexusformat);
				$taxnamelength = 0;
				$ntax = $1;
				$nchar = $2;
				$num = 0;
			}
			elsif (/^\s*(\d+)\s+(\d+)/) {
				$ntax = $1;
				$nchar = $2;
				$num = 0;
			}
			else {
				if ($num < $ntax) {
					if ($format eq 'PHYLIP' && /^(..........)\s*(\S.*?)\s*\r?\n?$/ || $format eq 'PHYLIPex' && /^(\S+)\s+(\S.*?)\s*\r?\n?$/) {
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
		if ($ntax && $nchar && @taxa && %seqs) {
			&resampleSequence($ntax, $nchar, \@taxa, \%part2site, \@site2part, \%seqs, $taxnamelength, $nexusformat);
		}
	}
	elsif ($format eq 'FASTA') {
		&errorMessage(__LINE__, "Input file format is \"FASTA\". But this script is not compatible to \"FASTA\" format.");
	}
	elsif ($format eq 'TF') {
		while (<INFILE>) {
			if (/^\"([^\"]+)\"\s*([\d\s]+)\r?\n?$/) {
				my $partname = $1;
				my $sites = $2;
				my @sites = $sites =~ /\d/g;
				push(@{$part2site{$partname}}, @sites);
			}
			elsif (/^\"([^\"]+)\"\s*(\S.*?)\s*\r?\n?$/) {
				my $taxon = $1;
				my $seq = $2;
				unless ($seqs{$taxon}) {
					push(@taxa, $taxon);
				}
				my @seq = $seq =~ /\S/g;
				push(@{$seqs{$taxon}}, @seq);
			}
			if (/\% end of data\r?\n?$/) {
				$ntax = scalar(@taxa);
				$nchar = scalar(@{$seqs{$taxa[0]}});
				foreach my $partname (keys(%part2site)) {
					if (scalar(@{$part2site{$partname}}) != $nchar) {
						&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
					}
					if ($taxnamelength < length($partname)) {
						$taxnamelength = length($partname);
					}
				}
				&resampleSequence($ntax, $nchar, \@taxa, \%part2site, \@site2part, \%seqs, $taxnamelength, $nexusformat);
				undef($ntax);
				undef($nchar);
				undef(@taxa);
				undef(%part2site);
				undef(@site2part);
				undef(%seqs);
				undef($nexusformat);
				$taxnamelength = 0;
			}
		}
		if (@taxa && %seqs) {
			$ntax = scalar(@taxa);
			$nchar = scalar(@{$seqs{$taxa[0]}});
			foreach my $partname (keys(%part2site)) {
				if (scalar(@{$part2site{$partname}}) != $nchar) {
					&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
				}
				if ($taxnamelength < length($partname)) {
					$taxnamelength = length($partname);
				}
			}
			&resampleSequence($ntax, $nchar, \@taxa, \%part2site, \@site2part, \%seqs, $taxnamelength, $nexusformat);
		}
	}
	close(INFILE);
}

sub resampleSequence {
	my $ntax = shift(@_);
	my $nchar = shift(@_);
	my @taxa = @{shift(@_)};
	my %part2site = %{shift(@_)};
	my @site2part = @{shift(@_)};
	my %seqs = %{shift(@_)};
	my $taxnamelength = shift(@_);
	my $nexusformat = shift(@_);
	# check data
	if (scalar(@taxa) != $ntax) {
		&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
	}
	foreach my $taxon (@taxa) {
		if (scalar(@{$seqs{$taxon}}) != $nchar) {
			&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
		}
		if ($format ne 'FASTA' && $taxnamelength < length($taxon)) {
			$taxnamelength = length($taxon);
		}
	}
	if (@site2part) {
		if (scalar(@site2part) != $nchar) {
			&errorMessage(__LINE__, 'Partition specification is not valid.');
		}
	}
	my $addnchar = 0;
	my $outputnchar = $nchar;
	if ($percent) {
		$addnchar = int($nchar * ($percent / 100) + 0.5);
		$outputnchar = $nchar + $addnchar;
	}
	elsif ($scale) {
		$outputnchar = int($nchar * $scale + 0.5);
	}

	# resampling
	my $filehandle;
	if ($outputfile =~ /^stdout$/i) {
		unless (open($filehandle, '>-')) {
			&errorMessage(__LINE__, "Cannot write STDOUT.");
		}
	}
	else {
		unless (open($filehandle, ">> $outputfile")) {
			&errorMessage(__LINE__, "Cannot write \"$outputfile\".");
		}
	}
	if ($format eq 'NEXUS') {
		print($filehandle "#NEXUS\n");
		print($filehandle "[seed = $seed]\n");
	}
	elsif ($format eq 'TF') {
		print($filehandle "% seed = $seed\n");
	}
	foreach my $repno (1 .. $nreps) {
		my @boot;
		my $nsample;
		if ($percent) {
			$nsample = $addnchar;
		}
		else {
			$nsample = $outputnchar;
		}
		if ($mode eq 'bootstrap' || $mode eq 'siteweighting' || $mode eq 'scaledbootstrap') {
			foreach (1 .. $nsample) {
				push(@boot, int($gen->rand($nchar)));
			}
		}
		elsif ($mode eq 'charpermute') {
			my @site = 0 .. ($nchar - 1);
			while (@site) {
				my $site = splice(@site, int($gen->rand(scalar(@site))), 1);
				push(@boot, $site);
			}
		}
		elsif ($mode eq 'destroy1') {
			foreach my $site (0 .. ($nchar - 1)) {
				my @taxonno = 0 .. (scalar(@taxa) - 1);
				while (@taxonno) {
					my $taxonno = splice(@taxonno, int($gen->rand(scalar(@taxonno))), 1);
					push(@{$boot[$site]}, $taxonno);
				}
			}
		}
		if ($format eq 'NEXUS') {
			print($filehandle "\nBegin Data;\n\tDimensions NTax=$ntax NChar=$outputnchar;\n\t$nexusformat\n\tMatrix\n");
		}
		elsif ($format eq 'PHYLIP' || $format eq 'PHYLIPex') {
			print($filehandle $ntax . ' ' . $outputnchar . "\n");
		}
		elsif ($format eq 'TF' && %part2site) {
			foreach my $partname (keys(%part2site)) {
				printf($filehandle "%-*s ", $taxnamelength + 2, '"' . $partname . '"');
				if ($mode eq 'siteweighting' || $mode eq 'seqpermute' || $mode eq 'charpermute' || $mode eq 'destroy1' || $mode eq 'destroy2') {
					print($filehandle join('', @{$part2site{$partname}}));
				}
				if ($mode eq 'bootstrap' || $mode eq 'siteweighting' || $mode eq 'scaledbootstrap') {
					foreach my $site (@boot) {
						print($filehandle $part2site{$partname}[$site]);
					}
				}
				print($filehandle "\n");
			}
		}
		my @temptaxa = @taxa;
		while (@temptaxa) {
			my $taxon = splice(@temptaxa, int($gen->rand(scalar(@temptaxa))), 1);
			if ($format eq 'NEXUS' || $format eq 'PHYLIPex') {
				printf($filehandle "%-*s ", $taxnamelength, $taxon);
			}
			elsif ($format eq 'PHYLIP') {
				print($filehandle $taxon . ' ');
			}
			elsif ($format eq 'TF') {
				printf($filehandle "%-*s ", $taxnamelength + 2, '"' . $taxon . '"');
			}
			if ($mode eq 'siteweighting' || $mode eq 'seqpermute') {
				print($filehandle join('', @{$seqs{$taxon}}));
			}
			elsif ($mode eq 'destroy2') {
				my @sites = @{$seqs{$taxon}};
				while (@sites) {
					print($filehandle splice(@sites, int($gen->rand(scalar(@sites))), 1));
				}
			}
			if ($mode eq 'bootstrap' || $mode eq 'charpermute' || $mode eq 'siteweighting' || $mode eq 'scaledbootstrap') {
				foreach my $site (@boot) {
					print($filehandle $seqs{$taxon}[$site]);
				}
			}
			elsif ($mode eq 'destroy1') {
				foreach my $site (0 .. ($nchar - 1)) {
					print($filehandle $seqs{$taxa[shift(@{$boot[$site]})]}[$site]);
				}
			}
			print($filehandle "\n");
		}
		if ($format eq 'NEXUS') {
			print($filehandle "\t;\nEnd;\n");
			if (%part2site) {
				my %partition;
				if ($mode eq 'bootstrap' || $mode eq 'siteweighting' || $mode eq 'scaledbootstrap') {
					my $siteno;
					if ($mode eq 'siteweighting') {
						$siteno = $nchar + 1;
					}
					else {
						$siteno = 1;
					}
					foreach my $site (@boot) {
						push(@{$partition{$site2part[$site]}}, $siteno);
						$siteno ++;
					}
				}
				print($filehandle "Begin Sets;\n");
				foreach my $partname (keys(%part2site)) {
					print($filehandle "\tCharSet $partname=");
					if ($mode eq 'siteweighting' || $mode eq 'seqpermute' || $mode eq 'charpermute' || $mode eq 'destroy1' || $mode eq 'destroy2') {
						print($filehandle join(' ', @{$part2site{$partname}}));
					}
					if ($mode eq 'siteweighting') {
						print($filehandle ' ');
					}
					if ($mode eq 'bootstrap' || $mode eq 'siteweighting' || $mode eq 'scaledbootstrap') {
						print($filehandle join(' ', @{$partition{$partname}}));
					}
					print($filehandle ";\n");
				}
				print($filehandle "End;\n");
			}
		}
		else {
			if ($format eq 'TF') {
				print($filehandle "% end of data\n");
			}
			print($filehandle "\n");
		}
	}
	close($filehandle);
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
pgresampleseq options inputfile outputfile

Command line options
====================
-r, --nreps=INTEGER
  Specify the number of replicates. (default: none)

-m, --mode=Bootstrap|SeqPermute|CharPermute|Destroy1|Destroy2
  Specify resampling mode. (default: Bootstrap)

-p, --percent=INTEGER
  Specify the number of percentages for random site weighting.
(default: 0)

-s, --scale=DECIMAL
  Specify scaling factor for scaled bootstrap. (default: 1.0)

--seed=INTEGER
  Specify seed number. (default: auto)

Acceptable input file formats
=============================
NEXUS
PHYLIP
TF (Treefinder)
(Character partition settings in NEXUS and TF are used for partitioned
 bootstrap resampling.)
_END
	exit;
}
