rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual-pdftex-version

all: $(doc).pdf

pgfmanual-pdftex-version.idx: 
	touch pgfmanual-pdftex-version.idx

pgfmanual-pdftex-version.ind: pgfmanual-pdftex-version.idx 
	makeindex $(doc).idx

pgfmanual-pdftex-version.pdf: $(doc).tex $(doc).ind 
	pdfelatex $(doc).tex
	(egrep -q $(rerun) $(doc).log && pdfelatex $(doc).tex) || true

clean:
	rm -f *.aux *.log *.bbl *.blg *.ps *.dvi *.pdf *.toc *.out *.snm
