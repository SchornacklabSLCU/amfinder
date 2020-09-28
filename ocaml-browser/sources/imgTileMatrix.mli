(* CastANet Browser - imgTileMatrix.mli *)

class type t = object
    method edge : int
    method get : r:int -> c:int -> GdkPixbuf.pixbuf
    method iter : (r:int -> c:int -> GdkPixbuf.pixbuf -> unit) -> unit
end


val create : GdkPixbuf.pixbuf -> ImgSource.t -> int -> t
