(* CastANet - cImage.ml *)

open CExt



class type sys = object

    method path : string
   
    method archive : string

end



class sys path = object 

    method path = path
    
    method archive = Filename.remove_extension path ^ ".zip"

end



class type visual = object

    method rows : int
    
    method columns : int
    
    method width : int

    method height : int

    method ratio : int

    method x_origin : int
    
    method y_origin : int

end



class visual edge (pixbuf : GdkPixbuf.pixbuf) =

    let width = GdkPixbuf.get_width pixbuf
    and height = GdkPixbuf.get_height pixbuf in

    let rows = height / edge
    and columns = width / edge in

    let ui_width = CGUI.Drawing.width ()
    and ui_height = CGUI.Drawing.height () in

    let ratio = min (ui_width / columns) (ui_height / rows) in

    let x_origin = (ui_width - ratio * columns) / 2
    and y_origin = (ui_height - ratio * rows) / 2 in

object

    method rows = rows
    method columns = columns
    method width = width
    method height = height
    method ratio = ratio
    method x_origin = x_origin
    method y_origin = y_origin

end



class type tile_matrix = object

    method edge : int
    
    method contents : GdkPixbuf.pixbuf Ext_Matrix.t

end



module Aux = struct

    let crop ~src_x ~src_y ~edge pix =
        let dest = GdkPixbuf.create
            ~width:edge
            ~height:edge () in
        GdkPixbuf.copy_area ~dest ~src_x ~src_y pix;
        dest
        
    let resize ?(interp = `NEAREST) e pix =
        let open GdkPixbuf in
        let scale_x = float e /. (float (get_width pix))
        and scale_y = float e /. (float (get_height pix)) in
        let dest = create ~width:e ~height:e () in
        scale ~dest ~scale_x ~scale_y ~interp pix;
        dest

end



class tile_matrix rows columns src_edge dst_edge = object

    val data = Ext_Matrix.init rows columns
        begin fun r c ->
            let src_x = c * src_edge
            and src_y = r * src_edge in
            Aux.resize dst_edge (Aux.crop ~src_x ~src_y ~edge:src_edge pixbuf)
        end

    method edge = dst_edge
    method contents = data

end 


class type image = object

    method sys : sys
    
    method visual : visual

    method small_tiles : Mosaic.tile_matrix

    method large_tiles : Mosaic.tile_matrix
  
    method annotations : CTable.annotation_table list

    method predictions : CTable.prediction_table list

end



class image path edge = 

    let pixbuf = GdkPixbuf.from_file fpath in

    let sys = new sys path
    and visual = new visual edge pixbuf in

    let annotations, predictions =
        if Sys.file_exists sys#archive then (
            let data = CTable.load sys#archive in
            (** No annotation table. *)
            if fst data = [] then
                (CTable.create
                    ~rows:visual#rows
                    ~columns:visual#columns, pt)
            else data
        ) else (CTable.create ~rows:visual#rows ~columns:visual#columns, []) in

    let small = new tile_matrix visual#rows visual#columns edge visual#ratio
    and large = new tile_matrix visual#rows visual#columns edge 180 in

object (self)

    initializer
        CLog.info "source image: '%s'\n\
                   source image size: %d x %d pixels\n\
                   tile matrix: %d x %d; edge: %d pixels"
            path self#visual#width self#visual#height
            self#visual#rows self#visual#columns edge

    method sys = sys
    method visual = visual
    
    method small_tiles = small
    method large_tiles = large

    method annotations = annotations
    method predictions = predictions

end



let load ~edge path =
    if Sys.file_exists path then new image path edge
    else invalid_arg "CImage.load: File not found"


