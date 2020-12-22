(* AMFinder - ui/uITileSet.ml
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

open Printf

module type PARAMS = sig
  val parent : GWindow.window
  val spacing : int
  val border_width : int
  val window_width : int
  val window_height : int
  val window_title : string
end

module type S = sig
  val add : r:int -> c:int -> ico:GdkPixbuf.pixbuf -> GdkPixbuf.pixbuf -> unit
  val run : unit -> [`OK | `SAVE | `DELETE_EVENT]
  val set_title : ('a, unit, string, unit) format4 -> 'a
  val hide : unit -> unit
end

module Make (P : PARAMS) : S = struct
  let cols = new GTree.column_list
  let coords = cols#add Gobject.Data.string
  let pixbuf = cols#add (Gobject.Data.gobject_by_name "GdkPixbuf")
  let mycflg = cols#add (Gobject.Data.gobject_by_name "GdkPixbuf")
  let store = GTree.list_store cols

  let add ~r ~c ~ico pix =
    let row = store#append ()
    and str = sprintf "<span foreground='white'><tt><b>R:</b>%03d\n\
      <b>C:</b>%03d</tt></span>" r c in
    store#set ~row ~column:coords str;
    store#set ~row ~column:pixbuf pix;
    store#set ~row ~column:mycflg ico

  let window =
    let wnd = GWindow.dialog
      ~parent:P.parent
      ~destroy_with_parent:true
      ~width:P.window_width
      ~height:P.window_height
      ~title:P.window_title
      ~resizable:false
      ~position:`CENTER_ON_PARENT
      ~type_hint:`MENU
      ~modal:true
      ~show:false () in
    wnd#add_button_stock `SAVE `SAVE;
    wnd#add_button_stock `OK `OK;
    wnd#vbox#set_border_width P.spacing;
    wnd

  let run = window#run
  let set_title fmt = ksprintf window#set_title fmt

  let hide =
    let hide () = window#misc#hide (); store#clear () in
    window#event#connect#delete (fun _ -> hide (); true);
    hide

  module Cell = struct
    let xc = `XALIGN 0.5
    let yc = `YALIGN 0.5
    let sz = 180
    let bg = `CELL_BACKGROUND_GDK (GDraw.color (`NAME "dimgray"))
    open GTree
    let mycflg = cell_renderer_pixbuf [bg; `XPAD 2; `WIDTH 34; xc; yc]
    let coords = cell_renderer_text [bg; `WIDTH 60; `XALIGN 0.; yc]
    let pixbuf = cell_renderer_pixbuf [bg; `WIDTH sz; `HEIGHT (sz + 2); xc; yc]
  end

  module VCol = struct
    let mycflg =
      let col = GTree.view_column
        ~renderer:(Cell.mycflg, ["pixbuf", mycflg]) () in
      col#set_fixed_width 34;
      col#set_sizing `FIXED;
      col
    let coords =
      let col = GTree.view_column
        ~renderer:(Cell.coords, ["markup", coords]) () in
      col#set_fixed_width 60;
      col#set_sizing `FIXED;
      col
    let pixbuf = 
      let col = GTree.view_column 
        ~renderer:(Cell.pixbuf, ["pixbuf", pixbuf]) () in
      col#set_fixed_width Cell.sz;
      col#set_sizing `FIXED;
      col
  end

  let view = 
    let scroll = GBin.scrolled_window
      ~hpolicy:`NEVER
      ~vpolicy:`ALWAYS
      ~shadow_type:`ETCHED_OUT
      ~border_width:P.border_width
      ~packing:window#vbox#add () in
    let icons = GTree.view
      ~model:store
      ~fixed_height_mode:true
      ~headers_visible:false
      ~enable_search:false
      ~border_width:P.border_width
      ~packing:scroll#add_with_viewport () in
    icons#append_column VCol.mycflg;
    icons#append_column VCol.pixbuf;
    icons#append_column VCol.coords;
    icons#selection#set_mode `NONE;
    icons#misc#set_can_focus false;
    icons
end
