(* CastANet - cAnnot.mli *)

(** Multi-level annotation manager. *)

val auto_background : bool ref
(** If set to [true], tiles lacking annotations are automatically considered
  * background (default value: [true]). While convenient, this may be disabled
  * to allow for training using partially annotated pictures. *)

type note
(** The type for annotations. Currently, this browser can handle four types of
  * situations: no annotation, user-defined annotations, computer-generated
  * annotations (probabilities), and constraints arising from annotations at a
  * different level. *)

type level = [`COLONIZATION | `ARB_VESICLES | `ALL_FEATURES]
(** Annotation levels. *)

type table
(** The type for annotation table. Annotation table consists of three matrices
  * corresponding to the different annotation levels (basic, intermediate and
  * complete). *)

val code_list : level -> string list  
(** Returns a character list containing all valid annotations for a given
  * annotation type. *)

type changelog = {
  user : (level * string) list;   (** User-defined annotations. *)
  lock : (level * string) list;   (** Switched off annotations. *)
  hold : (level * string) list;   (** Switched on annotations.  *)
}
(** Changelog indicating the modifications made to the annotations. *)

val get : table -> level -> r:int -> c:int -> changelog
(** [get t x ~r ~c] returns the current status of the tile at row [t] and
  * column [c] in the level [x]-matrix of table [t]. *)

val add : table -> level -> r:int -> c:int -> char -> changelog option
(** [add t x ~r ~c chr] adds annotation [chr] at row [r] and column [c] in
  * level [x]-matrix of table [t], and returns a changelog of altered 
  * annotations in all other layers. These changes are to be reflected in the
  * user interface. The function returns [None] if no change was made. *)

val rem : table -> level -> r:int -> c:int -> char -> changelog option
(** Same arguments as [add], but this function tries and remove a given 
  * annotation from a given tile. Again the changelog indicates the triggered 
  * modifications. *)




val import : string -> table option
(** Imports tables from a ZIP archive. Returns [None] in case of error. *)

val export : table -> string -> unit
(** [export t s] exports table [t] as ZIP archive [s]. *)




val set : table -> level -> r:int -> c:int -> char -> unit
(** [set t l ~r ~c a] sets annotation [a] to tile at row [r] and column [c] in
  * table [t] at annotation level [l]. This function updates the annotation and
  * propagates the constraints at other levels. *)

val add : table -> level -> r:int -> c:int -> char -> bool
(** Same as [set] above, but the function behaves as a query and returns a
  * boolean which indicates whether any change has been made. *)

val mem : table -> int -> int -> level -> char -> bool
(** [mem t c] checks whether tag [c] is part of the annotation [t]. *)

val get : t -> char -> float
(** Get the confidence associated with the given annotation. *)

val rem : t -> char -> unit
(** [rem t c] removes tag [c] from the annotation [t]. *)

val get_group : ?palette:CPalette.id -> t -> char -> int
(** Returns the group which the probability belongs. By default, returns 
  * deciles (useful when using a color gradient). *)

val get_active : t -> string
(** Return all active annotations. *)
