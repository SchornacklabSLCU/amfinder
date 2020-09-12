(* CastANet - uI_CursorPos.mli *)

(** GUI auxiliary module. Handles cursor position and displays coordinates. *)

(** Input parameters. *)
module type PARAMS = sig
  val packing : top:int -> GObj.widget -> unit
  (** Packing function to attach the vertical toolbar that displays cursor
    * coordinates to the user interface. *)
end

(** Output parameters. *)
module type S = sig
  val toolbar : GButton.toolbar
  (** Vertical toolbar. *)

  val row : GMisc.label
  (** GtkLabel that displays the current row index. *)

  val column : GMisc.label
  (** GtkLabel that displays the current column index. *)

  val get : unit -> int * int
  (** Returns the current cursor position. *)

  val set : r:int -> c:int -> unit
  (** [set ~r ~c] defines [(r, c)] as the new cursor position. Both [r] and [c]
    * must not be negative (please note: this function has no access to the
    * internal matrix and therefore cannot check the upper limit). *)
end

module Make : PARAMS -> S
(** Generator. *)
