(* CastANet - cAnnot.mli *)

open CExt

(** Multi-level annotation tables. *)

val auto_background : bool ref
(** If set to [true], tiles lacking annotations are automatically considered
  * background (default value: [true]). While convenient, this may be disabled
  * to allow for training using partially annotated pictures. *)

type note
(** The type for annotations. Currently, this browser can handle four types of
  * situations: no annotation, user-defined annotations, computer-generated
  * annotations (probabilities), and constraints arising from annotations at a
  * different level. *)

type table
(** The type for annotation table. Annotation table consists of three matrices
  * corresponding to the different annotation levels (basic, intermediate and
  * complete). *)

val code_list : CLevel.t -> char list  
(** Returns a character list containing all valid annotations for a given
  * annotation type. *)
  
val all_codes : char list
(** List of all available codes (irrespective of their level). *)
  
val colors : CLevel.t -> string list
(** Returns a string list containing the colors of the different annotation
  * types available at a given level. *)

type changelog = {
  user : (CLevel.t * string) list;   (** User-defined annotations. *)
  lock : (CLevel.t * string) list;   (** Switched off annotations. *)
  hold : (CLevel.t * string) list;   (** Switched on annotations.  *)
}
(** Changelog indicating the modifications made to the annotations. *)

val add : table -> CLevel.t -> r:int -> c:int -> char -> changelog option
(** [add t x ~r ~c chr] adds annotation [chr] at row [r] and column [c] in
  * level [x]-matrix of table [t], and returns a changelog of altered 
  * annotations in all other layers. These changes are to be reflected in the
  * user interface. The function returns [None] if no change was made. *)

val rem : table -> CLevel.t -> r:int -> c:int -> char -> changelog option
(** Same arguments as [add], but this function tries and remove a given 
  * annotation from a given tile. Again the changelog indicates the triggered 
  * modifications. *)

type note_type = [ 
  | `USER     (** Annotations defined by the user. *) 
  | `HOLD     (** Annotations constrained by other annotations. *)
  | `LOCK     (** Annotations made impossible by other annotations. *)
]

val get : table -> CLevel.t -> r:int -> c:int -> note_type -> string
(** [get t lvl ~r ~c nt] returns the annotations of type [nt] at row [r] and
  * column [c] in layer [lvl] of table [t]. *)

val load : string -> table option
(** Imports tables from a ZIP archive. Returns [None] in case of error. *)

val create : [ `DIM of (int * int) | `MAT of 'a EMatrix.t ] -> table
(** Creates an empty matrix with either the given dimensions, or by mapping an
  * existing matrix. *)

val save : table -> string -> unit
(** [export t s] exports table [t] as ZIP archive [s]. *)

val statistics : table -> CLevel.t -> (char * int) list
(** [statistics t lvl] returns the counts for each structure at level [lvl]
  * in table [t]. *)

val iter : (r:int -> c:int -> table -> unit) -> table -> CLevel.t -> unit
(** Table iterator. *)



