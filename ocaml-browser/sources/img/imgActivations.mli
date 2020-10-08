(* CastANet browser - imgActivations.mli *)

(** Class activation maps (CAMs). *)

open ImgTypes

val create : ?zip:Zip.in_file -> source -> activations
(** Builder. *)
