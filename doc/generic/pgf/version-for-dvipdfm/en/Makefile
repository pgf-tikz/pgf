rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = latex
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).pdf

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.pdf: $(doc).tex $(doc).ind revisionfile
	(TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	dvipdfm -p a4 $(doc)

revisionfile:
	cd ../../../../.. && ./scripts/pgf/pgfrevisionfile.sh

clean:
	rm -f  \
		plots/* \
		pgfmanual.out \
		pgfmanual.log \
		pgfmanual.idx \
		pgfmanual.ind \
		pgfmanual.ilg \
		pgfmanual.pdf \
		pgfmanual.toc \
		pgfmanual.bbl \
		pgfmanual.blg \
		pgfmanual.ps \
		pgfmanual.dvi \
		pgfmanual*.aux 
