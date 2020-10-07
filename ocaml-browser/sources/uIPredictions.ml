(* CastANet - uI_Predictions.ml *)

open Scanf
open Printf
open Morelib

module type PARAMS = sig
    val parent : GWindow.window
    val packing : GObj.widget -> unit
    val border_width : int
    val tooltips : GData.tooltips
end

module type S = sig
    val toolbar : GButton.toolbar
    val palette : GButton.tool_button
    val set_icon : string array -> unit
    val get_colors : unit -> string array
    val set_choices : string list -> unit
    val get_active : unit -> string option
    val overlay : GButton.button
    val cams : GButton.toggle_tool_button
end

type palette = string array

let folder = "data/palettes"
let palette_db = ref []

let validate_color ?(default = "#ffffffff") s =
  ksscanf s (fun _ _ -> default) "#%02x%02x%02x" 
    (sprintf "#%02x%02x%02xcc")

let load () =
  Array.fold_left (fun pal elt ->
    let path = Filename.concat folder elt in
    if Filename.check_suffix path ".palette" then (
      let base = Filename.remove_extension elt in
        let colors = File.read path
          |> String.split_on_char '\n'
          |> List.map validate_color
          |> Array.of_list
        in (base, colors) :: pal
    ) else pal
  ) [] (Sys.readdir folder)

let parse_html_color =
    let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
    fun s -> sscanf s "#%02x%02x%02x%02x" (fun r g b a -> f r, f g, f b, f a)

let draw_icon ?(digest = false) colors =
  let mul = if digest then 2 else 6 and h = 16 in
  let len = Array.length colors * mul in
  let surface = Cairo.Image.(create ARGB32 ~w:len ~h) in 
  let t = Cairo.create surface in
  Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
  Array.iteri (fun i clr ->
    let r, g, b, _ = parse_html_color clr in
    Cairo.set_source_rgba t r g b 1.0;
    Cairo.rectangle t (float (mul * i)) 0.0 ~w:(float mul) ~h:(float h);
    Cairo.fill t;
    Cairo.stroke t;
  ) colors;
  (* Draws the generated surface on a GtkPixmap. *)
  let pixmap = GDraw.pixmap ~width:len ~height:h () in
  let u = Cairo_gtk.create pixmap#pixmap in
  Cairo.set_source_surface u surface 0.0 0.0;
  Cairo.paint u;
  (* Retrieves the drawings as pixbuf. *)
  let pix = GdkPixbuf.create ~width:len ~height:h () in
  pixmap#get_pixbuf pix;
  pix


module TreeView = struct

    module Data = struct
        let cols = new GTree.column_list
        let name = cols#add Gobject.Data.string
        let colors = cols#add Gobject.Data.caml
        let pixbuf = cols#add Gobject.Data.gobject
        let store = GTree.list_store cols
    end

    module Cell = struct
        let name = GTree.cell_renderer_text [`WEIGHT `BOLD]
        let pixbuf = GTree.cell_renderer_pixbuf [`XALIGN 0.0; `YALIGN 0.5]
    end

    module VCol = struct
        let markup = GTree.view_column ~title:"Name"
            ~renderer:(Cell.name, ["text", Data.name]) ()
        let pixbuf = GTree.view_column ~title:"Palette"
            ~renderer:(Cell.pixbuf, ["pixbuf", Data.pixbuf]) ()
    end

end



module Aux = struct

    let markup_tool_button ~stock ~label ~packing () =
        let btn = GButton.tool_button ~packing () in
        btn#misc#set_sensitive false;
        let box = GPack.hbox ~spacing:2 ~packing:btn#set_label_widget () in
        ignore (GMisc.image ~width:25 ~stock ~packing:(box#pack ~expand:false) ());
        let markup = Printf.sprintf "<small>%s</small>" label in
        ignore (GMisc.label ~markup ~xalign:0.0 ~packing:box#add ());
        btn

end



module Make (P : PARAMS) : S = struct

    let toolbar = GButton.toolbar
        ~orientation:`VERTICAL
        ~style:`ICONS
        ~width:98 ~height:180
        ~packing:P.packing ()

    let packing = toolbar#insert



    module Activate = struct
        let dialog = 
            let dlg = GWindow.dialog
                ~parent:P.parent
                ~width:300
                ~height:100
                ~deletable:false
                ~resizable:false
                ~title:"Predictions"
                ~type_hint:`UTILITY
                ~destroy_with_parent:true
                ~position:`CENTER_ON_PARENT () in
            dlg#add_button_stock `CANCEL `CANCEL;
            dlg#add_button_stock `OK `OK;
            dlg#set_border_width P.border_width;
            dlg

        let combo, (store, data) = GEdit.combo_box_text 
            ~packing:dialog#vbox#add ()
    end

    let _ = UIHelper.separator packing

    let activate = 
        let item = GButton.tool_item ~packing () in
        let check = GButton.check_button ~packing:item#add () in
        check#misc#set_sensitive false;
        check#misc#set_can_focus false;
        ignore (GMisc.label
            ~markup:"<b><small>Prediction</small></b>"
            ~xalign:0.0 ~yalign:0.5
            ~packing:check#set_image ());
        check

    let container =
        let item = GButton.tool_item ~packing () in
        GPack.hbox ~spacing:2 ~packing:item#add ()

    let overlay =
        let btn = GButton.button ~packing:container#add () in
        btn#set_relief `NONE;
        btn#misc#set_sensitive false;
        GMisc.image ~stock:`OPEN ~packing:btn#set_image ();
        let callback () = btn#misc#set_sensitive activate#active in
        ignore (activate#connect#toggled ~callback);
        btn

    let remove =
        let btn = GButton.button ~packing:container#add () in
        btn#set_relief `NONE;        
        btn#misc#set_sensitive false;        
        GMisc.image ~stock:`CLOSE ~packing:btn#set_image ();        
        btn

    let palette, pal_icon =
        let btn = GButton.tool_button ~packing () in
        btn#misc#set_sensitive false;
        let box = GPack.hbox ~spacing:2 ~packing:btn#set_label_widget () in
        let packing = box#pack ~expand:false in
        let pal_icon = GMisc.image ~width:25 ~height:16 ~packing () in
        ignore (GMisc.label
            ~markup:"<small>Palette</small>"
            ~xalign:0.0 ~yalign:0.5
            ~packing:box#add ());
        btn, pal_icon

    let cams = 
        let btn = GButton.toggle_tool_button ~packing () in
        btn#misc#set_sensitive false;
        let markup = "<small>CAMs</small>" in
        ignore (GMisc.label ~markup ~packing:btn#set_label_widget ());
        btn

    let apply = Aux.markup_tool_button
        ~stock:`APPLY
        ~label:"Apply" ~packing ()

    let set_choices t =
        Activate.store#clear ();
        activate#misc#set_sensitive (t <> []);
        List.iter (fun x ->
            let row = Activate.store#append () in
            Activate.store#set ~row ~column:Activate.data x;     
        ) t;
        Activate.combo#set_active 0

    let get_active () =
        let result = Activate.dialog#run () in
        Activate.dialog#misc#hide ();
        if result = `OK then (
            Option.map (fun row ->
                let res = Activate.store#get ~row ~column:Activate.data in
                cams#misc#set_sensitive true;
                remove#misc#set_sensitive true;
                palette#misc#set_sensitive true;
                res
            ) Activate.combo#active_iter
        ) else None

  let set_tooltip s =
    let text = sprintf "%s %s" (CI18n.get `CURRENT_PALETTE) s in
    P.tooltips#set_tip ~text palette#coerce
  let set_icon t = pal_icon#set_pixbuf (draw_icon ~digest:true t)

  let dialog = 
    let dlg = GWindow.dialog
      ~parent:P.parent
      ~width:250
      ~height:200
      ~deletable:false
      ~resizable:false
      ~title:"Color Palettes"
      ~type_hint:`UTILITY
      ~destroy_with_parent:true
      ~position:`CENTER_ON_PARENT () in
    dlg#add_button_stock `OK `OK;
    dlg#vbox#set_border_width P.border_width;
    dlg

  let scroll = GBin.scrolled_window
    ~hpolicy:`NEVER
    ~vpolicy:`ALWAYS
    ~border_width:P.border_width
    ~packing:dialog#vbox#add ()

  let view =
    let tv = GTree.view
      ~model:TreeView.Data.store
      ~headers_visible:false
      ~packing:scroll#add () in
    tv#selection#set_mode `SINGLE;
    ignore (tv#append_column TreeView.VCol.markup);
    ignore (tv#append_column TreeView.VCol.pixbuf);
    tv

  let initialize =
    let aux () =
      let sel = ref None in
      List.iteri (fun i (id, colors) ->
        let id = String.capitalize_ascii id in
        let row = TreeView.Data.store#append () in
        if i = 0 then sel := Some (id, colors, row);
        let set ~column x = TreeView.Data.store#set ~row ~column x in
        set ~column:TreeView.Data.name id;
        set ~column:TreeView.Data.colors colors;
        set ~column:TreeView.Data.pixbuf (draw_icon colors)
      ) (load ());
      Option.iter (fun (id, colors, row) ->
        set_icon colors;
        set_tooltip id;
        view#selection#select_iter row
      ) !sel
    in Memoize.create ~label:"UI_Palette.Make" aux

  let get_selected_iter () =
    view#selection#get_selected_rows
    |> List.hd
    |> TreeView.Data.store#get_iter
    
  let get_colors () =
    let row = get_selected_iter () in
    TreeView.Data.store#get ~row ~column:TreeView.Data.colors

  let get_name () =
    let row = get_selected_iter () in
    TreeView.Data.store#get ~row ~column:TreeView.Data.name

  let _ =
    initialize ();
    let callback () =
      if dialog#run () = `OK then (
        set_icon (get_colors ());
        set_tooltip (get_name ());
        dialog#misc#hide ()
      )
    in palette#connect#clicked ~callback
end
