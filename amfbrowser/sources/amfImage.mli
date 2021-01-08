(* AMFinder - amfImage.mli
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

(** Image management. *)

class type image = object

    method ui : ImgUI.cls
    (** User interface. *)

    method file : ImgFile.cls
    (** File settings. *)

    method source : ImgSource.cls
    (** Source image settings. *)

    method brush : ImgBrush.cls
    (** Drawing toolbox. *)

    method draw : ImgDraw.cls
    (** Drawing functions. *)

    method cursor : ImgCursor.cls
    (** Cursor position manager. *)

    method pointer : ImgPointer.cls
    (** Mouse pointer tracker. *)

    method small_tiles : ImgTileMatrix.cls
    (** Small-sized tiles to be used in the right pane. *)

    method large_tiles : ImgTileMatrix.cls
    (** Large-sized tiles to be used in the left pane. *)

    method annotations : ImgAnnotations.cls
    (** User-defined annotations. *)

    method predictions : ImgPredictions.cls
    (** Computer-generated predictions (probabilities). *)

    method predictions_to_annotations : ?erase:bool -> unit -> unit
    (** Converts predictions to annotations. *)

    method show_predictions : unit -> unit
    (** Displays the active prediction layer. *)

    method show : unit -> unit
    (** Displays background, tiles as well as the activate annotation layer. *)

    method uncertain_tile : unit -> unit
    (** Draw the next uncertain tile image. *)

    method mosaic : ?sync:bool -> unit -> unit
    (** Displays the tile matrix. *)

    method magnified_view : unit -> unit
    (** Updates the magnified view. *)

    method update_statistics : unit -> unit
    (** Updates statistics (for layers). *)

    method at_exit : (unit -> unit) -> unit
    (** Registers a function to be run before the image gets destroyed. *)

    method save : unit -> unit
    (** Saves the current image. *)
    
    method screenshot : unit -> unit
    (** Saves a screenshot of the current magnified view. *)

end

val create : string -> image
(** [load ~edge:n path] loads image [path], using [n]x[n] squares as tiles.
  * @raise Invalid_argument if the file does not exist. *)
