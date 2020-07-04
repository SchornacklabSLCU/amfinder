(* CastANet - cExtlib.mli *)

(** Lightweight extension of OCaml standard library. *)

(** Matrix iterators. *)
module Matrix : sig
  type 'a matrix = 'a array array
  (** The type of matrices. *)

  val init : int -> int -> (int -> int -> 'a) -> 'a matrix
  (** [init r c f] builds a matrix of [r] rows and [c] columns and initializes
    * values using the function [f]. *)

  val map : ('a -> 'b) -> 'a matrix -> 'b matrix
  (** [map f m] builds a new matrix by applying [f] to all members of [m]. *)

  val mapi : (int -> int -> 'a -> 'b) -> 'a matrix -> 'b matrix
  (** Same as [map], but [f] receives row and column indexes as parameters. *)
  
  val iter : ('a -> unit) -> 'a matrix -> unit
  (** [iter f m] applies [f] to all members of the matrix [m]. *)
  
  val iteri : (int -> int -> 'a -> unit) -> 'a matrix -> unit
  (** Same as [iter], but [f] receives row and column indexes as parameters. *)
end


(** Text splitting functions. *)
module Split : sig
  val lines : string -> string list
  (** Split the input string at any linefeed (['\n']). *)

  val tabs : string -> string list
  (** Split the input string at any tabulation (['\t']). *)

  val colons : string -> string list
  (** Split the input string at any colon ([':']). *)

  val semicolons : string -> string list
  (** Split the input string at any semicolon ([';']). *)

  val commas : string -> string list
  (** Split the input string at any comma ([',']). *)

  val spaces : string -> string list
  (** Split the input string at any space ([' ']). *)
end


(** Operations on files. *)
module File : sig
  val read : ?binary:bool -> ?trim:bool -> string -> string
  (** Reads a file. *)
end


(** Maybe-values, aka value/error monad. This carries a little more information
  * than ['a option], by retrieving any exception raised during evaluation. *)
module Maybe : sig
  type 'a t
  (** The type for maybe-values. *)

  val from_value : 'a -> 'a t
  (** Creates a maybe-value from a value. *)

  val from_exception : exn -> 'a t
  (** Creates a maybe-value from an exception. *)

  val from_option : 'a option -> 'a t
  (** Creates a maybe-value from an option. *)
  
  val to_option : 'a t -> 'a option
  (** Converts a maybe-value to option. *)

  val is_value : 'a t -> bool
  (** Returns [true] if a maybe-value contains a value. *)

  val is_exception : 'a t -> bool
  (** Returns [true] if a maybe-value contains an exception. *)

  val eval : ('a -> 'b) -> 'a -> 'b t
  (** Creates a maybe-value from a function. *)

  val iter : ('a -> unit) -> 'a t -> unit
  (** Applies a function to the previously stored value, if any. *)

  val map : ('a -> 'b) -> 'a t -> 'b t
  (** Modifies the previously stored value, if any. *)

  val fix : (exn -> 'a) -> 'a t -> 'a t
  (** Tries to fix a previously raised error. *)
end


(** Operations on colors. *)
module Color : sig
  val html_to_int : string -> int * int * int
  (** [html_to_int "#RRGGBB"] returns 8-bit red, green and blue integers. *)

  val html_to_int16 : string -> int * int * int
  (** Same as [html_to_int], but returns 16-bit integers. *)

  val html_to_float : string -> float * float * float
  (** Same as [html_to_int], but returns floating-point numbers. *)

  val float_to_int : float -> float -> float -> int * int * int
  (** [float_to_int r g b] returns 8-bit red, green and blue integers. *)

  val float_to_html : float -> float -> float -> string
  (** [float_to_html r g b] returns the HTML notation "#RRGGBB". *)
end

val time : ('a -> 'b) -> 'a -> 'b
(** Benchmark function. *)

val memoize : (unit -> 'a) -> unit -> 'a
(** Memoization function. *)
