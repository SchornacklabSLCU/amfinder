(* CastANet - cPalette.mli *)

(** Color palettes. *)

type id = [ `VIRIDIS | `SUNSET ]
(** The available palettes. *)

val set_tile_edge : int -> unit
(** Initialization function. This functions is required to define the size of
  * an individual size, in pixels. *)

val max_group : id -> int
(** Returns the identifier of the last group the given palette can represent 
  * (this is zero-based, so the total number of groups is obtained by adding one
  * to the returned value). *)

val surface : int -> id -> Cairo.Surface.t
(** [surface n id] returns the Cairo surface corresponding to group [n] in
  * palette [id]. *)
  
val color : int -> id -> string
(** [color n id] returns the HTML color (["#RRGGBB"]) corresponding to 
  * group [n] in palette [id]. *)
