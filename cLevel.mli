(* CastANet - cLevel.mli *)

(** Annotation levels. *)

type t = [
  | `COLONIZATION   (** Basic annotation level (colonized vs non-colonized). *) 
  | `ARB_VESICLES   (** Intermediate level, with arbuscules and vesicles.    *)
  | `ALL_FEATURES   (** Fully-featured level, with IRH, ERH and hyphopodia.  *)
]
(** Annotation levels. *)

val available_levels : t list
(** List of available annotation levels. *)

val chars : t -> char list
(** Returns the list of valid characters at the given level. *)

val mem : t -> char -> bool
(** [mem lvl chr] indicates whether level [lvl] contains character [chr]. *)

val all_chars : string
(** All valid characters, irrespective of their level. *)

val all_chars_list : char list
(** Same as above, but as character list. *)

val colors : t -> string list
(** Returns the list of colors at the given level. *)
