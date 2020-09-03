(* CastANet - cImage.mli *)

type tiles = GdkPixbuf.pixbuf CExt.Matrix.t

type mosaic = { edge : int; matrix : tiles } 
type sizes = { small : mosaic; large : mosaic }
type param = { path : string; rows : int; cols : int }

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

(* Getters *)
let path t = t.param.path
let basename t = Filename.basename (path t)
let dirname t = Filename.dirname (path t)

let source t = function
  | `W -> t.graph.imgw 
  | `H -> t.graph.imgh

let origin t = function
  | `X -> t.graph.xini
  | `Y -> t.graph.yini

let dim t = function
  | `R -> t.param.rows
  | `C -> t.param.cols

let annotations {table; _} = table

let edge t = function
  | `SMALL -> t.sizes.small.edge 
  | `LARGE -> t.sizes.large.edge

let tiles t = function
  | `SMALL -> t.sizes.small.matrix
  | `LARGE -> t.sizes.large.matrix

let cursor_pos t = t.graph.cursor
let set_cursor_pos t pos = t.graph.cursor <- pos

let tile ~r ~c t typ = CExt.Matrix.get_opt (tiles t typ) r c
let annotation ~r ~c t = CExt.Matrix.get_opt (annotations t) r c

let iter_tiles f t typ = CExt.Matrix.iteri f (tiles t typ)

let x ~c t typ = (origin t `X) + c * (edge t typ)
let y ~r t typ = (origin t `Y) + r * (edge t typ)

let is_valid ~r ~c t = CExt.Matrix.get_opt (annotations t) r c <> None


module Binary = struct
  let binfile path = Filename.remove_extension path ^ ".bin"
  (* Save image as binary at exit. *)
  let save_at_exit img =
    let bin = binfile (path img) in
    (* Faster than erasing file contents. *)
    if Sys.file_exists bin then Sys.remove bin;
    let och = open_out_bin bin in
    output_value och img;
    close_out och
  (* Restore image at startup from binary data. *)
  let restore path =
    let bin = binfile path in
    if Sys.file_exists bin then (
      CLog.info "Loading binary file '%s'" (Filename.basename bin);
      let ich = open_in_bin bin in
      let img = input_value ich in
      close_in ich;
      Some img
    ) else None
end


module Create = struct
  open CExt
  let large_tile_matrix nr nc edge src =
    Matrix.init nr nc (fun r c ->
      let src_x = c * edge and src_y = r * edge in
      Image.(crop_square ~src_x ~src_y ~edge src |> resize ~edge:180)
    )
    
  let small_tile_matrix edge = Matrix.map (Image.resize ~edge)
    
  let annotations path tiles =
    let zip = Filename.remove_extension path ^ ".zip" in
    if Sys.file_exists zip then CTable.load zip
    else CTable.create (`MAT tiles)
end

let create ~ui_width:uiw ~ui_height:uih path =
  let img = match Binary.restore path with
    | Some img -> img
    | None -> let pix = GdkPixbuf.from_file path in
      let imgw, imgh = GdkPixbuf.(get_width pix, get_height pix) in
      let edge = CSettings.edge () in
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
  in img

let statistics img = CTable.statistics (annotations img)
   
let digest t =
  Printf.sprintf "<small><tt> \
    <b>Image:</b> %s ▪ \
    <b>Size:</b> %d × %d pixels ▪ \
    <b>Tiles:</b> %d × %d</tt></small>" 
  (basename t) (source t `W) (source t `H) (dim t `R) (dim t `C)
