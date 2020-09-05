(* CastANet - cImage.mli *)

open CExt
open CGUI
open Printf

module ImageOps = struct
  let crop ~src_x ~src_y ~edge:e pix =
    let dest = GdkPixbuf.create ~width:e ~height:e () in
    GdkPixbuf.copy_area ~dest ~src_x ~src_y pix;
    dest
      
  let resize ?(interp = `NEAREST) ~edge:e pix =
    let open GdkPixbuf in
    let scale_x = float e /. (float (get_width pix))
    and scale_y = float e /. (float (get_height pix)) in
    let dest = create ~width:e ~height:e () in
    scale ~dest ~scale_x ~scale_y ~interp pix;
    dest
end

type tiles = GdkPixbuf.pixbuf EMatrix.t

type mosaic = {
  edge : int;
  matrix : tiles;
}
 
type sizes = {
  small : mosaic;
  large : mosaic;
}

type param = {
  path : string; 
  rows : int; 
  cols : int;
}

type graph = {
  xini : int;
  yini : int;
  imgw : int;
  imgh : int;
  mutable cursor : int * int;
}

type t = {
  param : param;
  sizes : sizes;
  table : CTable.table;
  graph : graph;
}

(* garbage? 
let cursor_pos t = t.graph.cursor
let set_cursor_pos t pos = t.graph.cursor <- pos
let tile ~r ~c t typ = EMatrix.get_opt (tiles t typ) r c
let annotation ~r ~c t = EMatrix.get_opt (annotations t) r c
let is_valid ~r ~c t = EMatrix.get_opt (Mosaic.annotations t) r c <> None
 /end of garbage *)

(* Image currently being processed. *)
let active_image = ref None

module Par = struct
  open Arg
  let edge = ref 236
  let image_path = ref None
  let set_image_path x = if Sys.file_exists x then image_path := Some x
  let usage = "castanet_editor.exe [OPTIONS] [IMAGE_PATH]"
  let specs = align [
    "--edge", Set_int edge, sprintf " Tile size (default: %d pixels)." !edge;
  ]
  let initialize () = parse specs set_image_path usage
end

module Info = struct
  let path t = t.param.path
  let basename t = Filename.basename (path t)
  let dirname t = Filename.dirname (path t)
end

module Mosaic = struct
  let source t = function
    | `W -> t.graph.imgw 
    | `H -> t.graph.imgh

  let origin t = function
    | `X -> t.graph.xini
    | `Y -> t.graph.yini

  let dim t = function
    | `R -> t.param.rows
    | `C -> t.param.cols

  let edge t = function
    | `SMALL -> t.sizes.small.edge 
    | `LARGE -> t.sizes.large.edge

  let tiles t = function
    | `SMALL -> t.sizes.small.matrix
    | `LARGE -> t.sizes.large.matrix

  let annotations {table; _} = table
  let x ~c t typ = (origin t `X) + c * (edge t typ)
  let y ~r t typ = (origin t `Y) + r * (edge t typ)
end


module Iter = struct
  let tiles f t typ = EMatrix.iteri f (Mosaic.tiles t typ)
end






module Create = struct
  let large_tile_matrix nr nc edge src =
    EMatrix.init nr nc (fun r c ->
      let src_x = c * edge and src_y = r * edge in
      ImageOps.crop ~src_x ~src_y ~edge src |> ImageOps.resize ~edge:180
    )
    
  let small_tile_matrix edge = EMatrix.map (ImageOps.resize ~edge)
    
  let annotations path tiles =
    let zip = Filename.remove_extension path ^ ".zip" in
    if Sys.file_exists zip then CTable.load zip |> Option.get (* FIXME *)
    else CTable.create (`MAT tiles) 
end

let create ~ui_width:uiw ~ui_height:uih path =
  let pix = GdkPixbuf.from_file path in
  let imgw, imgh = GdkPixbuf.(get_width pix, get_height pix) in
  let edge = !Par.edge in
  let rows = imgh / edge and cols = imgw / edge in
  let large = Create.large_tile_matrix rows cols edge pix in
  let sub = min (uiw / cols) (uih / rows) in
  let small = Create.small_tile_matrix sub large in
  let table = Create.annotations path small in
  let graph = {
    imgw; imgh; cursor = (0, 0);
    xini = (uiw - sub * cols) / 2;
    yini = (uih - sub * rows) / 2;
  } and sizes = {
    small = {edge = sub; matrix = small};
    large = {edge = 180; matrix = large};
  } and param = {path; rows; cols} in
  let img = { param; sizes; graph; table } in
  CPalette.set_tile_edge sub;
  CLog.info "source image: '%s'" path;
  CLog.info "source image size: %d x %d pixels" imgw imgh;
  CLog.info "tile matrix: %d x %d; edge: %d pixels" rows cols edge;
  img

let statistics img = CTable.statistics (Mosaic.annotations img)
   
let digest t =
  sprintf "<small><tt> \
    <b>Image:</b> %s ▪ \
    <b>Size:</b> %d × %d pixels ▪ \
    <b>Tiles:</b> %d × %d</tt></small>" 
    (Info.basename t)
    (Mosaic.source t `W) (Mosaic.source t `H)
    (Mosaic.dim t `R) (Mosaic.dim t `C)


module Paint = struct
  let white_background ?(sync = true) () =
    let t = GUI_Drawing.cairo () in
    Cairo.set_source_rgba t 1.0 1.0 1.0 1.0;
    let w = float (GUI_Drawing.width ()) 
    and h = float (GUI_Drawing.height ()) in
    Cairo.rectangle t 0.0 0.0 ~w ~h;
    Cairo.fill t;
    Cairo.stroke t;
    if sync then GUI_Drawing.synchronize ()

  let tiles ?(sync = true) t =
    let pixmap = GUI_Drawing.pixmap ()
    and xini = Mosaic.origin t `X
    and yini = Mosaic.origin t `Y
    and edge = Mosaic.edge t `SMALL in
    Iter.tiles (fun ~r ~c tile ->
      pixmap#put_pixbuf
        ~x:(xini + c * edge)
        ~y:(yini + r * edge)
        ~width:edge ~height:edge tile
    ) t `SMALL;
    if sync then GUI_Drawing.synchronize ()
end


let load () =
  Par.initialize ();
  let path = match !Par.image_path with
    | None -> GUI_FileChooserDialog.run ()
    | Some path -> path in
  CGUI.window#show ();
  let ui_width = GUI_Drawing.width ()
  and ui_height = GUI_Drawing.height () in
  let t = create ~ui_width ~ui_height path in
  active_image := Some t;
  Paint.white_background ~sync:false ();
  Paint.tiles t;
  CGUI.status#set_label (digest t)
