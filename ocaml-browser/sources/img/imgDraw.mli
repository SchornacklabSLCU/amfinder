(* The Automated Mycorrhiza Finder version 1.0 - img/imgDraw.mli *)

(** High-level drawing functions. *)

open ImgTypes

val create : tile_matrix -> brush -> cursor -> annotations -> predictions -> draw
(** Builder. *)
