(* The Automated Mycorrhiza Finder version 1.0 - amfPar.ml *)

open Arg
open Printf

let edge = ref 40
let path = ref None

let set_image_path x = if Sys.file_exists x then path := Some x

let usage = "amfinder.exe [OPTIONS] [IMAGE_PATH]"

let specs = align [
    "-t", Set_int edge, sprintf 
        " Tile size used for image segmentation (default: %d pixels)." !edge;
    "--tile", Set_int edge,
        sprintf " Tile size used for image segmentation (default: %d pixels)." !edge;
]
let initialize () = parse specs set_image_path usage
