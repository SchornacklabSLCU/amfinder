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

val add : table -> level -> r:int -> c:int -> char -> changelog option
(** [add t x ~r ~c chr] adds annotation [chr] at row [r] and column [c] in
  * level [x]-matrix of table [t], and returns a changelog of altered 
  * annotations in all other layers. These changes are to be reflected in the
  * user interface. The function returns [None] if no change was made. *)

val rem : table -> level -> r:int -> c:int -> char -> changelog option
(** Same arguments as [add], but this function tries and remove a given 
  * annotation from a given tile. Again the changelog indicates the triggered 
  * modifications. *)

val load : string -> table option
(** Imports tables from a ZIP archive. Returns [None] in case of error. *)

val create : [ `DIM of (int * int) | `MAT of 'a CExt.Matrix.t ] -> table
(** Creates an empty matrix with either the given dimensions, or by mapping an
  * existing matrix. *)

val save : table -> string -> unit
(** [export t s] exports table [t] as ZIP archive [s]. *)
