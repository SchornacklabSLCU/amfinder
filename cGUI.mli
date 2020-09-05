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
end


(** The horizontal toolbox (left pane) contains the toggle buttons used to
  * set mycorrhizal annotations. Users can switch between three sets of toggle 
  * buttons which correspond to basic ([`COLONIZATION]), intermediate 
  * ([`ARB_VESICLES]) and full ([`ALL_FEATURES]) annotation modes.
  * Only one set is active at a given time. *)
module GToggles : sig
  val iter : (
    CLevel.t -> 
    char -> GButton.toggle_button -> GMisc.image -> unit) -> unit
  (** [iter f] applies the function [f] to every set of toggle buttons. *)

  val map : (
    CLevel.t -> 
    char -> GButton.toggle_button -> GMisc.image -> 'a) -> 'a array list
  (** Same as [iter], but builds a new list from the result of the application 
    * of function [f] to the toggle button sets. *)

  val toggle_any : char -> unit
  (** Inverts the status of the given toggle button. *)
end



(** Magnified view of the cursor area. *)
module GMagnify : sig
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
module GLayers : sig
  val get_active : unit -> char
  (** Indicates which layer is currently active. *)

  val is_active : char -> bool
  (** Indicates whether the given layer is active. *)

  val set_label : char -> int -> unit
  (** Updates the counter of the given annotation. *)

  val set_image : char -> GdkPixbuf.pixbuf -> unit
  (** Updates the icon of the given annotation. *)

  val iter_radios : (char -> unit) -> unit
  (** Iterator over radio buttons. *)

  val set_toggled : char -> (unit -> unit) -> GtkSignal.id
  (** Sets a callback function to call when a button is toggled. *)
end


(** Vertical toolbar which displays the coordinates (row and column) of the 
  * cursor. *)
module GCoords : sig
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
