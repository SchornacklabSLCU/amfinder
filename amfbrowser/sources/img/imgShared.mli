(* AMFinder - img/imgShared.mli
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

open GdkPixbuf

(** Image-related shared functions. *)

val crop_pixbuf : src_x:int -> src_y:int -> edge:int -> pixbuf -> pixbuf
(** [copy_pixbuf ~src_x:x ~src_y:y ~edge:e pix] extracts from pixbuf [pix] the
  * [e] {% $\times$ %} [e] tile with top left corner at [(x, y)]. *)

val resize_pixbuf : ?interp:interpolation -> int -> pixbuf -> pixbuf
(** [resize_pixbuf ?interp:i e pix] resizes pixbuf [pix] to a square of edge
  * [e], using interpolation method [i]. This function is intended for square
  * input as it will otherwise modify aspect ratio. *)

