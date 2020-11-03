(* CastANet - cGUI.ml *)

let _ = GMain.init ()

let window =
    let wnd = GWindow.window
        ~title:"CastANet Editor 2.0"
        ~resizable:false
        ~position:`CENTER ()
    in wnd#connect#destroy GMain.quit;
    wnd

let spacing = 5
let border_width = spacing

let tooltips = GData.tooltips ()


module Box = struct
    (* Adds a status label at the bottom of the interface. *)
    let v = GPack.vbox
        ~border_width
        ~packing:window#add ()

    (* To display the annotation modes. *)
    let b = GPack.button_box `HORIZONTAL
        ~border_width:(2 * spacing)
        ~layout:`SPREAD
        ~packing:(v#pack ~expand:false) ()

    (* Displays magnified view and whole image side by side. *)
    let h = GPack.hbox
        ~spacing
        ~border_width
        ~packing:v#add ()
end


module Levels = UILevels.Make (
    struct
        let init_level = AmfLevel.lowest (* TODO: replace with highest *)
        let packing = Box.b#add
    end )


let make_pane ~r ~c = GPack.table
    ~rows:r
    ~columns:c 
    ~row_spacings:spacing
    ~col_spacings:spacing 
    ~border_width
    ~packing:Box.h#add ()

let left_pane = make_pane ~r:2 ~c:1
let right_pane = make_pane ~r:1 ~c:2


let container = GPack.table 
    ~rows:3 ~columns:1
    ~row_spacings:spacing
    ~packing:(right_pane#attach ~left:1 ~top:0) ()

let toolbar = GButton.toolbar
    ~orientation:`VERTICAL
    ~style:`ICONS
    ~width:98 ~height:265
    ~packing:(container#attach ~left:0 ~top:0) ()

let status = 
    let lbl = GMisc.label
        ~xalign:0.0
        ~yalign:0.0
        ~packing:(Box.v#pack ~expand:false) () in
    lbl#set_use_markup true;
    lbl


module Params = struct
    module Toggles = struct
        include Levels
        let packing x = left_pane#attach ~top:0 ~left:0 ~expand:`X ~fill:`NONE x
        let remove = left_pane#remove  
    end
    module Magnifier = struct
        let rows = 3
        let columns = 3
        let tile_edge = 180
        let window = window
        let packing obj = left_pane#attach ~top:1 ~left:0 obj
    end
    module Drawing = struct
        let packing obj = right_pane#attach ~left:0 ~top:0 obj
    end
    module CursorPos = struct
        let packing obj = toolbar#insert obj
    end
    module Predictions = struct
        let parent = window
        let border_width = border_width
        let packing obj = toolbar#insert obj
        let tooltips = tooltips
    end
    module Layers = struct
        include Levels
        let packing obj = container#attach
            ~left:0 ~top:2 
            ~expand:`NONE ~fill:`Y obj
        let remove = container#remove
    end
    module TileSet = struct
        let parent = window
        let spacing = spacing
        let border_width = border_width
        let window_width = 320
        let window_height = 500
        let window_title = "Tile Set"
    end
    module FileChooser = struct
        let parent = window
        let title = "CastANet Image Chooser"
        let border_width = border_width
    end
end

module Toggles = UIToggleBar.Make(Params.Toggles)
module Magnifier = UIMagnifier.Make(Params.Magnifier)
module Drawing = UIDrawing.Make(Params.Drawing)
module Predictions = UIPredictions.Make(Params.Predictions)
module Layers = UILayers.Make(Params.Layers)
module TileSet = UITileSet.Make(Params.TileSet)
module FileChooser = UIFileChooser.Make(Params.FileChooser)
