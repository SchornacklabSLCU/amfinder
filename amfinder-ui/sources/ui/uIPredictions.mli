(* AMFinder - ui/uIPredictions.mli
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

    val set_palette_update : (unit -> unit) -> unit
    (** Defines the update function to use when the palette changes. *)

    val cams : GButton.toggle_tool_button
    (** Indicates whether CAMs are to be displayed or not. *)

    val convert : GButton.tool_button
    (** Converts predictions to annotations. *)

    val ambiguities : GButton.tool_button
    (** Emphasizes ambiguities. *)

end

module Make : PARAMS -> S
(** Generator. *)
