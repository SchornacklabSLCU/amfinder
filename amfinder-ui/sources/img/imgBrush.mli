(* AMFinder - img/imgBrush.mli
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

(** Image drawing functions. *)

class type cls = object

    method edge : int
    (** Returns tile size. *)

    method x_origin : int
    (** Returns drawing origin on X axis. *)

    method y_origin : int
    (** Returns drawing origin on Y axis. *)

    method set_update: (unit -> unit) -> unit
    (** Registers a function to update the overall view. *)

    method has_unchanged_boundaries : r:int -> c:int -> unit -> bool
    (** Ensure the given tile is within the visible window.
      * @return True when drawing has to be updated. *)

    method r_range : int * int
    (** Returns the range of visible rows. *)

    method c_range : int * int
    (** Returns the range of visible columns. *)

    method backcolor : string
    (** Returns image background color. *)

    method set_backcolor : string -> unit
    (** Defines image background color. *)

    method background : ?sync:bool -> unit -> unit
    (** Draws a white background on the right image area.
      * @param sync defaults to [true]. *)

    method pixbuf : ?sync:bool -> r:int -> c:int -> GdkPixbuf.pixbuf -> unit
    (** [pixbuf ?sync ~r ~c p] draws pixbuf [p] at row [r] and column [c].
      * @param sync defaults to [false]. *)

    method empty : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draws an empty tile. *)

    method surface : ?sync:bool -> r:int -> c:int -> Cairo.Surface.t -> unit
    (** [surface ?sync ~r ~c s] draws surface [s] at row [r] and column [c].
      * @param sync defaults to [false]. *)

    method locked_tile : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Specialized method for locked tiles. *)

    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draws the cursor.
      * @param sync defaults to [false]. *)

    method annotation :
        ?sync:bool ->
        r:int -> c:int -> AmfLevel.level -> Morelib.CSet.t -> unit
    (** Draws a tile annotation.
      * @param sync defaults to [false]. *)

    method annotation_other_layer :
        ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw the frame of an annotation, for tiles that gets annotated but not
      * in the active layer (to distinguish with non-annotated tiles). *)

    method prediction :
        ?sync:bool -> r:int -> c:int -> float list -> char -> unit
    (** Draws a tile prediction.
      * @param sync defaults to [false]. *)

    method palette : ?sync:bool -> unit -> unit
    (** Displays a full palette. *)

    method classes : ?sync:bool -> unit -> unit
    (** Displays the annotations. *)

    method show_probability : ?sync:bool -> float -> unit
    (** Displays the probability cursor. *)

    method hide_probability : ?sync:bool -> unit -> unit
    (** Hides probability. *)

    method sync : string -> unit -> unit
    (** Synchronize drawings between the back pixmap and the drawing area. *)

end

val create : ImgSource.cls -> cls
(** Builder. *)
