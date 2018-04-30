rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = lualatex --output-format=dvi
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).svg

test: pgfmanual-test.svg

test-no-fonts: pgfmanual-test-no-font.svg

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.svg: $(doc).tex $(doc).ind revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex
	dvisvgm --no-merge --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)

pgfmanual-no-font.svg: $(doc).tex $(doc).ind revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex
	dvisvgm --no-fonts --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)

pgfmanual-test.svg: $(doc)-test.tex $(doc).ind revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex
	dvisvgm --no-merge --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)-test

pgfmanual-test-merged.svg: $(doc)-test.tex $(doc).ind revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex
	dvisvgm --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)-test

pgfmanual-test-no-font.svg: $(doc)-test.tex $(doc).ind revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex
	dvisvgm --no-fonts --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)-test

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
