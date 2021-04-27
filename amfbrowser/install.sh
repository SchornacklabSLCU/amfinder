#! /bin/bash

OPAM="${OPAM:-$(which opam)}"

# Windows users may have to uncomment (remove #) --disable-sandboxing below:
$OPAM init #--disable-sandboxing
$OPAM switch create 4.08.0

eval $($OPAM env)

$OPAM install dune odoc lablgtk cairo2 cairo2-gtk magic-mime camlzip

eval $($OPAM env)

./build.sh

DIR="$HOME/.local/share/amfinder"

mkdir -p "$DIR"

cp -r data "$DIR" 
