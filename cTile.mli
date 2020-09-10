(* CastANet - cTile.mli *)

(** Multi-layered annotations. *)

type tile
(** The annotation type. *)

type layer = [ 
  | `USER   (** User-defined annotations. *)
  | `HOLD   (** Annotations on hold.      *)
  | `LOCK   (** Locked annotations.       *)
]
(** The different layers of annotations. *)

val create : unit -> tile
(** Creates an empty annotation. *)

val make :
  ?user:[`CHR of char | `STR of string] -> 
  ?lock:[`CHR of char | `STR of string] ->
  ?hold:[`CHR of char | `STR of string] -> unit -> tile
(** Same as create, but can specify individual values at creation time. *)

val of_string : string -> tile
(** Retrieves a note from its string representation.
  * @raise Invalid_argument when given a malformed string. *)

val to_string : tile -> string
(** Returns the string representation of the given annotation. *)

val get : tile -> layer -> string
(** Retrieves an annotation at a given layer. *)

val set : tile -> layer -> [`CHR of char | `STR of string] -> unit
(** Updates the annotation at a given layer. *)

val add : tile -> layer -> [`CHR of char | `STR of string] -> unit
(** Adds an annotation at the given layer. *)

val remove : tile -> layer -> [`CHR of char | `STR of string] -> unit
(** Removes an annotation from the given layer. *)

val is_empty : tile -> layer -> bool
(** Indicates whether the given annotations is empty. *)

val mem : tile -> layer -> [`CHR of char | `STR of string] -> bool
(** Indicates whether an annotation exists in the given layer. *)
