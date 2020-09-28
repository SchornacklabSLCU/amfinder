(* CastANet Browser - imgDraw.mli *)

(** Image drawing functions. *)

class type t = object

    method edge : int
    (** Returns tile size. *)

    method x_origin : int
    (** Returns drawing origin on X axis. *)

    method y_origin : int
    (** Returns drawing origin on Y axis. *)

    method cursor_pos : int * int
    (** Returns cursor position. *)

    method set_cursor_pos : (int * int) -> unit
    (** Defines cursor position. *)

    method backcolor : string
    (** Returns image background color. *)

    method set_backcolor : string -> unit
    (** Defines image background color. *)

    method background : ?sync:bool -> unit -> unit
    (** Draws a white background on the right image area.
      * @param sync defaults to [true]. *)

    method mosaic : ?sync:bool -> unit -> unit
    (** Draws all tiles from the given image.
      * @param sync defaults to [true]. *)

    method tile : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** [tile ?sync ~r ~c] draws the tile at row [r] and column [c].
      * @param sync defaults to [false]. *)

    method cursor : ?sync:bool -> unit -> unit
    (** Draws the cursor.
      * @param sync defaults to [false]. *)

    method pointer : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draws the cursor at mouse pointer.
      * @param sync defaults to [false]. *)

    method annotation : ?sync:bool -> r:int -> c:int -> CLevel.t -> char -> unit
    (** Draws a tile annotation.
      * @param sync defaults to [true]. *)

end


val create : ImgSource.t -> ImgTileMatrix.t -> t
(** Creates drawing functions. *)
