(* CastANet Browser - imgSource.ml *)

class type t = object
    method width : int
    method height : int   
    method edge : int
    method rows : int
    method columns : int
end


class source pixbuf edge = object
    val width = GdkPixbuf.get_width pixbuf
    val height = GdkPixbuf.get_height pixbuf
    method edge = edge
    method width = width
    method height = height 
    method rows = height / edge
    method columns = width / edge
end


let create pixbuf edge = new source pixbuf edge
