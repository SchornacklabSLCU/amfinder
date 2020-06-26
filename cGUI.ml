(* CastANet - cGUI.ml *)

let window =
  ignore (GMain.init ());
  let wnd = GWindow.window
    ~title:"CastANet Annotation Editor 1.0"
    ~resizable:false
    ~position:`CENTER () in
  wnd#connect#destroy GMain.quit;
  wnd


let spacing = 5
let border_width = spacing


module Box = struct
  let v = GPack.vbox ~spacing:2 ~border_width ~packing:window#add ()
  let h = GPack.hbox ~spacing   ~border_width ~packing:v#add ()
end


module Pane = struct
  let make label rows columns =
    let packing = (GBin.frame ~label ~packing:Box.h#add ())#add in
    GPack.table ~rows ~columns 
      ~row_spacings:spacing
      ~col_spacings:spacing 
      ~border_width ~packing ()
  let left = make "Magnified view" 2 1
  let right = make "Whole image" 1 2
end


module Zoom = struct
  let bbox = GPack.table ~rows:1 ~columns:7 
    ~col_spacings:10
    ~homogeneous:true
    ~packing:(Pane.left#attach ~top:0 ~left:0 ~expand:`X ~fill:`NONE) () 

  let set_icon image button rgba grey () =
    image#set_pixbuf (if button#active then rgba else grey)

  let add_item chr i =
    let grey = CIcon.get chr `GREY `LARGE in 
    let btn = GButton.toggle_button 
      ~relief:`NONE
      ~packing:(bbox#attach ~left:i ~top:0) () in
    let image = GMisc.image ~width:48 ~packing:btn#set_image () in
    image#set_pixbuf grey;
    btn, image
  
  let toggles_full =
    let n = ref (-1) in
    List.map (fun chr ->
      incr n;
      (chr, add_item chr !n)
    ) CAnnot.code_list

  let toggles = List.map (fun (x, y) -> x, fst y) toggles_full
  
  let toggle_from_char chr =
    String.index CAnnot.codes chr
    |> List.nth toggles |> snd
  
  let lock = ref false
  
  let activate t = 
    lock := true;
    String.iter (fun c -> (toggle_from_char c)#set_active true) t;
    lock := false
  
  let deactivate t =
    lock := true;
    String.iter (fun c -> (toggle_from_char c)#set_active false) t;
    lock := false
  
  let check chr =
    let required, forbidden, erased = match chr with
      | 'A' -> "R", "D", ""
      | 'V' -> "R", "D", ""
      | 'I' -> "R", "D", ""
      | 'E' -> "", "D", ""
      | 'R' -> "", "D", "AVIH"
      | 'D' -> "", "AVIERH", ""
      | 'H' -> "R", "D", ""
      |  _  -> assert false in
    activate required;
    deactivate forbidden;
    if not (toggle_from_char chr)#active then deactivate erased
 
  let toggle_any chr =
    let toggle = toggle_from_char chr in
    toggle#set_active (not toggle#active); check chr
   
  let _ = 
    List.iter (fun (chr, toggle) ->
      toggle#connect#toggled ~callback:(fun () ->
        if not !lock then check chr); ()
    ) toggles
end



let table = 
  (* No expansion means widget size will be preserved. *)
  let packing = Pane.left#attach ~top:1 ~left:0 ~expand:`NONE ~fill:`NONE in
  GPack.table ~rows:3 ~columns:3 ~homogeneous:true ~packing ()

let edge = 180

let tiles =
  let width = edge and height = edge in
  Array.init 3 (fun top -> 
    Array.init 3 (fun left ->
      let packing = table#attach ~left ~top ~expand:`NONE ~fill:`NONE in
      let pixmap = GDraw.pixmap ~width ~height () in
      let box = GPack.vbox ~width:(edge + 2) ~height:(edge + 2) ~packing () in
      let event = GBin.event_box ~packing:box#add () in
      if top = 1 && left = 1 then event#misc#modify_bg [`NORMAL, `RGB (255 lsl 8, 0, 0)]
      else event#misc#modify_bg [`NORMAL, `RGB (0xb0 lsl 8, 0xb0 lsl 8, 0xb0 lsl 8)];
      let image = GMisc.pixmap ~xalign:0.5 ~yalign:0.5 pixmap ~packing:event#add () in
      box, image
  ))
  

module Thumbnail = struct
  let frame = GBin.frame ~width:600 
    ~packing:(Pane.right#attach ~left:0 ~top:0) ()
  let area = GMisc.drawing_area ~packing:frame#add ()
  let memo = ref Obj.(magic (), magic ())
  let cairo () = snd !memo
  let pixmap () = fst !memo
  let width () = fst (pixmap ())#size
  let height () = snd (pixmap ())#size
  let refresh ev =
    let open Gdk.Rectangle in
    let r = GdkEvent.Expose.area ev in
    let x = x r and y = y r and width = width r and height = height r in
    let drawing = new GDraw.drawable area#misc#window in
    drawing#put_pixmap ~x ~y ~xsrc:x ~ysrc:y ~width ~height (pixmap ())#pixmap;
    false
  let synchronize () =
    let width = width () and height = height () in
    area#misc#draw (Some (Gdk.Rectangle.create ~x:0 ~y:0 ~width ~height))
  let initialize () =
    let t = cairo () in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    let r, g, b = 1.0, 1.0, 1.0 (* main_window_backcolor () *) in
    Cairo.set_source_rgba t r g b 1.0;
    Cairo.rectangle t 0.0 0.0 ~w:(float (width ())) ~h:(float (height ()));
    Cairo.fill t;
    Cairo.stroke t;
    synchronize ()     
  let create_drawing_toolbox {Gtk.width; height} =   
    let pixmap = GDraw.pixmap ~width ~height () in
    let cairo = Cairo_gtk.create pixmap#pixmap in
    memo := (pixmap, cairo);
    initialize ()
  let _ =
    area#event#add [`EXPOSURE];
    ignore (area#event#connect#expose refresh);
    ignore (area#misc#connect#size_allocate create_drawing_toolbox)  
end

module Layers = struct
  let toolbar = GButton.toolbar
    ~orientation:`VERTICAL
    ~style:`ICONS
    ~width:75
    ~height:565
    ~packing:(Pane.right#attach ~left:1 ~top:0 ~expand:`Y ~fill:`NONE) ()
  let packing = toolbar#insert

  let separator () = ignore (GButton.separator_tool_item ~packing ())
  let morespace () =
    let item = GButton.tool_item ~expand:false ~packing () in
    ignore (GPack.vbox ~height:5 ~packing:item#add ())

  let create ?group typ =
    let active, f = match typ with
      | `CHR chr -> false, CIcon.get chr `GREY 
      | `SPECIAL -> true, CIcon.get_special `RGBA (* is active *) in
    let radio = GButton.radio_tool_button ?group ~active ~packing () in
    let image = GMisc.image ~width:24 ~packing:radio#set_icon_widget () in
    image#set_pixbuf (f `SMALL);
    radio, image

  let label markup =
    let item = GButton.tool_item ~packing () in
    GMisc.label ~justify:`CENTER ~markup ~packing:item#add ()

  let _ = 
    separator ();
    label "<small>Layer</small>";
    morespace ()

  let master_full = create `SPECIAL
  let master = fst master_full
  let radios_full =
    List.map (fun c -> c, create ~group:master (`CHR c)) CAnnot.code_list
  let radios = List.map (fun (a, (b, _)) -> (a, b)) radios_full

  let get_active () =
    if master#get_active then `SPECIAL
    else `CHR (fst (List.find (fun x -> (snd x)#get_active) radios))
    
  let _ = separator ()
  
  let export = GButton.tool_button ~stock:`SAVE ~packing ()
  let preferences = GButton.tool_button ~stock:`PREFERENCES ~packing ()
  
  let _ = separator ()
  
  let _ =
    label "<small>Coordinates</small>";
    morespace ()
  
  let row = label "<tt><small><b>R:</b> 000</small></tt>"
  let column = label "<tt><small><b>C:</b> 000</small></tt>" 
  
  let _ = separator ()
  
  let confidence_title = label "<small>Confidence</small>"
  let _ = morespace ()

  let confidence = label "<tt><small><b>n. a.</b></small></tt>"
  let _ = morespace ()

  let confidence_color = label "<tt><span background='white' \
      foreground='white'>DDDDD</span></tt>"
  let _ = morespace (); separator ()

end

let status = 
  let lbl = GMisc.label ~xalign:0.0 ~yalign:0.0
    ~packing:(Box.v#pack ~expand:false) () in
  lbl#set_use_markup true;
  lbl
