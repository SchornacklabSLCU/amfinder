(* AMFinder - amfConst.mli
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

(** AMFinder constants. *)


val _EDGE_ : int
(** Edge of a tile when displayed in the interface, in pixels. *)

val _WMAX_ : int
(* Number of tiles to be displayed on the X axis. *)

val _HMAX_ : int
(* Number of tiles to be displayed on the Y axis. *)

val _WMAT_ : int
(* Width of the displayed tile matrix, in pixels. *)

val _HMAT_ : int
(* Height of the displayed tile matrix, in pixels. *)

val _DEBUG_ : bool
(** Tells whether the application runs in debugging mode. *)

val _BGCOLOR_ : string
(** Background color used in the GtkDrawingArea. *)

val _MAGN_ : int
(** Edge (in pixels) of the tiles displayed in the magnified view. *)

val _BLANK_ : GdkPixbuf.pixbuf
(** Blank tile to be displayed in the magnified view where appropriate. *)

