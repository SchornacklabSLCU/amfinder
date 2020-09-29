(* CastANet Browser - imgPointer.ml *)

class type t = object
    method get : (int * int) option
    method track : GdkEvent.Motion.t -> bool
    method leave : GdkEvent.Crossing.t -> bool
    method set_erase : (r:int -> c:int -> unit -> unit) -> unit
    method set_paint : (r:int -> c:int -> unit -> unit) -> unit
end

class pointer (source : ImgSource.t) (paint : ImgPaint.t) = object

    val mutable pos = None
    val mutable erase = (fun ~r:_ ~c:_ () -> ())
    val mutable paint = (fun ~r:_ ~c:_ () -> ())

    method get = pos
    method set_erase f = erase <- f
    method set_paint f = paint <- f

    method track ev =
      let x = truncate (GdkEvent.Motion.x ev) - paint#x_origin
      and y = truncate (GdkEvent.Motion.y ev) - paint#y_origin in
      let r = y / paint#edge and c = x / paint#edge in
        if r >= 0 && r < source#rows 
        && c >= 0 && c < source#columns then begin
            Option.iter (fun (r, c) -> erase ~r ~c) pos;
            pos <- Some (r, c);
            paint ~r ~c
        end;

    method leave _ =
        Option.iter (fun (r, c) -> erase ~r ~c) pos;
        pos <- None
end

let create source paint = new pointer source paint
