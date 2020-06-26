(* CastANet - cPalette.ml *)

type t = {
  colors : string array;
  max_group : int;
  surfaces : Cairo.Surface.t array; (* memoized. *)
}

type id = [ `VIRIDIS | `SUNSET ]

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

let max_group = function
  | `VIRIDIS -> (viridis ()).max_group
  | `SUNSET -> (sunset ()).max_group

let surface n = function
  | `VIRIDIS -> (viridis ()).surfaces.(n)
  | `SUNSET -> (sunset ()).surfaces.(n)

let color n = function
  | `VIRIDIS -> (viridis ()).colors.(n)
  | `SUNSET -> (sunset ()).colors.(n)
