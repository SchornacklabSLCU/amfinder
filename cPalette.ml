(* CastANet - cPalette.ml *)

open CExt

type t = {
  colors : string array;
  max_group : int;
  surfaces : Cairo.Surface.t array; (* memoized. *)
}

type id = [
  | `CIVIDIS
  | `PLASMA
  | `VIRIDIS
]

let edge = ref 0

let make_surface_table colors =
  Array.map (fun clr ->
    EDraw.square ~clr ~a:0.8 !edge
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
  |] in Ext_Memoize.create ~lbl:"cividis" f

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
  |] in Ext_Memoize.create ~lbl:"plasma" f 

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
  |] in Ext_Memoize.create ~lbl:"viridis" f

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
