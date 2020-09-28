(* CastANet Browser - imgSource.mli *)

class type t = object
    method width : int

    method height : int
 
    method edge : int

    method rows : int

    method columns : int

end


val create : GdkPixbuf.pixbuf -> int -> t
