(* AMFinder - amfImage.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

open Printf
open AmfConst
open ImgShared



class image path = 

    (* File settings. *)
    let file = ImgFile.create path in

    let zip = match Sys.file_exists file#archive with
        | true  -> Some (Zip.open_in file#archive)
        | false -> None in

    (* Source object. *)   
    let pixbuf = GdkPixbuf.from_file path in
    let source = ImgSource.create ?zip pixbuf in
    
    (* Drawing parameters. *)   
    let brush = ImgBrush.create source in
    let cursor = ImgCursor.create source brush
    and pointer = ImgPointer.create source brush in
    
    (* Image segmentation. *)   
    let small_tiles = ImgTileMatrix.create pixbuf source brush#edge
    and large_tiles = ImgTileMatrix.create pixbuf source _MAGN_ in

    (* Annotations, predictions and activations. *)
    let annotations, predictions, activations = 
        let annotations = ImgAnnotations.create ?zip source
        and predictions = ImgPredictions.create ?zip source
        and activations = ImgActivations.create ?zip source in
        Option.iter Zip.close_in zip;
        (annotations, predictions, activations) in

object (self)

    val draw = ImgDraw.create 
        small_tiles
        brush
        cursor
        annotations
        predictions

    val ui = ImgUI.create
        cursor
        annotations
        predictions

    val mutable exit_funcs = []

    initializer
        (* Cursor drawing functions. *)
        cursor#set_paint self#draw_annotated_tile;
        cursor#set_paint (fun ?sync:_ ~r:_ ~c:_ -> self#magnified_view);
        cursor#set_erase self#draw_annotated_tile;
        (* UI update functions. *)
        ui#set_paint self#update_current_tile;
        ui#set_paint self#update_statistics;
        ui#set_refresh (fun () -> self#mosaic ~sync:true ());
        (* Updates the display if the current palette changes. *)
        AmfUI.Predictions.set_palette_update (fun () -> self#mosaic ~sync:true ());
        AmfUI.Levels.current ()
        |> predictions#ids
        |> AmfUI.Predictions.set_choices;
        (* When the active r/c range changes, the entire mosaic is redraw to
         * the backing pixmap, then synchronized with the drawing area. *)
        brush#set_update (fun () -> self#mosaic ~sync:true ());
        brush#set_update self#magnified_view;

    method at_exit f = exit_funcs <- f :: exit_funcs

    method ui = ui
    method file = file
    method brush = brush
    method draw = draw
    method cursor = cursor
    method source = source
    method pointer = pointer
    method small_tiles = small_tiles
    method large_tiles = large_tiles
    method annotations = annotations
    method predictions = predictions

    method show_predictions () =
        let preds = AmfUI.Predictions.get_active () in
        predictions#set_current preds;
        (* TODO: only updates what is needed! *)
        self#mosaic ~sync:true ()

    method predictions_to_annotations ?(erase = false) () =
        match predictions#current_level with
        | None -> ()
        | Some level ->
            (* Level 1 predictions, i.e. root segmentation. *)
            if AmfLevel.is_col level then begin
                let set_annot ~r ~c (chr, _) =
                    let annot = annotations#get ~r ~c () in
                    if annot#is_empty () || erase then annot#add chr
                in predictions#iter (`MAX set_annot)
            (* Level 2 predictions, i.e. mycorrhizal structures. *)
            end else begin
                let set_annot ~r ~c t =
                    let annot = annotations#get ~r ~c () in
                    if annot#is_empty () || erase then
                        List.iter2 (fun chr x ->
                            if x >= !AmfPar.threshold then annot#add chr
                        ) (AmfLevel.to_header level) t
                in predictions#iter (`ALL set_annot)
            end;
            (* UI settings. *)
            self#update_counters ();
            AmfUI.Predictions.overlay#set_active false
    
    method update_statistics () = self#update_counters ()

    method screenshot () =
        let screenshot = AmfUI.Magnifier.screenshot () in
        let r, c = cursor#get in
        let prefix = Filename.remove_extension file#base in
        let filename = sprintf "%s_screenshot_R%dC%d.jpg" prefix r c in
        let path = Filename.concat (Filename.dirname file#path) filename in
        AmfLog.info "Saving screenshot as %S" filename;
        GdkPixbuf.save ~filename:path ~typ:"jpeg" screenshot

    method private draw_annotated_tile ?(sync = false) ~r ~c () =
        let tile_exists = draw#tile ~sync:false ~r ~c () in
        if tile_exists then draw#overlay ~sync:false ~r ~c ();
        if cursor#at ~r ~c then draw#cursor ~sync:false ~r ~c ();
        if sync then brush#sync "image#draw_annotated_tile" ()

    method uncertain_tile () =
        if predictions#active then begin
            let rec loop () =
                match predictions#next_uncertain with
                | None -> () (* Nothing to do. *)
                | Some (r, c) -> let mask = annotations#get ~r ~c () in
                    if mask#is_empty () then
                        ignore (cursor#update_cursor_pos ~r ~c)
                    else loop ()
            in loop ()
        end

    method private update_current_tile () =
        let r, c = cursor#get in
        self#draw_annotated_tile ~sync:true ~r ~c ()

    method private may_overlay_cam ~i ~j ~r ~c =
        if i = 1 && j = 1 && predictions#active && activations#active then (
             match predictions#current with
             | None -> large_tiles#get (* No active prediction set. *)
             | Some id -> activations#get id
        ) else large_tiles#get

    method magnified_view () =
        let r, c = cursor#get in
        for i = 0 to 2 do
            for j = 0 to 2 do
                let ri = r + i - 1 and cj = c + j - 1 in
                let get = self#may_overlay_cam ~i ~j ~r:ri ~c:cj in            
                let pixbuf = match get ~r:ri ~c:cj with
                    | None -> _BLANK_
                    | Some x -> x
                in AmfUI.Magnifier.set_pixbuf ~r:i ~c:j pixbuf
            done
        done;
        ui#update_toggles ()

    method private update_counters () =
        annotations#statistics ()
        |> List.iter (fun (c, n) -> AmfUI.Layers.set_label c n)

    method mosaic ?(sync = false) () =
        brush#background ~sync:false ();
        (* Redraw only the visible tiles. *)
        let rmin, rmax = brush#r_range
        and cmin, cmax = brush#c_range in
        for r = rmin to rmax do
            for c = cmin to cmax do
                self#draw_annotated_tile ~sync:false ~r ~c ()
            done;
        done;
        if predictions#active then begin 
            match AmfUI.Layers.current () with
            | '*' -> brush#classes ~sync:false ()
            |  _  -> brush#palette ~sync:false ()
        end;
        if sync then brush#sync "image#mosaic" ()

    method show () =
        (* No need to synchronize here. The #expose event (see ui/uIDrawing.ml
         * line 53) will refresh the drawing area for us. *)
        self#mosaic ();
        self#magnified_view ();
        self#update_counters ()

    method save () =
        List.iter (fun f -> f ()) exit_funcs;
        let zip = file#archive in
        let och = Zip.open_out zip in
        annotations#dump och;
        predictions#dump och;
        activations#dump och;
        source#save_settings och;
        (* Export the entire image. *)
        if !AmfPar.print_large_maps then self#save_image ();
        Zip.close_out och
    

    method private save_image () =
        let e = source#edge in
        let h = source#rows * e and w = source#columns * e in
        let surface = Cairo.Image.(create ARGB32 ~w ~h) in
        let t = Cairo.create surface in
        Cairo.set_line_width t 0.0;
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        Cairo.set_source_rgba t 1.0 1.0 1.0 1.0;
        Cairo.rectangle t 0.0 0.0 ~w:(float w) ~h:(float h);
        Cairo.fill t;
        for r = 0 to source#rows - 1 do
            for c = 0 to source#columns -1 do
                match large_tiles#get ~r ~c with
                | None -> ()
                | Some pix -> let x = float (c * e) and y = float (r * e) in
                    let _ = resize_pixbuf e pix in
                    (* Cairo_gtk.set_source_pixbuf t pix ~x ~y;
                    Cairo.paint t; *)
                    let mask = annotations#get ~r ~c () in
                    let opt =
                        if mask#mem 'Y' then Some "#FF00FFB0" else
                        if mask#mem 'N' then Some "#707070B0" else None in
                    Option.iter (fun clr ->
                        let s = AmfSurface.Annotation.filled clr e in
                        Cairo.set_source_surface t s ~x ~y;
                        Cairo.paint t
                    ) opt    
            done;
        done;
        let png = sprintf "%s_map.png" (Filename.remove_extension file#path) in
        Cairo.PNG.write surface png
end



let create path =
    if Sys.file_exists path then new image path
    else invalid_arg "AmfImage.load: File not found"
