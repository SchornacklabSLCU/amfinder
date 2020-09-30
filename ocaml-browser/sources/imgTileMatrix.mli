(* CastANet Browser - imgTileMatrix.mli *)

(** Tile matrices. *)

class type tile_matrix = object
    method get : r:int -> c:int -> GdkPixbuf.pixbuf
    (** Retrieves a specific tile. *)

    method iter : (r:int -> c:int -> GdkPixbuf.pixbuf -> unit) -> unit
    (** Iterates over tiles. *)
end

val create : GdkPixbuf.pixbuf -> ImgSource.source -> int -> tile_matrix
(** Builder. *)
