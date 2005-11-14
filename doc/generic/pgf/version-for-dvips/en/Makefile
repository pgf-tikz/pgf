rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = elatex

all: $(doc).ps

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.ps: $(doc).tex $(doc).ind 
	$(latex) $(doc).tex
	(egrep -q $(rerun) $(doc).log && $(latex) $(doc).tex) || true
	dvips -o $(doc).ps $(doc).dvi
	gs -dNOPAUSE -sDEVICE=pdfwrite -dBATCH -dCompatibilityLevel=1.4 -sOutputFile=$(doc).pdf $(doc).ps

clean:
	rm -f *.aux *.log *.bbl *.blg *.ps *.dvi *.pdf *.toc *.out *.snm
