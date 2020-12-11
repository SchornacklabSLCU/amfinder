(* The Automated Mycorrhiza Finder version 1.0 - amfSurface.ml *)

type edge = int
type color = string

let pi = acos (-1.0)
let two_pi = 2.0 *. pi

let initialize color edge =
    assert (edge > 0); 
    let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    let r, g, b, a = AmfColor.parse_rgba color in
    Cairo.set_source_rgba t r g b a;
    t, surface

module Create = struct
    let rectangle ~width ~height ~color () =
        assert (width > 0 && height > 0);
        let surface = Cairo.Image.(create ARGB32 ~w:width ~h:height) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = AmfColor.parse_rgba color in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float width) ~h:(float height);
        Cairo.fill t;
        Cairo.stroke t;
        t, surface

end



let arrowhead color edge =
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



let circle ?(margin = 2.0) color edge =
    let t, surface = initialize color edge in
    let edge = float edge -. margin in
    let radius = 0.5 *. edge in
    let centre = 0.5 *. margin +. radius in
    Cairo.arc t centre centre ~r:radius ~a1:0.0 ~a2:two_pi;
    Cairo.fill t;
    Cairo.stroke t;
    surface



module Square = struct

    (* See https://www.cairographics.org/samples/rounded_rectangle/ *)
    let rounded_rectangle t x y ~w ~h =
        let degrees = pi /. 180.0
        and corner_radius = h /. 5.0 in
        Cairo.Path.sub t;
        Cairo.arc t (x +. w -. corner_radius)  
                    (y +. corner_radius)
                    ~r:corner_radius
                    ~a1:(-90.0 *. degrees) ~a2:0.0;
        Cairo.arc t (x +. w -. corner_radius)
                    (y +. h -. corner_radius)
                    ~r:corner_radius
                    ~a1:0.0 ~a2:(90.0 *. degrees);
        Cairo.arc t (x +. corner_radius)
                    (y +. h -. corner_radius)
                    ~r:corner_radius
                    ~a1:(90.0 *. degrees) ~a2:(180.0 *. degrees);
        Cairo.arc t (x +. corner_radius)
                    (y +. corner_radius)
                    ~r:corner_radius
                    ~a1:(180.0 *. degrees) ~a2:(270.0 *. degrees);
        Cairo.Path.close t

    let draw 
      ?(eye = false)
      ?(lock = false)
      ?(margin = 2.0)
      ?(rounded = false)
      ?(symbol = "")
      ?(symbol_color = "#FFFFFFFF")
      ?(font_size = 16.0)
      ?(font_face = "Arial")
      ?(font_weight = Cairo.Bold)
      ?(dash = [||])
      ?(stroke = false)
      ?(dash_color = "#000000FF")
      ?(line_width = 1.5)
      ?(fill = true)
      ?(fill_color = "#FFFFFFB0")
      ?(multicolor = []) edge =

        (* Simple checks. Other values may be malformed as well. *)
        assert (font_size > 0.0
                 && line_width > 0.0
                 && margin >= 0.0
                 && mod_float margin 2.0 = 0.0);

        let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let edge = float edge -. margin and half = 0.5 *. margin in

        (* Filled rectangle, possibly with rounded corners. *)
        if fill then begin
            (* Multicolor display for mycorrhiza structures. *)
            if multicolor <> [] then begin
                let n = List.length multicolor in
                let w = edge /. (float n) in
                (* TODO: First and last should be round rectangles. *)
                Cairo.set_line_width t 1.0;
                List.iteri (fun i color ->
                    rounded_rectangle t (half +. float i *. w) half ~w ~h:edge;
                    let r, g, b, a = AmfColor.parse_rgba color in
                    Cairo.set_source_rgba t r g b a;
                    Cairo.fill t
                ) multicolor;
                rounded_rectangle t half half ~w:edge ~h:edge;
                let r, g, b, a = AmfColor.parse_rgba dash_color in
                Cairo.set_source_rgba t r g b a;
                Cairo.stroke t
            end else begin
                if rounded then rounded_rectangle t half half ~w:edge ~h:edge
                else Cairo.rectangle t half half ~w:edge ~h:edge;
                let r, g, b, a = AmfColor.parse_rgba fill_color in
                Cairo.set_source_rgba t r g b a;
                Cairo.fill t
            end;
        end;

        (* Centered symbol. *)
        if symbol = "" then begin
            (* Eye symbol for masked annotations. *)
            if eye then begin
                Cairo.set_source_rgba t 0.0 0.0 0.0 1.0;
                let radius = 4.0 in
                let centre = margin +. 0.5 *. (edge -. radius) in 
                Cairo.arc t centre centre ~r:radius ~a1:0.0 ~a2:two_pi;
                Cairo.fill t;
                Cairo.save t;
                Cairo.translate t centre centre;
                Cairo.scale t (16.0 /. 2.0) (10.0 /. 2.0);
                Cairo.arc t 0.0 0.0 ~r:1.0 ~a1:0.0 ~a2:two_pi;
                Cairo.restore t;
                Cairo.stroke t;
                Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;
                Cairo.move_to t (2.0 *. margin) (2.0 *. margin);
                Cairo.line_to t (edge -. margin) (edge -. margin);
                Cairo.stroke t;
            (* Lock symbol for non-editable tiles. *)
            end else if lock then begin
                let r, g, b, a = AmfColor.parse_rgba dash_color in
                Cairo.set_source_rgba t r g b a;
                Cairo.set_line_width t 2.0;
                let w = 14.0 and h = 10.0 in
                let centre = margin +. 0.5 *. edge in
                Cairo.arc t (centre -. 2.0) (centre -. 0.45 *. h)
                    ~r:6.0 ~a1:pi ~a2:0.0;
                rounded_rectangle t
                    (centre -. 0.65 *. w)
                    (centre -. 0.45 *. h) ~w ~h;
                Cairo.stroke t;
                Cairo.arc t (centre -. 2.0) (centre +. 1.0)
                    ~r:2.5 ~a1:0.0 ~a2:two_pi;
                Cairo.fill t
            end
        end else begin
            let r, g, b, a = AmfColor.parse_rgba symbol_color in
            Cairo.set_source_rgba t r g b a;
            Cairo.select_font_face t font_face ~weight:font_weight;
            Cairo.set_font_size t font_size;
            let te = Cairo.text_extents t symbol in
            let centre = half +. 0.5 *. edge in 
            Cairo.move_to t
                (centre -. Cairo.(te.x_bearing +. 0.5 *. te.width)) 
                (centre -. Cairo.(te.y_bearing +. 0.5 *. te.height));
            Cairo.show_text t symbol;
        end;

        (* Solid or dashed stroke. *)
        if stroke || Array.length dash > 0 then begin
            let r, g, b, a = AmfColor.parse_rgba dash_color in
            Cairo.set_source_rgba t r g b a;
            Cairo.set_line_width t line_width;
            Cairo.set_dash t dash;
            Cairo.rectangle t half half ~w:edge ~h:edge;
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
        ~margin:4.0
        ~dash:[|2.0|]
        ~dash_color x

    let locked dash_color x = draw
        ~lock:true
        ~margin:4.0
        ~dash:[|2.0|]
        ~fill_color:"#FFFFFF90"
        ~dash_color x

    let empty dash_color x = draw
        ~margin:4.0
        ~stroke:true
        ~fill_color:"#FFFFFFFF"
        ~dash_color x

    let filled ?symbol fill_color x =
        (* The symbol × is small and needs greater font size. *)
        let font_size = match symbol with Some "×" -> Some 24.0 | _ -> None in
        draw ~rounded:true ?symbol ?font_size ~fill_color x
        
    let colors t x = draw ~multicolor:t x
end



let prediction_palette ?(step = 12) colors edge =
    let len = Array.length colors in
    let surface = Cairo.Image.(create ARGB32 ~w:(step * len + 100) ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_NONE;
    Array.iteri (fun i color ->
        let r, g, b, a = AmfColor.parse_rgba color in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t (float (step * i + 50)) 0.0
            ~w:(float step)
            ~h:(float edge);
        Cairo.fill t;
        Cairo.stroke t;
    ) colors;
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    Cairo.select_font_face t "Arial" ~slant:Cairo.Italic;
    Cairo.set_font_size t 14.0;
    Cairo.set_source_rgba t 0.0 0.0 0.0 1.0;
    let te = Cairo.text_extents t "ggg" in
    Cairo.move_to t 
        (50.0 -. te.Cairo.width -. 5.0)
        (float edge /. 2.0 +. te.Cairo.height /. 2.0);
    Cairo.show_text t "low";
    Cairo.move_to t
        (float (50 + step * len + 5))
        (float edge /. 2.0 +. te.Cairo.height /. 2.0);
    Cairo.show_text t "high";
    surface

let annotation_legend symbs colors =
    assert List.(length symbs = length colors);
    let len = List.length colors in
    let margin = 8 in
    let w = 140 * len + 2 * margin and h = 30 + 2 * margin in
    let surface = Cairo.Image.(create ARGB32 ~w ~h) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    Cairo.set_source_rgba t 0.4 0.4 0.4 1.0;
    Cairo.rectangle t 0.0 0.0 ~w:(float w) ~h:(float h);
    Cairo.stroke t;
    let index = ref 0 in
    Cairo.select_font_face t "Arial";
    Cairo.set_font_size t 14.0;
    let te = Cairo.text_extents t "M" in
    List.iter2 (fun symb color ->
        let r, g, b = AmfColor.parse_rgb color in
        Cairo.set_source_rgba t r g b AmfColor.opacity;
        let x = float (margin + 140 * !index) in
        Cairo.arc t (x +. 15.0) (float margin +. 15.0) ~r:15.0 ~a1:0.0 ~a2:(2. *. acos(-1.0));
        Cairo.fill t;
        Cairo.stroke t;
        Cairo.set_source_rgba t 0.0 0.0 0.0 1.0;
        let x = x +. 32.0 and y = float margin +. 15.0 +. te.Cairo.height /. 2.0 in
        Cairo.move_to t x y;
        Cairo.show_text t symb;
        incr index
    ) symbs colors;
    surface

let pie_chart ?(margin = 2.0) prob_list colors edge =
    let t, surface = initialize "#ffffffff" edge in
    let edge = float edge -. margin in
    let radius = 0.5 *. edge in
    let from = ref 0.0 in
    List.iter2 (fun x clr ->
        let rad = two_pi *. x in  
        Cairo.move_to t radius radius;
        let a2 = !from +. rad in
        let centre = 0.5 *. margin +. radius in
        Cairo.arc t centre centre ~r:radius ~a1:!from ~a2;
        from := a2;
        Cairo.Path.close t;
        let r, g, b = AmfColor.parse_rgb clr in
        Cairo.set_source_rgba t r g b AmfColor.opacity;
        Cairo.fill t;
        Cairo.stroke t;
    ) prob_list colors;
    surface

module Dir = struct
    let top ~background ~foreground edge =
        let t, surface = initialize background edge in
        let r, g, b, a = AmfColor.parse_rgba foreground in
        Cairo.set_source_rgba t r g b a;
        Cairo.move_to t (float edge /. 2.0) 0.0;
        Cairo.line_to t 0.0 (float edge);
        Cairo.line_to t (float edge) (float edge);
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let bottom ~background ~foreground edge =
        let t, surface = initialize background edge in
        let r, g, b, a = AmfColor.parse_rgba foreground in
        Cairo.set_source_rgba t r g b a;
        Cairo.move_to t (float edge /. 2.0) (float edge);
        Cairo.line_to t 0.0 0.0;
        Cairo.line_to t (float edge) 0.0;
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let left ~background ~foreground edge =
        let t, surface = initialize background edge in
        let r, g, b, a = AmfColor.parse_rgba foreground in
        Cairo.set_source_rgba t r g b a;
        Cairo.move_to t 0.0 (float edge /. 2.0);
        Cairo.line_to t (float edge) 0.0;
        Cairo.line_to t (float edge) (float edge);
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let right ~background ~foreground edge =
        let t, surface = initialize background edge in
        let r, g, b, a = AmfColor.parse_rgba foreground in
        Cairo.set_source_rgba t r g b a;
        Cairo.move_to t (float edge) (float edge /. 2.0);
        Cairo.line_to t 0.0 0.0;
        Cairo.line_to t 0.0 (float edge);
        Cairo.fill t;
        Cairo.stroke t;
        surface
end
