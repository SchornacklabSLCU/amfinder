(* CastANet - cImage.mli *)

type mosaic = {
  edge : int;
  matrix : GdkPixbuf.pixbuf array array;
}

type t = {
  path : string;
  original_size : int * int;
  rc : int * int;
  pixels : int * int;
  large_tiles : mosaic; (* zoomed in version. *)
  small_tiles : mosaic; (* image overview.    *)
  annotations : CAnnot.t array array;
  mutable cursor : int * int;
}

let path img = img.path

let original_width img = fst img.original_size
let original_height img = snd img.original_size

let xini img = fst img.pixels
let yini img = snd img.pixels

let rows img = fst img.rc
let columns img = snd img.rc

let tiles img = function
  | `LARGE -> img.large_tiles.matrix
  | `SMALL -> img.small_tiles.matrix


module Create = struct
  let get_size path = let _, w, h = GdkPixbuf.get_file_info path in w, h
  let load_full_size_img = GdkPixbuf.from_file

  let scale ?(interp = `NEAREST) ~edge pix =
    let w, h = GdkPixbuf.(get_width pix, get_height pix) in
    let scale_x = float edge /. (float w)
    and scale_y = float edge /. (float h) in
    let dest = GdkPixbuf.create ~width:edge ~height:edge () in
    GdkPixbuf.scale
      ~dest ~dest_x:0 ~dest_y:0 ~width:edge ~height:edge
      ~scale_x ~scale_y ~ofs_x:0.0 ~ofs_y:0.0 
      ~interp pix;
    dest

  let get_large_tiles nr nc edge source =
    Array.init nr (fun r ->
      Array.init nc (fun c ->
        let tile = GdkPixbuf.create ~width:edge ~height:edge () in
        GdkPixbuf.copy_area ~dest:tile
          ~src_x:(c * edge) ~src_y:(r * edge)
          ~width:edge ~height:edge source;
        scale ~edge:CCore.edge tile
    ))
    
  let annotations path tiles =
    let tsv = Filename.remove_extension path ^ ".tsv" in
    if Sys.file_exists tsv then CAnnot.import tsv
    else CExt.Matrix.map (fun _ -> CAnnot.empty ()) tiles
end

let create ~ui_width ~ui_height path =
  let w, h = Create.get_size path in
  CLog.info "source image width: %d pixels; height: %d pixels" w h;
  let image = Create.load_full_size_img path in
  let edge = 236 in
  let nr = h / edge and nc = w / edge in
  CLog.info "tile matrix rows: %d; columns: %d; edge: %d pixels" nr nc edge;
  let large_tiles = Create.get_large_tiles nr nc edge image in
  let small_edge = min (ui_width / nc) (ui_height / nr) in
  CPalette.set_tile_edge small_edge;
  let small_tiles = CExt.Matrix.map (Create.scale ~edge:small_edge) large_tiles in
  let annotations = Create.annotations path small_tiles in
  let xini = (ui_width - small_edge * nc) / 2
  and yini = (ui_height - small_edge * nr) / 2 in
  { path; original_size = (w, h);
    rc = (nr, nc); pixels = (xini, yini); cursor = (0, 0);
    large_tiles = { edge = CCore.edge; matrix = large_tiles };
    small_tiles = { edge = small_edge; matrix = small_tiles };
    annotations }

let is_valid ~r ~c img =
  try ignore (img.annotations.(r).(c)); true with _ -> false

let edge img = function
  | `LARGE -> img.large_tiles.edge
  | `SMALL -> img.small_tiles.edge

let x ~c img typ = (xini img) + c * (edge img typ)
let y ~r img typ = (yini img) + r * (edge img typ)

let tile ~r ~c img typ = try Some (tiles img typ).(r).(c) with _ -> None

let annotations img = img.annotations
let annotation ~r ~c img = try Some (annotations img).(r).(c) with _ -> None

let statistics img =
  let annot = annotations img in
  List.map (fun chr ->
    let res = ref 0 in
    let f = match chr with 
      | '*' -> CAnnot.exists 
      |  _  -> (fun t -> CAnnot.mem t chr)
    in Array.(iter (iter (fun t -> if f t then incr res))) annot;
    (chr, !res)
  ) ('*' :: CAnnot.code_list)

let cursor_pos img = img.cursor
let set_cursor_pos img pos = img.cursor <- pos

let iter_tiles f img typ = CExt.Matrix.iteri f (tiles img typ)
let iter_annot f img = CExt.Matrix.iteri f (annotations img)
   
let digest img =
  Printf.sprintf "<small><tt> \
    <b>Image:</b> %s, \
    <b>width:</b> %d pixels, \
    <b>height:</b> %d pixels, \
    <b>rows:</b> %d, \
    <b>columns:</b> %d</tt></small>" 
  (Filename.basename (path img))
  (original_width img)
  (original_height img)
  (rows img)
  (columns img)
