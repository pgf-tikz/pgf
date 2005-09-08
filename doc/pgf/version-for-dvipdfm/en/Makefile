rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual

all: $(doc).pdf

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.pdf: $(doc).tex $(doc).ind 
	(elatex $(doc).tex) || true
	(egrep -q $(rerun) $(doc).log && pdfelatex $(doc).tex) || true
	dvipdfm $(doc)

clean:
	rm -f *.aux *.log *.bbl *.blg *.ps *.dvi *.pdf *.toc *.out *.snm
