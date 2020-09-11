(* CastANet - cGUI.mli *)

(** Graphical user interface. *)

val window : GWindow.window
(** Application main window. *)

module Levels : CGUI_Levels.S
(** Annotation types. *)

module Toggles : UI_ToggleBar.TOGGLE_BAR
(** The horizontal toolbox (left pane) contains the toggle buttons used to
  * set mycorrhizal annotations. Users can switch between three sets of toggle 
  * buttons which correspond to basic ([`COLONIZATION]), intermediate 
  * ([`ARB_VESICLES]) and full ([`ALL_FEATURES]) annotation modes.
  * Only one set is active at a given time. *)

module Magnifier : UI_Magnifier.MAGNIFIER
(** Magnified view of the cursor area. *)

module Drawing : UI_Drawing.DRAWING
(** Whole image (right pane). *)

module Layers : UI_Layers.LAYERS
(** Annotation layers. *)


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


module Palette : UI_Palette.S
(** Prediction manager. *)

val status : GMisc.label
(** Label used as a status bar. It displays general information related to the 
  * loaded image, such as height and width (in pixels). *)

module TileSet : UI_TileSet.S
(** Auxiliary window to display all tiles sharing a given annotation. *)

module FileChooser : UI_FileChooser.S
(** File chooser dialog to allow for selection of the JPEG/TIFF image to open
  * within the CastAnet editor. This dialog shows at startup (unless an image is
  * provided on the command line) as well as when the main window is closed.
  * Users can therefore load successive images without closing the application,
  * but only one image is active at a time. *)
