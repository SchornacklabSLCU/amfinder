(* CastANet - cPalette.mli *)

(** Color palettes. *)

type id = [
  | `CIVIDIS
  | `PLASMA 
  | `VIRIDIS
]
(** The available palettes. *)

val set_tile_edge : int -> unit
(** Initialization function. This functions is required to define the size of
  * an individual size, in pixels. *)

val max_group : id -> int
(** Returns the identifier of the last group the given palette can represent 
  * (this is zero-based, so the total number of groups is obtained by adding one
  * to the returned value). *)

val surface : id -> int -> Cairo.Surface.t
(** [surface id n] returns the Cairo surface corresponding to group [n] in
  * palette [id]. *)
  
val color : id -> int -> string
(** [color id n] returns the HTML color (["#RRGGBB"]) corresponding to 
  * group [n] in palette [id]. *)
