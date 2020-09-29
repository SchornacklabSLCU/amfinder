(* CastANet - imgCursor.ml *)

class type t = object
    method get : int * int
    method key_press : GdkEvent.Key.t -> bool
    method mouse_click : GdkEvent.Button.t -> bool
    method set_erase : (r:int -> c:int -> unit -> unit) -> unit
    method set_paint : (r:int -> c:int -> unit -> unit) -> unit
end



class cursor (source : ImgSource.t) (paint : ImgPaint.t) = 

object (self)

    val mutable cursor_pos = (0, 0)
    val mutable erase = (fun ~r:_ ~c:_ () -> ())
    val mutable paint = (fun ~r:_ ~c:_ () -> ())

    method get = cursor_pos
    method set_erase f = erase <- f
    method set_paint f = paint <- f

    method private move_left ?(jump = 1) () =
        let c' = c - jump and nc = source#columns in
        let c' = 
            if c' < 0 then (c' + (max 1 (1 + jump / nc)) * nc) mod nc 
            else if c' >= nc then c' mod nc else c'
        in (r, c')

    method private move_right ?(jump = 1) () =
        let c' = c + jump and nc = source#columns in
        let c' =
            if c' < 0 then (c' + nc) mod nc 
            else if c' >= nc then c' mod nc else c'
        in (r, c')
    
    method private move_up ?(jump = 1) () =
        let r' = r - jump and nr = source#rows in
        let r' =
            if r' < 0 then (r' + (max 1 (jump / nr)) * nr) mod nr
            else if r' >= nr then r' mod nr else r'
        in (r', c)

    method private move_down ?(jump = 1) () =
        let r' = r + jump and nr = source#rows in
        let r' =
            if r' < 0 then (r' + nr) mod nr
            else if r' >= nr then r' mod nr else r'
        in (r', c)

    method key_press ev =
        let modi = GdkEvent.Key.state ev in
        let jump =
            if List.mem `CONTROL modi then 25 else
            if List.mem `SHIFT   modi then 10 else 1 in
        let new_pos =
            match GdkEvent.Key.keyval ev with
            | 65361 -> self#move_left ~jump ()
            | 65362 -> self#move_up ~jump ()
            | 65363 -> self#move_right ~jump ()
            | 65364 -> self#move_down ~jump ()
            | _     -> cursor_pos in
        if new_pos = cursor_pos then false else (
            let r, c = cursor_pos in erase ~r ~c ();
            cursor_pos <- new_pos;
            let r, c = cursor_pos in paint ~r ~c ();
            true
        )

    method mouse_click ev =
        let x = truncate (GdkEvent.Button.x ev) - paint#x_origin
        and y = truncate (GdkEvent.Button.y ev) - paint#y_origin
        let r = y / paint#edge and c = x / paint#edge in
        if r >= 0 && r < source#rows 
           && c >= 0 && c < source#columns
           && (r, c) <> cursor_pos then begin
            let rc, cc = cursor_pos in erase ~r:rc ~c:cc ();
            cursor_pos <- (r, c);
            paint ~r ~c ()
        end;
        false

end


let create source paint = new cursor source paint
