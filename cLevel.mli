(* CastANet - cLevel.mli *)

(** Annotation levels. *)

type t = [
  | `COLONIZATION   (** Basic annotation level (colonized vs non-colonized). *) 
  | `ARB_VESICLES   (** Intermediate level, with arbuscules and vesicles.    *)
  | `ALL_FEATURES   (** Fully-featured level, with IRH, ERH and hyphopodia.  *)
]
(** Annotation levels. *)

val flags : t list
(** List of available annotation levels, sorted from lowest to highest. *)

val strings : string list
(** String representation of the available annotations levels, sorted from
  * lowest to highest. *)

val lowest : t
(** Least detailed level of mycorrhiza annotation. *)

val highest : t
(** Most detailed level of mycorrhiza annotation. *)

val others : t -> t list
(** [other lvl] returns the two other levels than [lvl], sorted from lowest to
  * highest. *)

val colors : t -> string list
(** Returns the list of colors at the given level. *)

val to_string : t -> string

val of_string : string -> t
