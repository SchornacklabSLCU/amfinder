(* AMFinder - ui/uIMagnifier.mli
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

(** GUI auxiliary module. Implements a magnified view of the 3x3 tile square
  * surrounding the cursor position. *)

(** Module parameters. *)
module type PARAMS = sig
    val rows : int
    (** Number of tiles to display on the Y axis. *)

    val columns : int
    (** Number of tiles to display on the X axis. *)

    val tile_edge : int
    (** Size, in pixels, of a magnified tile. *)

    val window : GWindow.window
    (** Main application window. *)

    val packing : GObj.widget -> unit
    (** Packing function to bind the magnified view to the interface. *)
end

(** Output module. *)
module type S = sig
    val event_boxes : GBin.event_box Morelib.Matrix.t
    (** Matrix of event boxes. *)

    val tiles : GMisc.image Morelib.Matrix.t
    (** Matrix of GtkImage widgets used to display a magnified view of the tile
    * square surrounding the cursor position. Square size is determined by
    * [rows] and [columns] (see [PARAMS]). *)

    val set_pixbuf : r:int -> c:int -> GdkPixbuf.pixbuf -> unit
    (** [set_pixbuf ~r ~c p] displays pixbuf [p] at row [r] and column [c].
    * Both values must be greater or equal to zero and strictly lower than
    * [rows] and [columns], respectively (see [PARAMS]). *)

    val screenshot : unit -> GdkPixbuf.pixbuf
    (** Takes a screenshot of the whole magnifier area. *)
end

module Make : PARAMS -> S
(** Generator. *)
