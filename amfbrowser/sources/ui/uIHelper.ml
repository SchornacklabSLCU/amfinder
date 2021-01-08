(* AMFinder - ui/uIHelper.ml
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

let separator packing = ignore (GButton.separator_tool_item ~packing ())

let morespace packing =
  let item = GButton.tool_item ~expand:false ~packing () in
  ignore (GPack.vbox ~height:5 ~packing:item#add ())

let label ?(vspace = true) packing markup =
  let item = GButton.tool_item ~packing () in
  let markup = sprintf "%s" markup in
  let label = GMisc.label ~markup ~justify:`CENTER ~packing:item#add () in
  if vspace then morespace packing;
  label

let pango_small = Printf.sprintf "<small>%s</small>"

let custom_tool_button ?packing icon label = 
    let btn = GButton.tool_button ?packing () in
    let box = GPack.hbox
        ~spacing:2
        ~packing:btn#set_label_widget () in
    let _ = GMisc.image 
        ~width:25
        ~pixbuf:(AmfIcon.get icon)
        ~packing:(box#pack ~expand:false) ()
    and _ = GMisc.label
        ~markup:(pango_small label)
        ~xalign:0.0
        ~yalign:0.5
        ~packing:box#add () in
    btn
