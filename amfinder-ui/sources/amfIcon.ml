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

type size = Small | Large
type style = Grayscale | RGBA

module Dir = struct
    let main = "data/icons"
    let annotations = Filename.(concat (concat main "annotations"))
    let interface = Filename.(concat (concat main "interface"))
end

let load_pixbuf size path =
    GdkPixbuf.from_file_at_size ~width:size ~height:size path

let annotation_icons =
    List.fold_left (fun res c ->
        let rgba = Dir.annotations (sprintf "%c_rgba.png" c)
        and grey = Dir.annotations (sprintf "%c_grey.png" c) in
        ((c, Small, RGBA), load_pixbuf 24 rgba) ::
        ((c, Small, Grayscale), load_pixbuf 24 grey) ::
        ((c, Large, RGBA), load_pixbuf 48 rgba) ::
        ((c, Large, Grayscale), load_pixbuf 48 grey) :: res      
    ) [] AmfLevel.all_chars_list

let overlay_icons =
    let overlay_rgba = Dir.interface "Overlay_rgba.png"
    and overlay_grey = Dir.interface "Overlay_grey.png" in
    [ (Small, RGBA), load_pixbuf 24 overlay_rgba;
      (Small, Grayscale), load_pixbuf 24 overlay_grey;
      (Large, RGBA), load_pixbuf 48 overlay_rgba;
      (Large, Grayscale), load_pixbuf 48 overlay_grey ] 

let get chr typ clr =
    match chr with
    | '*' -> List.assoc (typ, clr) overlay_icons
    | chr -> List.assoc (chr, typ, clr) annotation_icons

module Misc = struct
    let cam = function
        | RGBA -> load_pixbuf 24 (Dir.interface "CAMs_rgba.png")
        | Grayscale -> load_pixbuf 24 (Dir.interface "CAMs_grey.png")
    let conv = load_pixbuf 24 (Dir.interface "convert.png")
    let ambiguities = load_pixbuf 24 (Dir.interface "ambiguous.png")
    let palette = load_pixbuf 24 (Dir.interface "palette.png")
    let erase = load_pixbuf 24 (Dir.interface "erase.png")
    let snapshot = load_pixbuf 24 (Dir.interface "snapshot.png")
    let show_preds = load_pixbuf 24 (Dir.interface "show_preds.png")
    let hide_preds = load_pixbuf 24 (Dir.interface "hide_preds.png")
end
