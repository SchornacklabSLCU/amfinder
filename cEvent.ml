(* CastANet - cEvent.ml *)

let update_annotations ev =
  begin try
    let key = Char.uppercase_ascii (GdkEvent.Key.string ev).[0] in
    if String.contains "AVEIRDH" key then CGUI.HToolbox.toggle_any key
  with _ -> () end;
  false

let icons () =
  List.iter (fun (chr, (btn, img)) ->
    let rgba = CIcon.get chr `RGBA `SMALL
    and grey = CIcon.get chr `GREY `SMALL in
    let callback () = img#set_pixbuf (if btn#get_active then rgba else grey) in
    ignore (btn#connect#toggled ~callback)
  ) CGUI.VToolbox.radios;
  let btn, img = CGUI.VToolbox.master in
  let rgba = CIcon.get_special `RGBA `SMALL
  and grey = CIcon.get_special `GREY `SMALL in
  let callback () = img#set_pixbuf (if btn#get_active then rgba else grey) in
  ignore (btn#connect#toggled ~callback);
  Array.iter (fun (chr, (btn, img)) ->
    let rgba = CIcon.get chr `RGBA `LARGE
    and grey = CIcon.get chr `GREY `LARGE in
    let callback () = img#set_pixbuf (if btn#active then rgba else grey) in
    ignore (btn#connect#toggled ~callback);
  ) CGUI.HToolbox.toggles

let layers () =
  let activate radio () = if radio#get_active then CDraw.active_layer () in
  List.iter (fun x ->
    let radio = fst (snd x) in
    ignore (radio#connect#toggled ~callback:(activate radio))
  ) CGUI.VToolbox.radios;
  let master = fst CGUI.VToolbox.master in
  master#connect#toggled ~callback:(activate master);
  activate master ()

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

let mouse_pointer () =
  let open CGUI.Thumbnail in
  area#event#add [`POINTER_MOTION; `BUTTON_PRESS; `LEAVE_NOTIFY];
  area#event#connect#motion_notify CDraw.MouseTracker.update;
  area#event#connect#leave_notify CDraw.MouseTracker.hide;
  area#event#connect#button_press (CDraw.Cursor.at_mouse_pointer ~toggles);
  ()

let initialize () =
  List.iter (fun f -> f ()) [icons; layers; keyboard; mouse_pointer]