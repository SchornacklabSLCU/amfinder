(** amf - imgDraw.mli *)

(** High-level drawing functions. *)

open ImgTypes

val create : tile_matrix -> brush -> annotations -> predictions -> draw
(** Builder. *)
