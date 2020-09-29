(* CastANet - uI_TileSet.mli *)

module type PARAMS = sig
  val parent : GWindow.window
  val spacing : int
  val border_width : int
  val window_width : int
  val window_height : int
  val window_title : string
end

module type S = sig
  val add : r:int -> c:int -> ico:GdkPixbuf.pixbuf -> GdkPixbuf.pixbuf -> unit
  (** [add r c pix] adds the tile [pix] using coordinates [(r, c)] as legend. *)

  val run : unit -> [`OK | `SAVE | `DELETE_EVENT]
  (** Displays the dialog and returns the output flag. *)

  val set_title : ('a, unit, string, unit) format4 -> 'a
  (** Sets tile set title, using [printf]-like style. *)

  val hide : unit -> unit
  (** Hides the tile set and clears all tiles. *)
end

module Make : PARAMS -> S
(** Generator. *)
