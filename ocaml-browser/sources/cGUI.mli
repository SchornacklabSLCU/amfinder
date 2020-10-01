(* CastANet - cGUI.mli *)

(** Graphical user interface. *)

val window : GWindow.window
(** Application main window. *)

module Levels : UILevels.S
(** Annotation types. *)

module Toggles : UIToggleBar.S
(** The horizontal toolbox (left pane) contains the toggle buttons used to
  * set mycorrhizal annotations. Users can switch between three sets of toggle 
  * buttons which correspond to basic ([`COLONIZATION]), intermediate 
  * ([`ARB_VESICLES]) and full ([`ALL_FEATURES]) annotation modes.
  * Only one set is active at a given time. *)

module Magnifier : UIMagnifier.S
(** Magnified view of the cursor area. *)

module Drawing : UIDrawing.S
(** Whole image (right pane). *)

module Layers : UILayers.S
(** Annotation layers. *)

module CursorPos : UICursorPos.S
(** Vertical toolbar to display cursor position (row/column). *)

module Predictions : UIPredictions.S
(** Prediction manager. *)

val status : GMisc.label
(** Label used as a status bar. It displays general information related to the 
  * loaded image, such as height and width (in pixels). *)

module TileSet : UITileSet.S
(** Auxiliary window to display all tiles sharing a given annotation. *)

module FileChooser : UIFileChooser.S
(** File chooser dialog to allow for selection of the JPEG/TIFF image to open
  * within the CastAnet editor. This dialog shows at startup (unless an image is
  * provided on the command line) as well as when the main window is closed.
  * Users can therefore load successive images without closing the application,
  * but only one image is active at a time. *)
