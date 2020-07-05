(* CastANet - cSettings.mli *)

(** User settings. *)

val initialize : ?cmdline:bool -> unit -> unit
(** Reads command-line arguments. The optional parameter can be used to disable 
  * parsing command line arguments. *)

val image : unit -> string
(** Returns the image to be loaded. *)

val palette : unit -> CPalette.id
(** Returns the color palette to be used. *)

val edge : unit -> int
(** Square edge. *)

val erase_image : unit -> unit
(** Removes the current image. *)
