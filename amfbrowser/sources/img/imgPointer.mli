(* AMFinder - img/imgPointer.mli
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

(** Mouse pointer events. *)

class type cls = object

    method get : (int * int) option
    (** Returns the current pointer position, if any. *)

    method at : r:int -> c:int -> bool
    (** Tells whether the pointer is at a given coordinate. *)

    method track : GdkEvent.Motion.t -> bool
    (** Tracks pointer position. *)

    method leave : GdkEvent.Crossing.t -> bool
    (** Detects pointer leaving. *)

    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to repaint tiles below pointer. *)

    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to paint the pointer. *)

end

val create : ImgSource.cls -> ImgBrush.cls -> cls
(** Builder. *)
