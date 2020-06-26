#! /bin/bash

BIN="castanet-annotation-editor"
OPT='ocamlopt.opt'
CFLAGS='-w,s,-g'
OPT="ocamlopt -nodynlink -O3 -principal -inline 200"
PKGS='lablgtk2,cairo2,cairo2-gtk'

eval `opam config env` && \
ocamlbuild -cflags $CFLAGS -ocamlopt "$OPT" -pkgs $PKGS main.native && \
mv main.native "$BIN"
