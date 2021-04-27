#! /bin/bash

$OPAM init

$OPAM switch create 4.08.0

eval $($OPAM env)

$OPAM install dune odoc lablgtk cairo2 cairo2-gtk magic-mime camlzip

eval $($OPAM env)
