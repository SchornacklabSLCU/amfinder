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

    (* Fixed window size. *)
    let edge = 32
    and max_tile_w = 14 
    and max_tile_h = 14 in
    
    let x_origin = (ui_width - edge * max_tile_w) / 2
    and y_origin = (ui_height - edge * max_tile_h) / 2 in

object (self)

    val mutable rbound = 0 (* index of the topmost row. *)
    val mutable cbound = 0 (* index of the leftmost column. *)
    val mutable backcolor = "#ffffffff"

    method make_visible ~r ~c () =
        let rlimit = snd self#r_range and climit = snd self#c_range in
        let res = ref false in
        if r < rbound then (rbound <- r; res := true)
        else if r > rlimit then (rbound <- r - max_tile_h + 1; res := true);
        if c < cbound then (cbound <- c; res := true)
        else if c > climit then (cbound <- c - max_tile_w + 1; res := true);
        !res
 
    method r_range = rbound, min source#rows (rbound + max_tile_h - 1)
    method c_range = cbound, min source#columns (cbound + max_tile_w - 1)

    method edge = edge
    method x_origin = x_origin
    method y_origin = y_origin

    method private x ~c = x_origin + (c - cbound) * edge
    method private y ~r = y_origin + (r - rbound) * edge

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

    method prediction_palette ?(sync = false) () =
        let t = AmfUI.Drawing.cairo ()
        and y = float (self#y ~r:(snd self#r_range + 1) + 5) in
        let colors = AmfUI.Predictions.get_colors () in
        let surface = AmfSurface.prediction_palette colors edge in
        let rem = max_tile_w * edge - Cairo.Image.get_width surface in
        let x = float x_origin +. float rem /. 2.0 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync ()

    method annotation_legend ?(sync = false) () =
        let t = AmfUI.Drawing.cairo ()
        and y = float (self#y ~r:(snd self#r_range + 1) + 5) in
        let level = AmfUI.Levels.current () in
        let colors = AmfLevel.colors level
        and symbols = AmfLevel.symbols level in
        let surface = AmfSurface.annotation_legend symbols colors in
        let rem = max_tile_w * edge - Cairo.Image.get_width surface in
        let x = float x_origin +. float rem /. 2.0 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync () 
    

    method private margin ?(sync = false) ~r ~c surface =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c:cbound - edge) 
        and y = float (self#y ~r) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        let x = x -. float edge in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        let x = float (self#x ~c) 
        and y = float (self#y ~r:rbound - edge) in
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
        and x = float (self#x ~c:cbound - edge) 
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
        and y = float (self#y ~r:rbound - edge) in
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

    method private index_of_prob x = truncate (25.0 *. x) |> max 0 |> min 25

    method hide_probability ?(sync = false) () =
        let ncolors = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = max_tile_w * edge
        and prob_width = (ncolors + 2) * 12 in
        let surface = Cairo.Image.(create ARGB32 ~w:prob_width ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = AmfSurface.parse_html_color backcolor in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float grid_width) ~h:(float edge);
        Cairo.fill t;
        Cairo.stroke t;
        let y = float (self#y ~r:(snd self#r_range + 1) + 5 + edge + 5) in
        let t = AmfUI.Drawing.cairo () in
        let grid_width = max_tile_w * edge in
        Cairo.set_source_surface t surface
            (float x_origin +. float (grid_width - 12 * (ncolors + 2)) /. 2.0)
            (y);
        Cairo.paint t;
        if sync then self#sync ()

    method show_probability ?(sync = false) prob =
        self#hide_probability ();
        let t = AmfUI.Drawing.cairo () in
        let index = self#index_of_prob prob in
        let y = float (self#y ~r:(snd self#r_range + 1) + 5 + edge + 5) in
        let len = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = max_tile_w * edge in
        let rem = grid_width - 12 * len in
        let x = float x_origin +. float rem /. 2.0 in
        let x = x +. float index *. 12.0 in
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
        self#show_probability x;
        self#surface ?sync ~r ~c (Memo.palette index edge)

end



let create x = new brush x 
