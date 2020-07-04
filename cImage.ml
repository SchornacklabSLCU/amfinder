(* CastANet - cImage.mli *)

type mosaic = { edge : int; matrix : GdkPixbuf.pixbuf CExt.Matrix.t }

type t = {
  path : string;
  original_size : int * int;
  rc : int * int;
  pixels : int * int;
  large : mosaic; (* zoomed in version. *)
  small : mosaic; (* image overview.    *)
  annot : CAnnot.t CExt.Matrix.t;
  mutable cursor : int * int;
}

let path img = img.path
let basename img = Filename.basename img.path
let dirname img = Filename.dirname img.path

let original_size img = img.original_size

let xini img = fst img.pixels
let yini img = snd img.pixels

let rows img = fst img.rc
let columns img = snd img.rc

let annotations img = img.annot

let edge t x = (if x = `SMALL then t.small else t.large).edge
let tiles t x = (if x = `SMALL then t.small else t.large).matrix

let cursor_pos img = img.cursor
let set_cursor_pos img pos = img.cursor <- pos

let tile ~r ~c img typ = CExt.Matrix.get_opt (tiles img typ) r c
let annotation ~r ~c img = CExt.Matrix.get_opt (annotations img) r c

let iter_tiles f img typ = CExt.Matrix.iteri f (tiles img typ)
let iter_annot f img = CExt.Matrix.iteri f (annotations img)


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

  let get_large nr nc edge source =
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
  let large = Create.get_large nr nc edge image in
  let small_edge = min (ui_width / nc) (ui_height / nr) in
  CPalette.set_tile_edge small_edge;
  let small = CExt.Matrix.map (Create.scale ~edge:small_edge) large in
  let annot = Create.annotations path small in
  let xini = (ui_width - small_edge * nc) / 2
  and yini = (ui_height - small_edge * nr) / 2 in
  { path; original_size = (w, h);
    rc = (nr, nc); pixels = (xini, yini); cursor = (0, 0);
    large = { edge = CCore.edge; matrix = large };
    small = { edge = small_edge; matrix = small };
    annot }

let is_valid ~r ~c t = CExt.Matrix.get_opt (annotations t) r c <> None

let x ~c img typ = (xini img) + c * (edge img typ)
let y ~r img typ = (yini img) + r * (edge img typ)

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
    <b>Image:</b> %s, \
    <b>width:</b> %d pixels, \
    <b>height:</b> %d pixels, \
    <b>rows:</b> %d, \
    <b>columns:</b> %d</tt></small>" 
  (basename img) wpix hpix (rows img) (columns img)
