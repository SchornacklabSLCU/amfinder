(* AMFinder - img/imgBrush.ml
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

open Scanf
open Printf
open Morelib
open AmfConst

type orientation = Top | Bottom | Left | Right

class coords x_origin y_origin = object(self)

    method paint_background ?(row = true) () =
        let w, h = match row with
            | true  -> _EDGE_, (_HMAX_ + 1) * _EDGE_
            | false -> (_WMAX_ + 1) * _EDGE_, _EDGE_
        and xmul = if row then 1.25 else 0.50
        and ymul = if row then 0.50 else 1.25
        and context = AmfUI.Drawing.cairo () in
        let _, area = AmfSurface.rectangle ~rgba:_BGCOLOR_ ~w ~h
        and x = float x_origin -. xmul *. (float _EDGE_)
        and y = float y_origin -. ymul *. (float _EDGE_) in
        Cairo.set_source_surface context area x y;
        Cairo.paint context

    method private initialize_font () =
        let context = AmfUI.Drawing.cairo () in
        Cairo.select_font_face context "Monospace";
        Cairo.set_font_size context 12.0;
        Cairo.set_source_rgba context 1.0 0.0 0.0 1.0

    method write_row_index r y =
        self#initialize_font ();
        let s = sprintf "%04d" r in
        let context = AmfUI.Drawing.cairo () in
        let ext = Cairo.text_extents context s in
        let e = float _EDGE_ in
        let x = float x_origin -. 0.25 *. e -. ext.Cairo.width
        and y = float y +. 0.50 *. e -. ext.Cairo.y_bearing /. 2.0 in
        Cairo.move_to context x y;
        Cairo.show_text context s;
        x, y, ext.Cairo.width, ext.Cairo.height

    method write_column_index c x =
        self#initialize_font ();
        let s = sprintf "%04d" c in
        let context = AmfUI.Drawing.cairo () in
        let open Cairo in
        let ext = Cairo.text_extents context s in
        let e = float _EDGE_ in
        let x = float x +. 0.50 *. e -. ext.Cairo.width /. 2.0
        and y = float y_origin -. 0.25 *. e in
        Cairo.move_to context x y;
        Cairo.show_text context s;
        x, y, ext.Cairo.width, ext.Cairo.height

    method draw_window_arrow orientation visible x y =
        let fgcolor = match visible with
            | true  -> None 
            | false -> Some "#FFFFFFFF"
        and f =
            let open AmfSurface.Arrowhead in 
            match orientation with
            | Top    -> top
            | Bottom -> bottom
            | Left   -> left
            | Right  -> right
        in
        let surface = f ~bgcolor:"#FFFFFFFF" ?fgcolor (_EDGE_ / 4) in
        let context = AmfUI.Drawing.cairo () in
        Cairo.set_source_surface context surface x y;
        Cairo.paint context  

end



class brush (source : ImgTypes.source) =

    (* GtkDrawingArea dimensions, in pixels (allocated at startup).  *)
    let ui_width = AmfUI.Drawing.width ()
    and ui_height = AmfUI.Drawing.height () in
   
    (* Coordinates of the drawing origin, in pixels. *)
    let x_origin = (ui_width - _EDGE_ * _WMAX_) / 2
    and y_origin = (ui_height - _EDGE_ * _HMAX_) / 2 in

object (self)

    val mutable rbound = 0                  (* Index of the topmost row.     *)
    val mutable cbound = 0                  (* Index of the leftmost column. *)
    val mutable backcolor = "#ffffffff"     (* Background color.             *)

    val coords = new coords x_origin y_origin

    (* Adjust the displayed area to the cursor coordinates. *)
    method make_visible ~r ~c () =
        let res = ref false
        and rlimit = snd self#r_range 
        and climit = snd self#c_range in
        (* The area should be moved to top. *)
        if r < rbound then (rbound <- r; res := true) else
        (* The area should be moved to the bottom. *)
        if r > rlimit then (rbound <- r - _HMAX_ + 1; res := true);
        (* The area should be moved to the right. *)
        if c < cbound then (cbound <- c; res := true) else
        (* The area should be moved to the left. *)
        if c > climit then (cbound <- c - _WMAX_ + 1; res := true);
        (* Tells whether the area has moved. *)
        !res
 
    method r_range = rbound, min source#rows (rbound + _HMAX_ - 1)
    method c_range = cbound, min source#columns (cbound + _WMAX_ - 1)

    method edge = _EDGE_
    method x_origin = x_origin
    method y_origin = y_origin

    (* Converts a column index (c) to pixels (X axis). *)
    method private x ~c =
        assert (c >= cbound);
        x_origin + (c - cbound) * _EDGE_

    (* Converts a row index (r) to pixels (Y axis). *)
    method private y ~r =
        assert (r >= rbound);
        y_origin + (r - rbound) * _EDGE_

    method backcolor = backcolor
    method set_backcolor x = backcolor <- x

    method sync caller () =
        AmfLog.info_debug "brush#sync (triggered by %s)" caller;
        AmfUI.Drawing.synchronize ()

    method background ?(sync = true) () =
        let context = AmfUI.Drawing.cairo () in
        let r, g, b = AmfColor.parse_rgb backcolor in
        Cairo.set_source_rgb context r g b;
        Cairo.rectangle context 0.0 0.0
            ~w:(float ui_width)
            ~h:(float ui_height);
        Cairo.fill context;
        if sync then self#sync "brush#background" ()

    method pixbuf ?(sync = false) ~r ~c pixbuf =
        assert (GdkPixbuf.get_width pixbuf = _EDGE_);
        assert (GdkPixbuf.get_height pixbuf = _EDGE_);
        let pixmap = AmfUI.Drawing.pixmap () in
        pixmap#put_pixbuf
            ~x:(self#x ~c)
            ~y:(self#y ~r) pixbuf;
        if sync then AmfUI.Drawing.synchronize ()

    method surface ?(sync = false) ~r ~c surface =
        AmfLog.info_debug "brush#surface ~sync:%b ~r:%d ~c:%d" sync r c;
        let context = AmfUI.Drawing.cairo () in
        Cairo.set_source_surface context surface
            (float (self#x ~c))
            (float (self#y ~r));
        Cairo.paint context;
        if sync then AmfUI.Drawing.synchronize ()

    method private surface_from_func ?sync ~r ~c f =
        self#surface ?sync ~r ~c (f _EDGE_)

    method empty ?sync ~r ~c () =
        self#surface_from_func ?sync ~r ~c AmfMemoize.empty_square

    method locked_tile ?sync ~r ~c () =
        self#surface_from_func ?sync ~r ~c AmfMemoize.locked_square

    method annotation_other_layer ?sync ~r ~c () =
        self#surface_from_func ?sync ~r ~c AmfMemoize.dashed_square

    method cursor ?sync ~r ~c () =
        self#surface_from_func ~r ~c AmfMemoize.cursor;
        self#coordinates ?sync ~r ~c ()

    (* Center horizontally. *)
    method private legend_x surface =
        let hspace = _WMAX_ * _EDGE_ - Cairo.Image.get_width surface in
        float x_origin +. 0.5 *. float hspace

    (* Y position: after the last row, with 10 pixel vertical margin. *)
    method private legend_y =
        float (self#y ~r:(snd self#r_range + 1) + 10)

    method palette ?(sync = false) () =
        AmfLog.info_debug "brush#palette ~sync:%b" sync;
        let surface = AmfSurface.Legend.palette _EDGE_ in
        let x = self#legend_x surface 
        and y = self#legend_y
        and context = AmfUI.Drawing.cairo () in       
        Cairo.set_source_surface context surface x y;
        Cairo.paint context;
        if sync then AmfUI.Drawing.synchronize ()

    method classes ?(sync = false) () =
        AmfLog.info_debug "brush#classes ~sync:%b" sync;
        let surface = AmfSurface.Legend.classes () in
        let x = self#legend_x surface 
        and y = self#legend_y
        and context = AmfUI.Drawing.cairo () in
        Cairo.set_source_surface context surface x y;
        Cairo.paint context;
        if sync then AmfUI.Drawing.synchronize ()

    method private redraw_row_pane r =
        coords#paint_background ();
        let x, y, width, height = coords#write_row_index r (self#y ~r) in
        (* Adding arrows. *)
        coords#draw_window_arrow Top (r > 0) 
            (x +. width /. 2.0 -. float _EDGE_ /. 8.0)
            (y -. height -. float _EDGE_ /. 4.0 -. 2.0);
        coords#draw_window_arrow Bottom (r < source#rows - 1) 
            (x +. width /. 2.0 -. float _EDGE_ /. 8.0)
            (y +. 1.0 +. 2.0);

    method private redraw_column_pane c =
        coords#paint_background ~row:false ();
        let x, y, width, height = coords#write_column_index c (self#x ~c) in
        (* Adding arrows. *)
        coords#draw_window_arrow Left (c > 0) 
            (x -. float _EDGE_ /. 4.0 -. 2.0)
            (y -. height);
        coords#draw_window_arrow Right (c < source#columns - 1) 
            (x +. width +. 2.0)
            (y -. height)

    method private coordinates ?(sync = false) ~r ~c () =
        self#redraw_row_pane r;
        self#redraw_column_pane c;
        if sync then self#sync "coordinates" ()

    method private index_of_prob x = truncate (25.0 *. x) |> max 0 |> min 24

    method hide_probability ?(sync = false) () =
        let ncolors = Array.length (AmfUI.Predictions.get_colors ()) in
        let grid_width = _WMAX_ * _EDGE_
        and prob_width = (ncolors + 2) * 12 in
        let surface = Cairo.Image.(create ARGB32 ~w:prob_width ~h:_EDGE_) in
        let t = Cairo.create surface in
        Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
        let r, g, b, a = AmfColor.parse_rgba backcolor in
        Cairo.set_source_rgba t r g b a;
        Cairo.rectangle t 0.0 0.0 ~w:(float grid_width) ~h:(float _EDGE_);
        Cairo.fill t;
        Cairo.stroke t;
        let y = float (self#y ~r:(snd self#r_range + 1) + 10 + _EDGE_ + 5) in
        let t = AmfUI.Drawing.cairo () in
        let grid_width = _WMAX_ * _EDGE_ in
        Cairo.set_source_surface t surface
            (float x_origin +. float (grid_width - 12 * (ncolors + 2)) /. 2.0)
            y;
        Cairo.paint t;
        if sync then self#sync "hide_probability" ()

    method show_probability ?(sync = false) prob =
        self#hide_probability ();
        let t = AmfUI.Drawing.cairo () in
        let index = self#index_of_prob prob in
        let y = float (self#y ~r:(snd self#r_range + 1) + 10 + _EDGE_ + 5) in
        let len = Array.length (AmfUI.Predictions.get_colors ()) in
        let rem = _WMAX_ * _EDGE_ - 12 * len in
        let x = float x_origin +. float rem /. 2.0 in
        let x = x +. float index *. 12.0 in
        let surface = AmfSurface.Arrowhead.top ~bgcolor:self#backcolor 12 in        
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

    method private simple_square ?sync ~r ~c level set =
        assert (CSet.cardinal set = 1);
        let chr = CSet.choose set in
        let surface = AmfMemoize.layer level chr _EDGE_ in
        self#surface ?sync ~r ~c surface

    method annotation ?sync ~r ~c level set =
        (* One-color square in case of single annotation. *)
        if not (CSet.is_empty set) then begin
            if AmfLevel.is_myc level then (
                (* Multicolor square in case of multiple annotations. *)
                if AmfUI.Layers.current () = '*' then (
                    let colors = List.map2 
                        (fun chr clr ->
                            if CSet.mem chr set then clr 
                            else "#FFFFFF00"
                        ) (AmfLevel.to_header level) (AmfLevel.colors level)
                    in self#surface ?sync ~r ~c (AmfSurface.Annotation.colors colors _EDGE_)
                (* Other layers only show one type of annotation. *)
                ) else self#simple_square ?sync ~r ~c level set
            (* Root segmentation only has single-color annotations. *)
            ) else self#simple_square ?sync ~r ~c level set
        end

    method private pie_chart ?sync ~r ~c probs =
        AmfLog.info_debug "brush#pie_chart ~r:%d ~c:%d" r c;
        let level = AmfUI.Levels.current () in
        let colors = AmfLevel.colors level in
        let draw = match level with
            | true  -> AmfSurface.Prediction.pie_chart
            | false -> AmfSurface.Prediction.radar
        in self#surface ?sync ~r ~c (draw probs colors _EDGE_)

    method prediction ?sync ~r ~c t = function
        | '*' -> self#pie_chart ?sync ~r ~c t
        | chr -> let level = AmfUI.Levels.current () in
            AmfLevel.char_index level chr
            |> List.nth t
            |> self#index_of_prob
            |> (fun i -> AmfMemoize.palette i _EDGE_)
            |> self#surface ?sync ~r ~c

end



let create x = new brush x 
