(* CastANet - cImage.ml *)


class image path edge = 

    (* File settings. *)
    let file = ImgFile.create path in

    (* Source object. *)   
    let pixbuf = GdkPixbuf.from_file path in
    let source = ImgSource.create pixbuf edge in
    
    (* Drawing parameters. *)   
    let paint = ImgPaint.create source in
    let cursor = ImgCursor.create source paint
    and pointer = ImgPointer.create source paint in
    
    (* Image segmentation. *)   
    let small_tiles = ImgTileMatrix.create pixbuf source paint#edge
    and large_tiles = ImgTileMatrix.create pixbuf source 180 in

    (* Annotations and predictions. *)
    let annotations, predictions = ImgDataset.create source file#archive in

object (self)

    initializer
        (* Cursor drawing functions. *)
        cursor#set_paint self#draw_cursor;
        cursor#set_erase self#draw_tile;
        (* Pointer drawing functions. *)
        pointer#set_paint self#draw_pointer;
        pointer#set_erase self#draw_tile

    val mutable exit_funcs = []
    method at_exit f = exit_funcs <- f :: exit_funcs

    method file = file
    method paint = paint
    method cursor = cursor
    method source = source
    method pointer = pointer
    method small_tiles = small_tiles
    method large_tiles = large_tiles
    method annotations = annotations
    method predictions = predictions

    method private draw_cursor ~r ~c () =
        paint#pixbuf ~r ~c (small_tiles#get ~r ~c);
        (* Magnified view *)
        (* Toggle buttons *)
        paint#cursor ~sync:true ~r ~c ()

    method private draw_pointer ~r ~c () =
        paint#pixbuf ~r ~c (small_tiles#get ~r ~c);
        paint#pointer ~sync:true ~r ~c ()

    method private draw_tile ~r ~c () =
        paint#pixbuf ~r ~c (small_tiles#get ~r ~c);
        let level = CGUI.Levels.current ()
        and layer = CGUI.Layers.get_active () in
        paint#annotation ~sync:true ~r ~c level layer
        (* Magnified view *)
        (* Toggle buttons *)

    method show () =
        paint#background ~sync:false ();
        let level = CGUI.Levels.current ()
        and layer = CGUI.Layers.get_active () in
        small_tiles#iter (fun ~r ~c pixbuf ->
            paint#pixbuf ~r ~c pixbuf;
            let mask = annotations#get level ~r ~c in
            if mask#mem `USER (`CHAR layer) 
            || mask#mem `HOLD (`CHAR layer) then 
                paint#annotation ~r ~c level layer
        );
        let r, c = cursor#get in
        paint#cursor ~sync:true ~r ~c ()

    method save () =
        let zip = file#archive in
        List.iter (fun f -> f ()) exit_funcs
        (* CTable.save ~zip annotations predictions *)

end



let create ~edge path =
    if Sys.file_exists path then new image path edge
    else invalid_arg "CImage.load: File not found"

