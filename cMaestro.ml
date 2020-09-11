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
      ) (CImage.statistics img (CGUI.Levels.current ()))
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
      CPaint.tile ~r ~c ();
      CPaint.annot ~r ~c ();
      (* Moves to the new cursor position. *)
      let new_r, new_c = f_row r, f_col c in
      CImage.set_cursor_pos img (new_r, new_c);
      Img_UI_update.set_coordinates new_r new_c;
      Img_UI_update.magnified_view ();
      Img_UI_update.update_toggles ();
      CPaint.cursor ();
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
  CPaint.white_background ~sync:false ();
  CPaint.tiles ();
  CPaint.active_layer ();
  CGUI.status#set_label (digest t);
  at_exit save (* FIXME this may not be the ideal situation! *)


module Img_Tracker = struct
  let mem = ref None

  let erase ?(sync = false) img =
    Gaux.may (fun ((r, c) as pos) ->
      CPaint.tile ~r ~c ();
      CPaint.annot ~r ~c ();
      if pos = CImage.cursor_pos img then CPaint.cursor ();
      if sync then GUI_Drawing.synchronize ()
    ) !mem

  let show ~r ~c img =
    erase img;
    if CTable.is_valid (CImage.annotations img) ~r ~c then begin
      erase img;
      CPaint.tile ~r ~c ();
      CPaint.surface ~r ~c (CPaint.Surface.pointer ());
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
          and lvl = CGUI.Levels.current ()
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
    if r#get_active then CPaint.active_layer ());
  (* Repaints the tiles when the annotation level changes. *)
  CGUI.Levels.set_callback (fun _ r ->
    if r#active then CPaint.active_layer ())


