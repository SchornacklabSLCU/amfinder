(* CastANet - cImage.ml *)

class type t = object
    method file : ImgFile.t
    method source : ImgSource.t
    method draw : ImgDraw.t
    method small_tiles : ImgTileMatrix.t
    method large_tiles : ImgTileMatrix.t
    method annotations : CTable.annotation_table list
    method predictions : CTable.prediction_table list
end



class image path edge = 

    (* File settings. *)
    let file = ImgFile.create path in

    (* Source object. *)   
    let pixbuf = GdkPixbuf.from_file path in
    let source = ImgSource.create pixbuf edge in
    
    (* Drawing parameters. *)   
    let draw = ImgDraw.create source in

    (* Image segmentation. *)   
    let small_tiles = ImgTileMatrix.create pixbuf source draw#edge
    and large_tiles = ImgTileMatrix.create pixbuf source 180 in

    (* Annotations and predictions. *)
    let annotations, predictions =
        let rows = source#rows and columns = source#columns in
        match Sys.file_exists file#archive with
        | false -> CTable.create ~rows ~columns, []
        | _     -> match CTable.load file#archive with
            | [], pt -> CTable.create ~rows ~columns, pt
            | others -> others 
    in

object (self)

    initializer
        CLog.info "source image: '%s'\n\
                   source image size: %d x %d pixels\n\
                   tile matrix: %d x %d; edge: %d pixels"
            path source#width source#height source#rows source#columns edge

    method file = file
    method draw = draw
    method small_tiles = small_tiles
    method large_tiles = large_tiles
    method annotations = annotations
    method predictions = predictions

end



let load ~edge path =
    if Sys.file_exists path then new image path edge
    else invalid_arg "CImage.load: File not found"

