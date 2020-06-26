(* CastANet - cEvent.ml *)

let update_annotations ev =
  begin try
    let key = Char.uppercase_ascii (GdkEvent.Key.string ev).[0] in
    if String.contains "AVEIRDH" key then CGUI.Zoom.toggle_any key
  with _ -> () end;
  false

let icons () =
  List.iter (fun (chr, (btn, img)) ->
    let rgba = CIcon.get chr `RGBA `SMALL
    and grey = CIcon.get chr `GREY `SMALL in
    let callback () = img#set_pixbuf (if btn#get_active then rgba else grey) in
    ignore (btn#connect#toggled ~callback)
  ) CGUI.VToolbox.radios_full;
  let btn, img = CGUI.VToolbox.master_full in
  let rgba = CIcon.get_special `RGBA `SMALL
  and grey = CIcon.get_special `GREY `SMALL in
  let callback () = img#set_pixbuf (if btn#get_active then rgba else grey) in
  ignore (btn#connect#toggled ~callback);
  List.iter (fun (chr, (btn, img)) ->
    let rgba = CIcon.get chr `RGBA `LARGE
    and grey = CIcon.get chr `GREY `LARGE in
    let callback () = img#set_pixbuf (if btn#active then rgba else grey) in
    ignore (btn#connect#toggled ~callback);
  ) CGUI.Zoom.toggles_full

let toggles =
  List.map (fun (key, toggle) ->
    let id = toggle#connect#toggled 
      ~callback:(fun () -> CDraw.set_curr_annotation toggle#active key)
    in key, toggle, id
  ) CGUI.Zoom.toggles 
   
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
