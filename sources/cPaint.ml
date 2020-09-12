(* CastANet - cPaint.ml *)

open CExt
open Scanf
open Printf

let parse_html_color =
  let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
  fun s -> sscanf s "#%02x%02x%02x%02x" (fun r g b a -> f r, f g, f b, f a)

(* Error function for calls to Option.fold. *)
let none loc () = CLog.error "No active image (%s)" loc

module Surface = struct
  let square ~kind ~edge () =
    assert (edge > 0); 
    let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    let clr = match kind with 
      | `SOLID_CURSOR -> "#cc0000cc" (* 80% opacity. *)
      | `LIGHT_CURSOR -> "#cc000066" (* 40% opacity. *)
      | `RGBA_COLOR x -> x in
    let r, g, b, a = parse_html_color clr in
    Cairo.set_source_rgba t r g b a;
    let edge = float edge in
    Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
    Cairo.fill t;
    Cairo.stroke t;
    surface

  let small_square ~kind () =
    let some img = square ~kind ~edge:(CImage.edge img `SMALL) in
    Option.fold
      ~none:(none "CPaint.Surface.small_square")
      ~some (CImage.get_active ()) ()

  let joker = 
    let f () = small_square ~kind:(`RGBA_COLOR "#aaffaacc") () in
    Ext_Memoize.create ~label:"CPaint.Surface.master" f

  let cursor = 
    let f () = small_square ~kind:`SOLID_CURSOR () in
    Ext_Memoize.create ~label:"CPaint.Surface.cursor" f

  let pointer =
    let f () = small_square ~kind:`LIGHT_CURSOR () in
    Ext_Memoize.create ~label:"CPaint.Surface.pointer" f

  let layers =
    List.map (fun lvl ->
      let f lvl () =
        List.map2 (fun chr rgb ->
          chr, small_square ~kind:(`RGBA_COLOR rgb) ()
        ) (CAnnot.char_list lvl) (CLevel.colors lvl)
      in lvl, Ext_Memoize.create ~label:"CPaint.Surface.layers" (f lvl)
    ) CLevel.flags
          
  let get_from_char = function
    | '*' -> joker ()
    | '.' -> cursor ()
    | chr -> let lvl = CGUI.Levels.current () in
      List.assoc chr (List.assoc lvl layers ()) 
end


let background ?(color = "#ffffffff") ?(sync = true) () =
  let t = CGUI.Drawing.cairo () in
  let r, g, b, a = parse_html_color color in
  Cairo.set_source_rgba t r g b a;
  let w = float @@ CGUI.Drawing.width () 
  and h = float @@ CGUI.Drawing.height () in
  Cairo.rectangle t 0.0 0.0 ~w ~h;
  Cairo.fill t;
  Cairo.stroke t;
  if sync then CGUI.Drawing.synchronize ()


let tiles ?(sync = true) () =
  Option.iter (fun img ->
    let pixmap = CGUI.Drawing.pixmap ()
    and xini = CImage.origin img `X
    and yini = CImage.origin img `Y
    and edge = CImage.edge img `SMALL in
    CImage.iter_tiles (fun ~r ~c tile ->
      pixmap#put_pixbuf
        ~x:(xini + c * edge)
        ~y:(yini + r * edge)
        ~width:edge ~height:edge tile
    ) img `SMALL;
    if sync then CGUI.Drawing.synchronize ()
  ) (CImage.get_active ())


let tile ?(sync = false) ~r ~c () =
  Option.iter (fun img ->
    Option.iter (fun tile ->
      (CGUI.Drawing.pixmap ())#put_pixbuf
        ~x:(CImage.x ~c img `SMALL)
        ~y:(CImage.y ~r img `SMALL) tile;
      if sync then CGUI.Drawing.synchronize ()
    ) (CImage.tile r c img `SMALL)
  ) (CImage.get_active ())


(* FIXME Unsafe function - not for use outside! *)
let surface ?(sync = false) ~r ~c surface =
  Option.iter (fun img ->
    let t = CGUI.Drawing.cairo () in
    let x = CImage.x ~c img `SMALL 
    and y = CImage.y ~r img `SMALL in
    Cairo.set_source_surface t surface (float x) (float y);
    Cairo.paint t;
    if sync then CGUI.Drawing.synchronize ()
  ) (CImage.get_active ())


let annot ?(sync = false) ~r ~c () =
  Option.iter (fun img ->
    let typ = CGUI.Layers.get_active ()
    and tbl = CImage.annotations img
    and lvl = CGUI.Levels.current () in
    let draw = match typ with
      | '*' -> not (CTable.is_empty tbl lvl ~r ~c) (* Catches any annotation. *)
      | chr -> CTable.mem tbl lvl r c (`CHR chr) in
    if draw then begin
      surface ~r ~c (Surface.get_from_char typ);
      if sync then CGUI.Drawing.synchronize ()
    end
  ) (CImage.get_active ())


let cursor ?(sync = false) () =
  Option.iter (fun img ->
    let r, c = CImage.cursor_pos img in
    tile ~r ~c ();
    surface ~r ~c (Surface.get_from_char '.');
    if sync then CGUI.Drawing.synchronize ()
  ) (CImage.get_active ())


let active_layer ?(sync = true) () =
  Option.iter (fun img ->
    CTable.iter (fun ~r ~c _ ->
      tile ~r ~c ();
      annot ~r ~c ()
    ) (CImage.annotations img) (CGUI.Levels.current ());
    cursor ();
    if sync then CGUI.Drawing.synchronize ()
  ) (CImage.get_active ())


module Palette = struct
  type palette = {
    colors : string array;
    max_group : int;
    surfaces : Cairo.Surface.t array;
  }

  let folder = "data/palettes"
  let palette_db = ref []

  let load () =
    let all = Array.fold_left (fun pal elt ->
      let path = Filename.concat folder elt in
      if Filename.check_suffix path ".palette" then (
        let base = Filename.remove_extension elt in
        CLog.info "Loading palette %s" base;
        let colors = Ext_File.read path
          |> String.split_on_char '\n'
          |> List.map (sprintf "%scc")
          |> Array.of_list in
        let surfaces =
          Array.map (fun c -> 
            Surface.small_square ~kind:(`RGBA_COLOR c) ()
          ) colors in
        let max_group = Array.length surfaces - 1 in
        (base, {colors; surfaces; max_group}) :: pal
      ) else pal
    ) [] (Sys.readdir folder) in palette_db := all

  let mem str = List.mem_assoc str !palette_db
  let get str = List.assoc str !palette_db
  
  let colors pal = pal.colors
  let max_group pal = pal.max_group
  let surfaces pal = pal.surfaces
end
