(* CastANet - cGUI.mli *)

(** Graphical user interface. *)

val window : GWindow.window
(** Application main window. *)

(** Horizontal toolbox (left pane). *)
module HToolbox : sig
  val toggles : (char * (GButton.toggle_button * GMisc.image)) array
  (** Table of toggle buttons corresponding to the different annotations. *)
  val toggle_any : char -> unit
  (** Inverts the status of the given toggle button. *)
end


(** Magnified view of the cursor area. *)
module Magnify : sig
  val edge : int
  (** Size (in pixels) of an individual tile.  *)
  val tiles : GMisc.image array array
  (** Tiles (3 x 3 matrix) for magnified view of the cursor area. The 
    * annotations shown in [HToolbox] correspond to the central tile. *)
end


(** Whole image (right pane). *)
module Thumbnail : sig
  val area : GMisc.drawing_area
  (** Drawing area were the whole image is displayed. *)
  val cairo : unit -> Cairo.context
  (** Cairo context used to overlay annotation information. *)
  val pixmap : unit -> GDraw.pixmap
  (** Backing pixmap used to draw offscreen. *)
  val width : unit -> int
  (** Width of the drawing area, in pixels. *)
  val height : unit -> int
  (** height of the drawing area, in pixels. *)
  val refresh : GdkEvent.Expose.t -> bool
  (** Call to this functions refreshes the display. *)
  val synchronize : unit -> unit
  (** Synchronize the backing [pixmap] with the foreground [area]. *)
end


(** Vertical toolbox (right pane). *)
module VToolbox : sig
  val master : GButton.radio_tool_button * GMisc.image
  (** Main radio button. When active, all annotated tile get overlaid with a 
    * green square, no matter what the annotation is. *) 
  val radios : (char * (GButton.radio_tool_button * GMisc.image)) list
  (** Layer-specific radio buttons. When active, only tiles bearing the
    * corresponding annotation are displayed. *)  
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
  val export : GButton.tool_button
  (** Saves the current display as a PNG file (currently not implemented). *)
  val preferences : GButton.tool_button
  (** Shows preferences dialog (currently not implemented). *)
end

val status : GMisc.label
(** Label used as a status bar. It displays general information related to the 
  * loaded image, such as height and width (in pixels). *)