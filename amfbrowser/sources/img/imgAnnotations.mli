(* AMFinder - img/imgAnnotations.mli
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

(** Annotation manager. *)

class type cls = object

    method get : r:int -> c:int -> unit -> AmfAnnot.annot
    (** Returns the item at the given coordinates and annotation level. *)

    method iter : (r:int -> c:int -> AmfAnnot.annot -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

    method iter_layer : char -> (r:int -> c:int -> AmfAnnot.annot -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

    method statistics : ?level:AmfLevel.level -> unit -> (char * int) list
    (** Returns the current statistics. *)
   
    method has_annot : ?level:AmfLevel.level -> r:int -> c:int -> unit -> bool
    (** Indicates whether the given tile has annotation. By default, checks the
      * current annotation layer. *)

    method dump : Zip.out_file -> unit
    (** Saves annotations. *)
    
end

val create : ?zip:Zip.in_file -> ImgSource.cls -> cls
(** Builder. *)

