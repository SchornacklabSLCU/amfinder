(* CastANet - cGUI.ml *)

open Printf

type toggle_ext = {
  toggle : GButton.toggle_button;
  image : GMisc.image;
}

type radio_ext = {
  radio : GButton.radio_tool_button;
  label : GMisc.label;
  image : GMisc.image;
}

module Toolbox = struct
  module type TOGGLE = sig
    val table : GPack.table
    val toggles : (char * toggle_ext) array
  end 
  module type RADIO = sig
    val table : GButton.toolbar
    val radios : (char * radio_ext) list
  end 
  module type LABEL = sig
    val toolbar : GButton.toolbar
    val label_1 : GMisc.label
    val label_2 : GMisc.label
  end
end

(* Auxiliary module to create toolbar elements. *)
module ToolItem = struct
  let separator packing = ignore (GButton.separator_tool_item ~packing ())
  let morespace packing =
    let item = GButton.tool_item ~expand:false ~packing () in
    ignore (GPack.vbox ~height:5 ~packing:item#add ())
  let label ?(vspace = true) packing markup =
    let item = GButton.tool_item ~packing () in
    let markup = sprintf "<small>%s</small>" markup in
    let label = GMisc.label ~markup ~justify:`CENTER ~packing:item#add () in
    if vspace then morespace packing;
    label
end


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
  let v = GPack.vbox ~border_width ~packing:window#add ()
  (* To display the annotation modes (as radio buttons). *)
  let b = GPack.button_box `HORIZONTAL
    ~border_width:(2 * spacing) (* more space to make it clearly visible. *)
    ~layout:`SPREAD
    ~packing:(v#pack ~expand:false) ()
  (* To display the magnified view and whole image side by side. *)
  let h = GPack.hbox ~spacing ~border_width ~packing:v#add ()
end


module GUI_levels = struct
  let curr = ref CLevel.lowest
  let current () = !curr
  let make_radio group str lvl =
    (* Container for the GtkRadioButton and its corresponding GtkLabel. *)
    let packing = (GPack.hbox ~packing:Box.b#add ())#pack ~expand:false in
    (* Radio button without a label (will use a GtkLabel for that). *)
    let active = group = None in
    let r = GButton.radio_button ?group ~active ~packing () in
    (* Removes the unpleasant focus square around the round button. *)
    r#misc#set_can_focus false;
    let markup = sprintf "<big><b>%s</b></big>" str in
    ignore (GMisc.label ~markup ~packing ());
    (* Updates the annotation level upon activation. *)
    r#connect#toggled (fun () -> if r#active then curr := lvl);
    r
  let radios = 
    let group = ref None in
    List.map2 (fun lvl lbl ->
      let radio = make_radio !group lbl lvl in
      if !group = None then group := Some radio#group;
      lvl, radio
    ) CLevel.flags CLevel.strings
end


module Pane = struct
  let initialize label ~r ~c =
    let packing = (GBin.frame ~label ~packing:Box.h#add ())#add in
    GPack.table
      ~rows:r ~columns:c 
      ~row_spacings:spacing
      ~col_spacings:spacing 
      ~border_width ~packing ()
  let left = initialize "Magnified view" ~r:2 ~c:1
  let right = initialize "Whole image" ~r:1 ~c:2
end


module GToggles = struct
  (* Values here ensure that new buttons appear between existing ones when
   * the user switches between the different annotation levels. *)
  let get_col_spacing = function
    | `COLONIZATION -> 134
    | `ARB_VESICLES -> 68
    | `ALL_FEATURES -> 2

  let set_icon image button rgba grey () =
    image#set_pixbuf (if button#active then rgba else grey)  

  let add_item (table : GPack.table) i chr =
    let packing = table#attach ~left:i ~top:0 in
    let toggle = GButton.toggle_button ~relief:`NONE ~packing () in
    let image = GMisc.image ~width:48 ~packing:toggle#set_image () in
    image#set_pixbuf (CIcon.get chr `GREY `LARGE);
    chr, {toggle; image}

  let make_toolbox typ =
    let code_list = CAnnot.char_list typ in
    let module T = struct
      let table = GPack.table
        ~rows:1 ~columns:(List.length code_list)
        ~col_spacings:(get_col_spacing typ)
        ~homogeneous:true ()
      let toggles = Array.of_list (List.mapi (add_item table) code_list)
    end in (module T : Toolbox.TOGGLE)

  (* Setting up expand/fill allows to centre the button box. *)
  let packing = Pane.left#attach ~top:0 ~left:0 ~expand:`X ~fill:`NONE

  let toolboxes =
    List.map (fun typ ->
      typ, make_toolbox typ
    ) CLevel.flags

  let iter f =
    List.iter (fun (typ, mdl) ->
      let module T = (val mdl : Toolbox.TOGGLE) in
      Array.iter (fun (chr, {toggle; image}) -> 
        f typ chr toggle image
      ) T.toggles
    ) toolboxes

  let map f =
    List.map (fun (typ, mdl) ->
      let module T = (val mdl : Toolbox.TOGGLE) in
      Array.map (fun (chr, {toggle; image}) ->
        f typ chr toggle image
      ) T.toggles
    ) toolboxes

  let current_widget = ref None

  let detach () =
    match !current_widget with
    | None -> ()
    | Some widget -> Pane.left#remove widget

  let attach typ =
    detach ();
    let mdl = List.assoc typ toolboxes in
    let module T = (val mdl : Toolbox.TOGGLE) in
    let widget = T.table#coerce in
    packing widget;
    GUI_levels.curr := typ;
    current_widget := Some widget

  let current_toggles () =
    let current_toolbox = List.assoc !GUI_levels.curr toolboxes in
    let module T = (val current_toolbox : Toolbox.TOGGLE) in
    T.toggles

  let apply any chr = String.index CAnnot.all_chars chr
    |> Array.get (current_toggles ())
    |> snd
    |> (fun {toggle; _} -> any toggle)
 
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
  
  let check chr () = () (*
    if not !lock then begin
      activate (CAnnot.requires chr); (* FIXME *)
      deactivate (CAnnot.forbids chr); (* FIXME *)
      if not (is_active chr) then deactivate (CAnnot.erases chr) (* FIXME *)
    end*)

  let toggle_any chr =
    set_status `INVERT chr;
    check chr ()

  let _ =
    (* Initializes the annotation toolbar using the lightweight annotation style
     * `COLONIZATION, and initiates the callback function that updates the UI
     * according to the active radio button. *)
    attach `COLONIZATION;
    List.iter (fun (typ, radio) ->
      radio#connect#toggled ~callback:(fun () ->
        if radio#active then attach typ
      ); ()
    ) GUI_levels.radios;
    (* Initializes the callback function that activate or deactivate toggle
     * buttons based on key pressed and CAnnot-defined constraints. *)
    iter (fun _ chr toggle _ ->
      ignore (toggle#connect#toggled ~callback:(check chr))
    )
end


module GMagnify = struct
  let rows = 3
  let columns = 3
  let edge = CCore.edge

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


module GUI_Drawing = struct
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


let container = GPack.table 
  ~rows:3 ~columns:1
  ~row_spacings:spacing
  ~packing:(Pane.right#attach ~left:1 ~top:0) ()

let make_toolbar_and_labels ~top ~title ~vsp1 ~vsp2 ~lbl1 ~lbl2 =
  let module M = struct
    let toolbar = GButton.toolbar
      ~orientation:`VERTICAL
      ~style:`ICONS
      ~width:78 ~height:80
      ~packing:(container#attach ~left:0 ~top) ()
    let packing = toolbar#insert
    let _ = ToolItem.separator packing; ToolItem.label packing title
    let label_1 = ToolItem.label ~vspace:vsp1 packing lbl1
    let label_2 = ToolItem.label ~vspace:vsp2 packing lbl2
  end in (module M : Toolbox.LABEL)

module GUI_Coords = struct
  let lbl = make_toolbar_and_labels
    ~top:0 ~title:"Coordinates" 
    ~vsp1:false ~vsp2:false
    ~lbl1:"<tt><b>R:</b> 000</tt>"
    ~lbl2:"<tt><b>C:</b> 000</tt>" 
  include (val lbl : Toolbox.LABEL)
  let row = label_1
  let column = label_2
end

module GStats = struct
  let lbl = make_toolbar_and_labels
    ~top:1 ~title:"Confidence"
    ~vsp1:true ~vsp2:false
    ~lbl1:"<tt><b> n/a </b></tt>"
    ~lbl2:"<tt><span background='white' foreground='white'>DDDDD</span></tt>"
  include (val lbl : Toolbox.LABEL)
  let confidence = label_1
  let confidence_color = label_2
end


module GLayers = struct
  let add_item packing a_ref g_ref i chr =
    let active = !a_ref and group = !g_ref in
    let radio = GButton.radio_tool_button ~active ?group ~packing () in
    if active then (a_ref := false; g_ref := Some radio);
    let hbox = GPack.hbox ~spacing:2 ~packing:radio#set_icon_widget () in
    let packing = hbox#add in
    let image = GMisc.image ~width:24 ~packing () in
    let label = GMisc.label
      ~markup:"<small><tt>0000</tt></small>" ~packing () in
    image#set_pixbuf (CIcon.get chr (if chr = '*' then `RGBA else `GREY) `SMALL);
    chr, {radio; label; image}

  let make_toolbox typ =
    let code_list = '*' :: CAnnot.char_list typ in
    let module T = struct
      let table = GButton.toolbar
        ~orientation:`VERTICAL
        ~style:`ICONS
        ~width:78 ~height:480 ()
      let active = ref true
      let group = ref None
      let packing = table#insert
      let radios = 
        ToolItem.separator packing;
        ToolItem.label packing "Layer";
        List.mapi (add_item packing active group) code_list
    end in (module T : Toolbox.RADIO)
    
  let toolboxes =
    List.map (fun typ ->
      typ, make_toolbox typ
    ) CLevel.flags

  let current_widget = ref None

  let detach () =
    match !current_widget with
    | None -> ()
    | Some widget -> container#remove widget

  let packing = container#attach ~left:0 ~top:2 ~expand:`NONE ~fill:`Y

  let attach typ =
    detach ();
    let mdl = List.assoc typ toolboxes in
    let module T = (val mdl : Toolbox.RADIO) in
    let widget = T.table#coerce in
    packing widget;
    current_widget := Some widget
 
  let current_radios () =
    let toolbox = List.assoc !GUI_levels.curr toolboxes in
    let open (val toolbox : Toolbox.RADIO) in radios

  let get_joker () = current_radios ()
    |> List.hd
    |> snd
  
  let get_layer c1 = current_radios ()
    |> List.find (fun (c2, _) -> c1 = c2)
    |> snd

  let get_active () = current_radios ()
    |> List.find (fun (_, t) -> t.radio#get_active)
    |> fst
  
  let is_active chr =
    let ext = if chr = '*' then get_joker () else get_layer chr in
    ext.radio#get_active

  let set_image chr =
    let ext = if chr = '*' then get_joker () else get_layer chr in
    ext.image#set_pixbuf

  (* Commented out due to an exception raised. *)
  let set_label chr num = () (*
    let ext = if chr = '*' then get_joker () else get_layer chr in
    ksprintf ext.label#set_label "<small><tt>%04d</tt></small>" num*)
  
  let set_toggled chr callback =
    let ext = if chr = '*' then get_joker () else get_layer chr in
    ext.radio#connect#toggled ~callback
    
  let iter_radios f = List.iter (fun (chr, _) -> f chr) (current_radios ()) 
end


let _ =
  (* Initializes the annotation toolbar using the lightweight annotation style
   * `COLONIZATION, and initiates the callback function that updates the UI
   * according to the active radio button. *)
  GLayers.attach `COLONIZATION;
  List.iter (fun (typ, radio) ->
    radio#connect#toggled ~callback:(fun () ->
      if radio#active then GLayers.attach typ
    ); ()
  ) GUI_levels.radios


let status = 
  let lbl = GMisc.label ~xalign:0.0 ~yalign:0.0
    ~packing:(Box.v#pack ~expand:false) () in
  lbl#set_use_markup true;
  lbl


module GTileSet = struct
  let cols = new GTree.column_list
  let coords = cols#add Gobject.Data.string
  let pixbuf = cols#add (Gobject.Data.gobject_by_name "GdkPixbuf")
  let mycflg = cols#add (Gobject.Data.gobject_by_name "GdkPixbuf")
  let store = GTree.list_store cols

  let add ~r ~c ~ico pix =
    let row = store#append ()
    and str = sprintf "<span foreground='white'><tt><b>R:</b>%03d\n\
      <b>C:</b>%03d</tt></span>" r c in
    store#set ~row ~column:coords str;
    store#set ~row ~column:pixbuf pix;
    store#set ~row ~column:mycflg ico

  let window =
    let wnd = GWindow.dialog
      ~parent:window
      ~destroy_with_parent:true
      ~width:320 ~height:500
      ~title:"Tile set"
      ~resizable:false
      ~position:`CENTER_ON_PARENT
      ~type_hint:`MENU
      ~modal:true
      ~show:false () in
    wnd#add_button_stock `SAVE `SAVE;
    wnd#add_button_stock `OK `OK;
    wnd#vbox#set_border_width spacing;
    wnd

  let run = window#run
  let set_title fmt = ksprintf window#set_title fmt

  let hide =
    let hide () = window#misc#hide (); store#clear () in
    window#event#connect#delete (fun _ -> hide (); true);
    hide

  module Cell = struct
    let xc = `XALIGN 0.5
    let yc = `YALIGN 0.5
    let sz = CCore.edge 
    let bg = `CELL_BACKGROUND_GDK (GDraw.color (`NAME "dimgray"))
    open GTree
    let mycflg = cell_renderer_pixbuf [bg; `XPAD 2; `WIDTH 34; xc; yc]
    let coords = cell_renderer_text [bg; `WIDTH 60; `XALIGN 0.; yc]
    let pixbuf = cell_renderer_pixbuf [bg; `WIDTH sz; `HEIGHT (sz + 2); xc; yc]
  end

  module VCol = struct
    let mycflg =
      let col = GTree.view_column
        ~renderer:(Cell.mycflg, ["pixbuf", mycflg]) () in
      col#set_fixed_width 34;
      col#set_sizing `FIXED;
      col
    let coords =
      let col = GTree.view_column
        ~renderer:(Cell.coords, ["markup", coords]) () in
      col#set_fixed_width 60;
      col#set_sizing `FIXED;
      col
    let pixbuf = 
      let col = GTree.view_column 
        ~renderer:(Cell.pixbuf, ["pixbuf", pixbuf]) () in
      col#set_fixed_width Cell.sz;
      col#set_sizing `FIXED;
      col
  end

  let view = 
    let scroll = GBin.scrolled_window
      ~hpolicy:`NEVER
      ~vpolicy:`ALWAYS
      ~shadow_type:`ETCHED_OUT
      ~border_width
      ~packing:window#vbox#add () in
    let icons = GTree.view
      ~model:store
      ~fixed_height_mode:true
      ~headers_visible:false
      ~enable_search:false
      ~border_width
      ~packing:scroll#add_with_viewport () in
    icons#append_column VCol.mycflg;
    icons#append_column VCol.pixbuf;
    icons#append_column VCol.coords;
    icons#selection#set_mode `NONE;
    icons#misc#set_can_focus false;
    icons
end


module GUI_FileChooserDialog = struct
  let jpeg = GFile.filter ~name:"JPEG image" ~mime_types:["image/jpeg"] ()
  let tiff = GFile.filter ~name:"TIFF image" ~mime_types:["image/tiff"] ()

  (* The first element of wnd#action_area is the `OPEN button (see below). *)
  let set_sensitive wnd = (List.hd wnd#action_area#children)#misc#set_sensitive 

  let dialog = 
    let wnd = GWindow.file_chooser_dialog
      ~parent:window
      ~destroy_with_parent:true
      ~action:`OPEN
      ~title:"CastANet Image Chooser"
      ~modal:true
      ~position:`CENTER
      ~resizable:false
      ~border_width
      ~show:false () in
    wnd#add_button_stock `QUIT `QUIT;
    (List.hd wnd#action_area#children)#misc#modify_text [`NORMAL, `NAME "red"];
    wnd#add_select_button_stock `OPEN `OPEN;
    set_sensitive wnd false;
    wnd#connect#selection_changed (fun () ->
      Gaux.may (fun p ->
        set_sensitive wnd Sys.(file_exists p && not (is_directory p))
      ) wnd#filename
    );
    (* Other commands do not seem to affect window size. *)
    wnd#vbox#misc#set_size_request ~width:640 ~height:480 ();
    List.iter wnd#add_filter [jpeg; tiff];
    wnd#set_filter jpeg;
    wnd

  let run () =
    if dialog#run () = `OPEN then (
      dialog#misc#hide ();
      (* Should not raise an error.
       * The open button is not active when no file is selected. *)
      Option.get dialog#filename
    ) else exit 0
end
