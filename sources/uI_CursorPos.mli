(* CastANet - uI_CursorPos.mli *)

module type PARAMS = sig
  val packing : top:int -> GObj.widget -> unit
end

module type S = sig
  val toolbar : GButton.toolbar
  (** Main container. *)

  val row : GMisc.label
  (** Indicates the current row index. *)

  val column : GMisc.label
  (** Indicate the current column index. *)

  val get : unit -> int * int
  (** [get ()] returns the current position of the cursor on the tile matrix. *)

  val set : r:int -> c:int -> unit
  (** [set ~r ~c] defines [(r, c)] as the new coordinates of the cursor on the
    * tile matrix. This is a storage function only, which only ensures the
    * given values are greater than zero (upper limits are not checked). *)
end

module Make : PARAMS -> S
(** Generator. *)
