(* AMFinder - amfIcon.mli
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

(** Interface icons. *)

(** Icon size.  *)
type size = 
    | Small (** Small icons, 24 x 24 pixels. *)
    | Large (** Large icons, 48 x 48 pixels. *)


(** Color mode. *)
type style = 
    | Grayscale     (** Gray levels. *)
    | RGBA          (** Color mode (with alpha channel). *)


val get : char -> size -> style -> GdkPixbuf.pixbuf
(** [get chr sty sz] returns a GdkPixbuf corresponding to icon [chr], of 
  * style [sty] and size [sz]. @raise Invalid_argument if [chr] is not a 
  * valid character. *)


(** Miscellaneous icons. *)
module Misc : sig
    val cam : style -> GdkPixbuf.pixbuf
    (** Icon for class activation maps. *)

    val conv : GdkPixbuf.pixbuf
    (** Icon for conversion of predictions to annotations. *)

    val ambiguities : GdkPixbuf.pixbuf
    (** Icon to move cursor to ambiguous predictions. *)

    val palette : GdkPixbuf.pixbuf
    (** Icon for color palettes. *)

    val erase : GdkPixbuf.pixbuf
    (** Icon for eraser. *)

    val snapshot : GdkPixbuf.pixbuf
    (** Icon for snapshot. *)

    val show_preds : GdkPixbuf.pixbuf
    (** Add predictions. *)
    
    val hide_preds : GdkPixbuf.pixbuf
    (** Remove predictions. *)
end
