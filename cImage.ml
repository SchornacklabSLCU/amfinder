(* CastANet - cImage.ml *)

open CExt
open CGUI

(* Images are represented as mosaics of square tiles. *)
type tiles = {
  edge : int;
  matrix : GdkPixbuf.pixbuf Ext_Matrix.t;
}

(* Large tiles are used in the "zoomed in" area on the left side of the 
 * interface, while small tiles are drawn on the right side. *)
type sizes = {
  small : tiles;
  large : tiles;
}

(* Graphical properties (number of rows and columns, width/height, etc.). *)
type graph = {
  rows : int; cols : int;
  xini : int; yini : int;
  imgw : int; imgh : int;
  mutable cursor : int * int;
}

(* CastANet images consist of two mosaics of square tiles (to populate the two
 * sides of the interface), a set of multi-level annotations (defined by the
 * user or constrained by annotation rules), and graphical properties (to
 * ensure proper display on the main window). *)
type image = {
  fpath : string;
  sizes : sizes;
  table : CTable.table;
  graph : graph;
}

let active_image = ref None

let get_active () = !active_image

let rem_active () = active_image := None

let path t = t.fpath

let basename t = Filename.basename (path t)

let dirname t = Filename.dirname (path t)

let source t = function `W -> t.graph.imgw | `H -> t.graph.imgh

let origin t = function `X -> t.graph.xini | `Y -> t.graph.yini

let dim t = function `R -> t.graph.rows | `C -> t.graph.cols

let annotations {table; _} = table

let edge t = function
  | `SMALL -> t.sizes.small.edge 
  | `LARGE -> t.sizes.large.edge
  
let tiles t = function
  | `SMALL -> t.sizes.small.matrix
  | `LARGE -> t.sizes.large.matrix
  
let tile ~r ~c t typ = Ext_Matrix.get_opt (tiles t typ) r c

let x ~c t typ = (origin t `X) + c * (edge t typ)

let y ~r t typ = (origin t `Y) + r * (edge t typ)

let cursor_pos t = t.graph.cursor

let set_cursor_pos t pos = t.graph.cursor <- pos

let iter_tiles f t typ = Ext_Matrix.iteri f (tiles t typ)

let statistics t = CTable.statistics (annotations t)

module Create = struct
  let large_tile_matrix nr nc edge src =
    Ext_Matrix.init nr nc (fun r c ->
      let src_x = c * edge and src_y = r * edge in
      CPixbuf.crop ~src_x ~src_y ~edge src |> CPixbuf.resize ~edge:180
    )
    
  let small_tile_matrix edge = Ext_Matrix.map (CPixbuf.resize ~edge)
    
  let annotations path tiles =
    let zip = Filename.remove_extension path ^ ".zip" in
    (* FIXME Remove this once everything has been converted! *)
    let tsv = Filename.remove_extension path ^ ".tsv" in
    if Sys.file_exists zip then CTable.load zip |> Option.get 
    else if Sys.file_exists tsv then CTable.load_tsv tsv |> Option.get
    else CTable.create (`MAT tiles) 
end

let create ?(edge = 236) fpath =
  let uiw, uih = GUI_Drawing.(width (), height ()) in
  let pix = GdkPixbuf.from_file fpath in
  let imgw, imgh = GdkPixbuf.(get_width pix, get_height pix) in
  let rows = imgh / edge and cols = imgw / edge in
  let large = Create.large_tile_matrix rows cols edge pix in
  let sub = min (uiw / cols) (uih / rows) in
  let small = Create.small_tile_matrix sub large in
  let table = Create.annotations fpath small in
  let graph = { rows; cols;
    imgw; imgh; cursor = (0, 0);
    xini = (uiw - sub * cols) / 2;
    yini = (uih - sub * rows) / 2;
  } and sizes = {
    small = {edge = sub; matrix = small};
    large = {edge = 180; matrix = large};
  } in
  let img = { fpath; sizes; graph; table } in
  CPalette.set_tile_edge sub;
  CLog.info "source image: '%s'" fpath;
  CLog.info "source image size: %d x %d pixels" imgw imgh;
  CLog.info "tile matrix: %d x %d; edge: %d pixels" rows cols edge;
  active_image := Some img;
  img
