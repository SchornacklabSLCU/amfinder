(* uI_Palette.ml *)

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
  val show_predictions : GButton.toggle_tool_button
  val show_activations : GButton.toggle_tool_button
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
  let mul = if digest then 2 else 6 and h = 24 in
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


module Make (P : PARAMS) : S = struct

  let toolbar = GButton.toolbar
    ~orientation:`VERTICAL
    ~style:`ICONS
    ~width:92 ~height:200
    ~packing:P.packing ()

  let packing = toolbar#insert

  let _ = UIHelper.separator packing
  let _ = UIHelper.label packing "<small>Predictions</small>"

  let palette_icon, palette =
    let button = GButton.tool_button ~packing () in
    let image = GMisc.image ~width:55 ~height:24
      ~packing:button#set_icon_widget () in
    image, button

  let _ = UIHelper.morespace packing

  let show_predictions = GButton.toggle_tool_button ~label:"Show" ~packing ()
  let show_activations = 
    let btn = GButton.toggle_tool_button ~label:"Maps" ~packing () in
    show_predictions#connect#toggled (fun () ->
        btn#misc#set_sensitive show_predictions#get_active);
    btn#misc#set_sensitive false;
    btn

  let set_tooltip s =
    let text = sprintf "%s %s" (CI18n.get `CURRENT_PALETTE) s in
    P.tooltips#set_tip ~text palette#coerce
  let set_icon t = palette_icon#set_pixbuf (draw_icon ~digest:true t)

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
