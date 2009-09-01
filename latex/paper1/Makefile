SOURCEDOCUMENT=paper1
BIBS=paper1.bib
PDFVIEWER=evince
#PDFVIEWER=xpdf -remote rodrigo-xpdf

CAPITULOS=$(wildcard *.tex)

FROM_DOT=
FROM_SVG=
GRAPHICS=$(FROM_DOT) $(FROM_SVG)

all: $(SOURCEDOCUMENT).pdf

view: $(SOURCEDOCUMENT).pdf
	$(PDFVIEWER) $(SOURCEDOCUMENT).pdf &

fast: $(SOURCEDOCUMENT).tex $(CAPITULOS) $(BIBS) $(GRAPHICS) 
	pdflatex $<

$(SOURCEDOCUMENT).pdf: $(SOURCEDOCUMENT).tex $(CAPITULOS) $(BIBS) $(GRAPHICS) 
	pdflatex $< && \
	bibtex $(SOURCEDOCUMENT) && \
	pdflatex $< && \
	pdflatex $< || \
	$(RM) $@

graphics: $(GRAPHICS)

$(FROM_SVG): %.pdf: %.svg
	inkscape $< --export-eps=x.eps
	epstopdf x.eps -o=$@
	rm -f x.eps

$(FROM_DOT): %.pdf: %.dot
	dot -Gcharset=latin1 -Grankdir=LR -s300.0 -Tps $< > x.eps
	epstopdf x.eps -o=$@ 

clean:
	$(RM) *.aux *.bbl *.blg *.lof *.lot *.log $(SOURCEDOCUMENT).pdf *~ *.toc $(GRAPHICS) profiling.xml

