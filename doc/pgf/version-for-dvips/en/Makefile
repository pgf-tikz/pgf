rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual

all: $(doc).ps

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.ps: $(doc).tex $(doc).ind 
	elatex $(doc).tex
	(egrep -q $(rerun) $(doc).log && elatex $(doc).tex) || true
	dvips $(doc).dvi

clean:
	rm -f *.aux *.log *.bbl *.blg *.ps *.dvi *.pdf *.toc *.out *.snm
