my $buildno = '2.0.x';
#
# pgconvseq
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

# To do: single data set

use strict;

my $outputfile = $ARGV[-1];
if ($outputfile !~ /^stdout$/i) {
	print(<<"_END");
pgconvseq $buildno
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
}

# display usage if command line options were not specified
unless (@ARGV) {
	&helpMessage();
}

# initialize variables
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "\"$outputfile\" already exists.");
}
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}
my $format;
my $outformat;
my $numdataset = 0;
my $single = 0;

# check options
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:o|output)=(.+)$/i) {
		my $outoption = $1;
		if ($outoption =~ /^FASTA$/i) {
			unless ($outformat) {
				$outformat = 'FASTA';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^NEXUS$/i) {
			unless ($outformat) {
				$outformat = 'NEXUS';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^PHYLIP$/i) {
			unless ($outformat) {
				$outformat = 'PHYLIP';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^PHYLIPex$/i) {
			unless ($outformat) {
				$outformat = 'PHYLIPex';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^TF$/i) {
			unless ($outformat) {
				$outformat = 'TF';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:s|single)$/i) {
		$single = 1;
	}
	else {
		&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
	}
}
unless ($outformat) {
	&errorMessage(__LINE__, 'Output option is not specified.');
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
	my @taxa;
	my @seqs;
	my $ntax;
	my $nchar;
	my $nexusformat;
	unless (open(INFILE, "< $inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
	}
	if ($format eq 'NEXUS') {
		my $datablock = 0;
		my $paupblock = 0;
		my $setsblock = 0;
		my $matrix = 0;
		my $seqno = 0;
		my %taxa;
		my $partno = 0;
		my @partname;
		my %partname;
		my @partition;
		while (<INFILE>) {
			s/\[.*\]//g;
			if ($datablock != 1 && $paupblock != 1 && $setsblock != 1 && /^\s*Begin\s+Data\s*;/i && $ntax && $nchar && $nexusformat && @taxa && @seqs) {
				&makeOutputFile($ntax, $nchar, $nexusformat, \@taxa, \@seqs, \@partname, \@partition);
				undef($ntax);
				undef($nchar);
				undef($nexusformat);
				undef(@taxa);
				undef(@seqs);
				undef(%taxa);
				undef(@partname);
				undef(%partname);
				undef(@partition);
				$datablock = 1;
			}
			elsif ($datablock != 1 && $paupblock != 1 && $setsblock != 1 && /^\s*Begin\s+Data\s*;/i) {
				$datablock = 1;
			}
			elsif ($datablock != 1 && $paupblock != 1 && $setsblock != 1 && /^\s*Begin\s+PAUP\s*;/i) {
				$paupblock = 1;
			}
			elsif ($datablock != 1 && $paupblock != 1 && $setsblock != 1 && /^\s*Begin\s+Sets\s*;/i) {
				$setsblock = 1;
			}
			elsif ($datablock == 1 && /^\s*End\s*;/i) {
				$datablock = 0;
				$matrix = 0;
				$seqno = 0;
				$partno = 0;
			}
			elsif ($paupblock == 1 && /^\s*End\s*;/i) {
				$paupblock = 0;
			}
			elsif ($setsblock == 1 && /^\s*End\s*;/i) {
				$setsblock = 0;
			}
			elsif ($datablock == 1 && $matrix == 1 && /;/) {
				$matrix = 0;
			}
			elsif ($datablock == 1 && $matrix == 1) {
				if (/^\s*(\S+)\s+(\S.*?)\s*\r?\n?$/) {
					my $taxon = $1;
					my $seq = $2;
					unless (defined($taxa{$taxon})) {
						push(@taxa, $taxon);
						$taxa{$taxon} = $seqno;
						$seqno ++;
					}
					my @seq = $seq =~ /\S/g;
					$seqs[$taxa{$taxon}] .= join('', @seq);
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
				unless (defined($partname{$partname})) {
					push(@partname, $partname);
					$partname{$partname} = $partno;
					$partno ++;
				}
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
					my %tempsites;
					foreach my $siteno (sort({$a <=> $b} @tempsites)) {
						unless (defined($tempsites{$siteno})) {
							$partition[$partname{$partname}] .= $siteno . ' ';
							$tempsites{$siteno} = 1;
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
		if ($ntax && $nchar && $nexusformat && @taxa && @seqs) {
			&makeOutputFile($ntax, $nchar, $nexusformat, \@taxa, \@seqs, \@partname, \@partition);
		}
	}
	elsif ($format eq 'PHYLIP' || $format eq 'PHYLIPex') {
		my $num;
		while (<INFILE>) {
			if (/^\s*(\d+)\s+(\d+)/ && defined($num)) {
				&makeOutputFile($ntax, $nchar, $nexusformat, \@taxa, \@seqs);
				undef($nexusformat);
				undef(@taxa);
				undef(@seqs);
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
						$taxon =~ s/\s//g;
						push(@taxa, $taxon);
						my @seq = $seq =~ /\S/g;
						$seqs[$num] .= join('', @seq);
						$num ++;
					}
				}
				else {
					if (/^\s+(\S.*?)\s*\r?\n?$/) {
						my $seq = $1;
						my @seq = $seq =~ /\S/g;
						$seqs[$num % $ntax] .= join('', @seq);
						$num ++;
					}
				}
			}
		}
		if ($ntax && $nchar && @taxa && @seqs) {
			&makeOutputFile($ntax, $nchar, $nexusformat, \@taxa, \@seqs);
		}
	}
	elsif ($format eq 'FASTA') {
		my $taxon;
		my %taxa;
		while (<INFILE>) {
			if (/^>\s*(\S.*?)\s*\r?\n?$/) {
				$taxon = $1;
				if ($taxa{$taxon}) {
					$ntax = scalar(@taxa);
					foreach my $seqs (@seqs) {
						if ($nchar < length($seqs)) {
							$nchar = length($seqs);
						}
					}
					&makeOutputFile($ntax, $nchar, $nexusformat, \@taxa, \@seqs);
					undef($ntax);
					undef($nchar);
					undef($nexusformat);
					undef(@taxa);
					undef(@seqs);
					undef(%taxa);
				}
				$taxa{$taxon} = 1;
				push(@taxa, $taxon);
			}
			elsif ($taxon) {
				my @seq = $_ =~ /\S/g;
				$seqs[scalar(@taxa) - 1] .= join('', @seq);
			}
		}
		if (@taxa && @seqs) {
			$ntax = scalar(@taxa);
			foreach my $seqs (@seqs) {
				if ($nchar < length($seqs)) {
					$nchar = length($seqs);
				}
			}
			&makeOutputFile($ntax, $nchar, $nexusformat, \@taxa, \@seqs);
		}
	}
	elsif ($format eq 'TF') {
		my $seqno = 0;
		my $partno = 0;
		my %taxa;
		my @partname;
		my %partname;
		my @partition;
		while (<INFILE>) {
			if (/^\"([^\"]+)\"\s*([\d\s]+)\r?\n?$/) {
				my $partname = $1;
				my $sites = $2;
				unless (defined($partname{$partname})) {
					push(@partname, $partname);
					$partname{$partname} = $partno;
					$partno ++;
				}
				my @sites = $sites =~ /\d/g;
				$partition[$partname{$partname}] = join('', @sites);
			}
			elsif (/^\"([^\"]+)\"\s*(\S.*?)\s*\r?\n?$/i) {
				my $taxon = $1;
				my $seq = $2;
				unless (defined($taxa{$taxon})) {
					push(@taxa, $taxon);
					$taxa{$taxon} = $seqno;
					$seqno ++;
				}
				my @seq = $seq =~ /\S/g;
				$seqs[$taxa{$taxon}] .= join('', @seq);
			}
			if (/\% end of data\r?\n?$/) {
				$ntax = scalar(@taxa);
				$nchar = length($seqs[0]);
				&makeOutputFile($ntax, $nchar, $nexusformat, \@taxa, \@seqs, \@partname, \@partition);
				undef($ntax);
				undef($nchar);
				undef($nexusformat);
				undef(@taxa);
				undef(@seqs);
				undef(%taxa);
				undef(@partname);
				undef(%partname);
				undef(@partition);
				$seqno = 0;
				$partno = 0;
			}
		}
		if (@taxa && @seqs) {
			$ntax = scalar(@taxa);
			$nchar = length($seqs[0]);
			&makeOutputFile($ntax, $nchar, $nexusformat, \@taxa, \@seqs, \@partname, \@partition);
		}
	}
	close(INFILE);
}

sub makeOutputFile {
	$numdataset ++;
	my $ntax = shift(@_);
	my $nchar = shift(@_);
	my $nexusformat = shift(@_);
	my @taxa = @{shift(@_)};
	my @seqs = @{shift(@_)};
	my @partname;
	{
		my $temp = shift(@_);
		if ($temp) {
			@partname = @{$temp};
		}
	}
	my @partition;
	{
		my $temp = shift(@_);
		if ($temp) {
			@partition = @{$temp};
		}
	}
	# check data
	if (scalar(@taxa) != scalar(@seqs) || scalar(@taxa) != $ntax) {
		&errorMessage(__LINE__, "Input file is invalid.");
	}
	if ($format ne 'FASTA' || $outformat ne 'FASTA') {
		for (my $i = 0; $i < scalar(@seqs); $i ++) {
			if (length($seqs[$i]) != $nchar) {
				&errorMessage(__LINE__, "\"$inputfile\" is not valid.");
			}
		}
	}
	my $maxlength;
	my $taxnamelength;
	my %replace;
	if ($outformat ne 'FASTA') {
		foreach my $seqs (@seqs) {
			if ($maxlength < length($seqs)) {
				$maxlength = length($seqs);
			}
		}
		foreach my $taxon (@taxa) {
			if ($taxnamelength < length($taxon)) {
				$taxnamelength = length($taxon);
			}
		}
		for (my $i = 0; $i < scalar(@seqs); $i ++) {
			while ($maxlength > length($seqs[$i])) {
				$seqs[$i] .= '?';
			}
		}
	}
	if ($outformat ne 'PHYLIP' && $format eq 'PHYLIP' && -e "$inputfile.table") {
		unless (open(INFILE, "< $inputfile.table")) {
			&errorMessage(__LINE__, "Cannot read \"$inputfile.table\".");
		}
		while (<INFILE>) {
			if (/^(..........) \"(.+)\"\r?\n?$/) {
				my $taxon = $1;
				my $temp = $2;
				$taxon =~ s/\s//g;
				$replace{$taxon} = $temp;
			}
		}
		close(INFILE);
	}
	elsif ($outformat eq 'PHYLIP' && $taxnamelength > 10 && $outputfile !~ /^stdout$/i) {
		print("Sequence names are too long for PHYLIP format.\nSequence names will be replace and table file will be output.\n");
		my $temp = 1;
		foreach my $taxon (@taxa) {
			$replace{$taxon} = "Tax$temp";
			$temp ++;
		}
		if ($numdataset == 1) {
			if (-e "$outputfile.table") {
				&errorMessage(__LINE__, "\"$outputfile.table\" already exists.");
			}
			unless (open(OUTFILE, "> $outputfile.table")) {
				&errorMessage(__LINE__, "Cannot make \"$outputfile.table\".");
			}
			foreach my $taxon (@taxa) {
				printf(OUTFILE "%-10s ", $replace{$taxon});
				print(OUTFILE "\"$taxon\"\n");
			}
			close(OUTFILE);
		}
	}
	elsif ($outformat eq 'PHYLIP' && $taxnamelength > 10 && $outputfile =~ /^stdout$/i) {
		&errorMessage(__LINE__, "Sequence names are too long to output to STDOUT.");
	}
	foreach my $taxon (@taxa) {
		unless ($replace{$taxon}) {
			$replace{$taxon} = $taxon;
		}
	}
	if ($outformat eq 'TF') {
		if ($format eq 'NEXUS') {
			my @temppartition;
			my $partnumlength = length(scalar(@partition));
			for (my $i = 0; $i < scalar(@partition); $i ++) {
				foreach my $siteno (split(' ', $partition[$i])) {
					if ($siteno) {
						my @num = split('', sprintf("%0*d", $partnumlength, $i + 1));
						for (my $j = 0; $j < scalar(@num); $j ++) {
							$temppartition[$j][$siteno - 1] .= $num[$j];
						}
					}
				}
			}
			undef(@partname);
			undef(@partition);
			for (my $i = 0; $i < scalar(@temppartition); $i ++) {
				push(@partname, 'part' . ($i + 1));
				$partition[$i] = join('', @{$temppartition[$i]});
			}
		}
		foreach my $partname (@partname) {
			if ($taxnamelength < length($partname)) {
				$taxnamelength = length($partname);
			}
		}
		for (my $i = 0; $i < scalar(@partition); $i ++) {
			if (length($partition[$i]) != $nchar) {
				&errorMessage(__LINE__, 'Partition specification is not valid.');
			}
		}
	}
	elsif ($outformat eq 'NEXUS') {
		unless ($nexusformat) {
			my $datatype;
			foreach my $seqs (@seqs) {
				if ($seqs =~ /^[ACGTMRWSYKVHDBN\?\-]+$/i) {
					$datatype = 'DNA';
				}
				elsif ($seqs =~ /^[ACGUMRWSYKVHDBN\?\-]+$/i) {
					$datatype = 'RNA';
				}
				elsif ($seqs =~ /^[ARNDCQEGHILKMFPOSUTWYVBZXJ\*\?\-]+$/i) {
					$datatype = 'Protein';
				}
				else {
					$datatype = 'Standard';
				}
			}
			$nexusformat = "Format DataType=$datatype Gap=- Missing=?;";
		}
		if ($format eq 'TF') {
			my %temp;
			{
				undef(@partname);
				my @temppartname;
				foreach my $siteno (1 .. $nchar) {
					my $temp = 'part';
					for (my $i = 0; $i < scalar(@partition); $i ++) {
						$temp .= substr($partition[$i], $siteno - 1, 1);
					}
					unless (defined($temp{$temp})) {
						push(@temppartname, $temp);
					}
					$temp{$temp} .= $siteno . ' ';
				}
				@partname = @temppartname;
			}
			undef(@partition);
			for (my $i = 0; $i < scalar(@partname); $i ++) {
				push(@partition, $temp{$partname[$i]});
			}
		}
	}
	# output processed sequence file
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
	if ($outformat eq 'NEXUS') {
		print($filehandle "#NEXUS\n\nBegin Data;\n\tDimensions NTax=$ntax NChar=$maxlength;\n\t$nexusformat\n\tMatrix\n");
	}
	elsif ($outformat eq 'PHYLIP' || $outformat eq 'PHYLIPex') {
		print($filehandle $ntax . ' ' . $maxlength . "\n");
	}
	elsif ($outformat eq 'TF' && @partname > 1 && @partition > 1) {
		for (my $i = 0; $i < scalar(@partname); $i ++) {
			printf($filehandle "%-*s ", $taxnamelength + 2, '"' . $partname[$i] . '"');
			print($filehandle $partition[$i]);
			print($filehandle "\n");
		}
	}
	for (my $i = 0; $i < scalar(@taxa); $i ++) {
		if ($outformat eq 'NEXUS' || $outformat eq 'PHYLIPex') {
			printf($filehandle "%-*s  ", $taxnamelength, $replace{$taxa[$i]});
		}
		elsif ($outformat eq 'PHYLIP') {
			printf($filehandle "%-10s  ", $replace{$taxa[$i]});
		}
		elsif ($outformat eq 'FASTA') {
			print($filehandle ">$replace{$taxa[$i]}\n");
		}
		elsif ($outformat eq 'TF') {
			printf($filehandle "%-*s ", $taxnamelength + 2, '"' . $replace{$taxa[$i]} . '"');
		}
		print($filehandle $seqs[$i]);
		print($filehandle "\n");
	}
	if ($outformat eq 'NEXUS') {
		print($filehandle "\t;\nEnd;\n");
		if (@partname > 1 && @partition > 1) {
			print($filehandle "Begin Sets;\n");
			for (my $i = 0; $i < scalar(@partname); $i ++) {
				$partition[$i] =~ s/ $//;
				print($filehandle "\tCharSet $partname[$i]=");
				print($filehandle $partition[$i]);
				print($filehandle ";\n");
			}
			print($filehandle "End;\n");
		}
	}
	else {
		if ($outformat eq 'TF') {
			print($filehandle "% end of data\n");
		}
		print($filehandle "\n");
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
pgconvseq options inputfile outputfile

Command line options
====================
-o, --output=FASTA|NEXUS|PHYLIP|PHYLIPex|TF
  Specify output file format.

-s, --single
  Specify if you have trouble to convert interleaved single data set.

Acceptable input file formats
=============================
FASTA
NEXUS
PHYLIP
TF (Treefinder)
_END
	exit;
}
