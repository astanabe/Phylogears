my $buildno = '2.0.x';
#
# pgmcmctree
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
use File::Spec;
use File::Copy::Recursive ('fcopy', 'rcopy', 'dircopy');

# options
my $model = 'independent';
my $burnin = 10000;
my $sampfreq = 10;
my $nsample = 100000;

# input/output
my $inputfile;
my $outputfolder;
my $roughcalib;
my $fullcalib;

# global variables
my $devnull = File::Spec->devnull();
my $ndata = 0;
my @nchar;
my $rgenegamma = 0;

# file handles
my $filehandleinput1;
my $filehandleoutput1;

&main();

sub main {
	# print startup messages
	&printStartupMessage();
	# get command line arguments
	&getOptions();
	# check variable consistency
	&checkVariables();
	# prepare analysis
	&prepareAnalysis();
	# run rough estimation
	&runRough();
	# calc hessian matrix
	&calcHessianMatrix();
	# run full estimation
	&runFull();
	# run prior analysis
	&runPrior();
}

sub printStartupMessage {
	print(<<"_END");
pgmcmctree $buildno
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
	# display usage if command line options were not specified
	unless (@ARGV) {
		&helpMessage();
	}
}

sub getOptions {
	# get input file name
	$inputfile = $ARGV[-2];
	# get output file name
	$outputfolder = $ARGV[-1];
	# read command line options
	for (my $i = 0; $i < scalar(@ARGV) - 2; $i ++) {
		if ($ARGV[$i] =~ /^-+(?:model|m)=(.+)$/i) {
			$model = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:rough|roughcalib|r)=(.+)$/i) {
			$roughcalib = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:full|fullcalib|f)=(.+)$/i) {
			$fullcalib = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:burnin|b)=(\d+)$/i) {
			$burnin = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:sampfreq|s)=(\d+)$/i) {
			$sampfreq = $1;
		}
		elsif ($ARGV[$i] =~ /^-+(?:nsample|n)=(\d+)$/i) {
			$nsample = $1;
		}
		else {
			&errorMessage(__LINE__, "\"$ARGV[$i]\" is unknown option.");
		}
	}
}

sub checkVariables {
	if (!-e $inputfile) {
		&errorMessage(__LINE__, "The input file does not exist.");
	}
	if (-e $outputfolder) {
		&errorMessage(__LINE__, "The output folder already exists.");
	}
	if ($model !~ /^(?:globalclock|independent|autocorrelated)$/i) {
		&errorMessage(__LINE__, "The rate model is invalid.");
	}
	unless ($roughcalib) {
		&errorMessage(__LINE__, "The rough calibration tree was not given.");
	}
	if (!-e $roughcalib) {
		&errorMessage(__LINE__, "The rough calibration tree does not exist.");
	}
	unless ($fullcalib) {
		&errorMessage(__LINE__, "The full calibration tree was not given.");
	}
	if (!-e $fullcalib) {
		&errorMessage(__LINE__, "The full calibration tree does not exist.");
	}
	if ($burnin >= $nsample * $sampfreq) {
		&errorMessage(__LINE__, "The burn-in value is too large.");
	}
}

sub prepareAnalysis {
	# make output folder
	unless (mkdir($outputfolder)) {
		&errorMessage(__LINE__, "Cannot make outputfilder.");
	}
	# copy input sequence file
	$inputfile =~ /[^\/\\]+$/;
	my $inputfilename = $&;
	if (-e "$outputfolder/$inputfilename") {
		&errorMessage(__LINE__, "\"$outputfolder/$inputfilename\" already exists.");
	}
	unless (fcopy($inputfile, "$outputfolder/$inputfilename")) {
		&errorMessage(__LINE__, "Cannot copy input file to \"$outputfolder/$inputfilename\"");
	}
	$inputfile = $inputfilename;
	# copy rough calibration tree file
	$roughcalib =~ /[^\/\\]+$/;
	my $roughcalibfilename = $&;
	if (-e "$outputfolder/$roughcalibfilename") {
		&errorMessage(__LINE__, "\"$outputfolder/$roughcalibfilename\" already exists.");
	}
	unless (fcopy($roughcalib, "$outputfolder/$roughcalibfilename")) {
		&errorMessage(__LINE__, "Cannot copy input file to \"$outputfolder/$roughcalibfilename\"");
	}
	$roughcalib = $roughcalibfilename;
	# copy full calibration tree file
	$fullcalib =~ /[^\/\\]+$/;
	my $fullcalibfilename = $&;
	if (-e "$outputfolder/$fullcalibfilename") {
		&errorMessage(__LINE__, "\"$outputfolder/$fullcalibfilename\" already exists.");
	}
	unless (fcopy($fullcalib, "$outputfolder/$fullcalibfilename")) {
		&errorMessage(__LINE__, "Cannot copy input file to \"$outputfolder/$fullcalibfilename\"");
	}
	$fullcalib = $fullcalibfilename;
	# make output folders
	unless (mkdir("$outputfolder/Step1-calcSubstitutionRate")) {
		&errorMessage(__LINE__, "Cannot make outputfilder.");
	}
	unless (mkdir("$outputfolder/Step2-calcHessianMatrix")) {
		&errorMessage(__LINE__, "Cannot make outputfilder.");
	}
	unless (mkdir("$outputfolder/Step3-estimateDivergenceTimes")) {
		&errorMessage(__LINE__, "Cannot make outputfilder.");
	}
	unless (mkdir("$outputfolder/Step4-checkPrior")) {
		&errorMessage(__LINE__, "Cannot make outputfilder.");
	}
	# read input sequence file
	unless (open($filehandleinput1, "< $outputfolder/$inputfile")) {
		&errorMessage(__LINE__, "Cannot open \"$outputfolder/$inputfile\".");
	}
	while (<$filehandleinput1>) {
		if (/^ *\d+ +(\d+)\r?\n?$/) {
			push(@nchar, $1);
			$ndata ++;
		}
	}
	close($filehandleinput1);
	if ($ndata == 0) {
		&errorMessage(__LINE__, "The input sequence file is invalid.");
	}
	# set model value
	if ($model =~ /globalclock/i) {
		$model = 1;
	}
	elsif ($model =~ /independent/i) {
		$model = 2;
	}
	elsif ($model =~ /autocorrelated/i) {
		$model = 3;
	}
}

sub runRough {
	print(STDERR "Calculating substitution rate...\n");
	unless (chdir("$outputfolder/Step1-calcSubstitutionRate")) {
		&errorMessage(__LINE__, "Cannot change working directory.");
	}
	unless (open($filehandleoutput1, "> baseml.ctl")) {
		&errorMessage(__LINE__, "Cannot make \"baseml.ctl\".");
	}
	print($filehandleoutput1 <<"_END");
      seqfile = ../$inputfile * sequence data file name
     treefile = ../$roughcalib  * tree structure file name
      outfile = substitutionrate * main result file

        ndata = $ndata
        noisy = 3   * 0,1,2,3: how much rubbish on the screen
      verbose = 1   * 1: detailed output, 0: concise output
      runmode = 0   * 0: user tree;  1: semi-automatic;  2: automatic
                    * 3: StepwiseAddition; (4,5):PerturbationNNI

        model = 7   * 0:JC69, 1:K80, 2:F81, 3:F84, 4:HKY85
        Mgene = 1   * 0:rates, 1:separate; 2:diff pi, 3:diff kapa, 4:all diff

    fix_kappa = 0
        kappa = 2   * initial or given kappa

    fix_alpha = 0 
        alpha = 0.5  * initial or given alpha, 0:infinity (constant rate)
       Malpha = 0   * 1: different alpha's for genes, 0: one alpha
        ncatG = 5   * # of categories in the dG, AdG, or nparK models of rates

      fix_rho = 1  
          rho = 0.  * initial or given rho,   0:no correlation
        nparK = 0   * rate-class models. 1:rK, 2:rK&fK, 3:rK&MK(1/K), 4:rK&MK

        clock = 1   * 0: no clock, unrooted tree, 1: clock, rooted tree
        nhomo = 0   * 0 & 1: homogeneous, 2: kappa's, 3: N1, 4: N2
        getSE = 1   * 0: don't want them, 1: want S.E.s of estimates
 RateAncestor = 0   * (1/0): rates (alpha>0) or ancestral states (alpha=0)
    cleandata = 0  * remove sites with ambiguity data (1:yes, 0:no)?
_END
	close($filehandleoutput1);
	if (system("baseml")) {
		&errorMessage(__LINE__, "Cannot run baseml.");
	}
	unless (open($filehandleinput1, "< substitutionrate")) {
		&errorMessage(__LINE__, "Cannot open \"substitutionrate\".");
	}
	my @substitutionrate;
	my $submode = 0;
	while (<$filehandleinput1>) {
		if ($submode == 0 && /Substitution rate is per time unit/) {
			$submode = 1;
		}
		elsif ($submode == 1 && /^\s+(\d+\.\d+) \+\- \d+\.\d+/) {
			push(@substitutionrate, $1);
			$submode = 0;
		}
	}
	close($filehandleinput1);
	if (scalar(@substitutionrate) != scalar(@nchar)) {
		&errorMessage(__LINE__, "The output of baseml is inconsistent with input sequence file.");
	}
	# calculate weighted mean
	my $mean = 0;
	my $sumnchar = 0;
	for (my $i = 0; $i < scalar(@substitutionrate); $i ++) {
		$mean += $substitutionrate[$i] * $nchar[$i];
		$sumnchar += $nchar[$i];
	}
	$mean /= $sumnchar;
	$rgenegamma = sprintf("%.8f", $mean / ($mean ** 2));
	unless (chdir("../..")) {
		&errorMessage(__LINE__, "Cannot change working directory.");
	}
	print(STDERR "done\n\n");
}

sub calcHessianMatrix {
	print(STDERR "Calculating Hessian matrix...\n");
	unless (chdir("$outputfolder/Step2-calcHessianMatrix")) {
		&errorMessage(__LINE__, "Cannot change working directory.");
	}
	unless (open($filehandleoutput1, "> mcmctree.ctl")) {
		&errorMessage(__LINE__, "Cannot make \"mcmctree.ctl\".");
	}
	print($filehandleoutput1 <<"_END");
         seed = -1
      seqfile = ../$inputfile * sequence data file name
     treefile = ../$fullcalib  * tree structure file name
      outfile = usedata3

        ndata = $ndata
      usedata = 3    * 0: no data; 1:seq like; 2:normal approximation
        clock = $model    * 1: global clock; 2: independent rates; 3: correlated rates
      RootAge = '<15'  * constraint on root age, used if no fossil for root.

        model = 7    * 0:JC69, 1:K80, 2:F81, 3:F84, 4:HKY85
        alpha = 0.5   * alpha for gamma rates at sites
        ncatG = 5    * No. categories in discrete gamma

    cleandata = 0    * remove sites with ambiguity data (1:yes, 0:no)?

      BDparas = 1 1 0   * birth, death, sampling
  kappa_gamma = 6 2      * gamma prior for kappa
  alpha_gamma = 1 1      * gamma prior for alpha

  rgene_gamma = 1 $rgenegamma  * gamma prior for rate for genes
 sigma2_gamma = 1 4.5    * gamma prior for sigma^2     (for clock=2 or 3)

     finetune = 1: .1 .1 .1 .1 .1 .1  * times, rates, mixing, paras, RateParas

        print = 1
       burnin = $burnin
     sampfreq = $sampfreq
      nsample = $nsample
_END
	close($filehandleoutput1);
	if (system("mcmctree")) {
		&errorMessage(__LINE__, "Cannot run mcmctree.");
	}
	unless (fcopy("out.BV", "../Step3-estimateDivergenceTimes/in.BV")) {
		&errorMessage(__LINE__, "Cannot copy \"out.BV\".");
	}
	unless (fcopy("out.BV", "../Step4-checkPrior/in.BV")) {
		&errorMessage(__LINE__, "Cannot copy \"out.BV\".");
	}
	unless (chdir("../..")) {
		&errorMessage(__LINE__, "Cannot change working directory.");
	}
	print(STDERR "done\n\n");
}

sub runFull {
	print(STDERR "Estimating divergence times...\n");
	unless (chdir("$outputfolder/Step3-estimateDivergenceTimes")) {
		&errorMessage(__LINE__, "Cannot change working directory.");
	}
	unless (open($filehandleoutput1, "> mcmctree.ctl")) {
		&errorMessage(__LINE__, "Cannot make \"mcmctree.ctl\".");
	}
	print($filehandleoutput1 <<"_END");
         seed = -1
      seqfile = ../$inputfile * sequence data file name
     treefile = ../$fullcalib  * tree structure file name
      outfile = usedata2

        ndata = $ndata
      usedata = 2    * 0: no data; 1:seq like; 2:normal approximation
        clock = $model    * 1: global clock; 2: independent rates; 3: correlated rates
      RootAge = '<15'  * constraint on root age, used if no fossil for root.

        model = 7    * 0:JC69, 1:K80, 2:F81, 3:F84, 4:HKY85
        alpha = 0.5   * alpha for gamma rates at sites
        ncatG = 5    * No. categories in discrete gamma

    cleandata = 0    * remove sites with ambiguity data (1:yes, 0:no)?

      BDparas = 1 1 0   * birth, death, sampling
  kappa_gamma = 6 2      * gamma prior for kappa
  alpha_gamma = 1 1      * gamma prior for alpha

  rgene_gamma = 1 $rgenegamma  * gamma prior for rate for genes
 sigma2_gamma = 1 4.5    * gamma prior for sigma^2     (for clock=2 or 3)

     finetune = 1: .1 .1 .1 .1 .1 .1  * times, rates, mixing, paras, RateParas

        print = 1
       burnin = $burnin
     sampfreq = $sampfreq
      nsample = $nsample
_END
	close($filehandleoutput1);
	if (system("mcmctree")) {
		&errorMessage(__LINE__, "Cannot run mcmctree.");
	}
	unless (chdir("../..")) {
		&errorMessage(__LINE__, "Cannot change working directory.");
	}
	print(STDERR "done\n\n");
}

sub runPrior {
	print(STDERR "Running prior analysis...\n");
	unless (chdir("$outputfolder/Step4-checkPrior")) {
		&errorMessage(__LINE__, "Cannot change working directory.");
	}
	unless (open($filehandleoutput1, "> mcmctree.ctl")) {
		&errorMessage(__LINE__, "Cannot make \"mcmctree.ctl\".");
	}
	my $tempsampfreq = $sampfreq;
	print($filehandleoutput1 <<"_END");
         seed = -1
      seqfile = ../$inputfile * sequence data file name
     treefile = ../$fullcalib  * tree structure file name
      outfile = usedata0

        ndata = $ndata
      usedata = 0    * 0: no data; 1:seq like; 2:normal approximation
        clock = $model    * 1: global clock; 2: independent rates; 3: correlated rates
      RootAge = '<15'  * constraint on root age, used if no fossil for root.

        model = 7    * 0:JC69, 1:K80, 2:F81, 3:F84, 4:HKY85
        alpha = 0.5   * alpha for gamma rates at sites
        ncatG = 5    * No. categories in discrete gamma

    cleandata = 0    * remove sites with ambiguity data (1:yes, 0:no)?

      BDparas = 1 1 0   * birth, death, sampling
  kappa_gamma = 6 2      * gamma prior for kappa
  alpha_gamma = 1 1      * gamma prior for alpha

  rgene_gamma = 1 $rgenegamma  * gamma prior for rate for genes
 sigma2_gamma = 1 4.5    * gamma prior for sigma^2     (for clock=2 or 3)

     finetune = 1: .1 .1 .1 .1 .1 .1  * times, rates, mixing, paras, RateParas

        print = 1
       burnin = $burnin
     sampfreq = $tempsampfreq
      nsample = $nsample
_END
	close($filehandleoutput1);
	if (system("mcmctree")) {
		&errorMessage(__LINE__, "Cannot run mcmctree.");
	}
	unless (chdir("../..")) {
		&errorMessage(__LINE__, "Cannot change working directory.");
	}
	print(STDERR "done\n\n");
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
pgmcmctree options inputfile outputfolder

Command line options
====================
-m,--model=GLOBALCLOCK|INDEPENDENT|AUTOCORRELATED
  Specify rate model. (default: INDEPENDENT)

-b,--burnin=INTEGER
  Specify the number of iterations for burn-in. (default: 10000)

-s,--sampfreq=INTEGER
  Specify the sampling frequency. (default: 10)

-n,--nsample=INTEGER
  Specify the number of samples. (default: 10000)

-r,--roughcalib=TREEFILE
  Specify calibrated tree file for rough rate estimation. (default: none)

-f,--fullcalib=TREEFILE
  Specify calibrated tree file for full rate estimation. (default: none)

Acceptable input file formats
=============================
PHYLIPex
_END
	exit;
}
