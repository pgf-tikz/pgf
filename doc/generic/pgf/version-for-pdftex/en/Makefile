rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = pdflatex

all: $(doc).pdf

TEXINPUTS := ../../text-en:$(TEXINPUTS)

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.pdf: $(doc).tex $(doc).ind 
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true

clean:
	rm -f pgfmanual*.aux pgfmanual.{out,log,idx,ind,ilg,pdf,toc,bbl,blg}
