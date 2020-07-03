(* CastANet - cEvent.ml *)

let update_annotations ev =
  begin try
    let key = Char.uppercase_ascii (GdkEvent.Key.string ev).[0] in
    if String.contains CAnnot.codes key then CGUI.HToolbox.toggle_any key
  with _ -> () end;
  false

let icons () =
  CGUI.VToolbox.iter_radios (fun typ ->
    let f = match typ with
      | `JOKER -> CIcon.get_joker
      | `CHR chr -> CIcon.get chr in
    let callback () =
      let clr = match CGUI.VToolbox.is_active typ with
        | true  -> CDraw.active_layer (); `RGBA
        | false -> `GREY
      in CGUI.VToolbox.set_image typ (f clr `SMALL)
    in ignore (CGUI.VToolbox.set_toggled typ callback)
  );
  CDraw.active_layer ();
  Array.iter (fun (chr, (btn, img)) ->
    let rgba = CIcon.get chr `RGBA `LARGE
    and grey = CIcon.get chr `GREY `LARGE in
    let callback () = img#set_pixbuf (if btn#active then rgba else grey) in
    ignore (btn#connect#toggled ~callback);
  ) CGUI.HToolbox.toggles

let toggles =
  Array.map (fun (key, (toggle, _)) ->
    let id = toggle#connect#toggled 
      ~callback:(fun () -> CDraw.set_curr_annotation toggle#active key)
    in key, toggle, id
  ) CGUI.HToolbox.toggles 
   
let keyboard () =
  let connect = CGUI.window#event#connect in
  connect#key_press (CDraw.Cursor.arrow_key_press ~toggles);
  connect#key_press update_annotations;
  ()

let drawing_area () =
  let open CGUI.Thumbnail in
  area#event#add [`POINTER_MOTION; `BUTTON_PRESS; `LEAVE_NOTIFY];
  area#event#connect#motion_notify CDraw.MouseTracker.update;
  area#event#connect#leave_notify CDraw.MouseTracker.hide;
  area#event#connect#button_press (CDraw.Cursor.at_mouse_pointer ~toggles);
  ()

let buttons () =
  CGUI.VToolbox.export#connect#clicked ~callback:CDraw.display_set;
  ()


let initialize () =
  List.iter (fun f -> f ()) [icons; keyboard; drawing_area; buttons]
