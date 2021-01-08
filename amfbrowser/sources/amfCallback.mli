(* AMFinder - amfCallback.mli
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

(** Event manager. *)

type image_ref = AmfImage.image option ref


(** Magnifier. *)
module Magnifier : sig

    val capture_screenshot : image_ref -> unit
    (** Captures a snapshot of the magnified view. *)
end


(** Predictions. *)
module Predictions : sig

    val update_list : image_ref -> unit

    val update_cam: image_ref -> unit

    val convert : image_ref -> unit

    val select_list_item : image_ref -> unit

    val move_to_ambiguous_tile : image_ref -> unit

end


(** Window events. *)
module Window : sig

    val cursor : image_ref -> unit
    (** Arrow keys move cursor. *)

    val annotate : image_ref -> unit
    (** Letter change annotations. *)

    val save : image_ref -> unit
    (** Saves current image. *)

end


(** Events affecting the current tile displayed in the drawing area. *)
module DrawingArea : sig

    val cursor : image_ref -> unit
    (** Updates the current tile after a mouse click. *)

    val annotate : image_ref -> unit
    (** Updates the interface to reflect current tile change. *)

    val repaint : image_ref -> unit
    (** Redraws the current mosaic when the active layer changes. *)

    val repaint_and_count : image_ref -> unit
    (** Same as [repaint], but also computes statistics. *)

end


(* Events triggered by the toggle buttons. *)
module ToggleBar : sig

    val annotate : image_ref -> unit

end


(** Misc tools, and application settings. *)
module Toolbox : sig

    val snap : image_ref -> unit
    (** Take a snapshot of the current window. *)

    val export : image_ref -> unit
    (** Copy statistics to clipboard. *)

end
