(* CastANet - cTile.mli *)

(** Multi-layered annotations. *)

type t
(** The annotation type. *)

type layer = [ 
  | `USER   (** User-defined annotations. *)
  | `HOLD   (** Annotations on hold.      *)
  | `LOCK   (** Locked annotations.       *)
]
(** The different layers of annotations. *)

val create : unit -> t
(** Creates an empty annotation. *)

val of_string : string -> t
(** Retrieves a note from its string representation.
  * @raise Invalid_argument when given a malformed string. *)

val to_string : t -> string
(** Returns the string representation of the given annotation. *)

val get : t -> layer -> string
(** Retrieves an annotation at a given layer. *)

val set : t -> layer -> [`CHR of char | `STR of string] -> unit
(** Updates the annotation at a given layer. *)

val add : t -> layer -> [`CHR of char | `STR of string] -> unit
(** Adds an annotation at the given layer. *)

val remove : t -> layer -> [`CHR of char | `STR of string] -> unit
(** Removes an annotation from the given layer. *)

val mem : t -> layer -> [`CHR of char | `STR of string] -> bool
(** Indicates whether an annotation exists in the given layer. *)
