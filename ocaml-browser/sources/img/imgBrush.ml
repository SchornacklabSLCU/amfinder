(* CastANet Browser - imgPaint.ml *)

module Aux = struct
    open Scanf

    let parse_html_color =
      let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
      fun s -> sscanf s "#%02x%02x%02x%02x" (fun r g b a -> f r, f g, f b, f a)

    let pi = acos (-1.0)

    let varrow color edge =
        assert (edge > 0); 
        let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = parse_html_color color in
        Cairo.set_source_rgba t r g b a;
        let edge_m = float edge -. 4.0 in
        let ini = 2.0 in
        let r = edge_m /. 2.0 in
        let top =  1.0 *. r /. 2.0 in 
        let sup = sqrt (r *. r -. (top *. top)) in
        Cairo.move_to t (ini +. r) (ini +. edge_m);
        Cairo.line_to t (ini +. r -. sup) (ini +. r -. top);
        Cairo.line_to t (ini +. r +. sup) (ini +. r -. top);
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let harrow color edge =
        assert (edge > 0); 
        let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = parse_html_color color in
        Cairo.set_source_rgba t r g b a;
        let edge_m = float edge -. 4.0 in
        let ini = 2.0 in
        let r = edge_m /. 2.0 in
        let top =  1.0 *. r /. 2.0 in 
        let sup = sqrt (r *. r -. (top *. top)) in
        Cairo.move_to t (ini +. edge_m) (ini +. r);
        Cairo.line_to t (ini +. r -. top) (ini +. r -. sup);
        Cairo.line_to t (ini +. r -. top) (ini +. r +. sup);
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let circle color edge =
        assert (edge > 0); 
        let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = parse_html_color color in
        Cairo.set_source_rgba t r g b a;
        let radius = float edge /. 2.0 in
        Cairo.arc t radius radius ~r:radius ~a1:0.0 ~a2:(2.0 *. pi);
        Cairo.fill t;
        Cairo.stroke t;
        surface

    let square color edge =
        assert (edge > 0); 
        let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = parse_html_color color in
        Cairo.set_source_rgba t r g b a;
        let edge = float edge in
        Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
        Cairo.fill t;
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
    let cursor = memo Aux.square "#cc0000cc"    
    let pointer = memo Aux.square "#cc000066"

    let margin_square_off = memo Aux.square "#ffffffff"
    let margin_square_on = memo Aux.circle "#000000FF"

    let harrow = memo Aux.harrow "#000000FF"
    let varrow = memo Aux.varrow "#000000FF"

    let palette index edge =
        let color = (AmfUI.Predictions.get_colors ()).(index) in
        Aux.square color edge

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

    let edge = min (ui_width / (source#columns + 2)) 
                   (ui_height / (source#rows + 2)) in

    let cursor_edge = max 1 (edge / 2) in
    let cursor_more = (edge - cursor_edge) / 2 in

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

    method private margin ?(sync = false) ~r ~c surface =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c:0 - edge + cursor_more) 
        and y = float (self#y ~r + cursor_more) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        let x = float (self#x ~c + cursor_more) 
        and y = float (self#y ~r:0 - edge + cursor_more) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync ()

    method clear_margin ?sync ~r ~c () =
        let surface = Surface.margin_square_off cursor_edge in
        self#margin ?sync ~r ~c surface

    method private margin_marks ?(sync = false) ~r ~c () =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c:0 - edge + cursor_more) 
        and y = float (self#y ~r + cursor_more) in
        let surface = Surface.harrow cursor_edge in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        let surface = Surface.varrow cursor_edge in
        let x = float (self#x ~c + cursor_more) 
        and y = float (self#y ~r:0 - edge + cursor_more) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync ()

    method cursor ?sync ~r ~c () =
        self#surface ~r ~c (Surface.cursor edge);
        self#margin_marks ?sync ~r ~c ()

    method pointer ?sync ~r ~c () =
        self#surface ?sync ~r ~c (Surface.pointer edge)

    method annotation ?sync ~r ~c level chr =
        self#surface ?sync ~r ~c (Surface.layer level chr edge)

    method prediction ?sync ~r ~c (chr : char) prob =
        let index = truncate (24.0 *. prob)
            |> max 0
            |> min 24
        in self#surface ?sync ~r ~c (Surface.palette index edge)

end



let create x = new brush x 
