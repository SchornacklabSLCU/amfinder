(* AMFinder - amfSurface.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

open Cairo

type pixels = int
type color = string

let pi = acos (-1.0)
let pi2 = pi /. 2.0
let pi4 = pi /. 4.0
let twopi = 2.0 *. pi
let twopi3 = twopi /. 3.0
let twopi4 = twopi /. 4.0



let rectangle ?rgba ~w ~h =
    assert (w > 0 && h > 0);
    let surface = Image.create Image.ARGB32 ~w ~h in
    let context = create surface in
    set_line_width context 1.0;
    set_antialias context ANTIALIAS_SUBPIXEL;
    Option.iter (fun color ->
        let r, g, b, a = AmfColor.parse_rgba color in
        set_source_rgba context r g b a;
        rectangle context 0.0 0.0 ~w:(float w) ~h:(float h);
        fill context;
    ) rgba;
    context, surface

let square ?rgba e = rectangle ?rgba ~w:e ~h:e



module Arrowhead = struct

    let draw
      ?(bgcolor = "#FFFFFFFF")
      ?(fgcolor = "#FF0000FF") edge x1 y1 y2 y3 =
        let context, surface = square ~rgba:bgcolor edge in
        let r, g, b, a = AmfColor.parse_rgba fgcolor in
        set_source_rgba context r g b a;
        move_to context x1 y1;
        line_to context y1 y2;
        line_to context y2 y3;
        fill context;
        surface

    let top ?bgcolor ?fgcolor edge =
        let e = float edge in
        let x1 = e /. 2.0
        and y1 = 0.0
        and y2 = e
        and y3 = e in
        draw ?bgcolor ?fgcolor edge x1 y1 y2 y3

    let bottom ?bgcolor ?fgcolor edge =
        let e = float edge in
        let x1 = e /. 2.0
        and y1 = e
        and y2 = 0.0
        and y3 = 0.0 in
        draw ?bgcolor ?fgcolor edge x1 y1 y2 y3

    let left ?bgcolor ?fgcolor edge =
        let e = float edge in
        let x1 = e
        and y1 = e
        and y2 = 0.0
        and y3 = e /. 2.0 in
        draw ?bgcolor ?fgcolor edge x1 y1 y2 y3

    let right ?bgcolor ?fgcolor edge =
        let e = float edge in
        let x1 = 0.0
        and y1 = 0.0
        and y2 = e
        and y3 = e /. 2.0 in
        draw ?bgcolor ?fgcolor edge x1 y1 y2 y3

end



module Annotation = struct

    (* See https://www.cairographics.org/samples/rounded_rectangle/ *)
    let rounded_rectangle context ?(rad = 5.0) x y ~w ~h =
        let degrees = pi /. 180.0
        and corner_radius = h /. rad in
        Path.sub context;
        arc context (x +. w -. corner_radius)  
                    (y +. corner_radius)
                    ~r:corner_radius
                    ~a1:(-90.0 *. degrees) ~a2:0.0;
        arc context (x +. w -. corner_radius)
                    (y +. h -. corner_radius)
                    ~r:corner_radius
                    ~a1:0.0 ~a2:(90.0 *. degrees);
        arc context (x +. corner_radius)
                    (y +. h -. corner_radius)
                    ~r:corner_radius
                    ~a1:(90.0 *. degrees) ~a2:(180.0 *. degrees);
        arc context (x +. corner_radius)
                    (y +. corner_radius)
                    ~r:corner_radius
                    ~a1:(180.0 *. degrees) ~a2:(270.0 *. degrees);
        Path.close context

    let draw 
      ?(eye = false)
      ?(lock = false)
      ?(margin = 4.0)
      ?(rounded = false)
      ?(symbol = "")
      ?(symbol_color = "#FFFFFFFF")
      ?(font_size = 16.0)
      ?(font_face = "Arial")
      ?(font_weight = Bold)
      ?(dash = [||])
      ?(stroke = false)
      ?(dash_color = "#000000FF")
      ?(line_width = 1.0)
      ?(fill = true)
      ?(fill_color = "#FFFFFFB0")
      ?(multicolor = []) edge =

        (* Simple checks. Other values may be malformed as well. *)
        assert (font_size > 0.0
                 && line_width > 0.0
                 && margin >= 0.0
                 && mod_float margin 2.0 = 0.0);

        let surface = Image.(create ARGB32 ~w:edge ~h:edge) in
        let t = create surface in
        set_antialias t ANTIALIAS_SUBPIXEL;
        let edge = float edge -. margin and half = 0.5 *. margin in

        (* Filled rectangle, possibly with rounded corners. *)
        if fill then begin
            (* Multicolor display for mycorrhiza structures. *)
            if multicolor <> [] then begin
                let w = edge *. 0.5 in
                List.iteri (fun i color ->
                    rounded_rectangle ~rad:2.5 t
                        (half +. float (i / 2) *. w)
                        (half +. float (i mod 2) *. w) ~w ~h:w;
                    let r, g, b, a = AmfColor.parse_rgba color in
                    set_source_rgba t r g b a;
                    Cairo.fill t
                ) multicolor;
            end else begin
                if rounded then rounded_rectangle t half half ~w:edge ~h:edge
                else Cairo.rectangle t half half ~w:edge ~h:edge;
                let r, g, b, a = AmfColor.parse_rgba fill_color in
                set_source_rgba t r g b a;
                Cairo.fill t
            end;
        end;

        (* Centered symbol. *)
        if symbol = "" then begin
            (* Eye symbol for masked annotations. *)
            if eye then begin
                set_source_rgba t 0.0 0.0 0.0 1.0;
                let radius = 4.0 in
                let centre = margin +. 0.5 *. (edge -. radius) in 
                arc t centre centre ~r:radius ~a1:0.0 ~a2:twopi;
                Cairo.fill t;
                save t;
                translate t centre centre;
                scale t (16.0 /. 2.0) (10.0 /. 2.0);
                arc t 0.0 0.0 ~r:1.0 ~a1:0.0 ~a2:twopi;
                restore t;
                Cairo.stroke t;
                set_source_rgba t 1.0 0.0 0.0 1.0;
                move_to t (2.0 *. margin) (2.0 *. margin);
                line_to t (edge -. margin) (edge -. margin);
                Cairo.stroke t;
            (* Lock symbol for non-editable tiles. *)
            end else if lock then begin
                let r, g, b, a = AmfColor.parse_rgba dash_color in
                set_source_rgba t r g b a;
                set_line_width t 2.0;
                let w = 14.0 and h = 10.0 in
                let centre = margin +. 0.5 *. edge in
                arc t (centre -. 2.0) (centre -. 0.45 *. h)
                    ~r:6.0 ~a1:pi ~a2:0.0;
                rounded_rectangle t
                    (centre -. 0.65 *. w)
                    (centre -. 0.45 *. h) ~w ~h;
                Cairo.stroke t;
                arc t (centre -. 2.0) (centre +. 1.0)
                    ~r:2.5 ~a1:0.0 ~a2:twopi;
                Cairo.fill t
            end
        end else begin
            let r, g, b, a = AmfColor.parse_rgba symbol_color in
            set_source_rgba t r g b a;
            select_font_face t font_face ~weight:font_weight;
            set_font_size t font_size;
            let te = text_extents t symbol in
            let centre = half +. 0.5 *. edge in 
            move_to t
                (centre -. (te.x_bearing +. 0.5 *. te.width)) 
                (centre -. (te.y_bearing +. 0.5 *. te.height));
            show_text t symbol;
        end;

        (* Solid or dashed stroke. *)
        if stroke || Array.length dash > 0 then begin
            let r, g, b, a = AmfColor.parse_rgba dash_color in
            set_source_rgba t r g b a;
            set_line_width t line_width;
            set_dash t dash;
            rounded_rectangle t half half ~w:edge ~h:edge;
            Cairo.stroke t
        end;
        surface

    (* Specialized versions. *)
    let cursor dash_color x = draw 
        ~margin:0.0
        ~fill:false
        ~line_width:5.0
        ~stroke:true
        ~dash_color x

    let dashed dash_color x = draw
        ~eye:true
        ~dash:[|2.0|]
        ~line_width:1.5
        ~dash_color x

    let locked dash_color x = draw
        ~lock:true
        ~dash:[|2.0|]
        ~fill_color:"#FFFFFF90"
        ~line_width:1.5
        ~dash_color x

    let empty dash_color x = draw
        ~stroke:true
        ~fill_color:"#FFFFFFFF"
        ~line_width:1.5
        ~dash_color x

    let filled ?symbol fill_color x =
        let f = draw ~rounded:true ~stroke:true in
        match symbol with 
        | Some "×" -> f ~fill_color:"#FFFFFF90" ~dash_color:"#80808090"
            ~dash:[|2.0|] ~line_width:1.5 x
        | _ -> f ~fill_color ?symbol x
        
    let colors t x = draw ~multicolor:t ~stroke:true  x

end



module Prediction = struct
    
    (* Computes radius, taking margins into account. *)
    let radius ?(margin = 2.0) edge = (edge -. 2.0 *. margin) /. 2.0

    (* Computes centre, taking margins into account. *)
    let centre ?(margin = 2.0) edge = margin +. (radius ~margin edge)

    (* Draw filled background of any color (defaults to light grey). *)
    let draw_background ?(color = "#B3B3B3") context centre radius =
        let r, g, b = AmfColor.parse_rgb color in
        set_source_rgba context r g b AmfColor.opacity;
        arc context centre centre ~r:radius ~a1:0.0 ~a2:twopi;
        fill context

    (* Draw rings corresponding to probabilities of 1/3, 2/3 and 1. *)
    let draw_rings ?(color = "#606060") ?(init = 1) context centre radius =
        assert (init >= 0 && init <= 3);
        let r, g, b = AmfColor.parse_rgb color in
        set_source_rgba context r g b 1.0;
        for i = init to 3 do
            let r = float i /. 3.0 *. radius in
            arc context centre centre ~r ~a1:0.0 ~a2:twopi;
            stroke context;
        done

    (* Draw a filled dot at the given coordinates. *)
    let draw_dot ?(color = "#606060") context x y =
        let r, g, b = AmfColor.parse_rgb color in
        set_source_rgba context r g b 1.0;
        arc context x y ~r:1.0 ~a1:0.0 ~a2:twopi;
        fill context

    (* Draw radar polyline surface. *)
    let draw_polyline t segm =
        Path.sub t;
        set_source_rgba t 0.0 0.0 0.0 AmfColor.opacity;
        List.iteri (fun i (x, y) ->
            match i with
            | 0 -> move_to t x y
            | _ -> line_to t x y
        ) segm;
        Path.close t;
        set_source_rgba t 1.0 1.0 1.0 0.65;
        fill t

    (* Circle filled with a uniform color. *)
    let filled ?margin color edge =
        assert (edge > 0);
        let context, surface = square edge in
        let edge = float edge in
        let radius = radius ?margin edge
        and centre = centre ?margin edge in
        draw_background ~color context centre radius;
        draw_rings ~init:3 context centre radius;
        surface

    (* Circle filled with sectors. *)
    let pie_chart ?(margin = 2.0) weights colors edge =
        assert List.(length weights = length colors);
        let context, surface = square edge in
        let edge = float edge in
        let radius = radius ~margin edge
        and centre = centre ~margin edge in
        draw_rings ~init:3 context centre radius;
        (* Draw pie chart sectors. *)
        let draw_sector context a1 a2 color =
            move_to context centre centre;
            arc context centre centre ~r:radius ~a1 ~a2;
            let r, g, b = AmfColor.parse_rgb color in
            set_source_rgba context r g b AmfColor.opacity;
            fill context
        in
        (* Generate sectors. "1.0 -. x" is needed for sorting, see below. *)
        let _, sectors = List.fold_left2
            (fun (a1, res) w color ->
                let a2 = a1 +. twopi *. w in
                let f () = draw_sector context a1 a2 color in
                a2, (1.0 -. w, f) :: res
            ) (0.0, []) weights colors
        in
        (* Sort sectors so the smallest are the latest drawn. *)
        let sorted_sectors = List.sort
            (fun x y -> 
                compare (fst x) (fst y)
            ) sectors
        in
        (* Draw sectors. *)
        List.iter (fun x -> snd x ()) sorted_sectors;
        (* Draw pie chart decoration (a small centered dot). *)
        draw_dot context centre centre;
        surface

    let radar ?(margin = 2.0) prob_list colors edge =
        let context, surface = square edge in
        let edge = float edge in
        (* edge = margin + radius + radius + margin. *)
        let radius = radius ~margin edge
        and centre = centre ~margin edge in
        draw_background context centre radius;
        draw_rings context centre radius;
        (* Polar coordinates centered at (centre, centre). *)
        let calc_xy_and_df (segm, dots, angle) color prob =
            let x = prob *. radius *. cos angle +. centre
            and y = prob *. radius *. sin angle +. centre in
            let f () = draw_dot ~color context x y in
            ((x, y) :: segm, f :: dots, angle +. twopi4)
        in
        let xy, df, _ =
            List.fold_left2 calc_xy_and_df
            ([], [], pi4) colors prob_list
        in
        (* Draw radar surface, then dots. *)
        draw_polyline context xy;
        List.iter (fun f -> f ()) df;
        surface
end



module Legend = struct

    let palette ?(step = 12) edge =
        let colors = AmfUI.Predictions.get_colors () in
        let len = Array.length colors in
        let surface = Image.(create ARGB32 ~w:(step * len + 100) ~h:edge) in
        let t = create surface in
        set_antialias t ANTIALIAS_NONE;
        Array.iteri (fun i color ->
            let r, g, b, a = AmfColor.parse_rgba color in
            set_source_rgba t r g b a;
            Cairo.rectangle t (float (step * i + 50)) 0.0
                ~w:(float step)
                ~h:(float edge);
            fill t;
            stroke t;
        ) colors;
        set_antialias t ANTIALIAS_SUBPIXEL;
        select_font_face t "Arial" ~slant:Italic;
        set_font_size t 14.0;
        set_source_rgba t 0.0 0.0 0.0 1.0;
        let te = text_extents t "ggg" in
        move_to t 
            (50.0 -. te.width -. 5.0)
            (float edge /. 2.0 +. te.height /. 2.0);
        show_text t "low";
        move_to t
            (float (50 + step * len + 5))
            (float edge /. 2.0 +. te.height /. 2.0);
        show_text t "high";
        surface

    let classes () =
        let level = AmfUI.Levels.current () in
        let symbs = AmfLevel.symbols level
        and colors = AmfLevel.colors level in
        let len = List.length colors in
        let margin = 8 in
        let w = 140 * len + 2 * margin and h = 30 + 2 * margin in
        let surface = Image.(create ARGB32 ~w ~h) in
        let t = create surface in
        set_antialias t ANTIALIAS_SUBPIXEL;
        set_source_rgba t 0.4 0.4 0.4 1.0;
        Cairo.rectangle t 0.0 0.0 ~w:(float w) ~h:(float h);
        stroke t;
        let index = ref 0 in
        select_font_face t "Arial";
        set_font_size t 14.0;
        let te = text_extents t "M" in
        List.iter2 (fun symb color ->
            let r, g, b = AmfColor.parse_rgb color in
            set_source_rgba t r g b AmfColor.opacity;
            let x = float (margin + 140 * !index) in
            arc t (x +. 15.0) (float margin +. 15.0) ~r:15.0 ~a1:0.0 ~a2:twopi;
            fill t;
            stroke t;
            set_source_rgba t 0.0 0.0 0.0 1.0;
            let x = x +. 32.0 and y = float margin +. 15.0 +. te.height /. 2.0 in
            move_to t x y;
            show_text t symb;
            incr index
        ) symbs colors;
        surface
 
end
