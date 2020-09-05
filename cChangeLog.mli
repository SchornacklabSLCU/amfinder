(* CastANet - cChangeLog.mli *)

(** Change logs. *)

type t
(** The type for change logs. *)

val create : unit -> t
(** Creates an empty change log. *)

val is_empty : t -> bool
(** Indicates whether the change log is empty. *)

val add : t -> CNote.layer -> CLevel.t * string -> t
(** [add log t (lvl, str)] adds annotations [str] at level [lvl] in layer [t]
  * of changelog [log]. The changelog is left unchanged if annotations [str]
  * are already present at this level. *)

val remove : t -> CNote.layer -> CLevel.t * string -> t
(** Same principle as above, but to remove annotations from the changelog.
  * Use ["*"] to remove all annotations at a given level. *)
