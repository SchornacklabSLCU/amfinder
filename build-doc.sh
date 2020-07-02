#! /bin/bash

BIN="castanet-editor"
OPT='ocamlopt.opt'
CFLAGS='-w,s,-g'
OPT="ocamlopt -nodynlink -O3 -principal -inline 200"
PKGS='lablgtk2,cairo2,cairo2-gtk'
MLI="$(ocamldsort c*ml | sed 's/ml/mli/g')"
ODIRS="-I +/../lablgtk2 -I +/../cairo2 -I +/../cairo2-gtk -I _build"

eval `opam config env` && \
ocamldoc $ODIRS -t 'CastANet Editor' -html -d html-doc -stars $MLI
