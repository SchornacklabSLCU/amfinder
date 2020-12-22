(* AMFinder - ui/uITileSet.mli
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
  val parent : GWindow.window
  val spacing : int
  val border_width : int
  val window_width : int
  val window_height : int
  val window_title : string
end

module type S = sig
  val add : r:int -> c:int -> ico:GdkPixbuf.pixbuf -> GdkPixbuf.pixbuf -> unit
  (** [add r c pix] adds the tile [pix] using coordinates [(r, c)] as legend. *)

  val run : unit -> [`OK | `SAVE | `DELETE_EVENT]
  (** Displays the dialog and returns the output flag. *)

  val set_title : ('a, unit, string, unit) format4 -> 'a
  (** Sets tile set title, using [printf]-like style. *)

  val hide : unit -> unit
  (** Hides the tile set and clears all tiles. *)
end

module Make : PARAMS -> S
(** Generator. *)
