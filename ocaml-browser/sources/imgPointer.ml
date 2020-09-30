(* CastANet Browser - imgPointer.ml *)

class pointer (source : ImgSource.source) (img_paint : ImgPaint.paint) = 

object

    val mutable pos = None
    val mutable erase = (fun ~r:_ ~c:_ () -> ())
    val mutable paint = (fun ~r:_ ~c:_ () -> ())

    method get = pos
    method set_erase f = erase <- f
    method set_paint f = paint <- f

    method track ev =
        let x = truncate (GdkEvent.Motion.x ev) - img_paint#x_origin
        and y = truncate (GdkEvent.Motion.y ev) - img_paint#y_origin in
        let r = y / img_paint#edge and c = x / img_paint#edge in
        if r >= 0 && r < source#rows 
        && c >= 0 && c < source#columns then begin
            Option.iter (fun (r, c) -> erase ~r ~c ()) pos;
            pos <- Some (r, c);
            paint ~r ~c ()
        end;
        false

    method leave (_ : GdkEvent.Crossing.t)  =
        Option.iter (fun (r, c) -> erase ~r ~c ()) pos;
        pos <- None;
        false
end

let create source paint = new pointer source paint
