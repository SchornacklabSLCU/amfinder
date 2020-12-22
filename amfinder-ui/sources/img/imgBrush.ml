(* The Automated Mycorrhiza Finder version 1.0 - img/imgBrush.ml *)

open Scanf
open Printf
open Morelib

let _DEBUGGING_ = false


module Area = struct
    (* Edge of displayed tiles, in pixels.    *)
    let edge = 37
    (* Maximum number of tiles on the X axis. *)
    let wmax = 13
    (* Maximum number of tiles on the Y axis. *)
    let hmax = 12
end



class brush (source : ImgTypes.source) =

    (* GtkDrawingArea width, in pixels (allocated at startup).  *)
    let ui_width = AmfUI.Drawing.width ()
    (* GtkDrawingArea height, in pixels (allocated at startup). *)
    and ui_height = AmfUI.Drawing.height () in
   
    (* X coordinate (in pixels) of the drawing origin. *)
    let x_origin = (ui_width - Area.edge * Area.wmax) / 2
    (* Y coordinate (in pixels) of the drawing origin. *)
    and y_origin = (ui_height - Area.edge * Area.hmax) / 2 in

object (self)

    val mutable rbound = 0                  (* Index of the topmost row.     *)
    val mutable cbound = 0                  (* Index of the leftmost column. *)
    val mutable backcolor = "#ffffffff"     (* Background color.             *)

    (* Adjust the displayed area to the cursor coordinates. *)
    method make_visible ~r ~c () =
        let res = ref false
        and rlimit = snd self#r_range 
        and climit = snd self#c_range in
        (* The area should be moved to top. *)
        if r < rbound then (rbound <- r; res := true) else
        (* The area should be moved to the bottom. *)
        if r > rlimit then (rbound <- r - Area.hmax + 1; res := true);
        (* The area should be moved to the right. *)
        if c < cbound then (cbound <- c; res := true) else
        (* The area should be moved to the left. *)
        if c > climit then (cbound <- c - Area.wmax + 1; res := true);
        (* Tells whether the area has moved. *)
        !res
 
    method r_range = rbound, min source#rows (rbound + Area.hmax - 1)
    method c_range = cbound, min source#columns (cbound + Area.wmax - 1)

    method edge = Area.edge
    method x_origin = x_origin
    method y_origin = y_origin

    (* Converts a column index (c) to pixels (X axis). *)
    method private x ~c =
        assert (c >= cbound);
        x_origin + (c - cbound) * Area.edge

    (* Converts a row index (r) to pixels (Y axis). *)
    method private y ~r =
        assert (r >= rbound);
        y_origin + (r - rbound) * Area.edge

    method backcolor = backcolor
    method set_backcolor x = backcolor <- x

    (** Synchronizes GtkDrawingArea with the backing pixmap. *)
    method sync caller () =
        if _DEBUGGING_ then AmfLog.info "Calling brush#sync from %s" caller;
        AmfUI.Drawing.synchronize ()

    method background ?(sync = true) () =
        let t = AmfUI.Drawing.cairo () in
        let r, g, b, a = AmfColor.parse_rgba backcolor in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float ui_width) ~h:(float ui_height);
        Cairo.fill t;
        if sync then self#sync "brush#background" ()

    method pixbuf ?(sync = false) ~r ~c pixbuf =
        assert (GdkPixbuf.get_width pixbuf = Area.edge);
        assert (GdkPixbuf.get_height pixbuf = Area.edge);
        let pixmap = AmfUI.Drawing.pixmap () in
        pixmap#put_pixbuf
            ~x:(self#x ~c)
            ~y:(self#y ~r) pixbuf;
        if sync then self#sync "brush#pixbuf" ()

    method empty ?sync ~r ~c () =
        self#surface ?sync ~r ~c (AmfMemoize.empty_square Area.edge)

    method surface ?(sync = false) ~r ~c surface =
        let t = AmfUI.Drawing.cairo ()
        and x = float (self#x ~c)
        and y = float (self#y ~r) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync "brush#surface" ()

    method locked_tile ?sync ~r ~c () =
        self#surface ?sync ~r ~c (AmfMemoize.locked_square Area.edge)

    method prediction_palette ?(sync = false) () =
        let t = AmfUI.Drawing.cairo ()
        and y = float (self#y ~r:(snd self#r_range + 1) + 15) in
        let colors = AmfUI.Predictions.get_colors () in
        let surface = AmfSurface.Legend.palette colors Area.edge in
        let rem = Area.wmax * Area.edge - Cairo.Image.get_width surface in
        let x = float x_origin +. float rem /. 2.0 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync "brush#prediction_palette" ()

    method annotation_legend ?(sync = false) () =
        let t = AmfUI.Drawing.cairo ()
        and y = float (self#y ~r:(snd self#r_range + 1) + 20) in
        let level = AmfUI.Levels.current () in
        let colors = AmfLevel.colors level
        and symbols = AmfLevel.symbols level in
        let surface = AmfSurface.Legend.classes symbols colors in
        let rem = Area.wmax * Area.edge - Cairo.Image.get_width surface in
        let x = float x_origin +. float rem /. 2.0 in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t;
        if sync then self#sync "annotation_legend" () 

    method private draw_window_arrow orientation visible x y =
        let t = AmfUI.Drawing.cairo () in
        let fgcolor = if visible then "#FF0000FF" else "#FFFFFFFF" in
        let f = match orientation with
            | `TOP -> AmfSurface.Arrowhead.top
            | `BOTTOM -> AmfSurface.Arrowhead.bottom
            | `LEFT -> AmfSurface.Arrowhead.left
            | `RIGHT -> AmfSurface.Arrowhead.right
        in
        let surface = f ~bgcolor:self#backcolor ~fgcolor (Area.edge / 4) in
        Cairo.set_source_surface t surface x y;
        Cairo.paint t

    method private redraw_row_pane r =
        (* Background clean-up. *)
        let h_area = AmfSurface.rectangle
            ~rgba:backcolor
            ~w:Area.edge
            ~h:((Area.hmax + 1) * Area.edge)
        and t = AmfUI.Drawing.cairo ()
        and x = float x_origin -. 1.25 *. (float Area.edge)
        and y = float y_origin -. 0.50 *. (float Area.edge) in
        Cairo.set_source_surface t (snd h_area) x y;
        Cairo.paint t;
        (* Adding column number *)
        Cairo.select_font_face t "Monospace";
        Cairo.set_font_size t 12.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;         
        let text = sprintf "%04d" r in
        let Cairo.{width; height; y_bearing; _} = Cairo.text_extents t text in
        let x = float x_origin -. 0.25 *. (float Area.edge) -. width
        and y = float (self#y ~r) +. 0.5 *. (float Area.edge) -. y_bearing /. 2.0 in
        Cairo.move_to t x y;
        Cairo.show_text t text;
        (* Adding arrows. *)
        self#draw_window_arrow `TOP (r > 0) 
            (x +. width /. 2.0 -. float Area.edge /. 8.0)
            (y -. height -. float Area.edge /. 4.0 -. 2.0);
        self#draw_window_arrow `BOTTOM (r < source#rows - 1) 
            (x +. width /. 2.0 -. float Area.edge /. 8.0)
            (y +. 1.0 +. 2.0);

    method private redraw_column_pane c =
        (* Background clean-up. *)
        let h_area = AmfSurface.rectangle
            ~w:((Area.wmax + 1) * Area.edge)
            ~h:Area.edge
            ~rgba:backcolor
        and t = AmfUI.Drawing.cairo ()
        and x = float x_origin -. 0.50 *. (float Area.edge)
        and y = float y_origin -. 1.25 *. (float Area.edge) in
        Cairo.set_source_surface t (snd h_area) x y;
        Cairo.paint t;
        (* Adding column number *)
        Cairo.select_font_face t "Monospace";
        Cairo.set_font_size t 12.0;
        Cairo.set_source_rgba t 1.0 0.0 0.0 1.0;         
        let text = sprintf "%04d" c in
        let Cairo.{width; height; y_bearing; _} = Cairo.text_extents t text in
        let x = float (self#x ~c) +. 0.5 *. (float Area.edge) -. width /. 2.0
        and y = float y_origin -. 0.25 *. (float Area.edge) in
        Cairo.move_to t x y;
        Cairo.show_text t text;
        (* Adding arrows. *)
        self#draw_window_arrow `LEFT (c > 0) 
            (x -. float Area.edge /. 4.0 -. 2.0)
            (y -. height);
        self#draw_window_arrow `RIGHT (c < source#columns - 1) 
            (x +. width +. 2.0)
            (y -. height)

    method private coordinates ?(sync = false) ~r ~c () =
        self#redraw_row_pane r;
        self#redraw_column_pane c;
        if sync then self#sync "coordinates" ()

    method private index_of_prob x = truncate (25.0 *. x) |> max 0 |> min 24

    method hide_probability ?(sync = false) () =
        let ncolors = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = Area.wmax * Area.edge
        and prob_width = (ncolors + 2) * 12 in
        let surface = Cairo.Image.(create ARGB32 ~w:prob_width ~h:Area.edge) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = AmfColor.parse_rgba backcolor in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float grid_width) ~h:(float Area.edge);
        Cairo.fill t;
        Cairo.stroke t;
        let y = float (self#y ~r:(snd self#r_range + 1) + 15 + Area.edge + 5) in
        let t = AmfUI.Drawing.cairo () in
        let grid_width = Area.wmax * Area.edge in
        Cairo.set_source_surface t surface
            (float x_origin +. float (grid_width - 12 * (ncolors + 2)) /. 2.0)
            y;
        Cairo.paint t;
        if sync then self#sync "hide_probability" ()

    method show_probability ?(sync = false) prob =
        self#hide_probability ();
        let t = AmfUI.Drawing.cairo () in
        let index = self#index_of_prob prob in
        let y = float (self#y ~r:(snd self#r_range + 1) + 15 + Area.edge + 5) in
        let len = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = Area.wmax * Area.edge in
        let rem = grid_width - 12 * len in
        let x = float x_origin +. float rem /. 2.0 in
        let x = x +. float index *. 12.0 in
        (* let surface = AmfMemoize.arrowhead 12 in *)
        let surface = AmfSurface.Arrowhead.top
            ~bgcolor:self#backcolor 12 in        
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
        self#surface ~r ~c (AmfMemoize.cursor Area.edge);
        self#coordinates ?sync ~r ~c ()

    method annotation ?sync ~r ~c level set =
        (* One-color square in case of single annotation. *)
        let simple_square set =
            assert (CSet.cardinal set = 1);
            CSet.choose set
            |> (fun chr -> AmfMemoize.layer level chr Area.edge)
            |> self#surface ?sync ~r ~c
        in
        if not (CSet.is_empty set) then begin
            if AmfLevel.is_ir_struct level then (
                (* Multicolor square in case of multiple annotations. *)
                if AmfUI.Layers.current () = '*' then (
                    let colors = List.map2 
                        (fun chr clr ->
                            if CSet.mem chr set then clr 
                            else "#FFFFFF00"
                        ) (AmfLevel.to_header level) (AmfLevel.colors level)
                    in self#surface ?sync ~r ~c (AmfSurface.Annotation.colors colors Area.edge)
                (* Other layers only show one type of annotation. *)
                ) else simple_square set
            (* Root segmentation only has single-color annotations. *)
            ) else simple_square set
        end

    method annotation_other_layer ?sync ~r ~c () =
        self#surface ?sync ~r ~c (AmfMemoize.dashed_square Area.edge)

    method private pie_chart ?sync ~r ~c t =
        let level = AmfUI.Levels.current () in
        let palette = AmfLevel.colors level in
        let f = match level with
            | AmfLevel.RootSegm -> AmfSurface.Prediction.pie_chart
            | AmfLevel.IRStruct -> AmfSurface.Prediction.radar
        in self#surface ?sync ~r ~c (f t palette Area.edge)

    method prediction ?sync ~r ~c t = function
        | '*' -> self#pie_chart ?sync ~r ~c t
        | chr -> let level = AmfUI.Levels.current () in
            AmfLevel.char_index level chr
            |> List.nth t
            |> self#index_of_prob
            |> (fun i -> AmfMemoize.palette i Area.edge)
            |> self#surface ?sync ~r ~c

end



let create x = new brush x 
