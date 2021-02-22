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
open Morelib
open AmfConst

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
      ?(font_face = "Arial")
      ?(base_font_size = 16.0)
      ?(font_weight = Bold)
      ?(dash = [||])
      ?(stroke = false)
      ?(dash_color = "#808080ff")
      ?(line_width = 1.0)
      ?(fill = true)
      ?(fill_color = "#FFFFFFB0")
      ?(multicolor = [])
      ?(desaturate = false)
      ?(grayscale = false) edge =

        (* Simple checks. Other values may be malformed as well. *)
        assert (line_width > 0.0
             && margin >= 0.0
             && mod_float margin 2.0 = 0.0);

        (* Select color parser based on color/gray mode. *)
        let color_parser = match desaturate with
            | true -> AmfColor.parse_desaturate
            | false -> AmfColor.parse_rgba 
        in

        (* Make font size relative to tile edge. *)
        let font_size = float edge *. base_font_size /. (float _EDGE_) in

        let surface = Image.(create ARGB32 ~w:edge ~h:edge) in
        let t = create surface in
        set_antialias t ANTIALIAS_SUBPIXEL;
        let edge = float edge -. margin and half = 0.5 *. margin in

        (* Filled rectangle, possibly with rounded corners. *)
        if fill then begin
            (* Multicolor display for mycorrhiza structures. *)
            if multicolor <> [] then begin
                let w = edge *. 0.5 in
                let ys = [|0; 1; 1; 0|] in
                List.iteri (fun i color ->
                    rounded_rectangle ~rad:2.5 t
                        (half +. float (i / 2) *. w)
                        (half +. float ys.(i) *. w) ~w ~h:w;
                    let r, g, b, a = color_parser color in
                    set_source_rgba t r g b a;
                    Cairo.fill t
                ) multicolor;
            end else begin
                rounded_rectangle t half half ~w:edge ~h:edge;
                let clr = if grayscale then "#B0B0B0FF" else fill_color in
                let r, g, b, a = color_parser clr in
                set_source_rgba t r g b a;
                Cairo.fill t
            end;
        end;

        (* Centered symbol. *)
        if symbol = "" then begin
            (* TODO: make this an optional parameter? *)
            set_source_rgba t 0.6 0.6 0.6 1.0;
            (* Eye symbol for masked annotations. *)
            if eye then begin
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
                move_to t (2.5 *. margin) (2.5 *. margin);
                line_to t (edge -. 1.5 *. margin) (edge -. 1.5 *. margin);
                Cairo.stroke t;
            (* Lock symbol for non-editable tiles. *)
            end else if lock then begin
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
            let r, g, b, a = color_parser dash_color in
            set_source_rgba t r g b a;
            set_line_width t line_width;
            set_dash t dash;
            rounded_rectangle t half half ~w:edge ~h:edge;
            Cairo.stroke t
        end;
        surface

    (* Specialized versions. *)
    let cursor x = draw 
        ~margin:0.0
        ~fill:false
        ~line_width:5.0
        ~stroke:true
        ~dash_color:"#ff0000ff" x

    let dashed x = draw
        ~eye:true
        ~dash:[|2.0|]
        ~line_width:1.5 x

    let locked x = draw
        ~lock:true
        ~dash:[|2.0|]
        ~fill_color:"#f8f8f7ff"
        ~line_width:1.5 x

    let empty dash_color x = draw
        ~stroke:true
        ~fill_color:"#FFFFFFFF"
        ~line_width:1.5
        ~dash_color x

    let filled ?symbol ?(force_symbol = false) ?base_font_size ?grayscale fill_color x =
        let f = draw ?base_font_size ?grayscale ~rounded:true ~stroke:true in
        match symbol with 
        | Some "×" -> let symbol = if force_symbol then symbol else None in
            f ?symbol ~fill_color ~dash_color:"#808080ff"
            ~dash:[|2.0|] ~line_width:1.5 x
        | _ -> f ~fill_color ?symbol x
        
    let colors ?symbol ?symbol_color ?base_font_size t x =
        draw ?symbol ?symbol_color ?base_font_size ~multicolor:t ~stroke:true x

end



module Prediction = struct
    
    (* Computes radius, taking margins into account. *)
    let radius ?(margin = 2.0) edge = (edge -. 2.0 *. margin) /. 2.0

    (* Computes centre, taking margins into account. *)
    let centre ?(margin = 2.0) edge = margin +. (radius ~margin edge)

    (* Draw filled background of any color (defaults to light grey). *)
    let draw_background
      ?(color = "#B3B3B3")
      ?(opacity = AmfColor.opacity) context centre radius =
        let r, g, b = AmfColor.parse_rgb color in
        set_source_rgba context r g b opacity;
        arc context centre centre ~r:radius ~a1:0.0 ~a2:twopi;
        fill context

    (* Draw rings corresponding to probabilities of 1/3, 2/3 and 1. *)
    let draw_rings ?(color = "#000000") ?(init = 1) context centre radius =
        assert (init >= 0 && init <= 3);
        let r, g, b = AmfColor.parse_rgb color in
        set_source_rgba context r g b 1.0;
        for i = init to 3 do
            let r = float i /. 3.0 *. radius in
            arc context centre centre ~r ~a1:0.0 ~a2:twopi;
            stroke context;
        done

    (* Draw a filled dot at the given coordinates. *)
    let draw_dot ?(color = "#000000") ?(radius = 3.0) context x y =
        let r, g, b = AmfColor.parse_rgb color in
        set_source_rgba context r g b 1.0;
        arc context x y ~r:radius ~a1:0.0 ~a2:twopi;
        set_line_width context 2.0;
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
        set_source_rgba t 0.5 0.5 0.5 0.75;
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
        draw_dot ~radius:1.0 context centre centre;
        surface

    let radar_singleton ?(margin = 2.0) pos color edge =
        let context, surface = square edge in
        let edge = float edge in
        (* edge = margin + radius + radius + margin. *)
        let radius = radius ~margin edge
        and centre = centre ~margin edge in
        draw_background ~color:"#f8f8f7" ~opacity:1.0 context centre radius;
        draw_rings ~color:"#303030" context centre radius;
        let angle = -. 3.0 *. pi4 -. float pos *. twopi4 in
        let x = radius *. cos angle +. centre
        and y = radius *. sin angle +. centre in
        draw_dot ~color context x y;
        surface

    let radar ?(margin = 2.0) prob_list colors edge =
        let context, surface = square edge in
        let edge = float edge in
        (* edge = margin + radius + radius + margin. *)
        let radius = radius ~margin edge
        and centre = centre ~margin edge in
        draw_background ~color:"#f8f8f7" ~opacity:1.0 context centre radius;
        draw_rings ~color:"#303030" context centre radius;
        (* Polar coordinates centered at (centre, centre). *)
        let calc_xy_and_df (segm, dots, angle) color prob =
            let x = prob *. radius *. cos angle +. centre
            and y = prob *. radius *. sin angle +. centre in
            let f () = draw_dot ~color context x y in
            ((x, y) :: segm, f :: dots, angle -. twopi4)
        in
        let xy, df, _ =
            List.fold_left2 calc_xy_and_df
            ([], [], -.3.0 *. pi4) colors prob_list
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

    let sum ?(lim = -1) t =
        Array.fold_left (fun (j, s) n ->
            if lim = -1 then (-1, s + n) else
            if j < lim then (j + 1, s + n)
            else (j, s) 
        ) (0, 0) t |> snd

    let hspaces = function
        | true  -> [|110; 140; 120|]
        | false -> [|105; 85; 130; 75|]

    let classes () =
        let level = AmfUI.Levels.current () in
        let symbs = AmfLevel.symbols level
        and colors = AmfLevel.colors level in
        let len = List.length colors in
        let margin = 8 in
        let uni = hspaces (len = 3) in
        let w = sum uni + 2 * margin and h = 30 + 2 * margin in
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
            let x = float (margin + sum ~lim:!index uni)
            and y = float margin in
            if AmfUI.Levels.current () = AmfLevel.col then (
                arc t (x +. 15.0) (y +. 15.0) ~r:15.0 ~a1:0.0 ~a2:twopi;
                fill t
            ) else (
                (* Pseudo-radar with just one dot. *)
                let surface = Prediction.radar_singleton !index color 30 in
                set_source_surface t surface ~x ~y;
                paint t
            );
            set_source_rgba t 0.0 0.0 0.0 1.0;
            let x = x +. 32.0 and y = float margin +. 15.0 +. te.height /. 2.0 in
            move_to t x y;
            show_text t symb;
            incr index
        ) symbs colors;
        surface
 
end



module Icons = struct

    let filename ?(grayscale = false) ?(prefix = "") chr =
        let suf = if grayscale then "grey" else "rgba" in
        Printf.sprintf "%s%c_%s.png" prefix chr suf

    let myc_surface_from_char ?(grayscale = false) elt =
        let open AmfLevel in
        let symbs = AmfLevel.icon_text myc in
        let colors = List.map2 (fun chr clr ->
            if chr = elt then
                (if grayscale then "#B0B0B0FF" else clr)
            else "#FFFFFF00"
        ) (to_header myc) (colors myc) in
        Annotation.colors
            ~symbol:(List.assoc elt symbs)
            ~symbol_color:"#808080FF"
            ~base_font_size:24.0
            colors _LARGE_

    let make_surface () =
        let surface = Image.create Image.ARGB32 ~w:_LARGE_ ~h:_LARGE_ in
        let context = create surface in
        set_line_width context 1.0;
        set_antialias context ANTIALIAS_SUBPIXEL;
        set_source_rgba context 0.0 0.0 0.0 0.0;
        Cairo.rectangle context 0.0 0.0 ~w:(float _LARGE_) ~h:(float _LARGE_);
        fill context;
        surface, context

    let make_any_png f ?prefix ?(grayscale = false) level index chr color =
        let surface, context = make_surface ()
        and symbs = AmfLevel.icon_text level in
        let icon = f index level symbs grayscale chr color in
        Cairo.set_source_surface context icon ~x:0.0 ~y:0.0;
        Cairo.paint context;
        Cairo.PNG.write surface (filename ?prefix ~grayscale chr)

    let get_annotation_icon _ level symbs grayscale chr color =
        if AmfLevel.is_col level then
            Annotation.filled
                ~symbol:(List.assoc chr symbs)
                ~force_symbol:true
                ~base_font_size:(if chr = 'X' then 40.0 else 20.0)
                ~grayscale color _LARGE_
        else myc_surface_from_char ~grayscale chr

    let get_prediction_icon index level _ _ _ color =
        if AmfLevel.is_col level then Prediction.pie_chart [1.0] [color] _LARGE_
        else Prediction.radar_singleton index color _LARGE_

    let make_pred_png = make_any_png get_prediction_icon
    let make_annot_png = make_any_png get_annotation_icon

    let make_frame color png_file =
        let surface, context = make_surface () in
        let icon = Annotation.filled color _LARGE_ in
        Cairo.set_source_surface context icon ~x:0.0 ~y:0.0;
        Cairo.paint context;
        Cairo.PNG.write surface png_file

    let make_lock png_file =
        let surface, context = make_surface () in
        let icon = Annotation.locked _LARGE_ in
        Cairo.set_source_surface context icon ~x:0.0 ~y:0.0;
        Cairo.paint context;
        Cairo.PNG.write surface png_file

    let make ?grayscale () =
        (* Annotations. *)
        List.iter (fun level ->
            List.iteri2 (make_annot_png ?grayscale level)
                (AmfLevel.to_header level)
                (AmfLevel.colors level)
        ) AmfLevel.[col; myc];
        (* Predictions. *)
        List.iter (fun level ->
            List.iteri2 (make_pred_png ~prefix:"Pred" ?grayscale level)
                AmfLevel.(to_header level)
                AmfLevel.(colors level)
        ) AmfLevel.[col; myc]

    let generate () =
        make ();
        make ~grayscale:true ();
        make_lock "lock.png";
        make_frame "#88aa00ff" "add.png";
        make_frame "#aa0000ff" "remove.png";
        make_frame "#b0b0b0ff" "inactive.png"

    (* let _ = generate () *)
end
