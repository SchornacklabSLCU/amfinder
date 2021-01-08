(* AMFinder - img/imgPredictions.mli
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

(** Prediction tables. *)

class type cls = object

    method ids : AmfLevel.level -> string list
    (** Returns the list of predictions at the given annotation level. *)

    method current : string option
    (** Return the identifier of the active prediction table. *)

    method current_level : AmfLevel.level option
    (** Returns the level of the active predictions. *)

    method set_current : string option -> unit
    (** Define the active prediction table. *)

    method active : bool
    (** Tells whether predictions are being displayed. *)

    method count : int
    (** Returns the number of predictions in the current dataset. *)

    method next_uncertain : (int * int) option
    (** Returns the coordinates of the next most uncertain prediction. *)

    method get : r:int -> c:int -> float list option
    (** Return the probabilities at the given coordinates. *)
    
    method max_layer : r:int -> c:int -> (char * float) option
    (** Return the layer with maximum probability at the given coordinates. *)
    
    method iter : 
        [ `ALL of (r:int -> c:int -> float list -> unit)
        | `MAX of (r:int -> c:int -> char * float -> unit) ] -> unit
    (** Iterate over all predictions. *)
    
    method iter_layer : char -> (r:int -> c:int -> float -> unit) -> unit
    (** Iterate over tiles which have their top prediction on a given layer. *)
    
    method statistics : (char * int) list
    (** Statistics, currently based on the top prediction. *)
    
    method to_string : unit -> string
    (** Return the string representation of the active prediction table. *)
    
    method exists : r:int -> c:int -> bool
    (** Indicates whether the given tile has predictions. *)

    method dump : Zip.out_file -> unit
    (** Saves predictions. *)

end

val create : ?zip:Zip.in_file -> ImgSource.cls -> cls
(** Builder. *)

