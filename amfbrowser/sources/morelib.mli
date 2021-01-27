(* AMFinder - morelib.mli
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

(** Lightweight extension of the OCaml standard library. *)

(* Extended list operations. *)
module List : sig
    include module type of List
    (* Insert the original [List] for existing functions remain visible. *)

    val iteri2 : (int -> 'a -> 'b -> unit) -> 'a t -> 'b t -> unit
    (** Same as [iter2], except that the index is received as first argument. *)
end

module CSet : Set.S with type elt = char

(** String sets. *)
module StringSet : sig
    val union : string -> string -> string
    (** [union s1 s2] returns a string containing one instance of all characters
      * occurring in either [s1] or [s2], sorted in alphabetical order.  *)

    val inter : string -> string -> string
    (** [union s1 s2] returns a string containing one instance of all characters
      * occurring in both [s1] or [s2], sorted in alphabetical order.  *)

    val diff : string -> string -> string
    (** [union s1 s2] returns a string containing one instance of all characters
      * occurring in [s1] but not in [s2], sorted in alphabetical order.  *)
end


(** Matrix iterators. *)
module Matrix : sig
    type 'a t = 'a array array
    (** The type of matrices. *)

    val dim : 'a t -> int * int
    (** Returns the the number of rows and columns of the given matrix. *)

    val get : 'a t -> r:int -> c:int -> 'a
    (** [get t ~r ~c] returns [t.(r).(c)].
      * @raise Invalid_argument if the given indices are out of range. *)

    val get_opt : 'a t -> r:int -> c:int -> 'a option
    (** Same as [get], but returns [None] if indices are invalid. *)

    val set : 'a t -> r:int -> c:int -> 'a -> unit
    (** [set t ~r ~c x] stores [x] at row [r] and column [c] of matrix [t]. *)

    val make : r:int -> c:int -> 'a -> 'a t
    (** [make ~r ~c x] returns a matrix containing [r] rows and [c] columns,
      * with all elements initialized with [x]. *)

    val init : r:int -> c:int -> (r:int -> c:int -> 'a) -> 'a t
    (** [init ~r ~c f] builds a matrix of [r] rows and [c] columns and initializes
    * values using the function [f]. *)

    val map : ('a -> 'b) -> 'a t -> 'b t
    (** [map f m] builds a new matrix by applying [f] to all members of [m]. *)

    val mapi : (r:int -> c:int -> 'a -> 'b) -> 'a t -> 'b t
    (** Same as [map], but [f] receives row and column indexes as parameters. *)

    val map2 : ('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t
    (** Same as [map], but iterates over two matrices in one go. *) 

    val iter : ('a -> unit) -> 'a t -> unit
    (** [iter f m] applies [f] to all members of the matrix [m]. *)

    val iteri : (r:int -> c:int -> 'a -> unit) -> 'a t -> unit
    (** Same as [iter], but oasses row and column indexes as parameters. *)

    val iter2 : ('a -> 'b -> unit) -> 'a t -> 'b t -> unit
    (** Same as [iter], but iterates over two matrices in one go. *) 

    val fold : (r:int -> c:int -> 'a -> 'b -> 'a) -> 'a -> 'b t -> 'a
    (** Fold function. *)

    val to_string : cast:('a -> string) -> 'a t -> string
    (** Exports a matrix as string. *)

    val to_string_rc : cast:(r:int -> c:int -> 'a -> string) -> 'a t -> string
    (** Same as [to_string], but passes row and column indexes to [cast]. *)

    val of_string : cast:(string -> 'a) -> string -> 'a t
    (** Imports a matrix from a string. *)
    
    val of_string_rc : cast:(r:int -> c:int -> string -> 'a) -> string -> 'a t
    (** Same as [of_string], but passes row and column indexes to [cast]. *)

    val copy : ?dat:('a -> 'a) -> 'a t -> 'a t
    (** Returns a copy of a given matrix. *)
end


(** Text operations. *)
module Text : sig
  val explode : string -> char list
  (** Converts a string into a list of characters. *)

  val implode : char list -> string
  (** Converts a list of characters into a string. *)
end


(** Operations on files. *)
module File : sig
  val read : ?binary:bool -> ?trim:bool -> string -> string
  (** Reads a file. Setting up option [binary] results in file being opened in
    * binary mode (default: [false]). Option [trim] triggers trimming of 
    * leading and trailing spaces (default: [true]). *)
end


(** Memoized values with possible reinitialization. Such values are computed 
  * only once within a given session. However, they can recomputed when a new 
  * session starts, for instance to take into account the modification of 
  * general settings that affect the computation of memoized values. *)
module Memoize : sig
  val create : ?label:string -> ?one:bool -> (unit -> 'a) -> unit -> 'a
  (** Memoization function. The optional parameter [lbl] is used to report when
    * data are being recomputed due to a previous call to [forget] (see below).
    * The optional parameter [one] defines memoized values that are never
    * recomputed, i.e. insensitive to [forget] invokation. *)

  val forget : unit -> unit
  (** Triggers all memoized data to be recomputed when accessed. *)
end
