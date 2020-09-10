(* CastANet - cPyTable.mli *)

(** Import/export Python tables. *)

open CExt

val load : tsv:string -> (CLevel.t * (string * float list Ext_Matrix.t)) option
(** [load tsv] returns a matrix containing the computer-generated predictions
  * saved by the Pyton script castanet.py. *)
