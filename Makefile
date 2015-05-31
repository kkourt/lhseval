.PHONY: all
SHELL=/bin/bash

all: lhs2tex-eval-example.tex lhs2tex-eval-example.pdf \
     pandoc-lhs-eval pandoc-lhs-eval.html

pandoc-lhs-eval: pandoc-lhs-eval.lhs
	ghc --make $<

pandoc-lhs-eval.html: pandoc-lhs-eval.lhs pandoc-lhs-eval
	pandoc -t native pandoc-lhs-eval.lhs | ./pandoc-lhs-eval pandoc-lhs-eval.lhs | pandoc -t html -ss --highlight-style pygments -o pandoc-lhs-eval.html

lhs2tex-eval-example.tex: lhs2tex-eval-example.lhs
	lhs2TeX $< > $@

%.pdf: %.tex
	pdflatex $<

clean:
	rm -f pandoc-lhs-eval{,.hi,.o,.html} lhs2tex-eval-example.{pdf,tex,aux,ptb,log}
