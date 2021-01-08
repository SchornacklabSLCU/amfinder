(* AMFinder - amfAnnot.mli
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

(** Tile annotations. *)

class type annot = object

    method is_empty : ?level:AmfLevel.level -> unit -> bool
    (** Returns [true] when the tile has no annotation. *)

    method has_annot : ?level:AmfLevel.level -> unit -> bool
    (** Indicates whether the tile has annotation. *)

    method get : ?level:AmfLevel.level -> unit -> Morelib.CSet.t
    (** Returns the annotations associated with the given level, or the
      * current level if [?level] is [None]. *)

    method add : ?level:AmfLevel.level -> char -> unit
    (** [add chr] adds [chr] to the tile annotation. Only valid when annotating
      * intraradical structures. *)

    method remove : ?level:AmfLevel.level -> char -> unit
    (** [remove chr] removes [chr] from the tile annotation. *)

    method mem : char -> bool
    (** [mem chr] returns [true] when [chr] is part of the tile annotation. *)

    method all : string
    (** Returns all assigned annotations, irrespective of annotation level. *)

    method hot : ?level:AmfLevel.level -> unit -> int list
    (** Returns a one-hot vector containing tile annotations at a given level.
      * Uses current level when [?level] is [None]. *)

    method editable : bool
    (** Indicates whether the given tile annotation is editable. A tile is 
      * always editable at the root segmentation level. Otherwise, they have to
      * carry the annotation flag ['Y']. *)

    method erase : ?level:AmfLevel.level -> unit -> unit
    (** Removes all annotations at the given level. *)

end


val create : unit -> annot
(** Creates an empty annotation. *)

val of_string : string -> annot
(** Creates an annotation and initializes it with the given string. *)
