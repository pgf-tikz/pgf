rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = lualatex
TEXINPUTS := ../../text-en:../../images:$(TEXINPUTS)

all: $(doc).pdf

pgfmanual.pdf: $(doc).tex revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true

test: $(doc)-test.tex revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex) || true

revisionfile:
	cd ../../../../.. && ./scripts/pgf/pgfrevisionfile.sh

FORCE:

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
