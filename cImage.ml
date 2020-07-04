(* CastANet - cImage.mli *)

type mosaic = { edge : int; matrix : GdkPixbuf.pixbuf CExt.Matrix.t }

type t = {
  path : string;
  original_size : int * int;
  rows : int;
  columns : int;
  pixels : int * int;
  large : mosaic; (* zoomed in version. *)
  small : mosaic; (* image overview.    *)
  annot : CAnnot.t CExt.Matrix.t;
  mutable cursor : int * int;
}

let path t = t.path
let basename t = Filename.basename (path t)
let dirname t = Filename.dirname (path t)

let original_size t = t.original_size

let xini t = fst t.pixels
let yini t = snd t.pixels

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

module Create = struct
  let tile_matrix nr nc e source =
    CExt.Matrix.init nr nc (fun r c ->
      let open CExt.Image in
      crop_square ~src_x:(c * e) ~src_y:(r * e) ~edge:e source
      |> resize ~edge:CCore.edge
    )
    
  let annotations path tiles =
    let tsv = Filename.remove_extension path ^ ".tsv" in
    if Sys.file_exists tsv then CAnnot.import tsv
    else CExt.Matrix.map (fun _ -> CAnnot.empty ()) tiles
end

let create ~ui_width ~ui_height path =
  CLog.info "source image: '%s'" path;
  let _, w, h = GdkPixbuf.get_file_info path in
  CLog.info "source image size: %d x %d pixels" w h;
  let image = GdkPixbuf.from_file path in
  let edge = 236 in
  let nr = h / edge and nc = w / edge in
  CLog.info "tile matrix: %d x %d; edge: %d pixels" nr nc edge;
  let large = Create.tile_matrix nr nc edge image in
  let small_edge = min (ui_width / nc) (ui_height / nr) in
  CPalette.set_tile_edge small_edge;
  let small = CExt.Matrix.map (CExt.Image.resize ~edge:small_edge) large in
  let annot = Create.annotations path small in
  let xini = (ui_width - small_edge * nc) / 2
  and yini = (ui_height - small_edge * nr) / 2 in
  { path; original_size = (w, h); rows = nr; columns = nc;
    pixels = (xini, yini); cursor = (0, 0); annot;
    large = { edge = CCore.edge; matrix = large };
    small = { edge = small_edge; matrix = small } }

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
