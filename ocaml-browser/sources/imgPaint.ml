(* CastANet Browser - imgPaint.ml *)

module Aux = struct
    open Scanf

    let parse_html_color =
      let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
      fun s -> sscanf s "#%02x%02x%02x%02x" (fun r g b a -> f r, f g, f b, f a)

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
    let memo color =
        let rec get = ref (
            fun edge ->
                let res = Aux.square color edge in
                get := (fun _ -> res);
                res
        ) in
        fun edge -> !get edge

    let joker = memo "#00dd0099"
    let cursor = memo "#cc0000cc"    
    let pointer = memo "#cc000066"

    let layers =
        List.map (fun level ->
            let surfaces = List.map2 (fun x y -> x, memo y)
                (CLevel.to_header level)
                (CLevel.colors level)
            in level, surfaces
        ) CLevel.all_flags

    let layer level = function
        | '*' -> joker
        | chr -> List.(assoc chr (assoc level layers))
end



class paint (source : ImgSource.source) =

    let ui_width = CGUI.Drawing.width ()
    and ui_height = CGUI.Drawing.height () in

    let edge = min (ui_width / source#columns) (ui_height / source#rows) in

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

    method background ?(sync = true) () =
        let t = CGUI.Drawing.cairo () in
        let r, g, b, a = Aux.parse_html_color backcolor in
        Cairo.set_source_rgba t r g b a;
        let w = float @@ CGUI.Drawing.width () 
        and h = float @@ CGUI.Drawing.height () in
        Cairo.rectangle t 0.0 0.0 ~w ~h;
        Cairo.fill t;
        Cairo.stroke t;
        if sync then CGUI.Drawing.synchronize ()

    method pixbuf ?(sync = false) ~r ~c pixbuf =
        assert (GdkPixbuf.get_width pixbuf = edge);
        assert (GdkPixbuf.get_height pixbuf = edge);
        let pixmap = CGUI.Drawing.pixmap () in
        pixmap#put_pixbuf
            ~x:(self#x ~c)
            ~y:(self#y ~r) pixbuf;
        if sync then CGUI.Drawing.synchronize ()

    method surface ?(sync = false) ~r ~c surface =
        let t = CGUI.Drawing.cairo ()
        and x = float (self#x ~c)
        and y = float (self#y ~r) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then CGUI.Drawing.synchronize ()    

    method cursor ?sync ~r ~c () =
        self#surface ?sync ~r ~c (Surface.cursor edge)

    method pointer ?sync ~r ~c () =
        self#surface ?sync ~r ~c (Surface.pointer edge)

    method annotation ?sync ~r ~c level chr =
        self#surface ?sync ~r ~c (Surface.layer level chr edge)

end



let create source = new paint source 