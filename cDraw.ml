(* CastANet - cDraw.ml *)

open CExt
open Printf

let curr = ref None

let eval f = match !curr with None -> assert false | Some img -> f img

let curr_image () = eval (fun x -> x)

let white_background () =
  let open CGUI.Thumbnail in
  let cc = cairo () in
  Cairo.set_source_rgba cc 1.0 1.0 1.0 1.0;
  let w = float (width ()) and h = float (height ()) in
  Cairo.rectangle cc 0.0 0.0 ~w ~h;
  Cairo.fill cc;
  Cairo.stroke cc;
  synchronize ()

let unset_current () = curr := None

let make_cairo_surface ?clr ?(a = 0.8) img =
  CExt.Draw.square ?clr ~a (CImage.edge img `SMALL)

let load path =
  let ui_width, ui_height, pixmap =
    let open CGUI.Thumbnail in
    width (), height (), pixmap () in
  let t = CImage.create ~ui_width ~ui_height path in
  curr := Some t;
  let xini, yini, edge = CImage.(origin t `X, origin t `Y, edge t `SMALL) in
  white_background ();
  CImage.iter_tiles (fun r c tile -> 
    pixmap#put_pixbuf
      ~x:(xini + c * edge)
      ~y:(yini + r * edge)
      ~width:edge ~height:edge tile
  ) t `SMALL


module Layer = struct
  let master = CExt.Memoize.create "master"
    (fun () -> eval (make_cairo_surface ~clr:"#aaffaa" ~a:0.7))

  let colors = [ "#cdde87"; "#ffe680"; "#aaeeff"; "#afc6e9"; 
                 "#ffb380"; "#eeaaff"; "#ff8080" ]

  let categories = CExt.Memoize.create "categories"
    begin fun () ->
      let f img =
        List.map2 (fun chr clr ->
          let s = make_cairo_surface ~clr ~a:0.8 img in
          (chr, s)
        ) CAnnot.code_list colors
      in eval f
    end

  let get_surface ann = function
    | `JOKER -> master ()
    | `CHR chr -> match CAnnot.annotation_type () with
      | `BINARY -> List.assoc chr (categories ())
      | `GRADIENT -> let palette = CSettings.palette () in
        let grp = CAnnot.get_group ~palette ann chr in
        CPalette.surface palette grp  
end


let tile ?(sync = false) r c =
  Gaux.may (fun img ->
    let open CImage in
    Gaux.may (fun tile ->
      (CGUI.Thumbnail.pixmap ())#put_pixbuf
        ~x:(x ~c img `SMALL)
        ~y:(y ~r img `SMALL) tile;
      if sync then CGUI.Thumbnail.synchronize ()
    ) (tile r c img `SMALL)
  ) !curr

let surface ?(sync = false) r c s =
  Gaux.may (fun img ->
    if CImage.is_valid ~r ~c img then begin
      let t = CGUI.Thumbnail.cairo () in
      let x = CImage.x ~c img `SMALL 
      and y = CImage.y ~r img `SMALL in
      Cairo.set_source_surface t s (float x) (float y);
      Cairo.paint t;
      if sync then CGUI.Thumbnail.synchronize ()
    end
  ) !curr

let annot ?(sync = false) r c =
  Gaux.may (fun img ->
    Gaux.may (fun ann ->
      let typ = CGUI.VToolbox.get_active () in
      let draw = match typ with
        | `JOKER -> not (CAnnot.is_empty ann)
        | `CHR chr -> CAnnot.mem ann chr in
      if draw then begin
        surface r c (Layer.get_surface ann typ);
        if sync then CGUI.Thumbnail.synchronize ()
      end
    ) (CImage.annotation ~r ~c img)
  ) !curr

module CaN_Surfaces = struct
  let cursor = 
    let f () = match !curr with
      | None -> assert false
      | Some img -> make_cairo_surface img
    in CExt.Memoize.create "cursor" f
end

let cursor ?(sync = false) () =
  Gaux.may (fun img ->
    let r, c = CImage.cursor_pos img in
    tile r c;
    surface r c (CaN_Surfaces.cursor ());
    if sync then CGUI.Thumbnail.synchronize ()
  ) !curr


let missing_image = CExt.Memoize.create "missing_image"
  (fun () ->
    let pix = GdkPixbuf.create ~width:180 ~height:180 () in
    GdkPixbuf.fill pix 0l;
    pix)


module GUI = struct
  let erase_confidence () =
    CGUI.VToolbox.confidence#set_label "<tt><small><b> n/a </b></small></tt>";
    CGUI.VToolbox.confidence_color#set_label "<tt><span background='white' \
      foreground='white'>DDDDD</span></tt>"

  let update_confidence_text_area r c =
    Gaux.may (fun img ->
      begin match CImage.annotation ~r ~c img with
        | Some t when CAnnot.annotation_type () = `GRADIENT -> 
          if CAnnot.is_empty t then erase_confidence ()
          else begin 
            match CGUI.VToolbox.get_active () with
            | `JOKER -> erase_confidence ()
            | `CHR chr -> let palette = CSettings.palette () in
              let i = CAnnot.get_group ~palette:palette t chr in
              let prob = CAnnot.get t chr in
              if prob > 0.0 then (
                ksprintf CGUI.VToolbox.confidence#set_label 
                  "<tt><small><b>%-3.0f %%</b></small></tt>" 
                 (100. *. prob);
                ksprintf CGUI.VToolbox.confidence_color#set_label
                  "<tt><span background='%s' foreground='%s'>DDDDD</span></tt>"
                  (CPalette.color palette i) (CPalette.color palette i)
              ) else erase_confidence ()
            end
        | _ -> ()
      end
    ) !curr

  let update_text_areas ~r ~c () =
    ksprintf CGUI.VToolbox.row#set_label
      "<tt><small><b>R:</b> %03d</small></tt>" r;
    ksprintf CGUI.VToolbox.column#set_label
      "<tt><small><b>C:</b> %03d</small></tt>" c;
    update_confidence_text_area r c

  let curr_annotation () =
    match !curr with
    | None -> assert false
    | Some img -> let r, c = CImage.cursor_pos img in
      match CImage.annotation ~r ~c img with
      | None -> assert false 
      | Some x -> x 

  let statistics () =
    Gaux.may (fun img ->
      List.iter (fun (chr, num) ->
        match chr with
        | '*' -> CGUI.VToolbox.set_label `JOKER num
        |  _  -> CGUI.VToolbox.set_label (`CHR chr) num
      ) (CImage.statistics img)
    ) !curr

  let magnified_view () =
    Gaux.may (fun img ->
      let cur_r, cur_c = CImage.cursor_pos img in
      for i = 0 to 2 do
        for j = 0 to 2 do
          let r = cur_r + i - 1 and c = cur_c + j - 1 in
          let pixbuf = match CImage.tile r c img `LARGE with
            | None -> missing_image ()
            | Some x -> x
          in CGUI.Magnify.tiles.(i).(j)#set_pixbuf pixbuf
        done
      done;  
    ) !curr

  let coordinates new_r new_c =
    update_text_areas ~r:new_r ~c:new_c ()

  let update_active_toggles t =
    let ann = curr_annotation () |> CAnnot.get_active in
    Array.iter (fun (key, toggle, id) ->
      GtkSignal.handler_block toggle#as_widget id;
      toggle#set_active (String.contains ann key);
      statistics ();
      GtkSignal.handler_unblock toggle#as_widget id
    ) t
end

let set_curr_annotation active chr =
  Gaux.may (fun img ->
    let r, c = CImage.cursor_pos img in
    Gaux.may (fun ann ->
      CAnnot.(if active then add else rem) ann chr;
      GUI.statistics ();
      GUI.update_confidence_text_area r c
    ) (CImage.annotation ~r ~c img)
  ) !curr

let active_layer ?(sync = true) () =
  Gaux.may (fun img ->
    CImage.iter_annot (fun r c _ ->
      tile r c;
      annot r c
    ) img;
    cursor ();
    let r, c = CImage.cursor_pos img in GUI.update_text_areas ~r ~c ();
    if sync then CGUI.Thumbnail.synchronize ()
  ) !curr


let display_set () =
  Gaux.may (fun img ->
    let count = ref 0 in
    let show, ico = match CGUI.VToolbox.get_active () with
      | `JOKER -> (fun ann -> not (CAnnot.is_empty ann)), CIcon.get '*' `RGBA `SMALL
      | `CHR chr -> (fun ann -> CAnnot.mem ann chr), CIcon.get chr `RGBA `SMALL in
    CImage.iter_annot (fun r c ann ->
      if show ann then begin
        incr count;
        Gaux.may (CGUI.TileSet.add ~r ~c ~ico) (CImage.tile ~r ~c img `LARGE) 
      end
    ) img;
    CGUI.TileSet.set_title "Tile set (%d images)" !count;
    let _ = CGUI.TileSet.run () in
    CGUI.TileSet.hide ()
  ) !curr


module Cursor = struct
  let move ~f_row ~f_col toggles =
    Gaux.may (fun img ->
      let r, c = CImage.cursor_pos img in
      tile r c;
      annot r c;    
      let new_r, new_c = f_row r, f_col c in
      CImage.set_cursor_pos img (new_r, new_c);
      GUI.coordinates new_r new_c;
      GUI.magnified_view ();
      GUI.update_active_toggles toggles;
      cursor ();      
      CGUI.Thumbnail.synchronize ()
    ) !curr

  let move_left ?(jump = 1) = move
    ~f_row:(fun r -> r)
    ~f_col:(fun c -> 
      let f img =
        let nc = CImage.dim img `C and c' = c - jump in
        if c' < 0 then (c' + nc) mod nc else
        if c' >= nc then c' mod nc else c'
      in eval f)

  let move_right ?(jump = 1) = move
    ~f_row:(fun r -> r)
    ~f_col:(fun c ->
      let f img =
        let nc = CImage.dim img `C and c' = c + jump in
        if c' < 0 then (c' + nc) mod nc else
        if c' >= nc then c' mod nc else c'
      in eval f)

  let move_up ?(jump = 1) = move
    ~f_row:(fun r -> 
      let f img =
        let nr = CImage.dim img `R and r' = r - jump in
        if r' < 0 then (r' + nr) mod nr else
        if r' >= nr then r' mod nr else r'
      in eval f)
    ~f_col:(fun c -> c)

  let move_down ?(jump = 1) = move
    ~f_row:(fun r ->
      let f img =
        let nr = CImage.dim img `R and r' = r + jump in
        if r' < 0 then (r' + nr) mod nr else
        if r' >= nr then r' mod nr else r'
      in eval f)
    ~f_col:(fun c -> c)

  let arrow_key_press ?(toggles = [||]) ev =
    let sym, modi = GdkEvent.Key.(keyval ev, state ev) in
    let jump = 
      if List.mem `CONTROL modi then 25 else
      if List.mem `SHIFT   modi then 10 else 1 in
    let out, f = match sym with
      | 65361 -> true, move_left ~jump
      | 65362 -> true, move_up ~jump
      | 65363 -> true, move_right ~jump
      | 65364 -> true, move_down ~jump
      | _     -> false, ignore
    in f toggles;
    out

  let at_mouse_pointer ?(toggles = [||]) ev =
    Gaux.may (fun img ->
      let open GdkEvent.Button in
      let x = truncate (x ev) - CImage.origin img `X
      and y = truncate (y ev) - CImage.origin img `Y
      and e = CImage.edge img `SMALL in
      let r = y / e and c = x / e in
      if CImage.is_valid ~r ~c img then
        move ~f_row:(fun _ -> r) ~f_col:(fun _ -> c) toggles
    )!curr;
    false
 end


module MouseTracker = struct
  let mem = ref None

  let cairo_surface = 
    let f () = 
      match !curr with
      | None -> assert false
      | Some img -> make_cairo_surface ~a:0.4 img
    in CExt.Memoize.create "cairo_surface" f

  let erase ?(sync = false) img =
    Gaux.may (fun ((r, c) as pos) ->
      tile r c;
      annot r c;
      if pos = CImage.cursor_pos img then cursor ();
      if sync then CGUI.Thumbnail.synchronize ()
    ) !mem

  let show ~r ~c img =
    erase img;
    if CImage.is_valid ~r ~c img then begin
      erase img;
      tile r c;
      surface r c (cairo_surface ());
      mem := Some (r, c)
    end;
    CGUI.Thumbnail.synchronize ()

  let update ev =
    Gaux.may (fun img ->
      let open GdkEvent.Motion in
      let x = truncate (x ev) - CImage.origin img `X
      and y = truncate (y ev) - CImage.origin img `Y
      and e = CImage.edge img `SMALL in
      show ~r:(y / e) ~c:(x / e) img
    ) !curr;
    false

  let hide _ = Gaux.may (erase ~sync:true) !curr; false
end
