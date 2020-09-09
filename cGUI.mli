(* CastANet - cGUI.mli *)

(** Graphical user interface. *)

val window : GWindow.window
(** Application main window. *)


(** Annotation types. *)
module GUI_levels : sig 
  val current : unit -> CLevel.t
  (** Returns the active annotation level. *)

  val radios : (CLevel.t * GButton.radio_button) list
  (** Radio buttons corresponding to the different annotation types. *)
  
  val set_callback : (CLevel.t -> GButton.radio_button -> unit) -> unit
  (** Applies a callback function to all radio buttons. *)
end


(** The horizontal toolbox (left pane) contains the toggle buttons used to
  * set mycorrhizal annotations. Users can switch between three sets of toggle 
  * buttons which correspond to basic ([`COLONIZATION]), intermediate 
  * ([`ARB_VESICLES]) and full ([`ALL_FEATURES]) annotation modes.
  * Only one set is active at a given time. *)
module GUI_Toggles : sig
  val is_active : char -> bool option
  (** Indicates whether the given annotation is active at the current level. *)

  val set_status : (CLevel.t * CTile.t) list -> unit
  (** Updates all toggle buttons. *)

  val is_locked : unit -> bool
  (** Indicates whether a toggle is locked and callbacks should not apply. *)
end



(** Magnified view of the cursor area. *)
module GUI_Magnify : sig
  val tiles : GMisc.image array array
  (** Tiles (3 x 3 matrix) for magnified view of the cursor area. The 
    * annotations shown in [HToolbox] correspond to the central tile. *)
end



(** Whole image (right pane). *)
module GUI_Drawing : sig
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


(** TODO: documentation *)
module GUI_Layers : sig
  val get_active : unit -> char
  (** Indicates which layer is currently active. *)

  val set_label : char -> int -> unit
  (** Updates the counter of the given annotation. *)

  val set_callback : 
    (char -> 
      GButton.radio_tool_button -> GMisc.label -> GMisc.image -> unit) -> unit
  (** Sets a callback function to call when a button is toggled. The callback
    * function will be applied to all tool buttons. *)
end


(** Vertical toolbar which displays the coordinates (row and column) of the 
  * cursor. *)
module GUI_Coords : sig
  val toolbar : GButton.toolbar
  (** Main container. *)

  val row : GMisc.label
  (** Indicates the current row index. *)

  val column : GMisc.label
  (** Indicate the current column index. *)
end


(** Vertical toolbar which displays the confidence of the neural network 
  * predictions. *)
module GStats : sig
  val toolbar : GButton.toolbar
  (** Main container. *)

  val confidence : GMisc.label
  (** To be primarily used with computer-generated annotations. Indicates how
    * confident the annotation is (using percentage). *)

  val confidence_color : GMisc.label
  (** To be primarily used with computer-generated annotations. This label
    * displays the Viridis colour corresponding to the percentage displayed by
    * the label [confidence] (see above). *)
end


val status : GMisc.label
(** Label used as a status bar. It displays general information related to the 
  * loaded image, such as height and width (in pixels). *)



(** Auxiliary window to display all tiles sharing a given annotation. *)
module GTileSet : sig
  val add : r:int -> c:int -> ico:GdkPixbuf.pixbuf -> GdkPixbuf.pixbuf -> unit
  (** [add r c pix] adds the tile [pix] using coordinates [(r, c)] as legend. *)

  val run : unit -> [`OK | `SAVE | `DELETE_EVENT]
  (** Displays the dialog and returns the output flag. *)

  val set_title : ('a, unit, string, unit) format4 -> 'a
  (** Sets tile set title, using [printf]-like style. *)

  val hide : unit -> unit
  (** Hides the tile set and clears all tiles. *)
end


(** File chooser dialog to allow for selection of the JPEG/TIFF image to open
  * within the CastAnet editor. This dialog shows at startup (unless an image is
  * provided on the command line) as well as when the main window is closed.
  * Users can therefore load successive images without closing the application,
  * but only one image is active at a time. *)
module GUI_FileChooserDialog : sig
  val jpeg : GFile.filter
  (** File filter for JPEG images. *)
  
  val tiff : GFile.filter
  (** File filter for TIFF images. *)

  val run : unit -> string
  (** Displays a dialog window to select the image to open (if not provided
    * on the command line). The program terminates if no image is selected. *)
end
