(* The Automated Mycorrhiza Finder version 1.0 - err.ml *)

let out_of_bounds = 2

let invalid_argument = 3

module Level = struct
    let base = 10
    let unknown_level = base + 1
    let invalid_level_header = base + 2
end

module Annot = struct
    let base = 20
    let invalid_character = base + 1
end

module Image = struct
    let base = 30
    let unknown_annotation_file = base + 1
end
