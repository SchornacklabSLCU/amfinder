(* CastANet - cPaint.mli *)

(** Painting functions. Cairo surfaces and functions to draw background, tiles
  * and annotations on the UI drawing area. *)

(** {2 Cairo surfaces} *)

(** Cairo surfaces. *)
module Surface : sig
  val square :
    ?alpha:float -> 
    kind:[`CURSOR | `RGB of string] -> edge:int -> unit -> Cairo.Surface.t
  (** [square ~alpha:a ~kind:k ~edge:e ()] returns a square Cairo surface with
    * a transparency of [a] (defaults to [0.85]) and an edge of [e] pixels.
    * Square color is determined by the [kind] parameter, which can be bright 
    * red ([`CURSOR]) or any other color ([`RGB]). *)

  val joker : unit -> Cairo.Surface.t
  (** Cairo surface for joker layer (= any annotation). *)

  val cursor : unit -> Cairo.Surface.t
  (** Cairo surface for pointer tile. *)

  val pointer : unit -> Cairo.Surface.t
  (** Cairo surface for mouse pointer tile. *)
  
  val layers : (CLevel.t * (unit -> (char * Cairo.Surface.t) list)) list
  (** Cairo surfaces for the different annotation layers. *)

  val get_from_char : char -> Cairo.Surface.t
  (** Retrieves a surface from a character. The following special characters
    * are used: ['*'] returns the joker surface, while ['.'] returns the mouse
    * pointer surface. *)
end


(** {2 General drawing functions} *)

val white_background : ?sync:bool -> unit -> unit
(** Draws a white background on the right image area.
  * @param sync defaults to [true]. *)

val tiles : ?sync:bool -> unit -> unit
(** Draws all tiles from the active image.
  * @param sync defaults to [true]. *)

val tile : ?sync:bool -> r:int -> c:int -> unit -> unit
(** [tile ?sync ~r ~c] draws the tile at row [r] and column [c].
  * @param sync defaults to [false]. *)

val surface : ?sync:bool -> r:int -> c:int -> Cairo.Surface.t -> unit
(** Draws a Cairo surface.
  * @param [sync] defaults to [false]. *)

val annot : ?sync:bool -> r:int -> c:int -> unit -> unit
(** [annot ?sync ~r ~c] draws the annotations at row [r] and column [c].
  * @param sync defaults to [false]. *)

val cursor : ?sync:bool -> unit -> unit
(** Draws the cursor.
  * @param sync defaults to [false]. *)

val active_layer : ?sync:bool -> unit -> unit
(** Draws the active layer.
  * @param sync defaults to [true]. *)


(** {2 Color Palettes} *)

module Palette : sig
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
    * (this is zero-based, so the total number of groups is obtained by adding
    * one to the returned value). *)

  val surface : id -> int -> Cairo.Surface.t
  (** [surface id n] returns the Cairo surface corresponding to group [n] in
    * palette [id]. *)
    
  val color : id -> int -> string
  (** [color id n] returns the HTML color (["#RRGGBB"]) corresponding to 
    * group [n] in palette [id]. *)
end
