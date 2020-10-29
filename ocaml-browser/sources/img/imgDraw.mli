(** amf - imgDraw.mli *)

(** High-level drawing functions. *)

open ImgTypes

val create : tile_matrix -> brush -> cursor -> annotations -> predictions -> draw
(** Builder. *)
