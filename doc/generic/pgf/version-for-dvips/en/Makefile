rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = latex
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).ps

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.ps: $(doc).tex $(doc).ind revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	dvips -o $(doc).ps $(doc).dvi
	gs -dNOPAUSE -sDEVICE=pdfwrite -dBATCH -dCompatibilityLevel=1.4 -sOutputFile=$(doc).pdf $(doc).ps

test: $(doc)-test.tex $(doc).ind revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex) || true
	dvips -o $(doc)-test.ps $(doc)-test.dvi
	gs -dNOPAUSE -sDEVICE=pdfwrite -dBATCH -dCompatibilityLevel=1.4 -sOutputFile=$(doc)-test.pdf $(doc)-test.ps

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

