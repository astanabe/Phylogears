my $buildno = '2.0.2016.04.14';
use strict;
use LWP::UserAgent;

print(STDERR <<"_END");
pgretrieveseq $buildno
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

# display usage if command line options were not specified
unless (@ARGV) {
	&helpMessage();
}

# get output file name
my $outputfile = $ARGV[-1];
# check output file
if ($outputfile !~ /^stdout$/i && -e $outputfile) {
	&errorMessage(__LINE__, "Output file already exists.");
}
my $inputfile = $ARGV[-2];
unless (-e $inputfile) {
	&errorMessage(__LINE__, "\"$inputfile\" does not exist.");
}

# get other arguments
my $timeout = 300;
my $outformat;
my $database;
for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
	if ($ARGV[$i] =~ /^-+(?:timeout|t)=(\d+)$/i) {
		$timeout = $1;
	}
	elsif ($ARGV[$i] =~ /^-+(?:o|output)=(.+)$/i) {
		my $outoption = $1;
		if ($outoption =~ /^(?:GenBank|gb)$/i) {
			unless ($outformat) {
				$outformat = 'gb';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^FASTA$/i) {
			unless ($outformat) {
				$outformat = 'fasta';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
	elsif ($ARGV[$i] =~ /^-+(?:db|database)=(.+)$/i) {
		my $outoption = $1;
		if ($outoption =~ /^(?:Nucleotide|nuccore|nuc)$/i) {
			unless ($database) {
				$database = 'nuccore';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^(?:Protein|pro)$/i) {
			unless ($database) {
				$database = 'protein';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^(?:EST|nucest)$/i) {
			unless ($database) {
				$database = 'nucest';
			}
			else {
				&errorMessage(__LINE__, 'Output option is doubly specified.');
			}
		}
		elsif ($outoption =~ /^(?:GSS|nucgss)$/i) {
			unless ($database) {
				$database = 'nucgss';
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
		&errorMessage(__LINE__, "Invalid option.");
	}
}
unless ($outformat) {
	$outformat = 'gb';
}
unless ($database) {
	$database = 'nuccore';
}

# open input file
my $inputhandle;
unless (open($inputhandle, "< $inputfile")) {
	&errorMessage(__LINE__, "Cannot open \"$inputfile\".");
}

print(STDERR "Downloading sequences...");
my $ua = LWP::UserAgent->new;
$ua->timeout($timeout);
$ua->agent('pgretrieveseq/prerelease');
$ua->env_proxy;
my $baseurl = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=$database&retmode=text&rettype=$outformat&id=";
my $numid = 0;
my @ids;
while (<$inputhandle>) {
	s/\r?\n?$//;
	if (/^ *(\d+) *$/) {
		push(@ids, $1);
		$numid ++;
	}
	if (scalar(@ids) >= 100) {
		my $req = HTTP::Request->new(POST => $baseurl . join(',', @ids));
		my $res = $ua->request($req);
		if ($res->is_success) {
			my $outputhandle;
			if ($outputfile =~ /^stdout$/i) {
				unless (open($outputhandle, '>-')) {
					&errorMessage(__LINE__, "Cannot write STDOUT.");
				}
			}
			else {
				unless (open($outputhandle, ">> $outputfile")) {
					&errorMessage(__LINE__, "Cannot write \"$outputfile\".");
				}
			}
			foreach (split(/\n/,$res->content)) {
				unless (/^ *\r?\n?$/) {
					print($outputhandle "$_\n");
				}
			}
			close($outputhandle);
		}
		else {
			&errorMessage(__LINE__, "Cannot search at NCBI.\nError status: " . $res->status_line . "\n");
		}
		print(STDERR $numid . '...');
		if ($numid % 10000 == 0) {
			print(STDERR "\nResting NCBI server...");
			sleep(60);
			print(STDERR "\nOK. Now restart downloading...");
		}
		elsif ($numid % 1000 == 0) {
			sleep(10);
		}
		else {
			sleep(5);
		}
		undef(@ids);
	}
}
if (@ids) {
	my $req = HTTP::Request->new(POST => $baseurl . join(',', @ids));
	my $res = $ua->request($req);
	if ($res->is_success) {
		my $outputhandle;
		if ($outputfile =~ /^stdout$/i) {
			unless (open($outputhandle, '>-')) {
				&errorMessage(__LINE__, "Cannot write STDOUT.");
			}
		}
		else {
			unless (open($outputhandle, ">> $outputfile")) {
				&errorMessage(__LINE__, "Cannot write \"$outputfile\".");
			}
		}
		foreach (split(/\n/,$res->content)) {
			unless (/^ *\r?\n?$/) {
				print($outputhandle "$_\n");
			}
		}
		close($outputhandle);
	}
	else {
		&errorMessage(__LINE__, "Cannot search at NCBI.\nError status: " . $res->status_line . "\n");
	}
	print(STDERR $numid . '...');
	undef(@ids);
}
print(STDERR "done.\n\n");

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
pgretrieveseq options inputfile outputfile

Command line options
====================
-o, --output=FASTA|GENBANK
  Specify output format. (default: GENBANK)

-db, --database=NUCLEOTIDE|PROTEIN|EST|GSS
  Specify Entrez database name. (default: NUCLEOTIDE)

--timeout=INTEGER
  Specify timeout limit for NCBI access by seconds. (default: 300)

Input file format
=================
GenBank ID list (one per a line)
_END
	exit;
}
