(* amfSurface.ml *)

open Scanf

type edge = int
type color = string

let parse_html_color =
    let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
    fun s -> sscanf s "#%02x%02x%02x%02x" (fun r g b a -> f r, f g, f b, f a)

let pi = acos (-1.0)
let two_pi = 2.0 *. pi

let initialize color edge =
    assert (edge > 0); 
    let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    let r, g, b, a = parse_html_color color in
    Cairo.set_source_rgba t r g b a;
    t, surface


let up_arrowhead color edge =
    let t, surface = initialize color edge in
    let edge = float edge in
    let frac = 0.1 *. edge in
    let yini = frac and xini = edge /. 2.0 in
    let size =  0.48 *. xini in
    Cairo.move_to t xini yini;
    Cairo.line_to t (xini -. size) (edge -. frac);
    Cairo.line_to t (xini +. size) (edge -. frac);
    Cairo.fill t;
    Cairo.stroke t;
    surface


let down_arrowhead color edge =
    let t, surface = initialize color edge in
    let edge = float edge in
    let frac = 0.4 *. edge in
    let yini = edge -. frac and xini = edge /. 2.0 in
    let size =  0.3 *. xini in 
    Cairo.move_to t xini yini;
    Cairo.line_to t (xini -. size) frac;
    Cairo.line_to t (xini +. size) frac;
    Cairo.fill t;
    Cairo.stroke t;
    surface


let right_arrowhead color edge =
    let t, surface = initialize color edge in
    let edge = float edge in
    let frac = 0.4 *. edge in
    let xini = edge -. frac and yini = edge /. 2.0 in
    let size =  0.3 *. yini in 
    Cairo.move_to t xini yini;
    Cairo.line_to t frac (yini -. size);
    Cairo.line_to t frac (yini +. size);
    Cairo.fill t;
    Cairo.stroke t;
    surface


let circle color edge =
    let t, surface = initialize color edge in
    let radius = float edge /. 2.0 in
    Cairo.arc t radius radius ~r:radius ~a1:0.0 ~a2:two_pi;
    Cairo.fill t;
    Cairo.stroke t;
    surface


let solid_square color edge =
    let t, surface = initialize color edge in
    let edge = float edge in
    Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
    Cairo.fill t;
    Cairo.stroke t;
    surface


let empty_square ?(line = 5.0) color edge =
    let t, surface = initialize color edge in
    Cairo.set_line_width t line;
    let edge = float edge in
    Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
    Cairo.stroke t;
    surface


let prediction_palette ?(step = 12) colors edge =
    let len = Array.length colors in
    let surface = Cairo.Image.(create ARGB32 ~w:(step * len + 40) ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_NONE;
    Array.iteri (fun i color ->
        let r, g, b, a = parse_html_color color in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t (float (step * i + 20)) 0.0 ~w:(float step) ~h:(float edge);
        Cairo.fill t;
        Cairo.stroke t;
    ) colors;
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    Cairo.select_font_face t "Arial" ~weight:Cairo.Bold;
    Cairo.set_font_size t 16.0;
    Cairo.set_source_rgba t 0.0 0.0 0.0 1.0;
    let te = Cairo.text_extents t "0" in
    Cairo.move_to t 
        (10.0 -. te.Cairo.width /. 2.0)
        (float edge /. 2.0 +. te.Cairo.height /. 2.0);
    Cairo.show_text t "0";
    let te = Cairo.text_extents t "1" in
    Cairo.move_to t
        (float (20 + step * len + 10) -. te.Cairo.width /. 2.0)
        (float edge /. 2.0 +. te.Cairo.height /. 2.0);
    Cairo.show_text t "1";
    surface

let annotation_legend symbs colors =
    assert List.(length symbs = length colors);
    let len = List.length colors in
    let surface = Cairo.Image.(create ARGB32 ~w:(70 * len) ~h:30) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_NONE;
    let index = ref 0 in
    Cairo.select_font_face t "Arial";
    Cairo.set_font_size t 14.0;
    let te = Cairo.text_extents t "M" in
    List.iter2 (fun symb color ->
        let r, g, b, a = parse_html_color (color ^ "90") in
        Cairo.set_source_rgba t r g b a;
        let x = float (70 * !index) in
        Cairo.rectangle t x 0.0 ~w:30.0 ~h:30.0;
        Cairo.fill t;
        Cairo.stroke t;
        Cairo.set_source_rgba t 0.0 0.0 0.0 1.0;
        let x = x +. 32.0 and y = 15.0 +. te.Cairo.height /. 2.0 in
        Cairo.move_to t x y;
        Cairo.show_text t symb;
        incr index
    ) symbs colors;
    surface

let pie_chart prob_list colors edge =
    let t, surface = initialize "#ffffffff" edge in
    let radius = float edge /. 2.0 in
    let from = ref 0.0 in
    List.iter2 (fun x clr ->
        let rad = two_pi *. x in  
        Cairo.move_to t radius radius;
        let a2 = !from +. rad in
        Cairo.arc t radius radius ~r:radius ~a1:!from ~a2;
        from := a2;
        Cairo.Path.close t;
        let r, g, b, a = parse_html_color (clr ^ "90") in
        Cairo.set_source_rgba t r g b a;
        Cairo.fill t;
        Cairo.stroke t;
    ) prob_list colors;
    surface
