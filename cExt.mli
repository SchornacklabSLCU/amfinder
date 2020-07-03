(* CastANet - tTools.mli *)

(** Helper functions. The functions list below carry the prefix [tagger_] to 
  * prevent namespace clash when opening the module. *)

(** Extended strings. *)
val tagger_string_fold_left : ('a -> char -> 'a) -> 'a -> string -> 'a

(** Operations on strings. *)
module CString : sig
  val fold_right : (char -> 'a -> 'a) -> string -> 'a -> 'a
  (** [fold_right]-style function for strings. *)
end

val tagger_matrix_iteri : (int -> int -> 'a -> unit) -> 'a array array -> unit
(** Matrix iterator. *)

val split_lines : string -> string list
(** Split lines using linefeed (['\n']) as delimiter. For instance,
  * [split_lines "foo\nbar"] returns [\["foo"; "bar"\]]. *)

val split_tabs : string -> string list
(** Splits text using tabulation (['\t']) as delimiter. For instance,
  * [split_tabs "foo\tbar"] returns [\["foo"; "bar"\]]. *)

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
