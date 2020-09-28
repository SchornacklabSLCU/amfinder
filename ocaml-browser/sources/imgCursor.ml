(* CastANet - imgCursor.ml *)


class type t = object
    method cursor_pos : int * int
    method set_cursor_pos : int * int -> unit
    method move_left : ?jump:int -> unit -> unit
    method move_right : ?jump:int -> unit -> unit
    method move_up : ?jump:int -> unit -> unit
    method move_down : ?jump:int -> unit -> unit
end



class cursor_pos (source : ImgSource.t) = object

    val mutable cursor_pos = (0, 0)

    method cursor_pos = cursor_pos
    method set_cursor_pos x = cursor_pos <- x

    method move_left ?(jump = 1) () =
        let c' = c - jump and nc = source#columns in
        let c' = 
            if c' < 0 then (c' + (max 1 (1 + jump / nc)) * nc) mod nc 
            else if c' >= nc then c' mod nc else c'
        in cursor_pos <- (r, c')

    method move_right ?(jump = 1) () =
        let c' = c + jump and nc = source#columns in
        let c' =
            if c' < 0 then (c' + nc) mod nc 
            else if c' >= nc then c' mod nc else c'
        in cursor_pos <- (r, c')
    
    method move_up ?(jump = 1) () =
        let r' = r - jump and nr = source#rows in
        let r' =
            if r' < 0 then (r' + (max 1 (jump / nr)) * nr) mod nr
            else if r' >= nr then r' mod nr else r'
        in cursor_pos <- (r', c)

    method move_down ?(jump = 1) () =
        let r' = r + jump and nr = source#rows in
        let r' =
            if r' < 0 then (r' + nr) mod nr
            else if r' >= nr then r' mod nr else r'
        in cursor_pos <- (r', c)

end


let create source = new cursor_pos source
