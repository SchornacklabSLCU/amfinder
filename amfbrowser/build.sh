#! /bin/bash

OUT="amfbrowser.exe"

rm -f "$OUT" 2> /dev/null && \
cd "sources" && \
dune build "$OUT" && \
cd .. && \
mv "sources/_build/4.08.0/$OUT" .
