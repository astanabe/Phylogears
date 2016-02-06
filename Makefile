PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
PERL := $(filter /%,$(shell /bin/sh -c 'type perl'))
PROGRAM := pgaligncodon pgassembleseq pgcalcotudist pgcomptree pgconcatgap pgconcatseq pgconvchronogram pgconvseq pgconvswl pgconvtree pgdegenseq pgdivseq pgelimdupseq pgelimduptree pgemboss pgencodegap pgfillseq pgjointree pgmbburninparam pgpaup pgpaupbesttree pgpauplscores2lset pgphylip pgpickprimer pgpoy pgraxmlpartboot pgrecodeseq pgresampleseq pgretrieveseq pgspliceseq pgsplicetree pgsplittree pgstanstrand pgstripcolumn pgsumtree pgtestcomposition pgtf pgtfboot pgtfjoinlog pgtfratchet pgtnt pgtntboot pgtranseq pgtrimal

all: $(PROGRAM)

pgaligncodon: pgaligncodon.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgassembleseq: pgassembleseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgcalcotudist: pgcalcotudist.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgcomptree: pgcomptree.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgconcatgap: pgconcatgap.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgconcatseq: pgconcatseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgconvchronogram: pgconvchronogram.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgconvseq: pgconvseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgconvswl: pgconvswl.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgconvtree: pgconvtree.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgdegenseq: pgdegenseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgdivseq: pgdivseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgelimdupseq: pgelimdupseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgelimduptree: pgelimduptree.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgemboss: pgemboss.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgencodegap: pgencodegap.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgfillseq: pgfillseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgjointree: pgjointree.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgmbburninparam: pgmbburninparam.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgpaup: pgpaup.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgpaupbesttree: pgpaupbesttree.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgpauplscores2lset: pgpauplscores2lset.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgphylip: pgphylip.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgpickprimer: pgpickprimer.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgpoy: pgpoy.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgraxmlpartboot: pgraxmlpartboot.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgrecodeseq: pgrecodeseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgresampleseq: pgresampleseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgretrieveseq: pgretrieveseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgspliceseq: pgspliceseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgsplicetree: pgsplicetree.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgsplittree: pgsplittree.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgstanstrand: pgstanstrand.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgstripcolumn: pgstripcolumn.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgsumtree: pgsumtree.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtestcomposition: pgtestcomposition.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtf: pgtf.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtfboot: pgtfboot.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtfjoinlog: pgtfjoinlog.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtfratchet: pgtfratchet.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtnt: pgtnt.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtntboot: pgtntboot.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtranseq: pgtranseq.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@
pgtrimal: pgtrimal.pl
	echo '#!'$(PERL) > $@
	cat $< >> $@

install: $(PROGRAM)
	chmod 755 $^
	mkdir -p $(BINDIR)
	cp $^ $(BINDIR)

clean:
	rm $(PROGRAM)
