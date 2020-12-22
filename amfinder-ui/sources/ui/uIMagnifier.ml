(* AMFinder - ui/uIMagnifier.ml
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

open Morelib

module type PARAMS = sig
  val rows : int
  val columns : int
  val tile_edge : int
  val window : GWindow.window
  val packing : GObj.widget -> unit
end

module type S = sig
    val event_boxes : GBin.event_box Morelib.Matrix.t
    val tiles : GMisc.image Morelib.Matrix.t
    val set_pixbuf : r:int -> c:int -> GdkPixbuf.pixbuf -> unit
    val screenshot : unit -> GdkPixbuf.pixbuf
end

module Make (P : PARAMS) : S = struct
  let table = GPack.table
    ~rows:P.rows
    ~columns:P.columns
    ~packing:P.packing ()

  let tile_image ~r:top ~c:left =
    let event = GBin.event_box
      ~width:(P.tile_edge + 2)
      ~height:(P.tile_edge + 2) 
      ~packing:(table#attach ~top ~left) ()
    (* The centre has a red frame to grab users attention. *)
    and color = if top = 1 && left = 1 then "red" else "grey40" in
    event#misc#modify_bg [`NORMAL, `NAME color];
    event#event#add [`BUTTON_PRESS];
    let pixmap = GDraw.pixmap
      ~width:P.tile_edge
      ~height:P.tile_edge ()
    in event, GMisc.pixmap pixmap ~packing:event#add ()

  let all_data = Matrix.init P.rows P.columns tile_image
  let event_boxes = Matrix.map fst all_data
  let tiles = Matrix.map snd all_data
  
  let set_pixbuf ~r ~c buf =
    try
      assert (r >= 0 && r < P.rows);
      assert (c >= 0 && c < P.columns);
      tiles.(r).(c)#set_pixbuf buf
    with Assert_failure _ -> AmfLog.error "UI_Magnifier.Make.set_pixbuf was \
      given incorrect values (r = %d, c = %d)" r c
      
    let screenshot () =
        (* 3 tiles + outer margins (1 px) + inner margins (2 px). *)
        let sz = 180 * 3 + 2 * 1 + 2 * 2 in
        let screenshot = GdkPixbuf.create ~width:sz ~height:sz () in
        (* Source X and Y were determined from a window screenshot. *)
        GdkPixbuf.get_from_drawable ~dest:screenshot
            ~src_x:16 ~src_y:150 P.window#misc#window;
        screenshot
end
