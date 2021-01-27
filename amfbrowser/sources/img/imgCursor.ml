(* AMFinder - img/imgCursor.ml
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
    method get : int * int
    method at : r:int -> c:int -> bool
    method hide : unit -> unit
    method show : unit -> unit 
    method key_press : GdkEvent.Key.t -> bool
    method mouse_click : GdkEvent.Button.t -> bool
    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    method update_cursor_pos : r:int -> c:int -> bool
end

class cursor (source : ImgSource.cls) (brush : ImgBrush.cls)

= object (self)

    val mutable mem_cursor = None
    val mutable cursor_pos = (0, 0)
    val mutable erase = []
    val mutable paint = []

    method get = cursor_pos
    method at ~r ~c = cursor_pos = (r, c)
    method set_erase f = erase <- f :: erase
    method set_paint f = paint <- f :: paint

    method show () =
        match mem_cursor with
        | None -> ()
        | Some (r, c) -> cursor_pos <- (r, c);
            let sync = Some true in
            List.iter (fun f -> f ?sync ~r ~c ()) paint

    method hide () =
        let r, c = self#get and sync = Some true in
        mem_cursor <- Some (r, c);
        cursor_pos <- (-1, -1);
        List.iter (fun f -> f ?sync ~r ~c ()) erase

    method private move_left ?(jump = 1) () =
        let r, c = cursor_pos in
        let c' = c - jump and nc = source#columns in
        let c' = 
            if c' < 0 then (c' + (max 1 (1 + jump / nc)) * nc) mod nc 
            else if c' >= nc then c' mod nc else c'
        in (r, c')

    method private move_right ?(jump = 1) () =
        let r, c = cursor_pos in
        let c' = c + jump and nc = source#columns in
        let c' =
            if c' < 0 then (c' + nc) mod nc 
            else if c' >= nc then c' mod nc else c'
        in (r, c')
    
    method private move_up ?(jump = 1) () =
        let r, c = cursor_pos in
        let r' = r - jump and nr = source#rows in
        let r' =
            if r' < 0 then (r' + (max 1 (jump / nr)) * nr) mod nr
            else if r' >= nr then r' mod nr else r'
        in (r', c)

    method private move_down ?(jump = 1) () =
        let r, c = cursor_pos in
        let r' = r + jump and nr = source#rows in
        let r' =
            if r' < 0 then (r' + nr) mod nr
            else if r' >= nr then r' mod nr else r'
        in (r', c)

    method update_cursor_pos ~r ~c =
        if r >= 0 && r < source#rows
        && c >= 0 && c < source#columns
        && (r, c) <> cursor_pos then begin
            let old_r, old_c = cursor_pos in
            cursor_pos <- (r, c);
            if brush#has_unchanged_boundaries ~r ~c () then begin 
            List.iter (fun f -> f ?sync:(Some false) ~r:old_r ~c:old_c ()) erase;
            List.iter (fun f -> f ?sync:(Some true) ~r ~c ()) paint;
            end;
        end;
        false (* same event has to go to image#ui. *)

    method key_press ev =
        let modi = GdkEvent.Key.state ev in
        let jump =
            if List.mem `CONTROL modi then 25 else
            if List.mem `SHIFT   modi then 10 else 1 in
        let r, c =
            match GdkEvent.Key.keyval ev with
            | 65361 -> self#move_left ~jump ()
            | 65362 -> self#move_up ~jump ()
            | 65363 -> self#move_right ~jump ()
            | 65364 -> self#move_down ~jump ()
            | _     -> cursor_pos
        in self#update_cursor_pos ~r ~c


    method mouse_click ev =
        let rmin, _ = brush#r_range 
        and cmin, _ = brush#c_range in
        let x = GdkEvent.Button.x ev -. float brush#x_origin
        and y = GdkEvent.Button.y ev -. float brush#y_origin in
        let edge = float brush#edge in
        let r = rmin + truncate (y /. edge)
        and c = cmin + truncate (x /. edge) in
        ignore (self#update_cursor_pos ~r ~c);
        false

end


let create source paint = new cursor source paint
