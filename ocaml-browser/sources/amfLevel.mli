(* CastANet - amfLevel.mli *)

(** Annotation levels. *)

type level =
  | COLONIZATION   (** Basic annotation level (colonized vs non-colonized). *) 
  | MYC_STRUCTURES   (** Fully-featured level, with IRH, ERH and hyphopodia.  *)
(** Annotation levels. *)

val to_string : level -> string
(** [to_string t] returns the textual representation of the level [t]. *)

val of_string : string -> level
(** [of_string s] returns the level corresponding to the string [s]. *)

val to_header : level -> char list
(** [to_header t] returns the header associated with annotation level [t]. *)

val of_header : char list -> level
(** [of_header t] returns the annotation level associated with header [t]. *)

val chars : level -> Morelib.CSet.t
(** Returns the string set containing all available chars at a given level. *)

val char_index : level -> char -> int
(** Index of the given char at the given level. *)

val all_flags : level list
(** List of available annotation levels, sorted from lowest to highest. *)

val all_chars_list : char list
(** All available annotations. *)

val lowest : level
(** Least detailed level of mycorrhiza annotation. *)

val highest : level
(** Most detailed level of mycorrhiza annotation. *)

val others : level -> level list
(** [other t] returns the list of all annotations levels but [t]. *)

val colors : level -> string list
(** [colors t] returns the list of RGB colors to use to display annotations at
  * level [t]. *)

val symbols : level -> string list
(** Short symbols for annotation legend. *) 

(** Annotation rules. *)
module type ANNOTATION_RULES = sig

    val add_add : char -> Morelib.CSet.t
    (** Returns the annotations to add when a given annotation is added. *)

    val add_rem : char -> Morelib.CSet.t
    (** Returns the annotations to remove when a given annotation is added. *)

    val rem_add : char -> Morelib.CSet.t
    (** Returns the annotations to add when a given annotation is removed. *)

    val rem_rem : char -> Morelib.CSet.t
    (** Returns the annotations to remove when a given annotation is removed. *)

end

val rules : level -> (module ANNOTATION_RULES)
(** Returns the rules associated with a given annotation level. *)
