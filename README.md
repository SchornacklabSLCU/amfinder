# CastANet Editor

Graphical user interface to assist with the annotation of mycorrhiza images.

![](doc/castanet-editor.png)

## Installation instructions

### Installing OPAM, GTK and Cairo

[OPAM](https://opam.ocaml.org/) is the OCaml package manager.
[GTK](https://www.gtk.org/) is a library to create user interfaces, and
[Cairo](https://www.cairographics.org/) is a 2D graphics library.

#### Linux

For Debian and relatives, install OPAM with [`apt`](https://salsa.debian.org/apt-team/apt)
(for other distributions, check your favourite package manager). You also need
development files for GTK and Cairo. Run the following command as administrator:

```bash
apt install opam libgtk2.0-dev libcairo2-dev
```

#### OSX

Install OPAM with [`homebrew`](https://brew.sh/).

- You need [`gpatch`](https://formulae.brew.sh/formula/gpatch) for `opam` is relying on GNU-specific options.
- [`gtk+`](https://formulae.brew.sh/formula/gtk+) is the [brew] formula for GTK2.
- [`cairo`](https://formulae.brew.sh/formula/cairo) is the [brew] formula for Cairo.

```bash
brew install gpatch opam gtk+ cairo
```

#### MS Windows

You should first install the [Cygwin](https://www.cygwin.com/) packages:
git,wget,unzip,make,m4,gcc,gcc4-core,libmpfr4,autoconf,flexdll,libncurses-devel,
curl,ocaml,ocaml-compiler-libs,patch

Then you can build opam from sources as follows:

```bash
git clone https://github.com/ocaml/opam.git && cd opam
./configure && make && make install && cd ..
```


### Installing OCaml libraries

#### OPAM initialization

Simply run:

```bash
opam init
eval $(opam env)
```

### CastANet Dependencies

You need to install the following dependencies:

- The OCaml build system [`dune`](https://opam.ocaml.org/packages/dune/),
- The documentation generator [`odoc`](https://opam.ocaml.org/packages/odoc/),
- OCaml bindings to GTK2 library [`lablgtk`](https://opam.ocaml.org/packages/lablgtk/),
- OCaml bindings to Cairo libary [`cairo2`](https://opam.ocaml.org/packages/cairo2/)

This is done as follows:

```bash
opam install dune odoc lablgtk cairo2 cairo2-gtk
```
