(* CastANet - imgCursor.ml *)


class cursor 
  (img_source : ImgSource.source) 
  (img_brush : ImgBrush.brush)

= object (self)

    val mutable cursor_pos = (0, 0)
    val mutable erase = []
    val mutable paint = []

    method get = cursor_pos
    method at ~r ~c = cursor_pos = (r, c)
    method set_erase f = erase <- f :: erase
    method set_paint f = paint <- f :: paint

    method private move_left ?(jump = 1) () =
        let r, c = cursor_pos in
        let c' = c - jump and nc = img_source#columns in
        let c' = 
            if c' < 0 then (c' + (max 1 (1 + jump / nc)) * nc) mod nc 
            else if c' >= nc then c' mod nc else c'
        in (r, c')

    method private move_right ?(jump = 1) () =
        let r, c = cursor_pos in
        let c' = c + jump and nc = img_source#columns in
        let c' =
            if c' < 0 then (c' + nc) mod nc 
            else if c' >= nc then c' mod nc else c'
        in (r, c')
    
    method private move_up ?(jump = 1) () =
        let r, c = cursor_pos in
        let r' = r - jump and nr = img_source#rows in
        let r' =
            if r' < 0 then (r' + (max 1 (jump / nr)) * nr) mod nr
            else if r' >= nr then r' mod nr else r'
        in (r', c)

    method private move_down ?(jump = 1) () =
        let r, c = cursor_pos in
        let r' = r + jump and nr = img_source#rows in
        let r' =
            if r' < 0 then (r' + nr) mod nr
            else if r' >= nr then r' mod nr else r'
        in (r', c)

    method private update_cursor_pos ~r ~c =
        if r >= 0 && r < img_source#rows
        && c >= 0 && c < img_source#columns
        && (r, c) <> cursor_pos then (
            let old_r, old_c = cursor_pos in
            cursor_pos <- (r, c);
            List.iter (fun f -> f ?sync:(Some false) ~r:old_r ~c:old_c ()) erase;
            CGUI.CursorPos.update_coordinates ~r ~c;
            List.iter (fun f -> f ?sync:(Some true) ~r ~c ()) paint;
            true
        ) else false

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
        let x = truncate (GdkEvent.Button.x ev) - img_brush#x_origin
        and y = truncate (GdkEvent.Button.y ev) - img_brush#y_origin in
        let r = y / img_brush#edge 
        and c = x / img_brush#edge in
        ignore (self#update_cursor_pos ~r ~c);
        false

end


let create img_source paint = new cursor img_source paint
