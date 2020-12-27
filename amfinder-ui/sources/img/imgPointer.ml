(* AMFinder - img/imgPointer.ml
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

class type cls = object
    method get : (int * int) option
    method at : r:int -> c:int -> bool
    method track : GdkEvent.Motion.t -> bool
    method leave : GdkEvent.Crossing.t -> bool
    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
end


class pointer (source : ImgSource.cls) (brush : ImgBrush.cls)

= object (self)

    val mutable pos = None
    val mutable erase = (fun ?sync:_ ~r:_ ~c:_ () -> ())
    val mutable paint = (fun ?sync:_ ~r:_ ~c:_ () -> ())

    method get = pos
    method set_erase f = erase <- f
    method set_paint f = paint <- f

    method at ~r ~c =
        match pos with
        | None -> false
        | Some (cr, cc) -> r = cr && c = cc

    method private update_pointer_pos ~r ~c =
        let rmin, rmax = brush#r_range 
        and cmin, cmax = brush#c_range in
        if r >= rmin && r <= rmax 
        && c >= cmin && c <= cmax then
            begin 
                match pos with
                | Some old when old = (r, c) -> () (* same position *)
                | _ -> let old = pos in
                    pos <- None;
                    Option.iter (fun (r, c) -> erase ~sync:false ~r ~c ()) old;
                    pos <- Some (r, c);
                    paint ~sync:true ~r ~c ();
            end
        else Option.iter (fun (r, c) -> pos <- None; erase ~sync:true ~r ~c ()) pos

    method track ev =
        let rmin, _ = brush#r_range 
        and cmin, _ = brush#c_range in
        let x = GdkEvent.Motion.x ev -. float brush#x_origin
        and y = GdkEvent.Motion.y ev -. float brush#y_origin in
        let r, c =
            if x < 0.0 || y < 0.0 then (-1, -1) else
                let edge = float brush#edge in
                (rmin + truncate (y /. edge), cmin + truncate (x /. edge))
        in 
        self#update_pointer_pos ~r ~c;
        false

    method leave (_ : GdkEvent.Crossing.t)  =
        Option.iter (fun (r, c) ->
            pos <- None;
            erase ~sync:true ~r ~c ()
        ) pos;
        false

end



let create x y = new pointer x y
