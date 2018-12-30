
all: tikzexternaltest.pdf tikzexternaltestmakefile.pdf


tikzexternaltest.pdf: FORCE
	pdflatex -shell-escape tikzexternaltest.tex

tikzexternaltestmakefile.pdf: FORCE
	pdflatex tikzexternaltestmakefile.tex
	$(MAKE) -f tikzexternaltestmakefile.makefile
	pdflatex tikzexternaltestmakefile.tex
	$(MAKE) -f tikzexternaltestmakefile.makefile
	pdflatex tikzexternaltestmakefile.tex

FORCE:

clean:
	rm -f *.aux *.auxlock *.log *.pdf *.dpth *.dep *.makefile *.figlist *.out 
