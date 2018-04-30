doc   = pgfmanual
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).html

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.html: $(doc).tex $(doc).ind revisionfile
	TEXINPUTS="$(TEXINPUTS)" htlatex $(doc).tex

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
		pgfmanual.*gif \
		pgfmanual.*html \
		pgfmanual.*svg \
		pgfmanual.xref \
		pgfmanual.css \
		pgfmanual.4ct \
		pgfmanual.4tc \
		pgfmanual.dvi \
		pgfmanual.lg \
		pgfmanual.idv \
		pgfmanual*.aux \
		*.png
