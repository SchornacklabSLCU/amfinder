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

val rule : 
  CLevel.t -> 
  CLevel.t -> 
  [`CHR of char | `STR of string] -> hold * lock
(** [rule lvl1 lvl2 elt] returns the characters that are locked or on hold
  * when the element [elt] gets activated between levels [lvl1] and [lvl2].
  * [elt] can be a single character or a string. In the latter case, the
  * rules associated with individual characters are combined. *)

val others : [ `CHR of char | `STR of string ] -> CLevel.t -> string
(** Returns the string containing all characters *)

val mem : [ `CHR of char | `STR of string ] -> CLevel.t -> bool
(** Indicates whether the given character (or all characters from the given 
  * string) are available at the given level. *)
