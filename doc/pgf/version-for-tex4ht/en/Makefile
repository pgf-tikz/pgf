doc   = pgfmanual

all: $(doc).html

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.html: $(doc).tex $(doc).ind 
	htlatex $(doc).tex

clean:
	rm -f *.aux *.log *.bbl *.blg *.ps *.dvi *.pdf *.toc *.out *.snm *.html *.svg
