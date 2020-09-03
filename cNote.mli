(* CastANet - cNote.mli *)

(** Multi-layered annotations. *)

type t

type layer = [ `USER | `HOLD | `LOCK ]

val create : unit -> t

val of_string : string -> t

val to_string : t -> string

val get : t -> layer -> string
