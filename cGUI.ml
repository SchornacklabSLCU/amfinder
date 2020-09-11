(* CastANet - cGUI.ml *)

open Printf

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

module Levels_par = struct
  let init_level = CLevel.lowest
  let packing = Box.b#add
end
module Levels = UI_Levels.Make(Levels_par)

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

module CursorPos_params = struct
  let packing ~top x = container#attach ~left:0 ~top x
end
module CursorPos = UI_CursorPos.Make(CursorPos_params)



module Palette_params = struct
  let packing x = container#attach ~left:0 ~top:1 x
end
module Palette = UI_Palette.Make(Palette_params)



module Layers_params = struct
  let packing x = container#attach ~left:0 ~top:2 ~expand:`NONE ~fill:`Y x
  let remove = container#remove
  include Levels
end
module Layers = UI_Layers.Make(Layers_params)

let status = 
  let lbl = GMisc.label ~xalign:0.0 ~yalign:0.0
    ~packing:(Box.v#pack ~expand:false) () in
  lbl#set_use_markup true;
  lbl

(* Tile set. *)
module TileSet_params = struct
  let parent = window
  let spacing = spacing
  let border_width = border_width
  let window_width = 320
  let window_height = 500
  let window_title = "Tile Set"
end 
module TileSet = UI_TileSet.Make(TileSet_params)

(* File chooser. *)
module FileChooser_params = struct
  let parent = window
  let title = "CastANet Image Chooser"
  let border_width = border_width
end
module FileChooser = UI_FileChooser.Make(FileChooser_params)
