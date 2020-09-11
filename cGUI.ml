(* CastANet - cGUI.ml *)

open Printf

module Toolbox = struct
  module type LABEL = sig
    val toolbar : GButton.toolbar
    val label_1 : GMisc.label
    val label_2 : GMisc.label
  end
end

let window =
  ignore (GMain.init ());
  let wnd = GWindow.window
    ~title:"CastANet Editor 2.0"
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

module Levels = (val (CGUI_Levels.make ~packing:Box.b#add ()) : CGUI_Levels.S)

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

(* Toggle bar. *)
module ToggleBar_params = struct
  let packing x = Pane.left#attach ~top:0 ~left:0 ~expand:`X ~fill:`NONE x
  let remove = Pane.left#remove
  include Levels
end
module Toggles = UI_ToggleBar.Make(ToggleBar_params)


(* Magnifying glass *)
module Magnifier_params = struct
  let rows = 3
  let columns = 3
  let tile_edge = 180
  let packing x = Pane.left#attach ~top:1 ~left:0 x
end
module Magnifier = UI_Magnifier.Make(Magnifier_params)


(* Drawing. *)
module Drawing_params = struct
  let packing x = Pane.right#attach ~left:0 ~top:0 x
end
module Drawing = UI_Drawing.Make(Drawing_params)


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
    let _ = UI_Helper.separator packing; UI_Helper.label packing title
    let label_1 = UI_Helper.label ~vspace:vsp1 packing lbl1
    let label_2 = UI_Helper.label ~vspace:vsp2 packing lbl2
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

module GUI_Probs = struct
  let current_palette = ref `VIRIDIS
  let current () = !current_palette
  let toolbar = GButton.toolbar
    ~orientation:`VERTICAL
    ~style:`ICONS
    ~width:78 ~height:205
    ~packing:(container#attach ~left:0 ~top:1) ()
  let packing = toolbar#insert
  let _ = UI_Helper.separator packing; UI_Helper.label packing "Predictions"
  let radio_tool_button ?(active = false) ?group ~label typ =
    let radio = GButton.radio_tool_button ~active ?group ~packing () in
    let hbox = GPack.hbox ~packing:radio#set_icon_widget () in
    let image = GMisc.image ~width:20 ~packing:(hbox#pack ~expand:false) () in
    ignore (GMisc.label ~markup:(sprintf "<span size='x-small'>%s</span>" label)
      ~packing:(hbox#pack ~fill:true) ());
    image#set_pixbuf (CIcon.get_palette typ `SMALL);
    radio, image
  let viridis = radio_tool_button ~active:true ~label:"Viridis" `VIRIDIS
  let group = fst viridis
  let cividis = radio_tool_button ~group  ~label:"Cividis" `CIVIDIS
  let plasma = radio_tool_button ~group  ~label:"Plasma" `PLASMA
  let labelled_button label =
    let btn = GButton.tool_button ~packing () in
    ignore (GMisc.label ~markup:(sprintf "<small>%s</small>" label)
      ~packing:btn#set_icon_widget ());
    btn
  let best = labelled_button "Best"
  let threshold = labelled_button "Threshold"
end


module Layers_params = struct
  let packing x = container#attach ~left:0 ~top:2 ~expand:`NONE ~fill:`Y x
  let remove = container#remove
  include Levels
end
module GUI_Layers = UI_Layers.Make(Layers_params)


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
    let sz = 180
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
