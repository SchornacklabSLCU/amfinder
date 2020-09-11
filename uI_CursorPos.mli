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
end

module Make : PARAMS -> S
(** Generator. *)
