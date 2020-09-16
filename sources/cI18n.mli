(* CastANet - cI18n.mli *)

(** Internationalization. *)

type sentence = [
  | `CURRENT_PALETTE
]
(** Language-independent sentences. *)

val set : lang:string -> unit
(** Sets the current language. *)

val get : sentence -> string
(** Returns a sentence in the current language. *)
