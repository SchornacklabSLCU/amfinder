(* CastANet Browser - imgPaint.ml *)

open Scanf
open Printf

module Aux = struct

    let parse_html_color =
      let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
      fun s -> sscanf s "#%02x%02x%02x%02x" (fun r g b a -> f r, f g, f b, f a)

    let pi = acos (-1.0)

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


    let varrow color edge =
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

    let harrow color edge =
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
        Cairo.arc t radius radius ~r:radius ~a1:0.0 ~a2:(2.0 *. pi);
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let square color edge =
        let t, surface = initialize color edge in
        let edge = float edge in
        Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let unfilled color edge =
        let t, surface = initialize color edge in
        Cairo.set_line_width t 5.0;
        let edge = float edge in
        Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
        Cairo.stroke t;
        surface

    let palette ?(step = 12) colors edge =
        let len = Array.length colors in
        let surface = Cairo.Image.(create ARGB32 ~w:(step * len) ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        Array.iteri (fun i color ->
            let r, g, b, a = parse_html_color color in
            Cairo.set_source_rgba t r g b a;
            Cairo.rectangle t (float (step * i)) 0.0 ~w:(float step) ~h:(float edge);
            Cairo.fill t;
            Cairo.stroke t;
        ) colors;
        Cairo.set_source_rgba t 0.0 0.0 0.0 1.0;
        Cairo.set_line_width t 2.0;
        Cairo.rectangle t 0.0 0.0 ~w:(float (step * len)) ~h:(float edge);
        Cairo.stroke t;
        surface

end



module Surface = struct
    let memo f color =
        let rec get = ref (
            fun edge ->
                let res = f color edge in
                get := (fun _ -> res);
                res
        ) in
        fun edge -> !get edge

    let joker = memo Aux.square "#00dd0099"
    let cursor = memo Aux.unfilled "#cc0000cc"    
    let pointer = memo Aux.square "#cc000066"

    let margin_square_off = memo Aux.square "#ffffffff"
    let margin_square_on = memo Aux.circle "#000000FF"

    let harrow = memo Aux.harrow "#FF0000FF"
    let varrow = memo Aux.varrow "#FF0000FF"

    let up_arrowhead = memo Aux.up_arrowhead "#FF0000FF"

    let palette index edge =
        let color = (AmfUI.Predictions.get_colors ()).(index) in
        Aux.circle color edge

    let full_palette ?step edge =
        let colors = AmfUI.Predictions.get_colors () in
        Aux.palette ?step colors edge

    let layers =
        List.map (fun level ->
            let surfaces = List.map2 (fun x y -> x, memo Aux.square y)
                (AmfLevel.to_header level)
                (AmfLevel.colors level)
            in level, surfaces
        ) AmfLevel.all_flags

    let layer level = function
        | '*' -> joker
        | chr -> List.(assoc chr (assoc level layers))
end



class brush (source : ImgTypes.source) =

    let ui_width = AmfUI.Drawing.width ()
    and ui_height = AmfUI.Drawing.height () in

    (* Extra blank space for drawings. *)
    let extra_rows = 2
    and extra_cols = 4 in

    let edge = min (ui_width / (source#columns + extra_cols)) 
                   (ui_height / (source#rows + extra_rows)) in

    let x_origin = (ui_width - edge * source#columns) / 2
    and y_origin = (ui_height - edge * source#rows) / 2 in

object (self)

    val mutable backcolor = "#ffffffff"

    method edge = edge
    method x_origin = x_origin
    method y_origin = y_origin

    method private x ~c = x_origin + c * edge
    method private y ~r = y_origin + r * edge

    method backcolor = backcolor
    method set_backcolor x = backcolor <- x

    method sync () = AmfUI.Drawing.synchronize ()

    method background ?(sync = true) () =
        let t = AmfUI.Drawing.cairo () in
        let r, g, b, a = Aux.parse_html_color backcolor in
        Cairo.set_source_rgba t r g b a;
        let w = float @@ AmfUI.Drawing.width () 
        and h = float @@ AmfUI.Drawing.height () in
        Cairo.rectangle t 0.0 0.0 ~w ~h;
        Cairo.fill t;
        Cairo.stroke t;
        if sync then self#sync ()

    method pixbuf ?(sync = false) ~r ~c pixbuf =
        assert (GdkPixbuf.get_width pixbuf = edge);
        assert (GdkPixbuf.get_height pixbuf = edge);
        let pixmap = AmfUI.Drawing.pixmap () in
        pixmap#put_pixbuf
            ~x:(self#x ~c)
            ~y:(self#y ~r) pixbuf;
        if sync then self#sync ()

    method surface ?(sync = false) ~r ~c surface =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c)
        and y = float (self#y ~r) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync ()

    method palette ?(sync = false) () =
        let t = AmfUI.Drawing.cairo ()
        and y = float (self#y ~r:source#rows + 5)
        and surface = Surface.full_palette edge in
        let rem = source#columns * edge - Cairo.Image.get_width surface in
        let x = float x_origin +. float rem /. 2.0 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync ()

    method private margin ?(sync = false) ~r ~c surface =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c:0 - edge) 
        and y = float (self#y ~r) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        let x = x -. float edge in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        let x = float (self#x ~c) 
        and y = float (self#y ~r:0 - edge) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        let y = y -. float edge in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync ()

    method clear_margin ?sync ~r ~c () =
        let surface = Surface.margin_square_off edge in
        self#margin ?sync ~r ~c surface

    method private margin_marks ?(sync = false) ~r ~c () =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c:0 - edge) 
        and y = float (self#y ~r) in
        let surface = Surface.harrow edge in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        Cairo.select_font_face t "Arial";
        Cairo.set_font_size t 10.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;
        let text = sprintf "%04d" r in
        let te = Cairo.text_extents t text in
        Cairo.move_to t (x -. 0.5 *. te.Cairo.width) (y +. float edge /. 2.0 -. te.Cairo.y_bearing /. 2.0);
        Cairo.show_text t text;
        let surface = Surface.varrow edge in
        let x = float (self#x ~c) 
        and y = float (self#y ~r:0 - edge) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        Cairo.select_font_face t "Arial";
        Cairo.set_font_size t 10.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;
        let text = sprintf "%04d" c in
        let te = Cairo.text_extents t text in
        Cairo.move_to t (x +. float edge /. 2.0 -. te.Cairo.width /. 2.0) (y +. 10.0);
        Cairo.show_text t text;
        if sync then self#sync ()

    method private index_of_prob x = truncate (24.0 *. x) |> max 0 |> min 24

    (* TODO: cleanup first! *)
    method probability ?(sync = false) prob =
        (* clean up *)
        let len = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = source#columns * edge in
        let surface = Cairo.Image.(create ARGB32 ~w:((len + 2) * 12) ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = Aux.parse_html_color backcolor in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float grid_width) ~h:(float edge);
        Cairo.fill t;
        Cairo.stroke t;
        let t = AmfUI.Drawing.cairo () in
        let index = self#index_of_prob prob in
        let rem = grid_width - 12 * len in
        let x = float x_origin +. float rem /. 2.0
        and y = float (self#y ~r:source#rows + 5 + edge + 5) in
        Cairo.set_source_surface t surface
            (float x_origin +. float (grid_width - 12 * (len + 2)) /. 2.0)
            (y);
        Cairo.paint t;
        let x = x +. float (index + 1) *. 12.0 in
        let surface = Surface.up_arrowhead 12 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        Cairo.select_font_face t "Arial";
        Cairo.set_font_size t 10.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;
        let text = sprintf "%.02f" prob in
        let te = Cairo.text_extents t text in
        Cairo.move_to t (x +. 6.0 -. te.Cairo.width /. 2.0) (y +. 10.0 +. te.Cairo.height +. 5.0);
        Cairo.show_text t text;
        if sync then self#sync ()

    method cursor ?sync ~r ~c () =
        self#surface ~r ~c (Surface.cursor edge);
        self#margin_marks ?sync ~r ~c ()

    method pointer ?sync ~r ~c () =
        self#surface ?sync ~r ~c (Surface.pointer edge)

    method annotation ?sync ~r ~c level chr =
        self#surface ?sync ~r ~c (Surface.layer level chr edge)

    method prediction ?sync ~r ~c (chr : char) x =
        let index = self#index_of_prob x in
        self#surface ?sync ~r ~c (Surface.palette index edge)

end



let create x = new brush x 
