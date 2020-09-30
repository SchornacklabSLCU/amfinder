(* CastANet - cImage.ml *)

module Aux = struct
    let blank =
        let pix = GdkPixbuf.create ~width:180 ~height:180 () in
        GdkPixbuf.fill pix 0l;
        pix
end




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

    (* Annotations, predictions and activations. *)
    let annotations, predictions, activations = 
        let zip = match Sys.file_exists file#archive with
            | true  -> Some (Zip.open_in file#archive)
            | false -> None in
        let annotations = ImgAnnotations.create ?zip source
        and predictions = ImgPredictions.create ?zip source
        and activations = ImgActivations.create ?zip source in
        Option.iter Zip.close_in zip;
        (annotations, predictions, activations) in

object (self)

    initializer
        (* Cursor drawing functions. *)
        cursor#set_paint self#draw_cursor;
        cursor#set_erase self#draw_tile;
        (* Pointer drawing functions. *)
        pointer#set_paint self#draw_pointer;
        pointer#set_erase self#draw_tile
        (* TODO: insert predictions to palette if more than 1. *)

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
        match small_tiles#get ~r ~c with
        | None -> invalid_arg "CImage.image#draw_cursor: Out of bound"
        | Some pixbuf -> paint#pixbuf ~r ~c pixbuf;
            self#magnified_view ();
            (* Toggle buttons *)
            paint#cursor ~sync:true ~r ~c ()

    method private draw_pointer ~r ~c () =
        match small_tiles#get ~r ~c with
        | None -> invalid_arg "CImage.image#draw_pointer: Out of bound"
        | Some pixbuf -> paint#pixbuf ~r ~c pixbuf;
            paint#pointer ~sync:true ~r ~c ()

    method private draw_tile ~r ~c () =
        match small_tiles#get ~r ~c with
        | None -> invalid_arg "CImage.image#draw_tile: Out of bound"
        | Some pixbuf -> paint#pixbuf ~r ~c pixbuf;
            if cursor#at ~r ~c then paint#cursor ~sync:true ~r ~c () else
            begin
                let level = CGUI.Levels.current () in
                (* Magnified view *)
                (* Toggle buttons *)
                match CGUI.Layers.get_active () with
                | '*' -> ()
                | chr -> match CGUI.Palette.show_predictions#get_active with 
                    | true  -> Option.iter 
                        (paint#annotation ~sync:true ~r ~c level)
                        (predictions#max_layer ~r ~c)
                    | false -> Option.iter (fun mask -> 
                        if String.contains mask#all chr then
                            paint#annotation ~sync:true ~r ~c level chr
                        ) (annotations#get level ~r ~c)
            end

    method magnified_view () =
        let r, c = cursor#get in
        for i = 0 to 2 do
            for j = 0 to 2 do
                let ri = r + i - 1 and cj = c + j - 1 in
                let get = match CGUI.Palette.show_activations#get_active with
                    | true when i = 1 && j = 1 -> 
                        begin match predictions#current with
                        | None -> large_tiles#get
                        | Some id -> match CGUI.Layers.get_active () with
                            | '*' -> 
                                (match predictions#max_layer ~r:ri ~c:cj with
                                | None -> large_tiles#get
                                | Some max -> activations#get id max)
                            | chr -> activations#get id chr
                        end
                     | _ -> large_tiles#get in               
                let pixbuf = match get ~r:ri ~c:cj with
                    | None -> Aux.blank
                    | Some x -> x
                in CGUI.Magnifier.set_pixbuf ~r:i ~c:j pixbuf
            done
        done

    method private update_counters () =
        let source =
            match CGUI.Palette.show_predictions#get_active with
            | true  -> predictions#statistics
            | false -> annotations#statistics (CGUI.Levels.current ())
        in List.iter (fun (c, n) -> CGUI.Layers.set_label c n) source

    method active_layer ?(sync = false) () =
        let level = CGUI.Levels.current ()
        and layer = CGUI.Layers.get_active () in
        let f ~r ~c _ = paint#annotation ~r ~c level layer in
        begin
            match CGUI.Palette.show_predictions#get_active with
            | true  -> predictions#iter_layer layer f
            | false -> annotations#iter_layer level layer f
        end;
        if sync then CGUI.Drawing.synchronize ()

    method mosaic ?(sync = false) () =
        paint#background ~sync:false ();
        let level = CGUI.Levels.current ()
        and layer = CGUI.Layers.get_active () in
        small_tiles#iter (fun ~r ~c pixbuf ->
            paint#pixbuf ~r ~c pixbuf;
            match annotations#get level ~r ~c with
            | None -> invalid_arg "CImage.image#show: Out of bound"
            | Some mask -> if String.contains mask#all layer then 
                paint#annotation ~r ~c level layer
        );
        if sync then CGUI.Drawing.synchronize ()

    method show () =
        self#mosaic ();
        self#active_layer ();
        let r, c = cursor#get in
        paint#cursor ~sync:true ~r ~c ();
        self#magnified_view ();
        self#update_counters ()

    method save () =
        let zip = file#archive in
        List.iter (fun f -> f (ignore zip)) exit_funcs
        (* CTable.save ~zip annotations predictions *)

end



let create ~edge path =
    if Sys.file_exists path then new image path edge
    else invalid_arg "CImage.load: File not found"

