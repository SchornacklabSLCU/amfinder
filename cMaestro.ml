(* CastANet - cImage.mli *)

open CExt
open CGUI
open Printf


module Par = struct
  open Arg
  let edge = ref 236
  let image_path = ref None
  let set_image_path x = if Sys.file_exists x then image_path := Some x
  let usage = "castanet_editor.exe [OPTIONS] [IMAGE_PATH]"
  let specs = align [
    "--edge", Set_int edge, sprintf " Tile size (default: %d pixels)." !edge;
  ]
  let initialize () = parse specs set_image_path usage
end




(* Cairo surfaces for the painting functions below. *)
module Img_Surface = struct
  let square ?(alpha = 0.85) ~kind edge =
    assert (edge > 0); 
    let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    let clr = match kind with 
      | `CURSOR -> "#cc0000" 
      | `RGB x -> x in
    let r, g, b = EColor.html_to_float clr
    and a = max (min alpha 1.0) 0.0 in
    Cairo.set_source_rgba t r g b a;
    let edge = float edge in
    Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
    Cairo.fill t;
    Cairo.stroke t;
    surface

  let joker = 
    let aux () =
      match (CImage.get_active ()) with
      | None -> assert false (* does not happen. *)
      | Some img -> let edge = CImage.edge img `SMALL in
        square ~kind:(`RGB "#aaffaa") edge
    in Ext_Memoize.create ~label:"Img_Surface.master" aux

  let cursor = 
    let aux () =
      match (CImage.get_active ()) with
      | None -> assert false (* does not happen. *)
      | Some img -> let edge = CImage.edge img `SMALL in
        square ~kind:`CURSOR edge
    in Ext_Memoize.create ~label:"Img_Surface.cursor" aux

  let pointer = 
    let create () = 
      match (CImage.get_active ()) with
      | None -> assert false
      | Some img -> let edge = CImage.edge img `SMALL in
        square ~kind:`CURSOR ~alpha:0.40 edge
    in Ext_Memoize.create ~label:"Img_Surface.pointer" create

  let layers =
    List.map (fun lvl ->
      let aux lvl () =
        match (CImage.get_active ()) with
        | None -> assert false (* does not happen. *)
        | Some img -> let edge = CImage.edge img `SMALL in   
          List.map2 (fun chr rgb ->
            chr, square ~kind:(`RGB rgb) edge
          ) (CAnnot.char_list lvl) (CLevel.colors lvl)
      in lvl, Ext_Memoize.create ~label:"Img_Surface.layers" (aux lvl)
    ) CLevel.flags

  let get = function
    | '*' -> joker ()
    | '.' -> cursor ()
    | chr -> let lvl = GUI_levels.current () in
      List.assoc chr (List.assoc lvl layers ()) 
end


(* Painting functions. *)
module Img_Paint = struct
  let white_background ?(sync = true) () =
    let t = GUI_Drawing.cairo () in
    Cairo.set_source_rgba t 1.0 1.0 1.0 1.0;
    let w = float (GUI_Drawing.width ()) 
    and h = float (GUI_Drawing.height ()) in
    Cairo.rectangle t 0.0 0.0 ~w ~h;
    Cairo.fill t;
    Cairo.stroke t;
    if sync then GUI_Drawing.synchronize ()

  let tiles ?(sync = true) () =
    Option.iter (fun img ->
      let pixmap = GUI_Drawing.pixmap ()
      and xini = CImage.origin img `X
      and yini = CImage.origin img `Y
      and edge = CImage.edge img `SMALL in
      CImage.iter_tiles (fun ~r ~c tile ->
        pixmap#put_pixbuf
          ~x:(xini + c * edge)
          ~y:(yini + r * edge)
          ~width:edge ~height:edge tile
      ) img `SMALL;
      if sync then GUI_Drawing.synchronize ()
    ) (CImage.get_active ())

  let tile ?(sync = false) r c =
    Option.iter (fun img ->
      Option.iter (fun tile ->
        (GUI_Drawing.pixmap ())#put_pixbuf
          ~x:(CImage.x ~c img `SMALL)
          ~y:(CImage.y ~r img `SMALL) tile;
        if sync then GUI_Drawing.synchronize ()
      ) (CImage.tile r c img `SMALL)
    ) (CImage.get_active ())

  (* FIXME Unsafe function - not for use outside! *)
  let surface ?(sync = false) r c surface =
    Option.iter (fun img ->
      let t = GUI_Drawing.cairo () in
      let x = CImage.x ~c img `SMALL 
      and y = CImage.y ~r img `SMALL in
      Cairo.set_source_surface t surface (float x) (float y);
      Cairo.paint t;
      if sync then GUI_Drawing.synchronize ()
    ) (CImage.get_active ())

  let annot ?(sync = false) r c =
    Option.iter (fun img ->
      let typ = GUI_Layers.get_active ()
      and tbl = CImage.annotations img
      and lvl = GUI_levels.current () in
      let draw = match typ with
        | '*' -> not (CTable.is_empty tbl lvl ~r ~c) (* Catches any annotation. *)
        | chr -> CTable.mem tbl lvl r c (`CHR chr) in
      if draw then begin
        surface r c (Img_Surface.get typ);
        if sync then GUI_Drawing.synchronize ()
      end
    ) (CImage.get_active ())

  let cursor ?(sync = false) () =
    Option.iter (fun img ->
      let r, c = CImage.cursor_pos img in
      tile r c;
      surface r c (Img_Surface.get '.');
      if sync then GUI_Drawing.synchronize ()
    ) (CImage.get_active ())

  let active_layer ?(sync = true) () =
    Option.iter (fun img ->
      CTable.iter (fun ~r ~c _ ->
        tile r c;
        annot r c
      ) (CImage.annotations img) (GUI_levels.current ());
      cursor ();
 (*     let r, c = CImage.cursor_pos img in
      Img_UI_update.set_coordinates r c; *)
      if sync then GUI_Drawing.synchronize ()
    ) (CImage.get_active ())
end


(* Interaction with the user interface. *)
module Img_UI_update = struct
  let set_coordinates =
    let set lbl =
      ksprintf lbl#set_label "<tt><small><b>%c:</b> %03d</small></tt>"
    in fun r c -> GUI_Coords.(set row 'R' r; set column 'C' c)
    
  let update_toggles () =
    Option.iter (fun img ->
      let tbl = CImage.annotations img
      and r, c = CImage.cursor_pos img in
      let tiles = CTable.get_all tbl ~r ~c in
      GUI_Toggles.set_status tiles
    ) (CImage.get_active ())
    
  let set_counters =
    Option.iter (fun img ->
      List.iter (fun (chr, num) ->
        GUI_Layers.set_label chr num
      ) (CImage.statistics img (GUI_levels.current ()))
    ) (CImage.get_active ())
    
  let blank_tile =
    Ext_Memoize.create ~label:"CImage.Img_UI_update.blank_tile" ~one:true
    (fun () ->
      let pix = GdkPixbuf.create ~width:180 ~height:180 () in
      GdkPixbuf.fill pix 0l; pix)

  let magnified_view () =
    Option.iter (fun img ->
      let cur_r, cur_c = CImage.cursor_pos img in
      for i = 0 to 2 do
        for j = 0 to 2 do
          let r = cur_r + i - 1 and c = cur_c + j - 1 in
          let pixbuf = match CImage.tile r c img `LARGE with
            | None -> blank_tile ()
            | Some x -> x
          in GUI_Magnify.tiles.(i).(j)#set_pixbuf pixbuf
        done
      done;  
    ) (CImage.get_active ())
end


(* Keyboard-related actions. *)
module Img_Move = struct
  let apply f =
    match (CImage.get_active ()) with
    | None -> assert false
    | Some img -> f img

  let run ~f_row ~f_col _ =
    Option.iter (fun img ->
      (* Cursor gets removed; we need to repaint the tile. *)
      let r, c = CImage.cursor_pos img in
      Img_Paint.tile r c;
      Img_Paint.annot r c;
      (* Moves to the new cursor position. *)
      let new_r, new_c = f_row r, f_col c in
      CImage.set_cursor_pos img (new_r, new_c);
      Img_UI_update.set_coordinates new_r new_c;
      Img_UI_update.magnified_view ();
      Img_UI_update.update_toggles ();
      Img_Paint.cursor ();
      GUI_Drawing.synchronize ()
    ) (CImage.get_active ())

  let left ?(jump = 1) = run
    ~f_row:(fun r -> r)
    ~f_col:(fun c -> 
      let f img =
        let nc = CImage.dim img `C and c' = c - jump in
        if c' < 0 then (c' + nc) mod nc else
        if c' >= nc then c' mod nc else c'
      in apply f)

  let right ?(jump = 1) = run
    ~f_row:(fun r -> r)
    ~f_col:(fun c ->
      let f img =
        let nc = CImage.dim img `C and c' = c + jump in
        if c' < 0 then (c' + nc) mod nc else
        if c' >= nc then c' mod nc else c'
      in apply f)

  let up ?(jump = 1) = run
    ~f_row:(fun r -> 
      let f img =
        let nr = CImage.dim img `R and r' = r - jump in
        if r' < 0 then (r' + nr) mod nr else
        if r' >= nr then r' mod nr else r'
      in apply f)
    ~f_col:(fun c -> c)

  let down ?(jump = 1) = run
    ~f_row:(fun r ->
      let f img =
        let nr = CImage.dim img `R and r' = r + jump in
        if r' < 0 then (r' + nr) mod nr else
        if r' >= nr then r' mod nr else r'
      in apply f)
    ~f_col:(fun c -> c)
end



  
let digest t =
  sprintf "<small><tt> \
    <b>Image:</b> %s ▪ \
    <b>Size:</b> %d × %d pixels ▪ \
    <b>Tiles:</b> %d × %d</tt></small>" 
    (CImage.basename t)
    (CImage.source t `W) (CImage.source t `H)
    (CImage.dim t `R) (CImage.dim t `C)

let save () =
  match (CImage.get_active ()) with
  | None -> ()
  | Some img -> CImage.path img
    |> Filename.remove_extension
    |> sprintf "%s.zip"
    |> CTable.save (CImage.annotations img)

let load () =
  (* Retrieves an image path from the command line or from a file chooser. *)
  Par.initialize ();
  let path = match !Par.image_path with
    | None -> GUI_FileChooserDialog.run ()
    | Some path -> path in
  (* Displays the main window in order to retrieve drawing parameters. *)
  CGUI.window#show ();
  (* Loads the image, creates tiles and populates the main window. *)
  let t = CImage.create ~edge:!Par.edge path in
  (* Draws background and tiles, then adds image info to the status bar. *)
  Img_Paint.white_background ~sync:false ();
  Img_Paint.tiles ();
  Img_Paint.active_layer ();
  CGUI.status#set_label (digest t);
  at_exit save (* FIXME this may not be the ideal situation! *)


module Img_Tracker = struct
  let mem = ref None

  let erase ?(sync = false) img =
    Gaux.may (fun ((r, c) as pos) ->
      Img_Paint.tile r c;
      Img_Paint.annot r c;
      if pos = CImage.cursor_pos img then Img_Paint.cursor ();
      if sync then GUI_Drawing.synchronize ()
    ) !mem

  let show ~r ~c img =
    erase img;
    if CTable.is_valid (CImage.annotations img) ~r ~c then begin
      erase img;
      Img_Paint.tile r c;
      Img_Paint.surface r c (Img_Surface.pointer ());
      mem := Some (r, c)
    end;
    GUI_Drawing.synchronize ()
end


(* UI-based functions that trigger changes. *)
module Img_Trigger = struct
  let arrow_keys ev =
    let sym, modi = GdkEvent.Key.(keyval ev, state ev) in
    let jump = 
      if List.mem `CONTROL modi then 25 else
      if List.mem `SHIFT   modi then 10 else 1 in
    let out, f = match sym with
      | 65361 -> true, Img_Move.left ~jump
      | 65362 -> true, Img_Move.up ~jump
      | 65363 -> true, Img_Move.right ~jump
      | 65364 -> true, Img_Move.down ~jump
      | _     -> false, ignore
    in f [(* toggles *)];
    out

  (* Can be given GdkEvent.Key.t values or characters. *)
  let annotation_keys ev = 
    try
      Option.iter (fun img ->
        let key = Char.uppercase_ascii (
          match ev with
          | `CHR chr -> chr
          | `GDK evt -> (GdkEvent.Key.string evt).[0]
        ) in
        CLog.info "Key pressed: %C" key;
        match GUI_Toggles.is_active key with
        | None -> () (* Invalid key, nothing to do! *)
        | Some is_active ->
          let tbl = CImage.annotations img
          and lvl = GUI_levels.current ()
          and r, c = CImage.cursor_pos img in
          CTable.(if is_active then remove else add) tbl lvl ~r ~c key
          |> GUI_Toggles.set_status
      ) (CImage.get_active ());
      false
    with _ -> false

  let mouse_click ev =
    Option.iter (fun img ->
      let open GdkEvent.Button in
      let x = truncate (x ev) - CImage.origin img `X
      and y = truncate (y ev) - CImage.origin img `Y
      and e = CImage.edge img `SMALL in
      let r = y / e and c = x / e in
      if CTable.is_valid (CImage.annotations img) ~r ~c then
        Img_Move.run ~f_row:(fun _ -> r) ~f_col:(fun _ -> c)  [(* toggles *)]
    )(CImage.get_active ());
    false

  let mouse_move ev =
    Option.iter (fun img ->
      let e = CImage.edge img `SMALL
      and x = truncate (GdkEvent.Motion.x ev) - CImage.origin img `X
      and y = truncate (GdkEvent.Motion.y ev) - CImage.origin img `Y in
      Img_Tracker.show ~r:(y / e) ~c:(x / e) img
    ) (CImage.get_active ());
    false
  
  let mouse_leave _ =
    Option.iter (Img_Tracker.erase ~sync:true) (CImage.get_active ());
    false
end

let initialize () =
  (* Callback functions for keyboard events. *)
  let connect = CGUI.window#event#connect in
  ignore (connect#key_press Img_Trigger.arrow_keys);
  ignore (connect#key_press (fun x -> Img_Trigger.annotation_keys (`GDK x)));
  (* Callback functions for mouse events. *)
  let connect = GUI_Drawing.area#event#connect in
  ignore (connect#button_press Img_Trigger.mouse_click);
  ignore (connect#motion_notify Img_Trigger.mouse_move);
  ignore (connect#leave_notify Img_Trigger.mouse_leave);
  (* Repaints the tiles when the active layer changes. *)
  GUI_Layers.set_callback (fun _ r _ _ -> 
    if r#get_active then Img_Paint.active_layer ());
  (* Repaints the tiles when the annotation level changes. *)
  GUI_levels.set_callback (fun _ r ->
    if r#active then Img_Paint.active_layer ())


