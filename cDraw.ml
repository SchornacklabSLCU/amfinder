(* CastANet - caN_draw.ml *)

open CExt
open Printf

let curr = ref None

let load path =
  let ui_width, ui_height, pixmap =
    let open CGUI.Thumbnail in
    width (), height (), pixmap () in
  let t = CImage.create ~ui_width ~ui_height path in
  curr := Some t;
  let xini, yini, edge = CImage.(xini t, yini t, edge t `SMALL) in
  CImage.iter_tiles (fun r c tile -> 
    pixmap#put_pixbuf
      ~x:(xini + c * edge)
      ~y:(yini + r * edge)
      ~width:edge ~height:edge tile
  ) t `SMALL;
  at_exit (fun () -> 
    let tsv = Filename.remove_extension path ^ ".tsv" in
    CAnnot.export tsv (CImage.annotations t))

let eval f = match !curr with None -> assert false | Some img -> f img

let curr_image () = eval (fun x -> x)

let make_cairo_surface ?(r = 0.0) ?(g = 0.0) ?(b = 0.0) ?(a = 1.0) img =
  let open Cairo in
  let e = CImage.edge img `SMALL in
  let surface = Image.create Image.ARGB32 ~w:e ~h:e in
  let t = create surface in
  set_antialias t ANTIALIAS_SUBPIXEL;
  set_source_rgba t r g b a;
  let e = float e in
  rectangle t 0.0 0.0 ~w:e ~h:e;
  fill t;
  stroke t;
  surface

module Layer = struct
  let master = CExt.memoize
    begin fun () ->
      let f img =    
        let r, g, b = tagger_html_to_float "#aaffaa" in
        make_cairo_surface ~r ~g ~b ~a:0.7 img
      in eval f
    end

  let colors = [ "#cdde87"; "#ffe680"; "#aaeeff"; "#afc6e9"; 
                 "#ffb380"; "#eeaaff"; "#ff8080" ]

  let viridis_palette = [|
    "#440154"; "#481567"; "#482677"; "#453781"; "#404788";
    "#39568C"; "#33638D"; "#2D708E"; "#287D8E"; "#238A8D";
    "#1F968B"; "#20A387"; "#29AF7F"; "#3CBB75"; "#55C667";
    "#73D055"; "#95D840"; "#B8DE29"; "#DCE319"; "#FDE725" |]
  
  let viridis_length = Array.length viridis_palette 
    
  let sunset_palette = [|
    "#4B2991"; "#5A2995"; "#692A99"; "#782B9D"; "#872CA2";
    "#952EA0"; "#A3319F"; "#B1339E"; "#C0369D"; "#CA3C97";
    "#D44292"; "#DF488D"; "#EA4F88"; "#ED5983"; "#F2637F";
    "#F66D7A"; "#FA7876"; "#F98477"; "#F89078"; "#F79C79";
    "#F6A97A"; "#F3B584"; "#F1C18E"; "#EFCC98"; "#EDD9A3";
  |]
    
  let sunset_length = Array.length sunset_palette

  let viridis_surfaces = CExt.memoize
    (fun () ->
      match !curr with
      | None -> assert false
      | Some img -> Array.map 
        (fun clr ->
          let r, g, b = tagger_html_to_float clr in
          make_cairo_surface ~r ~g ~b ~a:0.8 img
        ) viridis_palette
    )

  let categories = CExt.memoize
    begin fun () ->
      let f img =
        List.map2 (fun chr clr ->
          let r, g, b = tagger_html_to_float clr in
          let s = make_cairo_surface ~r ~g ~b ~a:0.8 img in
          (chr, s)
        ) CAnnot.code_list colors
      in eval f
    end

  let get_surface ann = function
    | `SPECIAL -> master ()
    | `CHR chr -> match CAnnot.annotation_type () with
      | `BINARY -> List.assoc chr (categories ())
      | `GRADIENT -> let grp = CAnnot.get_group ~size:(viridis_length - 1) ann chr in
        (viridis_surfaces ()).(grp)
   
end

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
          | `SPECIAL -> erase_confidence ()
          | `CHR chr -> let size = Layer.viridis_length - 1 in
            let i = CAnnot.get_group ~size t chr in
            let prob = CAnnot.get t chr in
            if prob > 0.0 then (
              ksprintf CGUI.VToolbox.confidence#set_label 
                "<tt><small><b>%-3.0f %%</b></small></tt>" 
               (100. *. prob);
              ksprintf CGUI.VToolbox.confidence_color#set_label
                "<tt><span background='%s' foreground='%s'>DDDDD</span></tt>"
                Layer.viridis_palette.(i) Layer.viridis_palette.(i)
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

let set_curr_annotation active chr =
  Gaux.may (fun img ->
    CAnnot.(if active then add else rem) (curr_annotation ()) chr;
    let r, c = CImage.cursor_pos img in
    update_confidence_text_area r c
  ) !curr

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
        | `SPECIAL -> not (CAnnot.is_empty ann)
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
      | Some img -> make_cairo_surface ~r:0.8 ~a:0.8 img
    in CExt.memoize f
end

let cursor ?(sync = false) () =
  Gaux.may (fun img ->
    let r, c = CImage.cursor_pos img in
    tile r c;
    surface r c (CaN_Surfaces.cursor ());
    if sync then CGUI.Thumbnail.synchronize ()
  ) !curr


let active_layer ?(sync = true) () =
  Gaux.may (fun img ->
    CImage.iter_annotations (fun r c _ ->
      tile r c;
      annot r c
    ) img;
    cursor ();
    let r, c = CImage.cursor_pos img in update_text_areas ~r ~c ();
    if sync then CGUI.Thumbnail.synchronize ()
  ) !curr

let missing_image = CExt.memoize 
  (fun () ->
    let pix = GdkPixbuf.create ~width:180 ~height:180 () in
    GdkPixbuf.fill pix 0l;
    pix)


module GUI = struct
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
    List.iter (fun (key, toggle, id) ->
      GtkSignal.handler_block toggle#as_widget id;
      toggle#set_active (String.contains ann key);
      GtkSignal.handler_unblock toggle#as_widget id
    ) t
end


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
        let nc = CImage.columns img and c' = c - jump in
        if c' < 0 then (c' + nc) mod nc else
        if c' >= nc then c' mod nc else c'
      in eval f)

  let move_right ?(jump = 1) = move
    ~f_row:(fun r -> r)
    ~f_col:(fun c ->
      let f img =
        let nc = CImage.columns img and c' = c + jump in
        if c' < 0 then (c' + nc) mod nc else
        if c' >= nc then c' mod nc else c'
      in eval f)

  let move_up ?(jump = 1) = move
    ~f_row:(fun r -> 
      let f img =
        let nr = CImage.rows img and r' = r - jump in
        if r' < 0 then (r' + nr) mod nr else
        if r' >= nr then r' mod nr else r'
      in eval f)
    ~f_col:(fun c -> c)

  let move_down ?(jump = 1) = move
    ~f_row:(fun r ->
      let f img =
        let nr = CImage.rows img and r' = r + jump in
        if r' < 0 then (r' + nr) mod nr else
        if r' >= nr then r' mod nr else r'
      in eval f)
    ~f_col:(fun c -> c)

  let arrow_key_press ?(toggles = []) ev =
    let sym, modi = GdkEvent.Key.(keyval ev, state ev) in
    let jump = 
      if List.mem `CONTROL modi then 25 else
      if List.mem `SHIFT   modi then 10 else 1 in
    begin match sym with
      | 65361 -> move_left ~jump
      | 65362 -> move_up ~jump
      | 65363 -> move_right ~jump
      | 65364 -> move_down ~jump
      | _     -> ignore
    end toggles;
    false

  let at_mouse_pointer ?(toggles = []) ev =
    Gaux.may (fun img ->
      let open GdkEvent.Button in
      let x = truncate (x ev) - CImage.xini img
      and y = truncate (y ev) - CImage.yini img
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
      | Some img -> make_cairo_surface ~r:0.8 ~a:0.4 img
    in CExt.memoize f

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
      let x = truncate (x ev) - CImage.xini img
      and y = truncate (y ev) - CImage.yini img
      and e = CImage.edge img `SMALL in
      show ~r:(y / e) ~c:(x / e) img
    ) !curr;
    false

  let hide _ = Gaux.may (erase ~sync:true) !curr; false
end
