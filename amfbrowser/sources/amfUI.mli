(* AMFinder - amfUI.mli
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

(** Graphical user interface. *)

val window : GWindow.window
(** Application main window. *)

val status_icon : GMisc.status_icon
(** Status icon to be displayed on the system tray. *)

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

module Predictions : UIPredictions.S
(** Prediction manager. *)

module FileChooser : UIFileChooser.S
(** File chooser dialog to allow for selection of the JPEG/TIFF image to open
  * within the CastAnet editor. This dialog shows at startup (unless an image is
  * provided on the command line) as well as when the main window is closed.
  * Users can therefore load successive images without closing the application,
  * but only one image is active at a time. *)

module Tools : UITools.S
(** Misc tools such as snapshot or export, and application settings. *)
