(* CastANet - cGUI.ml *)

open Printf

let window =
  ignore (GMain.init ());
  let wnd = GWindow.window
    ~title:"CastANet Editor 1.0"
    ~resizable:false
    ~position:`CENTER () in
  wnd#connect#destroy GMain.quit;
  wnd


let spacing = 5
let border_width = spacing


module Box = struct
  (* To allow for a status label to be added at the bottom of the interface. *)
  let v = GPack.vbox ~spacing:2 ~border_width ~packing:window#add ()
  (* To display the magnified view and whole image side by side. *)
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


module HToolbox = struct
  let bbox =
    (* Setting up expand/fill allows to centre the button box. *)
    let packing = Pane.left#attach ~top:0 ~left:0 ~expand:`X ~fill:`NONE in
    GPack.table
      ~rows:1 ~columns:7 
      ~col_spacings:10
      ~homogeneous:true
      ~packing ()

  let set_icon image button rgba grey () =
    image#set_pixbuf (if button#active then rgba else grey)

  let add_item i chr =
    let toggle = GButton.toggle_button 
      ~relief:`NONE
      ~packing:(bbox#attach ~left:i ~top:0) () in
    let icon = GMisc.image ~width:48 ~packing:toggle#set_image () in
    icon#set_pixbuf (CIcon.get chr `GREY `LARGE);
    toggle, icon
  
  let toggles = Array.of_list CAnnot.code_list
    |> Array.mapi add_item
    |> Array.to_list
    |> List.combine CAnnot.code_list
    |> Array.of_list
 
  module Action = struct
    let apply any chr = String.index CAnnot.codes chr
      |> Array.get toggles
      |> snd
      |> fst
      |> any
   
    let is_active = apply (fun t -> t#active)

    let set_status status = 
      apply (fun t -> 
        let status = match status with
          | `INVERT -> not t#active
          | `BOOL b -> b
        in t#set_active status)
    
    let lock = ref false
    
    let activate t = 
      lock := true;
      String.iter (set_status (`BOOL true)) t;
      lock := false
    
    let deactivate t =
      lock := true;
      String.iter (set_status (`BOOL false)) t;
      lock := false
    
    let check chr () =
      if not !lock then begin
        activate (CAnnot.requires chr);
        deactivate (CAnnot.forbids chr);
        if not (is_active chr) then deactivate (CAnnot.erases chr)
      end

    let _ = 
      Array.iter (fun (chr, (toggle, _)) ->
        ignore (toggle#connect#toggled ~callback:(check chr))
      ) toggles
  end
    
  let toggle_any chr =
    Action.set_status `INVERT chr;
    Action.check chr () 
end


module Magnify = struct
  let rows = 3
  let columns = 3
  let edge = 180

  let table = GPack.table
    ~rows ~columns
    ~packing:(Pane.left#attach ~top:1 ~left:0) ()

  let tile_image top left =
    let event = GBin.event_box
      ~width:(edge + 2) ~height:(edge + 2) 
      ~packing:(table#attach ~top ~left) ()
    (* The centre has a red frame to grab users attention. *)
    and color = if top = 1 && left = 1 then "red" else "gray60" in
    event#misc#modify_bg [`NORMAL, `NAME color];
    let pixmap = GDraw.pixmap ~width:edge ~height:edge () in
    GMisc.pixmap pixmap ~packing:event#add ()

  let tiles = Array.(init rows (fun t -> init columns (tile_image t)))
end


module Thumbnail = struct
  let area = 
    let packing = Pane.right#attach ~left:0 ~top:0 in
    let packing = (GBin.frame ~width:600 ~packing ())#add in
    GMisc.drawing_area ~packing ()

  type drawing_tools = { pixmap : GDraw.pixmap; cairo : Cairo.context }
  let dt = ref None

  let get f () = match !dt with None -> assert false | Some dt -> f dt
  let cairo = get (fun dt -> dt.cairo)
  let pixmap = get (fun dt -> dt.pixmap)
  let width = get (fun dt -> fst dt.pixmap#size)
  let height = get (fun dt -> snd dt.pixmap#size)

  let synchronize () =
    let width = width () and height = height () in
    area#misc#draw (Some (Gdk.Rectangle.create ~x:0 ~y:0 ~width ~height))

  let _ =
    (* Repaint masked area upon GtkDrawingArea exposure. *)
    let repaint ev =
      let open Gdk.Rectangle in
      let r = GdkEvent.Expose.area ev in
      let x = x r and y = y r and width = width r and height = height r in
      let drawing = new GDraw.drawable area#misc#window in
      drawing#put_pixmap
        ~x ~y ~xsrc:x ~ysrc:y
        ~width ~height (pixmap ())#pixmap;
      false in
    area#event#add [`EXPOSURE];
    area#event#connect#expose repaint;
    (* Creates a GtkPixmap and its Cairo.context upon widget size allocation. *)
    let initialize {Gtk.width; height} =  
      let pixmap = GDraw.pixmap ~width ~height () in
      let cairo = Cairo_gtk.create pixmap#pixmap in
      dt := Some {pixmap; cairo}
    in area#misc#connect#size_allocate initialize
end


module VToolbox = struct

  let toolbar = GButton.toolbar
    ~orientation:`VERTICAL
    ~style:`ICONS
    ~width:75 ~height:565 (* Minimal size to display widgets. *)
    ~packing:(Pane.right#attach ~left:1 ~top:0 ~expand:`Y ~fill:`NONE) ()

  let packing = toolbar#insert

  module Create = struct
    let separator () = ignore (GButton.separator_tool_item ~packing ())
    let morespace () =
      let item = GButton.tool_item ~expand:false ~packing () in
      ignore (GPack.vbox ~height:5 ~packing:item#add ())
    let label ?(vspace = true) markup =
      let item = GButton.tool_item ~packing () in
      let markup = sprintf "<small>%s</small>" markup in
      let label = GMisc.label ~markup ~justify:`CENTER ~packing:item#add () in
      if vspace then morespace ();
      label
    let radio ?group typ =
      let active, get_icon = match typ with
        | `CHR chr -> false, CIcon.get chr `GREY 
        | `SPECIAL -> true, CIcon.get_special `RGBA in
      let radio = GButton.radio_tool_button ?group ~active ~packing () in
      let image = GMisc.image ~width:24 ~packing:radio#set_icon_widget () in
      image#set_pixbuf (get_icon `SMALL);
      radio, image
  end
  
  let _ = Create.separator ()

  let _ = Create.label "Layer"
  let master = Create.radio `SPECIAL

  let radios =
    let group = fst master in
    List.map (fun c -> c, Create.radio ~group (`CHR c)) CAnnot.code_list
 
  let _ = Create.separator ()

  let _ = Create.label "Coordinates" 
  let row = Create.label ~vspace:false "<tt><b>R:</b> 000</tt>"
  let column = Create.label ~vspace:false "<tt><b>C:</b> 000</tt>" 
  
  let _ = Create.separator ()
  
  let _ = Create.label "Confidence"
  let confidence = Create.label "<tt><b> n/a </b></tt>"
  let confidence_color = Create.label "<tt><span background='white' \
      foreground='white'>DDDDD</span></tt>"

  let _ = Create.separator ()

  let export = GButton.tool_button ~stock:`SAVE ~packing ()
  let preferences = GButton.tool_button ~stock:`PREFERENCES ~packing ()

  let _ = Create.separator ()

  let get_active () =
    if (fst master)#get_active then `SPECIAL
    else `CHR (fst (List.find (fun (_, (x, _)) -> x#get_active) radios))
end

let status = 
  let lbl = GMisc.label ~xalign:0.0 ~yalign:0.0
    ~packing:(Box.v#pack ~expand:false) () in
  lbl#set_use_markup true;
  lbl
