(* CastANet Browser - imgPaint.ml *)

open Scanf
open Printf

module Memo = struct
    let memo f color =
        let rec get = ref (
            fun edge ->
                let res = f color edge in
                get := (fun _ -> res);
                res
        ) in
        fun edge -> !get edge

    let joker = memo    AmfSurface.solid_square "#00dd0099"
    let cursor = memo AmfSurface.empty_square "#cc0000cc"    
    let pointer = memo AmfSurface.solid_square "#cc000066"

    let margin_square_off = memo AmfSurface.solid_square "#ffffffff"
    let margin_square_on = memo AmfSurface.circle "#000000FF"

    let right_arrowhead = memo AmfSurface.right_arrowhead "#FF0000FF"
    let down_arrowhead = memo AmfSurface.down_arrowhead "#FF0000FF"

    let up_arrowhead = memo AmfSurface.up_arrowhead "#FF0000FF"

    let palette index edge =
        let color = (AmfUI.Predictions.get_colors ()).(index) in
        AmfSurface.circle color edge

    let full_palette ?step edge =
        let colors = AmfUI.Predictions.get_colors () in
        AmfSurface.palette ?step colors edge

    let layers =
        List.map (fun level ->
            let surfaces = List.map2 (fun x y -> x, memo AmfSurface.solid_square y)
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
        let r, g, b, a = AmfSurface.parse_html_color backcolor in
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
        and surface = Memo.full_palette edge in
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
        let surface = Memo.margin_square_off edge in
        self#margin ?sync ~r ~c surface

    method private margin_marks ?(sync = false) ~r ~c () =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c:0 - edge) 
        and y = float (self#y ~r) in
        let surface = Memo.right_arrowhead edge in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        Cairo.select_font_face t "Arial";
        Cairo.set_font_size t 14.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;
        let text = sprintf "%04d" r in
        let te = Cairo.text_extents t text in
        Cairo.move_to t (x -. 0.7 *. te.Cairo.width) (y +. float edge /. 2.0 -. te.Cairo.y_bearing /. 2.0);
        Cairo.show_text t text;
        let surface = Memo.down_arrowhead edge in
        let x = float (self#x ~c) 
        and y = float (self#y ~r:0 - edge) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        Cairo.select_font_face t "Arial";
        Cairo.set_font_size t 14.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;
        let text = sprintf "%04d" c in
        let te = Cairo.text_extents t text in
        Cairo.move_to t (x +. float edge /. 2.0 -. te.Cairo.width /. 2.0) (y +. 10.0);
        Cairo.show_text t text;
        if sync then self#sync ()

    method private index_of_prob x = truncate (24.0 *. x) |> max 0 |> min 24

    method hide_probability ?(sync = false) () =
        let ncolors = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = source#columns * edge
        and prob_width = (ncolors + 2) * 12 in
        let surface = Cairo.Image.(create ARGB32 ~w:prob_width ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = AmfSurface.parse_html_color backcolor in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float grid_width) ~h:(float edge);
        Cairo.fill t;
        Cairo.stroke t;
        let y = float (self#y ~r:source#rows + 5 + edge + 5) in
        let t = AmfUI.Drawing.cairo () in
        let grid_width = source#columns * edge in
        Cairo.set_source_surface t surface
            (float x_origin +. float (grid_width - 12 * (ncolors + 2)) /. 2.0)
            (y);
        Cairo.paint t;
        if sync then self#sync ()

    method show_probability ?(sync = false) prob =
        self#hide_probability ();
        let t = AmfUI.Drawing.cairo () in
        let index = self#index_of_prob prob in
        let y = float (self#y ~r:source#rows + 5 + edge + 5) in
        let len = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = source#columns * edge in
        let rem = grid_width - 12 * len in
        let x = float x_origin +. float rem /. 2.0 in
        let x = x +. float (index + 1) *. 12.0 in
        let surface = Memo.up_arrowhead 12 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        Cairo.select_font_face t "Arial";
        Cairo.set_font_size t 14.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;
        let text = sprintf "%.02f" prob in
        let te = Cairo.text_extents t text in
        Cairo.move_to t (x +. 6.0 -. te.Cairo.width /. 2.0) (y +. 10.0 +. te.Cairo.height +. 5.0);
        Cairo.show_text t text;
        if sync then self#sync ()

    method cursor ?sync ~r ~c () =
        self#surface ~r ~c (Memo.cursor edge);
        self#margin_marks ?sync ~r ~c ()

    method pointer ?sync ~r ~c () =
        self#surface ?sync ~r ~c (Memo.pointer edge)

    method annotation ?sync ~r ~c level chr =
        self#surface ?sync ~r ~c (Memo.layer level chr edge)

    method pie_chart ?sync ~r ~c t =
        AmfUI.Levels.current ()
        |> AmfLevel.colors
        |> (fun colors -> AmfSurface.pie_chart t colors edge)
        |> self#surface ?sync ~r ~c

    method prediction ?sync ~r ~c (chr : char) x =
        let index = self#index_of_prob x in
        self#surface ?sync ~r ~c (Memo.palette index edge)

end



let create x = new brush x 
