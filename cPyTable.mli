(* CastANet - cPyTable.mli *)

(** Import/export Python tables. *)

open CExt

type pytable
(** The type for Python tables. *)

val label : pytable -> string
(** Returns the Python table identifier (base name without extension). *)

val level : pytable -> CLevel.t
(** Returns the Python table level. *)

val header : pytable -> char list
(** Returns the header of the Python table. *)

val matrix : pytable -> float list Ext_Matrix.t
(** Returns the prediction matrix. *)

val load : tsv:string -> pytable option
(** [load tsv] returns a matrix containing the computer-generated predictions
  * saved by the Pyton script castanet.py. *)
