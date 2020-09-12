(* CastANet - cPaint.mli *)

(** Painting functions. This module implements Cairo surfaces and functions to 
  * draw background, tiles and annotations on the UI drawing area. *)

(** {2 Cairo surfaces} *)

(** Memoized Cairo surfaces. *)
module Surface : sig
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

val background : ?color:string -> ?sync:bool -> unit -> unit
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
  type palette
  (** The type of color palettes. *)

  val load : unit -> unit
  (** Loads color palettes. *)

  val mem : string -> bool
  (** Indicates whether a palette exists. *)

  val get : string -> palette
  (** Retrieves a given color palette by name. *)

  val max_group : palette -> int
  (** Returns the identifier of the last group the given palette can represent 
    * (this is zero-based, so the total number of groups is obtained by adding
    * one to the returned value). *)

  val surfaces : palette -> Cairo.Surface.t array
  (** Returns all Cairo surfaces for a given palette. *)
    
  val colors : palette -> string array
  (** Returns all (as HTML-formatted) colors used in the given palette. *)
end
