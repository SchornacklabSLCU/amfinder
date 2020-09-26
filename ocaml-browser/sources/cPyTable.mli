(* CastANet - cPyTable.mli *)

(** Import/export Python tables. *)

open CExt

type python_table
(** The type for Python tables. *)

val label : pytable -> string
(** Returns the Python table identifier (base name without extension). *)

val level : pytable -> CLevel.t
(** Returns the Python table level. *)

val header : pytable -> char list
(** Returns the header of the Python table. *)

val matrix : pytable -> float list Ext_Matrix.t
(** Returns the prediction matrix. *)

val from_string : path:string -> string -> pytable
(** Build a table from the given string. The labelled argument [path] is used
  * to generate a label for the given Python table. *)

val to_string : pytable -> string
(** Converts a Python table to string (for export purposes). *)
