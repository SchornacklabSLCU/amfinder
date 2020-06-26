(* CastANet - cPalette.ml *)

type t = {
  colors : string array;
  max_group : int;
  surfaces : Cairo.Surface.t array; (* memoized. *)
}

type id = [
  | `CIVIDIS
  | `SUNSET
  | `VIRIDIS
]

let edge = ref 0

let make_cairo_surface ?(r = 0.0) ?(g = 0.0) ?(b = 0.0) ?(a = 1.0) () =
  let open Cairo in
  let surface = Image.(create ARGB32 ~w:!edge ~h:!edge) in
  let t = create surface in
  set_antialias t ANTIALIAS_SUBPIXEL;
  set_source_rgba t r g b a;
  let edge = float !edge in
  rectangle t 0.0 0.0 ~w:edge ~h:edge;
  fill t;
  stroke t;
  surface

let make_surface_table colors =
  Array.map  (fun clr ->
    let r, g, b = CExt.tagger_html_to_float clr in
    make_cairo_surface ~r ~g ~b ~a:0.8 ()
  ) colors

let make colors () = {
  colors;
  max_group = Array.length colors - 1;
  surfaces = make_surface_table colors;
}

(* source: https://kite.com/python/docs/bokeh.palettes.cividis *)
let cividis =
  let f = make [|
    "#00204D"; "#00285F"; "#002F6F"; "#05366E"; "#233E6C";
    "#34456B"; "#414D6B"; "#4C546C"; "#575C6D"; "#61646F";
    "#6A6C71"; "#737475"; "#7C7B78"; "#868379"; "#918C78";
    "#9B9477"; "#A69D75"; "#B2A672"; "#BCAF6F"; "#C8B86A";
    "#D3C164"; "#E0CB5E"; "#ECD555"; "#F8DF4B"; "#FFEA46"; 
  |] in CExt.memoize f

(* source: https://www.thinkingondata.com/something-about-viridis-library/ *)
let viridis = 
  let f = make [|
    "#440154"; "#481567"; "#482677"; "#453781"; "#404788";
    "#39568C"; "#33638D"; "#2D708E"; "#287D8E"; "#238A8D";
    "#1F968B"; "#20A387"; "#29AF7F"; "#3CBB75"; "#55C667";
    "#73D055"; "#95D840"; "#B8DE29"; "#DCE319"; "#FDE725";
  |] in CExt.memoize f
  
let sunset =
  let f = make [|
    "#4B2991"; "#5A2995"; "#692A99"; "#782B9D"; "#872CA2";
    "#952EA0"; "#A3319F"; "#B1339E"; "#C0369D"; "#CA3C97";
    "#D44292"; "#DF488D"; "#EA4F88"; "#ED5983"; "#F2637F";
    "#F66D7A"; "#FA7876"; "#F98477"; "#F89078"; "#F79C79";
    "#F6A97A"; "#F3B584"; "#F1C18E"; "#EFCC98"; "#EDD9A3";
  |] in CExt.memoize f

let set_tile_edge n = edge := n

let get f typ =
  let get_palette = match typ with
    | `CIVIDIS -> cividis
    | `SUNSET -> sunset
    | `VIRIDIS -> viridis
  in f (get_palette ())

let max_group = get (fun pal -> pal.max_group)
let surface = get (fun pal n -> pal.surfaces.(n))
let color = get (fun pal n -> pal.colors.(n))
