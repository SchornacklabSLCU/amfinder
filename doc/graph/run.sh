#! /bin/bash

cd ../..

ocamldep -one-line *.ml *.mli \
  | grep -v "cmx" \
  | ./doc/graph/mkgraph.py \
  | dot -Tpng > ./doc/graph/dep_graph.png
