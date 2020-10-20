(* CastANet - uI_Predictions.mli *)

(** GUI auxiliary module. Loads color palettes. *)

module type PARAMS = sig
  val parent : GWindow.window
  val packing : #GButton.tool_item_o -> unit
  val border_width : int
  val tooltips : GData.tooltips
end

module type S = sig

    val palette : GButton.tool_button
    (** Displays a small utility window to select a palette. *)

    val set_icon : string array -> unit
    (** Updates the palette icon. *)

    val get_colors : unit -> string array
    (** Returns the colors associated with the current palette. *)

    val set_choices : string list -> unit
    (** Sets prediction list. *)
    
    val get_active : unit -> string option
    (** Tells which prediction is active. *)

    val overlay : GButton.toggle_tool_button
    (** Button that allows to select the predictions to display. *)

    val palette : GButton.tool_button
    (** Color palette selector. *)

    val cams : GButton.toggle_tool_button
    (** Indicates whether CAMs are to be displayed or not. *)

    val apply : GButton.tool_button
    (** Converts predictions to annotations. *)

end

module Make : PARAMS -> S
(** Generator. *)
