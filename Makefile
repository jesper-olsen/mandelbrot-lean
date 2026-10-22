SHELL := /bin/bash

EXE := .lake/build/bin/mandelbrot

.PHONY: all bench-small bench-large clean

all: $(EXE)

$(EXE): Mandelbrot.lean lakefile.toml
	lake build

bench-small: $(EXE)
	time $(EXE) png=1 width=1000 height=750 > image.dat

bench-large: $(EXE)
	time $(EXE) png=1 width=5000 height=5000 > image.dat

clean:
	lake clean
	rm -f image.dat
