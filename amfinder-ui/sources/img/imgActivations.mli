(* The Automated Mycorrhiza Finder version 1.0 - img/imgActivations.mli *)

(** Class activation maps (CAMs). *)

open ImgTypes

val create : ?zip:Zip.in_file -> source -> activations
(** Builder. *)
