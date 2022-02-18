(* AMFinder - img/imgShared.ml
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

open GdkPixbuf

let crop_pixbuf ~src_x ~src_y ~edge pixbuf =
    let dest = create ~width:edge ~height:edge ~has_alpha:true () in
    copy_area ~dest ~src_x ~src_y pixbuf;
    dest

let resize_pixbuf ?(interp = `NEAREST) edge pixbuf =
    let width = get_width pixbuf
    and height = get_height pixbuf in
    if width = edge && height = edge then pixbuf else begin
        let scale_x = float edge /. (float width)
        and scale_y = float edge /. (float height) in
        let dest = create ~width:edge ~height:edge ~has_alpha:true () in
        scale ~dest ~scale_x ~scale_y ~interp pixbuf;
        dest
    end
