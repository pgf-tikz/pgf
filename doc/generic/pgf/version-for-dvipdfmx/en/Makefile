rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = latex -shell-escape
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).pdf revisionfile

pgfmanual.pdf: $(doc).tex revisionfile
	mkdir -p plots
	(TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	dvipdfmx -p a4 $(doc)

test: $(doc)-test.tex revisionfile
	mkdir -p plots
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex) || true
	dvipdfmx -p a4 $(doc)-test

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
