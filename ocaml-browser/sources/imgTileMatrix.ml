(* CastANet Browser - imgTileMatrix.ml *)

class type t = object
    method get : r:int -> c:int -> GdkPixbuf.pixbuf
    method iter : (r:int -> c:int -> GdkPixbuf.pixbuf -> unit) -> unit
end


module Aux = struct
    let crop ~src_x ~src_y ~edge pix =
        let dest = GdkPixbuf.create ~width:edge ~height:edge () in
        GdkPixbuf.copy_area ~dest ~src_x ~src_y pix;
        dest

    let resize ?(interp = `NEAREST) edge pixbuf =
        let width = GdkPixbuf.get_width pixbuf
        and height = GdkPixbuf.get_height pixbuf in
        let scale_x = float edge /. (float width)
        and scale_y = float edge /. (float height) in
        let dest = GdkPixbuf.create ~width:edge ~height:edge () in
        GdkPixbuf.scale ~dest ~scale_x ~scale_y ~interp pixbuf;
        dest
end


class tile_matrix pixbuf (source : ImgSource.t) edge = object

    val data =
        let extract ~r ~c =
            let crop = Aux.crop
                ~src_x:(c * source#edge)
                ~src_y:(r * source#edge)
                ~edge:source#edge pixbuf
            in Aux.resize edge crop
        in Morelib.Matrix.init ~r:source#rows ~c:source#columns extract

    method get ~r ~c = Morelib.Matrix.get data ~r ~c
    method iter f = Morelib.Matrix.iteri f data
end


let create pixbuf source edge = new tile_matrix pixbuf source edge
