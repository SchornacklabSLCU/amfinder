(* AMFinder - img/imgUI.mli
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

(** Interaction with the user interface. *)

class type cls = object

    method set_paint : (unit -> unit) -> unit
    (** Painting functions to update the current tile. *)

    method set_refresh : (unit -> unit) -> unit
    (** Sets the painting function to refresh the whole drawing area. *)

    method update_toggles : unit -> unit
    (** Update annotations at the current cursor position. *)

    method toggle :
        GButton.toggle_button ->
        GMisc.image -> char -> GdkEvent.Button.t -> bool
    (** Update annotations when a toggle button is toggled. *)

    method key_press : GdkEvent.Key.t -> bool
    (** Update annotations based on key press. *)

    method mouse_click : GdkEvent.Button.t -> bool
    (** Update annotations based on mouse click. *)

end

val create :
    ImgCursor.cls ->
    ImgAnnotations.cls -> ImgPredictions.cls -> cls
(** UI object generator. *)
