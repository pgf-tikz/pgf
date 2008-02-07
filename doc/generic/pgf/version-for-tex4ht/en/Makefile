doc   = pgfmanual
TEXINPUTS := ../../text-en:$(TEXINPUTS)

all: $(doc).html

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.html: $(doc).tex $(doc).ind 
	TEXINPUTS="$(TEXINPUTS)" htlatex $(doc).tex

clean:
	rm -f pgfmanual*.aux pgfmanual{.out,.log,.idx,.ind,.ilg,.pdf,.toc,.bbl,.blg,.ps,*.gif,*.html,*.svg,.xref,.css,.4ct,.4tc,.dvi,.lg,.idv} *.png

