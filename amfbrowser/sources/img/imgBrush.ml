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

class type cls = object
    method edge : int
    method x_origin : int
    method y_origin : int
    method set_update: (unit -> unit) -> unit
    method has_unchanged_boundaries : r:int -> c:int -> unit -> bool
    method r_range : int * int
    method c_range : int * int
    method backcolor : string
    method set_backcolor : string -> unit
    method background : ?sync:bool -> unit -> unit
    method pixbuf : ?sync:bool -> r:int -> c:int -> GdkPixbuf.pixbuf -> unit
    method empty : ?sync:bool -> r:int -> c:int -> unit -> unit
    method surface : ?sync:bool -> r:int -> c:int -> Cairo.Surface.t -> unit
    method locked_tile : ?sync:bool -> r:int -> c:int -> unit -> unit
    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    method annotation :
        ?sync:bool ->
        r:int -> c:int -> AmfLevel.level -> Morelib.CSet.t -> unit
    method annotation_other_layer :
        ?sync:bool -> r:int -> c:int -> unit -> unit
    method prediction :
        ?sync:bool -> r:int -> c:int -> float list -> char -> unit
    method palette : ?sync:bool -> unit -> unit
    method classes : ?sync:bool -> unit -> unit
    method show_probability : ?sync:bool -> float -> unit
    method hide_probability : ?sync:bool -> unit -> unit
    method sync : string -> unit -> unit
end


(* Display row/column coordinate values in the margin.
 * Draw arrowheads indicating valid directions. *)
class coords (source : ImgSource.cls) x_origin y_origin = object(self)

    method paint_background ?(row = true) () =
        let w, h = match row with
            | true  -> _EDGE_ + 1, (_HMAX_ + 1) * _EDGE_
            | false -> (_WMAX_ + 1) * _EDGE_, _EDGE_ + 1
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
        self#draw_row_arrows r x y ext.Cairo.width ext.Cairo.height

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
        self#draw_column_arrows c x y ext.Cairo.width ext.Cairo.height

    method private draw_window_arrow orientation visible x y =
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

    method private draw_row_arrows r x y width height =
        self#draw_window_arrow Top (r > 0) 
            (x +. width /. 2.0 -. float _EDGE_ /. 8.0)
            (y -. height -. float _EDGE_ /. 4.0 -. 2.0);
        self#draw_window_arrow Bottom (r < source#rows - 1) 
            (x +. width /. 2.0 -. float _EDGE_ /. 8.0)
            (y +. 1.0 +. 2.0);

    method private draw_column_arrows c x y width height =
        self#draw_window_arrow Left (c > 0) 
            (x -. float _EDGE_ /. 4.0 -. 2.0)
            (y -. height);
        self#draw_window_arrow Right (c < source#columns - 1) 
            (x +. width +. 2.0)
            (y -. height)

end



(* Display prediction legend (either a color palette or individual classes).
 * Show/hide probability values when displaying a color palette. *)
class legend x_origin y_max = 

    let legend_pos_y = float (y_max + 10 + _EDGE_ + 5) in

object(self)

    method private center_horiz surface =
        let hspace = _WMAT_ - Cairo.Image.get_width surface in
        float x_origin +. 0.5 *. float hspace

    method palette () =
        let surface = AmfSurface.Legend.palette _EDGE_ in
        let x = self#center_horiz surface 
        and y = float (y_max + 10)
        and context = AmfUI.Drawing.cairo () in       
        Cairo.set_source_surface context surface x y;
        Cairo.paint context

    method classes () =
        let surface = AmfSurface.Legend.classes () in
        let x = self#center_horiz surface 
        and y = float (y_max + 10)
        and context = AmfUI.Drawing.cairo () in
        Cairo.set_source_surface context surface x y;
        Cairo.paint context

    method index_of_prob x = truncate (25.0 *. x) |> max 0 |> min 24

    method hide_probability () =
        let w = AmfUI.Predictions.get_colors ()
            |> Array.length
            |> (fun n -> (n + 2) * 12) in
        (* Draw a filled rectangle to hide any previous value. *)
        let surface = Cairo.Image.(create ARGB32 ~w ~h:_EDGE_) in
        let context = Cairo.create surface in
        let r, g, b = AmfColor.parse_rgb _BGCOLOR_ in
        Cairo.set_source_rgb context r g b;
        Cairo.rectangle context 0.0 0.0
            ~w:(float _WMAT_)
            ~h:(float _EDGE_);
        Cairo.fill context;
        (* Paint the rectangle on the drawing area. *)
        let context = AmfUI.Drawing.cairo () in
        Cairo.set_source_surface context surface
            (float x_origin +. float (_WMAT_ - w) /. 2.0)
            legend_pos_y;
        Cairo.paint context

    method show_probability pr =
        let index = self#index_of_prob pr in
        let x = AmfUI.Predictions.get_colors ()
            |> Array.length
            |> (fun n -> float x_origin +. float (_WMAT_ - 12 * n) /. 2.0)
            |> (+.) (float index *. 12.0) in
        (* Draw a vertical arrowhead below the color associated with pr. *)
        let surface = AmfSurface.Arrowhead.top ~bgcolor:_BGCOLOR_ 12 in    
        let context = AmfUI.Drawing.cairo () in
        Cairo.set_source_surface context surface x legend_pos_y;
        Cairo.paint context;
        (* Write the probability value below the arrowhead. *)
        Cairo.select_font_face context "Monospace";
        Cairo.set_font_size context 12.0;
        Cairo.set_source_rgb context 1.0 0.0 0.0;
        let text = sprintf "%.02f" pr in
        let te = Cairo.text_extents context text in
        Cairo.move_to context
            (x +. 6.0 -. te.Cairo.width /. 2.0)
            (legend_pos_y +. 10.0 +. te.Cairo.height +. 5.0);
        Cairo.show_text context text

end



class brush (source : ImgSource.cls) =

    (* GtkDrawingArea dimensions, in pixels (allocated at startup).  *)
    let ui_width = AmfUI.Drawing.width ()
    and ui_height = AmfUI.Drawing.height () in
   
    (* Coordinates of the drawing origin, in pixels. *)
    let x_origin = (ui_width - _EDGE_ * _WMAX_) / 2
    and y_origin = (ui_height - _EDGE_ * _HMAX_) / 2 in

object (self)

    val mutable rbound = 0            (* Index of the topmost row.     *)
    val mutable cbound = 0            (* Index of the leftmost column. *)
    val mutable backcolor = _BGCOLOR_ (* Background color.             *)

    val coords = new coords source x_origin y_origin
    val legend = new legend x_origin (y_origin + _HMAT_)

    val mutable update_funcs : (unit -> unit) list = []

    method set_update f = update_funcs <- f :: update_funcs

    (* Adjust the displayed area to the cursor coordinates. *)
    method has_unchanged_boundaries ~r ~c () =
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
        (* Runs update functions when the visible window changes. *)
        if !res then List.iter (fun f ->  f ()) update_funcs;
        (* Tells whether the visibe window was left unchanged. *)
        not !res
 
    method r_range = rbound, min (source#rows - 1) (rbound + _HMAX_ - 1)
    method c_range = cbound, min (source#columns - 1) (cbound + _WMAX_ - 1)

    method edge = _EDGE_
    method x_origin = x_origin
    method y_origin = y_origin

    (* Column index (c) to pixels (X axis). *)
    method private x ~c =
        assert (c >= cbound);
        x_origin + (c - cbound) * _EDGE_

    (* Row index (r) to pixels (Y axis). *)
    method private y ~r =
        assert (r >= rbound);
        y_origin + (r - rbound) * _EDGE_

    method backcolor = backcolor
    method set_backcolor x = backcolor <- x

    method sync caller () =
        AmfLog.info_debug "brush#sync (caller: %s)" caller;
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
        assert GdkPixbuf.(get_width pixbuf = _EDGE_);
        assert (GdkPixbuf.get_height pixbuf = _EDGE_);
        let pixmap = AmfUI.Drawing.pixmap () in
        pixmap#put_pixbuf
            ~x:(self#x ~c)
            ~y:(self#y ~r) pixbuf;
        if sync then AmfUI.Drawing.synchronize ()

    method surface ?(sync = false) ~r ~c surface =
        let context = AmfUI.Drawing.cairo () in
        Cairo.set_source_surface context surface
            (float (self#x ~c))
            (float (self#y ~r));
        Cairo.paint context;
        if sync then self#sync "brush#surface" ()

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

    method palette ?(sync = false) () =
        legend#palette ();
        if sync then self#sync "brush#palette" ()
        
    method classes ?(sync = false) () =
        legend#classes ();
        if sync then self#sync "brush#classes" ()

    method private coordinates ?(sync = false) ~r ~c () =
        (* Row index. *)
        coords#paint_background ();
        coords#write_row_index r (self#y ~r);
        (* Column index. *)
        coords#paint_background ~row:false ();
        coords#write_column_index c (self#x ~c);
        if sync then self#sync "brush#coordinates" ()

    method hide_probability ?(sync = false) () =
        legend#hide_probability ();
        if sync then self#sync "brush#hide_probability" ()

    method show_probability ?(sync = false) pr =
        legend#hide_probability ();
        legend#show_probability pr;
        if sync then self#sync "brush#show_probability" ()

    method private simple_square ?sync ~r ~c level set =
        assert (CSet.cardinal set = 1);
        let chr = CSet.choose set in
        let surface = AmfMemoize.layer level chr _EDGE_ in
        self#surface ?sync ~r ~c surface

    method annotation ?sync ~r ~c level set =
        (* One-color square in case of single annotation. *)
        if not (CSet.is_empty set) then begin
            (* Multicolor square in case of multiple annotations. *)
            if AmfLevel.is_myc level && AmfUI.Layers.current () = '*' then (
                let colors = List.map2 
                    (fun chr clr ->
                        if CSet.mem chr set then clr 
                        else "#FFFFFF00"
                    ) (AmfLevel.to_header level) (AmfLevel.colors level)
                in
                self#surface_from_func ?sync ~r ~c 
                    (AmfSurface.Annotation.colors colors)
            (* Simple squares in all other situations. *)
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
            |> legend#index_of_prob
            |> (fun i -> AmfMemoize.palette i _EDGE_)
            |> self#surface ?sync ~r ~c

end



let create x = new brush x 
