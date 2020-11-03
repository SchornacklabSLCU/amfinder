(* CastANet Browser - imgPointer.ml *)

class pointer 
  (img_source : ImgTypes.source)
  (img_brush : ImgTypes.brush)

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
        let rmin, rmax = img_brush#r_range 
        and cmin, cmax = img_brush#c_range in
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
        let rmin, _ = img_brush#r_range 
        and cmin, _ = img_brush#c_range in
        let x = GdkEvent.Motion.x ev -. float img_brush#x_origin
        and y = GdkEvent.Motion.y ev -. float img_brush#y_origin in
        let r, c =
            if x < 0.0 || y < 0.0 then (-1, -1) else
                let edge = float img_brush#edge in
                (rmin + truncate (y /. edge), cmin + truncate (x /. edge))
        in 
        self#update_pointer_pos ~r ~c;
        false

    method leave (_ : GdkEvent.Crossing.t)  =
        Option.iter (fun (r, c) -> pos <- None; erase ~sync:true ~r ~c ()) pos;
        false

end



let create x y = new pointer x y
