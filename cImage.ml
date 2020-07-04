(* CastANet - cImage.mli *)

type mosaic = { edge : int; matrix : GdkPixbuf.pixbuf CExt.Matrix.t }

type t = {
  path : string;
  original_size : int * int;
  rows : int;
  columns : int;
  xini : int;
  yini : int;
  large : mosaic; (* zoomed in version. *)
  small : mosaic; (* image overview.    *)
  annot : CAnnot.t CExt.Matrix.t;
  mutable cursor : int * int;
}

let path t = t.path
let basename t = Filename.basename (path t)
let dirname t = Filename.dirname (path t)

let original_size t = t.original_size

let xini t = t.xini
let yini t = t.yini

let rows t = t.rows
let columns t = t.columns

let annotations t = t.annot

let edge t x = (if x = `SMALL then t.small else t.large).edge
let tiles t x = (if x = `SMALL then t.small else t.large).matrix

let cursor_pos t = t.cursor
let set_cursor_pos t pos = t.cursor <- pos

let tile ~r ~c t typ = CExt.Matrix.get_opt (tiles t typ) r c
let annotation ~r ~c t = CExt.Matrix.get_opt (annotations t) r c

let iter_tiles f t typ = CExt.Matrix.iteri f (tiles t typ)
let iter_annot f t = CExt.Matrix.iteri f (annotations t)

let x ~c t typ = (xini t) + c * (edge t typ)
let y ~r t typ = (yini t) + r * (edge t typ)

let is_valid ~r ~c t = CExt.Matrix.get_opt (annotations t) r c <> None


module Binary = struct
  let binfile path = Filename.chop_extension path ^ ".bin"
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
  let w, h = GdkPixbuf.(get_width pix, get_height pix) in
  let edge = 236 in
  let nr = h / edge and nc = w / edge in
  CLog.info "source image: '%s'" path;
  CLog.info "source image size: %d x %d pixels" w h;
  CLog.info "tile matrix: %d x %d; edge: %d pixels" nr nc edge;
  let large = Create.large_tile_matrix nr nc edge pix in
  let small_edge = min (uiw / nc) (uih / nr) in
  let small = Create.small_tile_matrix small_edge large in
  let annot = Create.annotations path small in
  CPalette.set_tile_edge small_edge;
  let xini = (uiw - small_edge * nc) / 2
  and yini = (uih - small_edge * nr) / 2 in
  let img = { path; original_size = (w, h); rows = nr; columns = nc;
    xini; yini; cursor = (0, 0); annot;
    large = { edge = CCore.edge; matrix = large };
    small = { edge = small_edge; matrix = small } } in
  Binary.save_at_exit img;
  img

let statistics img =
  let res = List.map (fun c -> c, ref 0) ('*' :: CAnnot.code_list) in
  iter_annot (fun r c t ->
    if CAnnot.exists t then incr (List.assoc '*' res);
    String.iter (fun chr -> incr (List.assoc chr res)) (CAnnot.get_active t)
  ) img;
  List.map (fun (c, r) -> c, !r) res
   
let digest img =
  let wpix, hpix = original_size img in
  Printf.sprintf "<small><tt> \
    <b>Image:</b> %s ▪ \
    <b>Size:</b> %d × %d pixels ▪ \
    <b>Tiles:</b> %d × %d</tt></small>" 
  (basename img) wpix hpix (rows img) (columns img)
