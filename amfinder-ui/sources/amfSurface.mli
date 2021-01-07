(* AMFinder - amfSurface.mli
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

open Cairo

(** Cairo surfaces for drawing. *)

type pixels = int
type color = string



val rectangle : ?rgba:color -> w:pixels -> h:pixels -> context * Surface.t
(** [rectangle ?rgba:c ~w ~h] draws a rectangle with a width and height of 
  * [w] and [h] pixels, respectively, filled with color [c]. *)

val square : ?rgba:color -> pixels -> context * Surface.t
(** [square ?rgba:c ~e] draws a square with an pixels of [e] pixels, filled
  * with color [c]. *)



(** Arrowheads. *)
module Arrowhead : sig

    val top : ?bgcolor:color -> ?fgcolor:color -> pixels -> Surface.t
    (** Draw an arrowhead toward the top. *)
    
    val bottom : ?bgcolor:color -> ?fgcolor:color -> pixels -> Surface.t
    (** Draw an arrowhead toward the bottom. *)

    val left : ?bgcolor:color -> ?fgcolor:color -> pixels -> Surface.t
    (** Draw an arrowhead to the left. *)

    val right : ?bgcolor:color -> ?fgcolor:color -> pixels -> Surface.t
    (** Draw an arrowhead toward the right. *)

end



(** Square tile drawings corresponding to annotations. *)
module Annotation : sig

    val cursor : pixels -> Surface.t
    (** Square with a thick stroke. *)

    val filled :
        ?symbol:string ->
        ?force_symbol:bool ->
        ?base_font_size:float -> 
        ?grayscale:bool -> color -> pixels -> Surface.t
    (** Rounded, filled square with a centered symbol. *)

    val colors :
        ?symbol:string ->
        ?symbol_color:string ->
        ?base_font_size:float -> color list -> pixels -> Surface.t
    (** Rounded square filled with multiple colors. *)

    val dashed : pixels -> Surface.t
    (** Square with a dashed stroke and an eye symbol. *)
    
    val locked : pixels -> Surface.t
    (** Square with a dashed stroke and a red lock. *)

    val empty : color -> pixels -> Surface.t
    (** Rounded square with a solid stroke and a white background. *)

end



(** Circular tile drawings corresponding to predictions. *)
module Prediction : sig

    val filled : ?margin:float -> color -> pixels -> Surface.t
    (** Circle. *)

    val pie_chart : ?margin:float -> float list -> color list -> pixels -> Surface.t
    (** Pie chart for root segmentation. *)

    val radar : ?margin:float -> float list -> color list -> pixels -> Surface.t
    (** Same, but for prediction of intraradical structures. *)

end



(** Legends. *)
module Legend : sig

    val palette : ?step:int -> pixels -> Surface.t
    (** Prediction values (continuous color palette). Colors are retrieved from
      * [AmfUI.Predictions.get_colors ()]. *)

    val classes : unit -> Surface.t
    (** Annotation classes (discrete colors). *)

end
