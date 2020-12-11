(* The Automated Mycorrhiza Finder version 1.0 - img/imgUI.mli *)

(** Interaction with the user interface. *)

open ImgTypes

val create : cursor -> annotations -> predictions -> ui
