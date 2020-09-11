(* CastANet - uI_Magnifier.mli *)

(** GUI auxiliary module. Implements a magnified view of the 3x3 tile square
  * surrounding the cursor position. *)

(** Module parameters. *)
module type PARAMS = sig
  val rows : int
  (** Number of tiles to display on the Y axis. *)

  val columns : int
  (** Number of tiles to display on the X axis. *)

  val tile_edge : int
  (** Size, in pixels, of a magnified tile. *)
  
  val packing : GObj.widget -> unit
  (**  *)
end

(** Output module. *)
module type S = sig
  val tiles : GMisc.image array array
  (** Tiles (3 x 3 matrix) for magnified view of the cursor area. The 
    * annotations shown in [HToolbox] correspond to the central tile. *)

  val set_pixbuf : r:int -> c:int -> GdkPixbuf.pixbuf -> unit
  (** [set_pixbuf ~r ~c p] displays pixbuf [p] at row [r] and column [c]. *)
end

module Make : PARAMS -> S
(** Generator. *)
