(* AMFinder - ui/uITools.ml
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

module type PARAMS = sig
    val packing : GObj.widget -> unit
    val border_width : int
    val tooltips : GData.tooltips
end

module type S = sig
    val toolbar : GButton.toolbar
    val config : GButton.tool_button
    val export : GButton.tool_button
    val snapshot : GButton.tool_button
end

module Make (P : PARAMS) : S = struct

    let toolbar = GButton.toolbar
        ~orientation:`VERTICAL
        ~style:`ICONS
        ~width:92 ~height:155
        ~packing:P.packing ()

    let packing = toolbar#insert

    let _ = UIHelper.separator packing
    let _ = UIHelper.label packing "<b><small>Toolbox</small></b>"

    let snapshot = 
        let btn = GButton.tool_button ~packing () in
        let box = GPack.hbox
            ~spacing:2
            ~packing:btn#set_label_widget () in
        let _ = GMisc.image 
            ~width:25
            ~pixbuf:AmfIcon.Misc.snapshot
            ~packing:(box#pack ~expand:false) ()
        and _ = GMisc.label
            ~markup:(UIHelper.pango_small "Snap")
            ~xalign:0.0
            ~yalign:0.5
            ~packing:box#add () in
        btn

    let export = 
        let btn = GButton.tool_button ~packing () in
        let box = GPack.hbox
            ~spacing:2
            ~packing:btn#set_label_widget () in
        let _ = GMisc.image 
            ~width:25
            ~pixbuf:AmfIcon.Misc.export
            ~packing:(box#pack ~expand:false) ()
        and _ = GMisc.label
            ~markup:(UIHelper.pango_small "Export")
            ~xalign:0.0
            ~yalign:0.5
            ~packing:box#add () in
        btn

    let config = 
        let btn = GButton.tool_button ~packing () in
        P.tooltips#set_tip ~text:"Application settings" btn#coerce;
        let box = GPack.hbox
            ~spacing:2
            ~packing:btn#set_label_widget () in
        let _ = GMisc.image 
            ~width:25
            ~pixbuf:AmfIcon.Misc.config
            ~packing:(box#pack ~expand:false) ()
        and _ = GMisc.label
            ~markup:(UIHelper.pango_small "Settings")
            ~xalign:0.0
            ~yalign:0.5
            ~packing:box#add () in
        btn
end
