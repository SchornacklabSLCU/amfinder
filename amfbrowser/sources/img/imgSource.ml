(* AMFinder - img/imgSource.ml
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

class type cls = object
    method width : int
    method height : int
    method edge : int
    method rows : int
    method columns : int
    method save_settings : Zip.out_file -> unit
end


class source ?zip pixbuf =

    let edge =
        match zip with
        | None -> !AmfPar.edge
        | Some ich -> Zip.find_entry ich "settings.json"
            |> Zip.read_entry ich
            |> (fun s -> sscanf s "{%_[\"']tile_edge%_[\"']: %d}" (fun n -> n)) in

object (self)

    val width = GdkPixbuf.get_width pixbuf

    val height = GdkPixbuf.get_height pixbuf

    method edge = edge

    method width = width

    method height = height

    method rows = height / edge

    method columns = width / edge

    method save_settings och =
        let data = sprintf "{\"tile_edge\": %d}" edge in
        Zip.add_entry data och "settings.json"

end


let create ?zip pixbuf = new source ?zip pixbuf
