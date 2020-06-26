(* CastANet - cGUI.mli *)

(** Graphical user interface. *)

val window : GWindow.window
(** Application main window. *)

(** Horizontal toolbox (left pane). *)
module HToolbox : sig
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


(** Vertical toolbox (right pane). *)
module VToolbox : sig
  val master : GButton.radio_tool_button * GMisc.image
  (** Main radio button. When active, all annotated tile get overlaid with a 
    * green square, no matter what the annotation is. *) 

  val radios : (char * (GButton.radio_tool_button * GMisc.image)) list
  (** Layer-specific radio buttons. When active, only tiles bearing the
    * corresponding annotation are displayed. *)
  
  val export : GButton.tool_button
  (** Saves the current display as a PNG file (currently not implemented). *)
  
  val preferences : GButton.tool_button
  (** Shows preferences dialog (currently not implemented). *)
  
  val row : GMisc.label
  (** Indicates the current row index. *)

  val column : GMisc.label
  (** Indicate the current column index. *)
  
  val confidence : GMisc.label
  (** To be primarily used with computer-generated annotations. Indicates how
    * confident the annotation is (using percentage). *)
  
  val confidence_color : GMisc.label
  (** To be primarily used with computer-generated annotations. This label
    * displays the Viridis colour corresponding to the percentage displayed by
    * the label [confidence] (see above). *)

  val get_active : unit -> [`CHR of char | `SPECIAL]
  (** Indicates which layer is currently active ([`SPECIAL] corresponds to
    * [master], while [`CHR _] corresponds to elements of the list [radios]
    * (see above). *)
end

val status : GMisc.label
(** Label used as a status bar. It displays general information related to the 
  * loaded image, such as height and width (in pixels). *)
