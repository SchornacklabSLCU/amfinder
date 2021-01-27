(* AMFinder - amfPar.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

open Arg
open Printf

let edge = ref 126
let print_large_maps = ref false
let path = ref None
let debug = ref false
let threshold = ref 0.5

let verbose () = !debug

let set_image_path x = if Sys.file_exists x then path := Some x

let usage = "amfbrowser.exe [OPTIONS] [[IMAGE] ...]"

let specs = align [
    "-t", Set_int edge, sprintf 
        " Tile size used for image segmentation (default: %d pixels)." !edge;
    "--tile", Set_int edge, sprintf
        " Tile size used for image segmentation (default: %d pixels)." !edge;
    "-m", Set print_large_maps, sprintf
        " Print colonisation map (default: %b)." !print_large_maps;
    "--map", Set print_large_maps, sprintf
        " Print colonisation map (default: %b)." !print_large_maps;
    "-th", Set_float threshold, sprintf 
        " Annotation probability threshold (default: %.1f)." !threshold;
    "--threshold", Set_float threshold, sprintf
        " Annotation probability threshold (default: %.1f)." !threshold;
    "-v", Set debug, sprintf 
        " Runs the application in verbose/debugging mode (default: %b)." !debug;
    "--verbose", Set debug, sprintf 
        " Runs the application in verbose/debugging mode (default: %b)." !debug;
]

let initialize () = parse specs set_image_path usage
