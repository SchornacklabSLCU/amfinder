(* AMFinder - ui/uIDrawing.mli
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

module type PARAMS = sig
  val packing : GObj.widget -> unit
end

module type S = sig
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

module Make : PARAMS -> S
(** Generator. *)
