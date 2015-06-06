rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = lualatex
TEXINPUTS := ../../text-en:../../images:$(TEXINPUTS)

all: $(doc).pdf

dist: FORCE
	$(latex) -shell-escape --jobname=pgfmanual '\def\pgfautoxrefs{1}\pdfminorversion=5 \pdfobjcompresslevel=2 \input{$(doc)}'
	makeindex $(doc).idx
	@echo "$(doc).pdf remade with auto-xref support. Check if auto-xrefs work and rerun make dist if not."

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.pdf: $(doc).tex $(doc).ind 
	TEXINPUTS="$(TEXINPUTS)" $(latex) -shell-escape '$(linkcode)' $(doc).tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
	@echo "Use 'make dist' to generate auto-xrefs."

test: $(doc)-test.tex $(doc).ind 
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc)-test.tex) || true
	@echo "Use 'make dist' to generate auto-xrefs."

FORCE:

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
