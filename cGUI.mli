(* CastANet - cGUI.mli *)

(** Graphics user interface. *)

val window : GWindow.window
(** Application main window. *)

(** Magnified view (left pane). *)
module Zoom : sig
  val toggles : (char * GButton.toggle_button) list 
  val toggles_full : (char * (GButton.toggle_button * GMisc.image)) list
  val toggle_any : char -> unit
end

val edge : int

val tiles : (GPack.box * GMisc.image) array array

(** Whole image (right pane). *)
module Thumbnail : sig
  val frame : GBin.frame
  val area : GMisc.drawing_area
  val cairo : unit -> Cairo.context
  val pixmap : unit -> GDraw.pixmap
  val width : unit -> int
  val height : unit -> int
  val refresh : GdkEvent.Expose.t -> bool
  val synchronize : unit -> unit
end

(** Annotation layers. *)
module Layers : sig
  val toolbar : GButton.toolbar
  open GButton
  val master : radio_tool_button
  val radios : (char * radio_tool_button) list
  val master_full : radio_tool_button * GMisc.image
  val radios_full : (char * (radio_tool_button * GMisc.image)) list
  val get_active : unit -> [`CHR of char | `SPECIAL]
  val export : GButton.tool_button
  val preferences : GButton.tool_button
  val row : GMisc.label
  val column : GMisc.label
  val confidence : GMisc.label
  val confidence_color : GMisc.label
end

val status : GMisc.label
