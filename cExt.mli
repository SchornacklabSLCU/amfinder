(* CastANet - cExt.mli *)

(** Lightweight extension of OCaml standard library. *)

(** Matrix iterators. *)
module Matrix : sig
  type 'a t = 'a array array
  (** The type of matrices. *)

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
  
  val iteri : (int -> int -> 'a -> unit) -> 'a t -> unit
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


(** Image (Gdkpixbuf) manipulation. *)
module Image : sig
  open GdkPixbuf

  val crop_square : src_x:int -> src_y:int -> edge:int -> pixbuf -> pixbuf
  (** Crop a square from the given pixbuf. *)
  
  val resize : ?interp:interpolation -> edge:int -> pixbuf -> pixbuf
  (** Resize an image. By default, uses nearest-neighbor interpolation. *)
end


(** Drawing functions. *)
module Draw : sig
  val square : ?clr:string -> ?a:float -> int -> Cairo.Surface.t
  (** [square ?clr ?a e] draws a square of edge [e] filled with color 
    * ["#RRGGBB"] and transparency [a]. *)
end


val time : ('a -> 'b) -> 'a -> 'b
(** Benchmark function. *)

(** Memoization. *)
module Memoize : sig
  val create : string -> (unit -> 'a) -> unit -> 'a
  (** Memoization function. The first argument is a label used to report when
    * data are being recomputed due to a previous call to [forget] (see 
    * below). *)

  val forget : unit -> unit
  (** Forget previously memoized data. *)
end
