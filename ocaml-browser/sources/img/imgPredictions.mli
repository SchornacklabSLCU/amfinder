(* CastANet browser - imgPredictions.mli *)

(** Prediction tables. *)

open ImgTypes

val create : ?zip:Zip.in_file -> source -> predictions
(** Builder. *)

