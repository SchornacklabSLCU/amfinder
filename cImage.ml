(* CastANet - cImage.mli *)

type annot = CAnnot.t CExt.Matrix.t
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

type t = { param : param; sizes : sizes; annot : annot; graph : graph }

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

let annotations t = t.annot

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
let iter_annot f t = CExt.Matrix.iteri f (annotations t)

let x ~c t typ = (origin t `X) + c * (edge t typ)
let y ~r t typ = (origin t `Y) + r * (edge t typ)

let is_valid ~r ~c t = CExt.Matrix.get_opt (annotations t) r c <> None


module Binary = struct
  let binfile path = Filename.remove_extension path ^ ".bin"
  (* Save image as binary at exit. *)
  let save_at_exit img =
    let f () =
      let och = path img |> binfile |> open_out_bin in
      output_value och img;
      close_out och
    in at_exit f
  (* Restore image at startup from binary data. *)
  let restore path =
    let bin = binfile path in
    if Sys.file_exists bin then (
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
    let tsv = Filename.remove_extension path ^ ".tsv" in
    if Sys.file_exists tsv then CAnnot.import tsv
    else Matrix.map (fun _ -> CAnnot.empty ()) tiles
end

let create ~ui_width:uiw ~ui_height:uih path =
  match Binary.restore path with
  | Some img -> img
  | None ->
    let pix = GdkPixbuf.from_file path in
    let imgw, imgh = GdkPixbuf.(get_width pix, get_height pix) in
    let edge = 236 in
    let rows = imgh / edge and cols = imgw / edge in
    let large = Create.large_tile_matrix rows cols edge pix in
    let sub = min (uiw / cols) (uih / rows) in
    let small = Create.small_tile_matrix sub large in
    let annot = Create.annotations path small in
    let graph = {
      imgw; imgh; cursor = (0, 0);
      xini = (uiw - sub * cols) / 2;
      yini = (uih - sub * rows) / 2;
    } and sizes = {
      small = {edge = sub; matrix = small};
      large = {edge = 180; matrix = large};
    } and param = {path; rows; cols} in
    let img = { param; sizes; graph; annot } in
    Binary.save_at_exit img;
    CPalette.set_tile_edge sub;
    CLog.info "source image: '%s'" path;
    CLog.info "source image size: %d x %d pixels" imgw imgh;
    CLog.info "tile matrix: %d x %d; edge: %d pixels" rows cols edge;
    img

let statistics img =
  let res = List.map (fun c -> c, ref 0) ('*' :: CAnnot.code_list) in
  iter_annot (fun r c t ->
    if CAnnot.exists t then incr (List.assoc '*' res);
    String.iter (fun chr -> incr (List.assoc chr res)) (CAnnot.get_active t)
  ) img;
  List.map (fun (c, r) -> c, !r) res
   
let digest t =
  Printf.sprintf "<small><tt> \
    <b>Image:</b> %s ▪ \
    <b>Size:</b> %d × %d pixels ▪ \
    <b>Tiles:</b> %d × %d</tt></small>" 
  (basename t) (source t `W) (source t `H) (dim t `R) (dim t `C)
