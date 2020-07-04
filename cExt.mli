(* CastANet - cExtlib.mli *)

(** Helper functions. The functions list below carry the prefix [tagger_] to 
  * prevent namespace clash when opening the module. *)

(** Extended strings. *)
val tagger_string_fold_left : ('a -> char -> 'a) -> 'a -> string -> 'a

(** Operations on strings. *)
module CString : sig
  val fold_right : (char -> 'a -> 'a) -> string -> 'a -> 'a
  (** [fold_right]-style function for strings. *)
end

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



val read_file : ?trim:bool -> string -> string
(** Reads a file. *)

val tagger_time : ('a -> 'b) -> 'a -> 'b
(** Benchmark function. *)

val tagger_html_to_int : string -> int * int * int
(** [html_to_int "#RRGGBB"] returns 8-bit red, green and blue values. *)

val tagger_html_to_int16 : string -> int * int * int
(** Same as [html_to_int], but returns 16-bit values. *)

val tagger_html_to_float : string -> float * float * float
(** Same as [html_to_int], but returns values as floats. *)

val tagger_float_to_int : float -> float -> float -> int * int * int
(** [float_to_html r g b] returns 8-bit red, green and blue values. *)

val tagger_float_to_html : float -> float -> float -> string
(** [float_to_html r g b] returns "#RRGGBB" (hexadecimal notation). *)

val memoize : (unit -> 'a) -> unit -> 'a
(** Memoization function. *)
