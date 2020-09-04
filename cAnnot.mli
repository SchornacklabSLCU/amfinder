(* CastANet - cAnnot.mli *)

(** Annotations and rules. *)

type lock = string
type hold = string

val chars : CLevel.t -> string
(** Returns a string containing available annotations at a given level. *)

val char_list : CLevel.t -> char list
(** Same as above, but returns a list of characters. *)

val all_chars : string
(** All available characters, irrespective of the annotation level. *)

val all_chars_list : char list
(** Same as above, but returns a list of characters. *)

val rule : CLevel.t -> CLevel.t -> char -> hold * lock
(** [rule lvl1 lvl2 chr] returns the characters that are locked or on hold
  * when character [chr] gets activated between levels [lvl1] and [lvl2]. *)
  
val others : [ `CHR of char | `STR of string ] -> CLevel.t -> string
(** Returns the string containing all characters *)
