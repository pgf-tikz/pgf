rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = lualatex --output-format=dvi
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).svg

test: pgfmanual-test.svg

test-no-fonts: pgfmanual-test-no-font.svg

pgfmanual.dvi: $(doc).tex revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true

pgfmanual.svg: $(doc).dvi
	dvisvgm --font-format=woff --no-merge --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)

pgfmanual-no-font.svg: $(doc).dvi
	dvisvgm --no-fonts --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)

pgfmanual-test.dvi: $(doc)-test.tex revisionfile
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex

pgfmanual-test.svg: $(doc)-test.dvi
	dvisvgm --no-merge --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)-test

pgfmanual-test-merged.svg: $(doc)-test.dvi
	dvisvgm --output=%f-%4p.svg --page=1- --bbox=a4 --linkmark=none $(doc)-test

pgfmanual-test-no-font.svg: $(doc)-test.dvi
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
