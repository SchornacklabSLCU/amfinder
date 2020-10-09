(* CastANet - cLevel.mli *)

(** Annotation levels. *)

type t = [
  | `COLONIZATION   (** Basic annotation level (colonized vs non-colonized). *) 
  | `ARB_VESICLES   (** Intermediate level, with arbuscules and vesicles.    *)
  | `ALL_FEATURES   (** Fully-featured level, with IRH, ERH and hyphopodia.  *)
]
(** Annotation levels. *)


val to_string : t -> string
(** [to_string t] returns the textual representation of the level [t]. *)


val of_string : string -> t
(** [of_string s] returns the level corresponding to the string [s]. *)


val to_header : t -> char list
(** [to_header t] returns the header associated with annotation level [t]. *)


val of_header : char list -> t
(** [of_header t] returns the annotation level associated with header [t]. *)


val all_flags : t list
(** List of available annotation levels, sorted from lowest to highest. *)


val lowest : t
(** Least detailed level of mycorrhiza annotation. *)


val highest : t
(** Most detailed level of mycorrhiza annotation. *)


val others : t -> t list
(** [other t] returns the list of all annotations levels but [t]. *)


val colors : t -> string list
(** [colors t] returns the list of RGB colors to use to display annotations at
  * level [t]. *)


