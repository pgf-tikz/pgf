rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = vlatex
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).ps

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.ps: $(doc).tex $(doc).ind 
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true

clean:
	rm -f pgfmanual*.aux pgfmanual.{out,log,idx,ind,ilg,pdf,toc,bbl,blg,ps}

