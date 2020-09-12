(* CastANet - uI_Palette.mli *)

module type PARAMS = sig
  val packing : GObj.widget -> unit
end

module type S = sig
  val toolbar : GButton.toolbar
  (** Main container. *)

  val current : unit -> CIcon.palette
  (** Returns the current palette. *)

  val viridis : GButton.radio_tool_button * GMisc.image
  (** Activates the viridis palette. *)
  
  val cividis : GButton.radio_tool_button * GMisc.image
  (** Activates the cividis palette. *)
  
  val plasma : GButton.radio_tool_button * GMisc.image
  (** Activates the plasma palette. *)
end

module Make : PARAMS -> S
(** Generator. *)
