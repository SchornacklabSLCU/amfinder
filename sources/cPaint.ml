(* CastANet - cPaint.ml *)

open CExt
open Scanf

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


(* TODO: clean this. *)
module Palette = struct
  type palette = {
    colors : string array;
    max_group : int;
    surfaces : Cairo.Surface.t array; (* memoized. *)
  }

  type id = [ `CIVIDIS | `PLASMA | `VIRIDIS ]

  let edge = ref 0

  let make_surface_table colors =
    Array.map (fun clr ->
      let clr = clr ^ "cc" in (* 80% opacity *)
      Surface.square ~kind:(`RGBA_COLOR clr) ~edge:!edge ()
    ) colors

  let make colors () = {
    colors;
    max_group = Array.length colors - 1;
    surfaces = make_surface_table colors;
  }

  (* R source:
   *  library(cividis)
   *  cividis(25) *)
  let cividis =
    let f = make [|
      "#00204D"; "#00285F"; "#002F6F"; "#05366E"; "#233E6C";
      "#34456B"; "#414D6B"; "#4C546C"; "#575C6D"; "#61646F";
      "#6A6C71"; "#737475"; "#7C7B78"; "#868379"; "#918C78";
      "#9B9477"; "#A69D75"; "#B2A672"; "#BCAF6F"; "#C8B86A";
      "#D3C164"; "#E0CB5E"; "#ECD555"; "#F8DF4B"; "#FFEA46"; 
    |] in Ext_Memoize.create ~label:"CPalette.cividis" f

  (* R source:
   *  library(viridis)
   *  viridis_pal(option='C')(25) *)
  let plasma =
    let f = make [|
      "#0D0887"; "#270592"; "#3B049A"; "#4C02A1"; "#5D01A6";
      "#6E00A8"; "#7E03A8"; "#8E0BA5"; "#9C179E"; "#A92395";
      "#B52F8C"; "#C13B82"; "#CC4678"; "#D5536F"; "#DE5F65";
      "#E56B5D"; "#ED7953"; "#F3864A"; "#F89441"; "#FCA338";
      "#FDB32F"; "#FDC328"; "#FBD424"; "#F6E726"; "#F0F921";
    |] in Ext_Memoize.create ~label:"CPalette.plasma" f 

  (* R source:
   *  library(scales)
   *  viridis_pal()(25) *)
  let viridis = 
    let f = make [|
      "#440154"; "#471164"; "#481F70"; "#472D7B"; "#443A83";
      "#404688"; "#3B528B"; "#365D8D"; "#31688E"; "#2C728E"; 
      "#287C8E"; "#24868E"; "#21908C"; "#1F9A8A"; "#20A486"; 
      "#27AD81"; "#35B779"; "#47C16E"; "#5DC863"; "#75D054"; 
      "#8FD744"; "#AADC32"; "#C7E020"; "#E3E418"; "#FDE725";
    |] in Ext_Memoize.create ~label:"CPalette.viridis" f

  let set_tile_edge n = edge := n

  let get f typ =
    let get_palette = match typ with
      | `CIVIDIS -> cividis
      | `PLASMA -> plasma
      | `VIRIDIS -> viridis
    in f (get_palette ())

  let max_group = get (fun pal -> pal.max_group)
  let surface = get (fun pal n -> pal.surfaces.(n))
  let color = get (fun pal n -> pal.colors.(n))
end
