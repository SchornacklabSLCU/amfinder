(* CastANet Browser - imgPaint.ml *)

open Scanf
open Printf
open Morelib

module Memo = struct
    let memo f color =
        let rec get = ref (
            fun edge ->
                let res = f color edge in
                get := (fun _ -> res);
                res
        ) in
        fun edge -> !get edge

    let joker = memo AmfSurface.Square.filled "#00dd0099"
    let cursor = memo AmfSurface.Square.cursor "#cc0000ff"    

    let dashed_square = memo AmfSurface.Square.dashed "#000000FF"

    let margin_square_off = memo AmfSurface.Square.filled "#FFFFFFFF"
    let margin_square_on = memo AmfSurface.circle "#000000FF"

    let arrowhead = memo AmfSurface.arrowhead "#FF0000FF"

    let palette index edge =
        let color = (AmfUI.Predictions.get_colors ()).(index) in
        AmfSurface.circle color edge

    let layers =
        let make_surface lvl chr clr = 
            let symbol = List.assoc_opt chr (AmfLevel.icon_text lvl) in
            chr, memo (AmfSurface.Square.filled ?symbol) clr in
        let open AmfLevel in
        List.map (fun level ->
            level, List.map2 (make_surface level) (to_header level) (colors level)
        ) all_flags

    let layer level = function
        | '*' -> joker
        | chr -> List.(assoc chr (assoc level layers))
end



class brush (source : ImgTypes.source) =

    let ui_width = AmfUI.Drawing.width ()
    and ui_height = AmfUI.Drawing.height () in

    (* Fixed window size. *)
    let edge = 32
    and max_tile_w = 16
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

    method sync calling_func () =
        (* For debugging purposes. *)
        if false then AmfLog.info "Sync from %s" calling_func;
        AmfUI.Drawing.synchronize ()

    method background ?(sync = true) () =
        let t = AmfUI.Drawing.cairo () in
        let r, g, b, a = AmfColor.parse_rgba backcolor in
        Cairo.set_source_rgba t r g b a;
        let w = float @@ AmfUI.Drawing.width () 
        and h = float @@ AmfUI.Drawing.height () in
        Cairo.rectangle t 0.0 0.0 ~w ~h;
        Cairo.fill t;
        Cairo.stroke t;
        if sync then self#sync "background" ()

    method pixbuf ?(sync = false) ~r ~c pixbuf =
        assert (GdkPixbuf.get_width pixbuf = edge);
        assert (GdkPixbuf.get_height pixbuf = edge);
        let pixmap = AmfUI.Drawing.pixmap () in
        pixmap#put_pixbuf
            ~x:(self#x ~c)
            ~y:(self#y ~r) pixbuf;
        if sync then self#sync "pixbuf" ()

    method surface ?(sync = false) ~r ~c surface =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c)
        and y = float (self#y ~r) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync "surface" ()

    method missing_tile ?sync ~r ~c () =
        AmfSurface.Create.square ~edge ~color:"#808080FF" ()
        |> snd
        |> self#surface ?sync ~r ~c

    method prediction_palette ?(sync = false) () =
        let t = AmfUI.Drawing.cairo ()
        and y = float (self#y ~r:(snd self#r_range + 1) + 15) in
        let colors = AmfUI.Predictions.get_colors () in
        let surface = AmfSurface.prediction_palette colors edge in
        let rem = max_tile_w * edge - Cairo.Image.get_width surface in
        let x = float x_origin +. float rem /. 2.0 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync "prediction_palette" ()

    method annotation_legend ?(sync = false) () =
        let t = AmfUI.Drawing.cairo ()
        and y = float (self#y ~r:(snd self#r_range + 1) + 20) in
        let level = AmfUI.Levels.current () in
        let colors = AmfLevel.colors level
        and symbols = AmfLevel.symbols level in
        let surface = AmfSurface.annotation_legend symbols colors in
        let rem = max_tile_w * edge - Cairo.Image.get_width surface in
        let x = float x_origin +. float rem /. 2.0 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync "annotation_legend" () 

    method private draw_window_arrow orientation visible x y =
        let t = AmfUI.Drawing.cairo () in
        let color = if visible then "#FF0000FF" else "#FFFFFFFF" in
        let f = match orientation with
            | `TOP -> AmfSurface.Dir.top
            | `BOTTOM -> AmfSurface.Dir.bottom
            | `LEFT -> AmfSurface.Dir.left
            | `RIGHT -> AmfSurface.Dir.right
        in
        let surface = f
            ~background:self#backcolor
            ~foreground:color (edge / 4) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t

    method private redraw_row_pane r =
        (* Background clean-up. *)
        let h_area = AmfSurface.Create.rectangle
            ~width:edge
            ~height:((max_tile_h + 1) * edge)
            ~color:backcolor ()
        and t = AmfUI.Drawing.cairo ()
        and x = float x_origin -. 1.25 *. (float edge)
        and y = float y_origin -. 0.50 *. (float edge) in
        Cairo.set_source_surface t (snd h_area) x y;
        Cairo.paint t;
        (* Adding column number *)
        Cairo.select_font_face t "Monospace";
        Cairo.set_font_size t 12.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;         
        let text = sprintf "%04d" r in
        let Cairo.{width; height; y_bearing; _} = Cairo.text_extents t text in
        let x = float x_origin -. 0.25 *. (float edge) -. width
        and y = float (self#y ~r) +. 0.5 *. (float edge) -. y_bearing /. 2.0 in
        Cairo.move_to t x y;
        Cairo.show_text t text;
        (* Adding arrows. *)
        self#draw_window_arrow `TOP (r > 0) 
            (x +. width /. 2.0 -. float edge /. 8.0)
            (y -. height -. float edge /. 4.0 -. 2.0);
        self#draw_window_arrow `BOTTOM (r < source#rows - 1) 
            (x +. width /. 2.0 -. float edge /. 8.0)
            (y +. 1.0 +. 2.0);

    method private redraw_column_pane c =
        (* Background clean-up. *)
        let h_area = AmfSurface.Create.rectangle
            ~width:((max_tile_w + 1) * edge)
            ~height:edge
            ~color:backcolor ()
        and t = AmfUI.Drawing.cairo ()
        and x = float x_origin -. 0.50 *. (float edge)
        and y = float y_origin -. 1.25 *. (float edge) in
        Cairo.set_source_surface t (snd h_area) x y;
        Cairo.paint t;
        (* Adding column number *)
        Cairo.select_font_face t "Monospace";
        Cairo.set_font_size t 12.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;         
        let text = sprintf "%04d" c in
        let Cairo.{width; height; y_bearing; _} = Cairo.text_extents t text in
        let x = float (self#x ~c) +. 0.5 *. (float edge) -. width /. 2.0
        and y = float y_origin -. 0.25 *. (float edge) in
        Cairo.move_to t x y;
        Cairo.show_text t text;
        (* Adding arrows. *)
        self#draw_window_arrow `LEFT (c > 0) 
            (x -. float edge /. 4.0 -. 2.0)
            (y -. height);
        self#draw_window_arrow `RIGHT (c < source#columns - 1) 
            (x +. width +. 2.0)
            (y -. height)

    method private coordinates ?(sync = false) ~r ~c () =
        self#redraw_row_pane r;
        self#redraw_column_pane c;
        if sync then self#sync "coordinates" ()

    method private index_of_prob x = truncate (25.0 *. x) |> max 0 |> min 25

    method hide_probability ?(sync = false) () =
        let ncolors = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = max_tile_w * edge
        and prob_width = (ncolors + 2) * 12 in
        let surface = Cairo.Image.(create ARGB32 ~w:prob_width ~h:edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = AmfColor.parse_rgba backcolor in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float grid_width) ~h:(float edge);
        Cairo.fill t;
        Cairo.stroke t;
        let y = float (self#y ~r:(snd self#r_range + 1) + 15 + edge + 5) in
        let t = AmfUI.Drawing.cairo () in
        let grid_width = max_tile_w * edge in
        Cairo.set_source_surface t surface
            (float x_origin +. float (grid_width - 12 * (ncolors + 2)) /. 2.0)
            y;
        Cairo.paint t;
        if sync then self#sync "hide_probability" ()

    method show_probability ?(sync = false) prob =
        self#hide_probability ();
        let t = AmfUI.Drawing.cairo () in
        let index = self#index_of_prob prob in
        let y = float (self#y ~r:(snd self#r_range + 1) + 15 + edge + 5) in
        let len = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = max_tile_w * edge in
        let rem = grid_width - 12 * len in
        let x = float x_origin +. float rem /. 2.0 in
        let x = x +. float index *. 12.0 in
        let surface = Memo.arrowhead 12 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        Cairo.select_font_face t "Monospace";
        Cairo.set_font_size t 12.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;
        let text = sprintf "%.02f" prob in
        let te = Cairo.text_extents t text in
        Cairo.move_to t
            (x +. 6.0 -. te.Cairo.width /. 2.0)
            (y +. 10.0 +. te.Cairo.height +. 5.0);
        Cairo.show_text t text;
        if sync then self#sync "show_probability" ()

    method cursor ?sync ~r ~c () =
        self#surface ~r ~c (Memo.cursor edge);
        self#coordinates ?sync ~r ~c ()

    method annotation ?sync ~r ~c level set =
        if not (CSet.is_empty set) then begin
             (* FIXME: what to display in case of multiple annotations? *)
            let chr = (CSet.to_seq set |> String.of_seq).[0] in
            self#surface ?sync ~r ~c (Memo.layer level chr edge)
        end

    method annotation_other_layer ?sync ~r ~c () =
        self#surface ?sync ~r ~c (Memo.dashed_square edge)

    method pie_chart ?sync ~r ~c t =
        AmfUI.Levels.current ()
        |> AmfLevel.colors
        |> (fun colors -> AmfSurface.pie_chart t colors edge)
        |> self#surface ?sync ~r ~c

    method prediction ?sync ~r ~c (chr : char) x =
        let index = self#index_of_prob x in
        (* self#show_probability x; *)
        self#surface ?sync ~r ~c (Memo.palette index edge)
end



let create x = new brush x 
