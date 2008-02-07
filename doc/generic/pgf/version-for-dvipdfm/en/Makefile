rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = latex
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).pdf

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.pdf: $(doc).tex $(doc).ind 
	(TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	dvipdfm -p a4 $(doc)

clean:
	rm -f pgfmanual*.aux pgfmanual.{out,log,idx,ind,ilg,pdf,toc,bbl,blg,ps,dvi}
