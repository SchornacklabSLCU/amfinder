(* CastANet - uI_Predictions.mli *)

(** GUI auxiliary module. Loads color palettes. *)

module type PARAMS = sig
  val parent : GWindow.window
  val packing : GObj.widget -> unit
  val border_width : int
  val tooltips : GData.tooltips
end

module type S = sig
  val toolbar : GButton.toolbar
  (** Main container. *)

  val palette : GButton.tool_button
  (** Displays a small utility window to select a palette. *)

  val set_icon : string array -> unit
  (** Updates the palette icon. *)

  val get_colors : unit -> string array
  (** Returns the colors associated with the current palette. *)

  val show_predictions : GButton.toggle_tool_button
  (** Display predictions. *)
  
  val show_activations : GButton.toggle_tool_button
  (** Display activation maps. *)
end

module Make : PARAMS -> S
(** Generator. *)
