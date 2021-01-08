(* AMFinder - img/imgDraw.mli
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

(** High-level drawing functions. *)

class type cls = object

    method tile : ?sync:bool -> r:int -> c:int -> unit -> bool
    (** Draw tile image at the given coordinates. *)    

    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw cursor at the given coordinates. *)

    method overlay : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw annotation/prediction at the given coordinates. *)

end

val create :
    ImgTileMatrix.cls ->
    ImgBrush.cls ->
    ImgCursor.cls -> ImgAnnotations.cls -> ImgPredictions.cls -> cls
(** Builder. *)
