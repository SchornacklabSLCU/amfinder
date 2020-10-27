(* CastANet Browser - imgSource.ml *)

class source pixbuf edge =

object (self)

    val width = GdkPixbuf.get_width pixbuf

    val height = GdkPixbuf.get_height pixbuf

    method edge = edge

    method width = width

    method height = height

    method rows = height / edge

    method columns = width / edge

end


let create pixbuf edge = new source pixbuf edge
