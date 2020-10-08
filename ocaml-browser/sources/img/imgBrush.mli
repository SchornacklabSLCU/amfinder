(* CastANet Browser - imgPaint.mli *)

(** Image drawing functions. *)

class type brush = object

    method edge : int
    (** Returns tile size. *)

    method x_origin : int
    (** Returns drawing origin on X axis. *)

    method y_origin : int
    (** Returns drawing origin on Y axis. *)

    method backcolor : string
    (** Returns image background color. *)

    method set_backcolor : string -> unit
    (** Defines image background color. *)

    method background : ?sync:bool -> unit -> unit
    (** Draws a white background on the right image area.
      * @param sync defaults to [true]. *)

    method pixbuf : ?sync:bool -> r:int -> c:int -> GdkPixbuf.pixbuf -> unit
    (** [pixbuf ?sync ~r ~c p] draws pixbuf [p] at row [r] and column [c].
      * @param sync defaults to [false]. *)

    method surface : ?sync:bool -> r:int -> c:int -> Cairo.Surface.t -> unit
    (** [surface ?sync ~r ~c s] draws surface [s] at row [r] and column [c].
      * @param sync defaults to [false]. *)

    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draws the cursor.
      * @param sync defaults to [false]. *)

    method pointer : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draws the cursor at mouse pointer.
      * @param sync defaults to [false]. *)

    method annotation : ?sync:bool -> r:int -> c:int -> CLevel.t -> char -> unit
    (** Draws a tile annotation.
      * @param sync defaults to [false]. *)

    method sync : unit -> unit
    (** Synchronize drawings between the back pixmap and the drawing area. *)

end


val create : ImgSource.source -> brush
(** Creates drawing functions. *)
