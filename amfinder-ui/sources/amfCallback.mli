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

(** Magnifier. *)
module Magnifier : sig

    val capture_screenshot : AmfImage.image option ref -> unit

end



(** Annotations. *)
module Annotations : sig
    val update_mosaic : AmfImage.image option ref -> unit
end



(** Predictions. *)
module Predictions : sig

    val update_list : AmfImage.image option ref -> unit

    val update_cam: AmfImage.image option ref -> unit

    val convert : AmfImage.image option ref -> unit

    val select_list_item : AmfImage.image option ref -> unit

    val move_to_ambiguous_tile : AmfImage.image option ref -> unit

end



(** Window events. *)
module Window : sig

    val cursor : AmfImage.image -> unit
    (** Arrow keys move cursor. *)

    val annotate : AmfImage.image -> unit
    (** Letter change annotations. *)

    val save : AmfImage.image option ref -> unit
    (** Saves current image. *)

end


module DrawingArea : sig

    val cursor : AmfImage.image -> unit

    val annotate : AmfImage.image -> unit

end


module ToggleBar : sig

    val annotate : AmfImage.image -> unit

end
