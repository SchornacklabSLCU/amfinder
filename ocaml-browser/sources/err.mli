(* The Automated Mycorrhiza Finder version 1.0 - err.mli *)


val out_of_bounds : int

val invalid_argument : int

module Level : sig
    val unknown_level : int   
    val invalid_level_header : int
end

module Annot : sig
    val invalid_character : int
end

module Image : sig
    val unknown_annotation_file : int
end
