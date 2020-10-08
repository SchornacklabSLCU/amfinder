(* CastANet - cImage.ml *)

open Printf

module Aux = struct
    let blank =
        let pix = GdkPixbuf.create ~width:180 ~height:180 () in
        GdkPixbuf.fill pix 0l;
        pix
end



class draw 
  (small_tiles : ImgTileMatrix.tile_matrix)
  (brush : ImgBrush.brush)
  (annotations : ImgAnnotations.annotations)
  (predictions : ImgPredictions.predictions) 

= object (self)

    method tile ?(sync = true) ~r ~c () =
        match small_tiles#get ~r ~c with
        | None -> CLog.error ~code:Err.out_of_bounds "CImage.image#draw#tile: \
            Index out of bounds (r = %d, c = %d)" r c
        | Some pixbuf -> brush#pixbuf ~sync ~r ~c pixbuf

    method cursor ?(sync = true) ~r ~c () =
        self#tile ~sync:false ~r ~c ();
        brush#cursor ~sync ~r ~c ()

    method pointer ?(sync = true) ~r ~c () =
        self#tile ~sync:false ~r ~c ();
        brush#pointer ~sync ~r ~c ()    

    method annotation ?sync ~r ~c mask =
        let level = annotations#current_level in
        match annotations#current_layer with
        | '*' -> brush#annotation ?sync ~r ~c level '*'
        | chr -> match mask#active (`CHAR chr) with
            | true  -> brush#annotation ?sync ~r ~c level chr
            | false -> () (* no annotation in this layer. *)

    method prediction ?sync ~r ~c () =
        if predictions#active then
            match predictions#max_layer ~r ~c with
            | None -> () (* is that possible? *)
            | Some chr -> let level = annotations#current_level in
                match annotations#current_layer with
                | '*' -> brush#annotation ?sync ~r ~c level chr
                | cur when chr = cur -> brush#annotation ?sync ~r ~c level chr
                | _ -> () (* Not to be displayed. *)

    method overlay ?(sync = true) ~r ~c () =
        let level = annotations#current_level in
        let mask = annotations#get ~level ~r ~c () in
        (* Gives priority to annotations over predictions. *)
        if mask#is_empty () then self#prediction ~sync ~r ~c ()
        else self#annotation ~sync ~r ~c mask

end



class image path edge = 

    (* File settings. *)
    let file = ImgFile.create path in

    (* Source object. *)   
    let pixbuf = GdkPixbuf.from_file path in
    let source = ImgSource.create pixbuf edge in
    
    (* Drawing parameters. *)   
    let brush = ImgBrush.create source in
    let cursor = ImgCursor.create source brush
    and pointer = ImgPointer.create source brush in
    
    (* Image segmentation. *)   
    let small_tiles = ImgTileMatrix.create pixbuf source brush#edge
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

    val draw = new draw small_tiles brush annotations predictions
    val mutable exit_funcs = []

    initializer
        (* Cursor drawing functions. *)
        cursor#set_paint draw#cursor;
        cursor#set_paint (fun ?sync:_ ~r:_ ~c:_ -> self#magnified_view);
        cursor#set_erase self#draw_annotated_tile;
        (* Pointer drawing functions. *)
        pointer#set_paint draw#pointer;
        pointer#set_erase self#draw_annotated_tile;
        annotations#current_level
        |> predictions#ids
        |> CGUI.Predictions.set_choices

    method at_exit f = exit_funcs <- f :: exit_funcs

    method file = file
    method brush = brush
    method cursor = cursor
    method source = source
    method pointer = pointer
    method small_tiles = small_tiles
    method large_tiles = large_tiles
    method annotations = annotations
    method predictions = predictions

    method show_predictions () =
        let preds = CGUI.Predictions.get_active () in
        predictions#set_current preds;
        self#mosaic ()    

    (* TODO: it should be possible to choose the folder! *)
    method screenshot () =
        let screenshot = CGUI.Magnifier.screenshot () in
        let r, c = cursor#get in
        let filename = sprintf "AMF_screenshot_R%d_C%d.jpg" r c in
        CLog.info "Saving screenshot as %S" filename;
        GdkPixbuf.save ~filename ~typ:"jpeg" screenshot

    (* + self#magnified_view () and toggle buttons *)
    method private draw_annotated_tile ?(sync = false) ~r ~c () =
        let sync = false in
        draw#tile ~sync ~r ~c ();
        if cursor#at ~r ~c then brush#cursor ~sync ~r ~c ()
        else if pointer#at ~r ~c then brush#pointer ~sync ~r ~c ()
        else draw#overlay ~sync ~r ~c ();
        if sync then brush#sync ()

    method private may_overlay_cam ~i ~j ~r ~c =
        if i = 1 && j = 1 && predictions#active && activations#active then (
             match predictions#current with
             | None -> large_tiles#get (* No active prediction set. *)
             | Some id -> match annotations#current_layer with
                | '*' -> (* let's find the top layer. *)
                    begin match predictions#max_layer ~r ~c with
                        | None -> large_tiles#get
                        | Some max -> activations#get id max
                    end
                | chr -> activations#get id chr
        ) else large_tiles#get

    method magnified_view () =
        let r, c = cursor#get in
        for i = 0 to 2 do
            for j = 0 to 2 do
                let ri = r + i - 1 and cj = c + j - 1 in
                let get = self#may_overlay_cam ~i ~j ~r:ri ~c:cj in            
                let pixbuf = match get ~r:ri ~c:cj with
                    | None -> Aux.blank
                    | Some x -> x
                in CGUI.Magnifier.set_pixbuf ~r:i ~c:j pixbuf
            done
        done

    method private update_counters () =
        let source =
            match predictions#active with
            | true  -> predictions#statistics
            | false -> annotations#statistics (annotations#current_level)
        in List.iter (fun (c, n) -> CGUI.Layers.set_label c n) source

    method mosaic ?(sync = false) () =
        brush#background ~sync:false ();
        small_tiles#iter (fun ~r ~c pixbuf ->
            brush#pixbuf ~sync:false ~r ~c pixbuf;
            self#draw_annotated_tile ~sync:false ~r ~c ()
        );
        if sync then brush#sync ()

    method show () =
        self#mosaic ();
        let r, c = cursor#get in
        brush#cursor ~sync:true ~r ~c ();
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

