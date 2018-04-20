PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
PERL := $(filter /%,$(shell /bin/sh -c 'type perl'))
VERSION := 2.0.2018.04.20
PROGRAM := pgaligncodon pgcalcotudist pgcomptree pgconcatgap pgconcatseq pgconvchronogram pgconvseq pgconvswl pgconvtree pgdegenseq pgdivseq pgelimdupseq pgelimduptree pgemboss pgencodegap pgfillseq pgjointree pgmcmctree pgmbburninparam pgpaup pgpaupbesttree pgpauplscores2lset pgphylip pgpickprimer pgpoy pgrecodeseq pgresampleseq pgretrieveseq pgspliceseq pgsplicetree pgsplittree pgstanstrand pgstripcolumn pgsumtree pgtestcomposition pgtf pgtfboot pgtfjoinlog pgtfratchet pgtnt pgtntboot pgtranseq pgtrimal

all: $(PROGRAM)

pgaligncodon: pgaligncodon.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgcalcotudist: pgcalcotudist.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgcomptree: pgcomptree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgconcatgap: pgconcatgap.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgconcatseq: pgconcatseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgconvchronogram: pgconvchronogram.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgconvseq: pgconvseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgconvswl: pgconvswl.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgconvtree: pgconvtree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgdegenseq: pgdegenseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgdivseq: pgdivseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgelimdupseq: pgelimdupseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgelimduptree: pgelimduptree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgemboss: pgemboss.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgencodegap: pgencodegap.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgfillseq: pgfillseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgjointree: pgjointree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgmcmctree: pgmcmctree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgmbburninparam: pgmbburninparam.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgpaup: pgpaup.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgpaupbesttree: pgpaupbesttree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgpauplscores2lset: pgpauplscores2lset.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgphylip: pgphylip.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgpickprimer: pgpickprimer.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgpoy: pgpoy.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgrecodeseq: pgrecodeseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgresampleseq: pgresampleseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgretrieveseq: pgretrieveseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgspliceseq: pgspliceseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgsplicetree: pgsplicetree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgsplittree: pgsplittree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgstanstrand: pgstanstrand.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgstripcolumn: pgstripcolumn.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgsumtree: pgsumtree.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtestcomposition: pgtestcomposition.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtf: pgtf.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtfboot: pgtfboot.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtfjoinlog: pgtfjoinlog.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtfratchet: pgtfratchet.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtnt: pgtnt.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtntboot: pgtntboot.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtranseq: pgtranseq.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

pgtrimal: pgtrimal.pl
	echo '#!'$(PERL) > $@
	$(PERL) -npe "s/buildno = '2\.0\.x'/buildno = '$(VERSION)'/" $< >> $@

install: $(PROGRAM)
	chmod 755 $^
	mkdir -p $(BINDIR)
	cp $^ $(BINDIR)

clean:
	rm $(PROGRAM)
