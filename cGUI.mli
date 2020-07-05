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
  (** Height of the drawing area, in pixels. *)

  val synchronize : unit -> unit
  (** Synchronizes the backing [pixmap] with the foreground [area]. *)
end



(** Vertical toolbox (right pane). *)
module VToolbox : sig
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

  val get_active : unit -> [`CHR of char | `JOKER]
  (** Indicates which layer is currently active ([`JOKER] corresponds to
    * [master], while [`CHR _] corresponds to elements of the list [radios]
    * (see above). *)

  val export : GButton.tool_button
  (** Saves the current display as a PNG file (currently not implemented). *)

  val preferences : GButton.tool_button
  (** Shows preferences dialog (currently not implemented). *)

  type radio_type = [`JOKER | `CHR of char]
  (** The type of radio buttons. *)

  val is_active : radio_type -> bool
  (** Indicates whether the given layer is active. *)

  val set_label : radio_type -> int -> unit
  (** Updates the counter of the given annotation. *)

  val set_image : radio_type -> GdkPixbuf.pixbuf -> unit
  (** Updates the icon of the given annotation. *)

  val iter_radios : (radio_type -> unit) -> unit
  (** Iterator over radio buttons. *)

  val set_toggled : radio_type -> (unit -> unit) -> GtkSignal.id
  (** Sets a callback function to call when a button is toggled. *)
end



val status : GMisc.label
(** Label used as a status bar. It displays general information related to the 
  * loaded image, such as height and width (in pixels). *)



(** Auxiliary window to display all tiles sharing a given annotation. *)
module TileSet : sig
  val add : r:int -> c:int -> ico:GdkPixbuf.pixbuf -> GdkPixbuf.pixbuf -> unit
  (** [add r c pix] adds the tile [pix] using coordinates [(r, c)] as legend. *)

  val run : unit -> [`OK | `SAVE | `DELETE_EVENT]
  (** Displays the dialog and returns the output flag. *)

  val set_title : ('a, unit, string, unit) format4 -> 'a
  (** Sets tile set title, using [printf]-like style. *)

  val hide : unit -> unit
  (** Hides the tile set and clears all tiles. *)
end


(** Image selector. *)
module ImageList : sig
  val jpeg : GFile.filter
  (** JPEG file filter. *)
  
  val tiff : GFile.filter
  (** TIFF file filter. *)

  val run : unit -> string
  (** Displays a dialog window to select the image to open (if not provided
    * on the command line). The program terminates if no image is selected. *)
end
