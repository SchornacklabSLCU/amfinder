(* AMFinder - amfIcon.ml
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

type size = [ `SMALL | `LARGE ]
type style = [ `GRAY | `RGB ]

type id = [
    | `APP
    | `ATTACH
    | `CAM of style
    | `CONVERT
    | `DETACH
    | `EXPORT
    | `LOW_QUALITY
    | `PALETTE
    | `SETTINGS
    | `SNAP
    | `CLASS of char * size * style
]

module Dir = struct
    let main = Filename.concat (Glib.get_user_data_dir ()) "amfinder/data/icons"
    let annotations = Filename.(concat (concat main "annotations"))
    let interface = Filename.(concat (concat main "interface"))
end

let load_pixbuf size path =
    GdkPixbuf.from_file_at_size ~width:size ~height:size path

let annotation_icons =
    List.fold_left (fun res c ->
        let rgba = Dir.annotations (sprintf "%c_rgba.png" c)
        and grey = Dir.annotations (sprintf "%c_grey.png" c) in
        ((c, `SMALL, `RGB), load_pixbuf 24 rgba) ::
        ((c, `SMALL, `GRAY), load_pixbuf 24 grey) ::
        ((c, `LARGE, `RGB), load_pixbuf 48 rgba) ::
        ((c, `LARGE, `GRAY), load_pixbuf 48 grey) :: res      
    ) [] AmfLevel.all_chars_list

let overlay_icons =
    let overlay_rgba = Dir.interface "Overlay_rgba.png"
    and overlay_grey = Dir.interface "Overlay_grey.png" in
    [ (`SMALL, `RGB), load_pixbuf 24 overlay_rgba;
      (`SMALL, `GRAY), load_pixbuf 24 overlay_grey;
      (`LARGE, `RGB), load_pixbuf 48 overlay_rgba;
      (`LARGE, `GRAY), load_pixbuf 48 overlay_grey ] 

let get_class_icon chr typ clr =
    match chr with
    | '*' -> List.assoc (typ, clr) overlay_icons
    | chr -> List.assoc (chr, typ, clr) annotation_icons

module Misc = struct
    let intf_pbuf24 s = load_pixbuf 24 (Dir.interface s)
    let cam = function
        | `RGB -> intf_pbuf24 "CAMs_rgba.png"
        | `GRAY -> intf_pbuf24 "CAMs_grey.png"
    let conv = intf_pbuf24 "convert.png"
    let ambiguities = intf_pbuf24 "ambiguous.png"
    let palette = intf_pbuf24 "palette.png"
    let config = intf_pbuf24 "config.png"
    let export = intf_pbuf24 "export.png"
    let snapshot = intf_pbuf24 "snapshot.png"
    let show_preds = intf_pbuf24 "show_preds.png"
    let hide_preds = intf_pbuf24 "hide_preds.png"
    let amfbrowser = intf_pbuf24 "amfbrowser.png"
end

let get = function
    | `APP -> Misc.amfbrowser
    | `ATTACH -> Misc.show_preds
    | `CAM style -> Misc.cam style
    | `CONVERT -> Misc.conv
    | `DETACH -> Misc.hide_preds
    | `EXPORT -> Misc.export
    | `LOW_QUALITY -> Misc.ambiguities
    | `PALETTE -> Misc.palette
    | `SETTINGS -> Misc.config
    | `SNAP -> Misc.snapshot
    | `CLASS (chr, size, style) -> get_class_icon chr size style

