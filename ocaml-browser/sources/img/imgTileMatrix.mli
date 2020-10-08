(* CastANet Browser - imgTileMatrix.mli *)

(** Tile matrices. *)

open ImgTypes

val create : GdkPixbuf.pixbuf -> source -> int -> tile_matrix
(** Builder. *)
