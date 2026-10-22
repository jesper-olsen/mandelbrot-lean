# Mandelbrot in Goose

This repository contains a [Lean](https://lean-lang.org/) implementation for generating visualizations of the Mandelbrot set. 

The program compiles to a single native executable. It can render the Mandelbrot set directly to the terminal as ASCII art or produce a data file for `gnuplot` to generate a high-resolution PNG image.

### Other Language Implementations

This project is part of a suite of mandelbrot implementations in different languages.

Single Thread/Multi-thread shows the number of seconds it takes to do a 5000x5000 calculation.


| Language                                                       | Single Thread   | Multi-Thread | Simd | Multi-Thread + Simd |
| :------------------------------------------------------------- | ---------------:| -----------: | ----:| ------------------: |
| [Awk](https://github.com/jesper-olsen/mandelbrot-awk)          |           146.3 |              |      |                     |
| [C](https://github.com/jesper-olsen/mandelbrot-c)              |             3.6 |          0.6 |  0.7 |               0.2   |
| [C++](https://github.com/jesper-olsen/mandelbrot-cpp)          |             3.7 |          0.6 |  0.7 |               0.2   |
| [Erlang](https://github.com/jesper-olsen/mandelbrot_erl)       |            35.6 |          8.3 |      |                     |
| [Fortran](https://github.com/jesper-olsen/mandelbrot-f)        |             4.5 |              |      |                     |
| [Go](https://github.com/jesper-olsen/mandelbrot-go)            |             4.1 |          0.8 |  1.3 |               0.4   |
| [Goose](https://github.com/jesper-olsen/mandelbrot-goose)      |             3.9 |              |      |                     |
| [Java](https://github.com/jesper-olsen/mandelbrot-java)        |             3.9 |          0.8 |  1.4 |               0.5   |
| **[Lean](https://github.com/jesper-olsen/mandelbrot-lean)**    |             4.0 |              |      |                     |
| [Lua](https://github.com/jesper-olsen/mandelbrot-lua)          |            33.2 |              |      |                     |
| [Mojo](https://github.com/jesper-olsen/mandelbrot-mojo)        |             3.8 |          1.2 |  0.7 |               0.4   |
| [Odin](https://github.com/jesper-olsen/mandelbrot-odin)        |             4.4 |              |      |                     |
| [Py](https://github.com/jesper-olsen/mandelbrot-py)            |     (pure) 93.3 | (jax)    5.9 |      |                     |
| [R](https://github.com/jesper-olsen/mandelbrot-R)              |           335.0 |              |      |                     |
| [Rust](https://github.com/jesper-olsen/mandelbrot-rs)          |             4.7 |          1.3 |  1.4 |               0.8   |
| [Swift](https://github.com/jesper-olsen/mandelbrot-swift)      |             4.5 |          1.2 |  1.3 |               0.7   |
| [Tcl](https://github.com/jesper-olsen/mandelbrot-tcl)          |           306.9 |              |      |                     |
| [Typescript](https://github.com/jesper-olsen/mandelbrot-ts)    |             4.1 |          0.8 |      |                     |
| [Zig](https://github.com/jesper-olsen/mandelbrot-zig)          |             4.9 |          0.9 |  0.7 |               0.3   |
|                                                                |                 |              |      |                     |
| [Bash5.3](https://github.com/jesper-olsen/mandelbrot-bash)     |         10187.3 |              |      |                     |
| [Zsh](https://github.com/jesper-olsen/mandelbrot-bash)         |          2683.6 |              |      |                     |
| [Ksh (93u+m)](https://github.com/jesper-olsen/mandelbrot-bash) |          1271.5 |              |      |                     |
| [Nu](https://github.com/jesper-olsen/mandelbrot-nu)            |   (est) 17186.6 |              |      |                     |




---

## Prerequisites

You will need the following installed:

1. [Lake](https://lean-lang.org/install/) - Lean's build tool
2.  **Make** (optional, but recommended for easy building).
3.  **Gnuplot** (required *only* for generating PNG images).

---

## Build

You can compile the program directly or use the provided Makefile:

run `make` in the project directory.

```sh
make
```

---

## Usage

The compiled executable can be configured via command-line arguments using a `key=value` format.

### 1. ASCII Art Output

To render the Mandelbrot set directly in your terminal, run the executable.

```sh
.lake/build/bin/mandelbrot
```

You can change the view and resolution by passing parameters:
```sh
# Zoom in on a different area with a wider view
.lake/build/bin/mandelbrot width=120 ll_x=-0.75 ll_y=0.1 ur_x=-0.74 ur_y=0.11
```

### 2. PNG Image Generation

To create a high-resolution PNG, you first generate a data file and then process it with `gnuplot`.

**Step 1: Generate the data file**
Set `png=1` and specify the desired dimensions. Redirect the output to a file.

```sh
.lake/build/bin/mandelbrot png=1 width=1000 height=750 > image.dat
```

**Step 3: Run gnuplot**
This will read `image.dat` and create `mandelbrot.png`.

```sh
gnuplot topng.gp
```
The result is a high-quality `mandelbrot.png` image.

![PNG Image of the Mandelbrot Set](mandelbrot.png)

## Performance

Benchmarks were run on an **Apple M5** system with Lean version 4.35.0:
```sh
lean --version
Lean (version 4.35.0, arm64-apple-darwin24.6.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc, Release)
```

**Generating a 1000x750 data file:**
```sh
make bench-small
time .lake/build/bin/mandelbrot png=1 width=1000 height=750 > image.dat

real    0m0.151s
user    0m0.138s
sys     0m0.005s
```

**Generating a 5000x5000 data file:**
```sh
make bench-large
time .lake/build/bin/mandelbrot png=1 width=5000 height=5000 > image.dat

real    0m4.041s
user    0m3.998s
sys     0m0.025s
```
