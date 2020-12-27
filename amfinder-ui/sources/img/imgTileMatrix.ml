(* AMFinder - img/imgTileMatrix.ml
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
open ImgShared


class type cls = object
    method get : r:int -> c:int -> GdkPixbuf.pixbuf option
    method iter : (r:int -> c:int -> GdkPixbuf.pixbuf -> unit) -> unit
end


class tile_matrix pixbuf (source : ImgSource.cls) edge =

object (self)

    val data = Morelib.Matrix.init
        ~r:source#rows
        ~c:source#columns (fun ~r:_ ~c:_ -> None)

    method private extract r c =
        let crop = crop_pixbuf
            ~src_x:(c * source#edge)
            ~src_y:(r * source#edge)
            ~edge:source#edge pixbuf
        in resize_pixbuf edge crop

    method get ~r ~c =
        match Matrix.get_opt data ~r ~c with
        | None -> None (* Wrong r/c values. *)
        | Some opt -> match opt with
            | None -> let tile = self#extract r c in
                data.(r).(c) <- Some tile;
                Some tile
            | some -> some
    
    method iter f =
        let rec loop r c =
            begin match self#get ~r ~c with
                | None -> assert false (* does not happen. *)
                | Some pixbuf -> let () = f ~r ~c pixbuf in ()
            end;
            let r', c' = 
                if c + 1 = source#columns then r + 1, 0 
                else r, c + 1 in
            if r' < source#rows then loop r' c' 
        in loop 0 0

end


let create a b c = new tile_matrix a b c
