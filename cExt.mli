(* CastANet - cExt.mli *)

(** Lightweight extension of the OCaml standard library. *)

(** String sets. *)
module Ext_StringSet : sig
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
module Ext_Matrix : sig
  type 'a t = 'a array array
  (** The type of matrices. *)

  val dim : 'a t -> int * int
  (** Returns the dimensions of the given matrix, i.e. the number of rows and
    * columns. *)

  val get : 'a t -> int -> int -> 'a
  (** [get t r c] returns [t.(r).(c)] or raises an error. *)
  
  val get_opt : 'a t -> int -> int -> 'a option
  (** Same as [get], but returns [None] if the indices are invalid. *)

  val init : int -> int -> (int -> int -> 'a) -> 'a t
  (** [init r c f] builds a matrix of [r] rows and [c] columns and initializes
    * values using the function [f]. *)

  val map : ('a -> 'b) -> 'a t -> 'b t
  (** [map f m] builds a new matrix by applying [f] to all members of [m]. *)

  val mapi : (int -> int -> 'a -> 'b) -> 'a t -> 'b t
  (** Same as [map], but [f] receives row and column indexes as parameters. *)
  
  val iter : ('a -> unit) -> 'a t -> unit
  (** [iter f m] applies [f] to all members of the matrix [m]. *)
  
  val iteri : (r:int -> c:int -> 'a -> unit) -> 'a t -> unit
  (** Same as [iter], but [f] receives row and column indexes as parameters. *)
  
  val fold : (r:int -> c:int -> 'a -> 'b -> 'a) -> 'a -> 'b t -> 'a
  (** Fold function. *)

  val to_string : cast:('a -> string) -> 'a t -> string
  (** Exports a matrix as string. *)

  val of_string : cast:(string -> 'a) -> string -> 'a t
  (** Imports a matrix from a string. *)
  
  val copy : ?dat:('a -> 'a) -> 'a t -> 'a t
  (** Returns a copy of a given matrix. *)
end


(** Text operations. *)
module Ext_Text : sig
  val explode : string -> char list
  (** Converts a string into a list of characters. *)

  val implode : char list -> string
  (** Converts a list of characters into a string. *)
end


(** Operations on files. *)
module Ext_File : sig
  val read : ?binary:bool -> ?trim:bool -> string -> string
  (** Reads a file. Setting up option [binary] results in file being opened in
    * binary mode (default: [false]). Option [trim] triggers trimming of 
    * leading and trailing spaces (default: [true]). *)
end


val time : ('a -> 'b) -> 'a -> 'b
(** Benchmark function. *)

(** Memoized values with possible reinitialization. Such values are computed 
  * only once within a given session. However, they can recomputed when a new 
  * session starts, for instance to take into account the modification of 
  * general settings that affect the computation of memoized values. *)
module Ext_Memoize : sig
  val create : ?label:string -> ?one:bool -> (unit -> 'a) -> unit -> 'a
  (** Memoization function. The optional parameter [lbl] is used to report when
    * data are being recomputed due to a previous call to [forget] (see below).
    * The optional parameter [one] defines memoized values that are never
    * recomputed, i.e. insensitive to [forget] invokation. *)

  val forget : unit -> unit
  (** Triggers all memoized data to be recomputed when accessed. *)
end
