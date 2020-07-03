#! /bin/bash

OUT="castanet_editor.exe"
rm -f "$OUT" 2> /dev/null && dune build "$OUT" && mv "_build/4.08.0/$OUT" . 
