(* CastANet - uI_Drawing.ml *)

type drawing_tools = {
  pixmap : GDraw.pixmap;
  cairo : Cairo.context;
}

module type PARAMS = sig
  val packing : GObj.widget -> unit
end

module type S = sig
  val area : GMisc.drawing_area
  val cairo : unit -> Cairo.context
  val pixmap : unit -> GDraw.pixmap
  val width : unit -> int
  val height : unit -> int
  val synchronize : unit -> unit
end

module Make (P : PARAMS) : S = struct
  let area = 
    let frame = GBin.frame ~width:600 ~packing:P.packing () in
    GMisc.drawing_area ~packing:frame#add ()

  let dt = ref None

  let get f () = match !dt with None -> assert false | Some dt -> f dt
  let cairo = get (fun dt -> dt.cairo)
  let pixmap = get (fun dt -> dt.pixmap)
  let width = get (fun dt -> fst dt.pixmap#size)
  let height = get (fun dt -> snd dt.pixmap#size)

  let synchronize () =
    let rect = Gdk.Rectangle.create
      ~x:0 ~y:0
      ~width:(width ())
      ~height:(height ())
    in area#misc#draw (Some rect)

  let _ =
    (* Repaint masked area upon GtkDrawingArea exposure. *)
    let repaint ev =
      let open Gdk.Rectangle in
      let r = GdkEvent.Expose.area ev in
      let x = x r and y = y r and width = width r and height = height r in
      let drawing = new GDraw.drawable area#misc#window in
      drawing#put_pixmap
        ~x ~y ~xsrc:x ~ysrc:y
        ~width ~height (pixmap ())#pixmap;
      false in
    area#event#add [`EXPOSURE; `POINTER_MOTION; `BUTTON_PRESS; `LEAVE_NOTIFY];
    area#event#connect#expose repaint;
    (* Creates a GtkPixmap and its Cairo.context upon widget size allocation. *)
    let initialize {Gtk.width; height} =  
      let pixmap = GDraw.pixmap ~width ~height () in
      let cairo = Cairo_gtk.create pixmap#pixmap in
      dt := Some {pixmap; cairo}
    in area#misc#connect#size_allocate initialize
end
