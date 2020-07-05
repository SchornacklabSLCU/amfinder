(* CastANet - cSettings.mli *)

(** User settings. *)

val initialize : unit -> unit
(** Reads command-line arguments. *)

val image : unit -> string
(** Returns the image to be loaded. *)

val palette : unit -> CPalette.id
(** Returns the color palette to be used. *)

val edge : unit -> int
(** Square edge. *)
