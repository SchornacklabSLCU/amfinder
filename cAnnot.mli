(* CastANet - cAnnot.mli *)

(** Annotations and rules. *)

type lock = string
type hold = string

val get_rule : CLevel.t -> CLevel.t -> char -> hold * lock
(** [get_rule lvl1 lvl2 chr] returns the characters that are locked or on hold
  * when character [chr] gets activated between levels [lvl1] and [lvl2]. *)
  
val others : [ `CHR of char | `STR of string ] -> CLevel.t -> string
(** Returns the string containing all characters *)
