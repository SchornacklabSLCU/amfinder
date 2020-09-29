#! /bin/bash

cd ../../ocaml-browser/sources

ocamldep -one-line *.ml *.mli \
  | grep -v "cmx" \
  | ../../doc/graph/mkgraph.py \
  | tee ../../doc/graph/dep_graph.dot \
  | dot -x -Tpng > ../../doc/graph/dep_graph.png
