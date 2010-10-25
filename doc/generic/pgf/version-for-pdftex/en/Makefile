rerun = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
doc   = pgfmanual
latex = pdflatex
TEXINPUTS := ../../text-en:../../images:$(TEXINPUTS)

all: $(doc).pdf

# make dist will also enable automatic cross references in codeexamples.
# This is disabled by default as it requires higher mem limits.
#
# It employs a 'texmf.cnf' which lies in ../../text-en.
dist: FORCE
	export TEXMFCNF="../../text-en:$(TEXMFCNF)"; \
	export TEXINPUTS="$(TEXINPUTS)"; \
	$(latex) '\def\pgfautoxrefs{1}\pdfminorversion=5 \pdfobjcompresslevel=2 \input{$(doc)}'
	makeindex $(doc).idx
	@echo "$(doc).pdf remade with auto-xref support. Check if auto-xrefs work and rerun make dist if not."

pgfmanual.idx: 
	touch pgfmanual.idx

pgfmanual.ind: pgfmanual.idx 
	makeindex $(doc).idx

pgfmanual.pdf: $(doc).tex $(doc).ind 
	TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex
	(egrep -q $(rerun) $(doc).log && TEXINPUTS="$(TEXINPUTS)" $(latex) $(doc).tex) || true
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
