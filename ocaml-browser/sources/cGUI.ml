(* CastANet - cGUI.ml *)

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

let tooltips = GData.tooltips ()

module Box = struct
  (* To allow for a status label to be added
   * at the bottom of the interface. *)
  let v = GPack.vbox
    ~border_width
    ~packing:window#add ()

  (* To display the annotation modes (as radio buttons).
   * We use double spacing to make it more visible. *)
  let b = GPack.button_box `HORIZONTAL
    ~border_width:(2 * spacing)
    ~layout:`SPREAD
    ~packing:(v#pack ~expand:false) ()

  (* Container to display magnified view and whole image 
   * side by side on the interface. *)
  let h = GPack.hbox
    ~spacing
    ~border_width
    ~packing:v#add ()
end

module Levels = UI_Levels.Make (
  struct
    let init_level = CLevel.lowest (* TODO: replace with highest *)
    let packing = Box.b#add
  end )

let framed_pane ~label ~r ~c =
  let frame = GBin.frame ~label ~packing:Box.h#add () in
  GPack.table
    ~rows:r ~columns:c 
    ~row_spacings:spacing
    ~col_spacings:spacing 
    ~border_width
    ~packing:frame#add ()

let left_pane = framed_pane ~label:"Magnified view" ~r:2 ~c:1
let right_pane = framed_pane ~label:"Whole image" ~r:1 ~c:2

module Toggles = UI_ToggleBar.Make (
  struct
    include Levels
    let packing x = left_pane#attach ~top:0 ~left:0 ~expand:`X ~fill:`NONE x
    let remove = left_pane#remove  
  end )

module Magnifier = UI_Magnifier.Make (
  struct
    let rows = 3
    let columns = 3
    let tile_edge = 180
    let packing obj = left_pane#attach ~top:1 ~left:0 obj
  end )

module Drawing = UI_Drawing.Make (
  struct
    let packing obj = right_pane#attach ~left:0 ~top:0 obj
  end )

let container = GPack.table 
  ~rows:3 ~columns:1
  ~row_spacings:spacing
  ~packing:(right_pane#attach ~left:1 ~top:0) ()

module CursorPos = UI_CursorPos.Make (
  struct
    let packing ~top obj = container#attach ~left:0 ~top obj
  end )

module Palette = UI_Palette.Make (
  struct
    let parent = window
    let border_width = border_width
    let packing obj = container#attach ~left:0 ~top:2 obj
    let tooltips = tooltips
  end )

module Layers = UI_Layers.Make (
  struct
    include Levels
    let packing obj = container#attach
      ~left:0 ~top:1 
      ~expand:`NONE ~fill:`Y obj
    let remove = container#remove
  end )

let status = 
  let lbl = GMisc.label ~xalign:0.0 ~yalign:0.0
    ~packing:(Box.v#pack ~expand:false) () in
  lbl#set_use_markup true;
  lbl

module TileSet = UI_TileSet.Make (
  struct
    let parent = window
    let spacing = spacing
    let border_width = border_width
    let window_width = 320
    let window_height = 500
    let window_title = "Tile Set"
  end )

module FileChooser = UI_FileChooser.Make (
  struct
    let parent = window
    let title = "CastANet Image Chooser"
    let border_width = border_width
  end )
