(* CastANet - cPaint.ml *)

open CGUI
open CExt

module Surface = struct
  let square ?(alpha = 0.85) ~kind edge =
    assert (edge > 0); 
    let surface = Cairo.Image.(create ARGB32 ~w:edge ~h:edge) in
    let t = Cairo.create surface in
    Cairo.set_antialias t Cairo.ANTIALIAS_SUBPIXEL;
    let clr = match kind with 
      | `CURSOR -> "#cc0000" 
      | `RGB x -> x in
    let r, g, b = EColor.html_to_float clr
    and a = max (min alpha 1.0) 0.0 in
    Cairo.set_source_rgba t r g b a;
    let edge = float edge in
    Cairo.rectangle t 0.0 0.0 ~w:edge ~h:edge;
    Cairo.fill t;
    Cairo.stroke t;
    surface

  let joker = 
    let aux () =
      match (CImage.get_active ()) with
      | None -> assert false (* does not happen. *)
      | Some img -> let edge = CImage.edge img `SMALL in
        square ~kind:(`RGB "#aaffaa") edge
    in Ext_Memoize.create ~label:"Surface.master" aux

  let cursor = 
    let aux () =
      match (CImage.get_active ()) with
      | None -> assert false (* does not happen. *)
      | Some img -> let edge = CImage.edge img `SMALL in
        square ~kind:`CURSOR edge
    in Ext_Memoize.create ~label:"Surface.cursor" aux

  let pointer = 
    let create () = 
      match (CImage.get_active ()) with
      | None -> assert false
      | Some img -> let edge = CImage.edge img `SMALL in
        square ~kind:`CURSOR ~alpha:0.40 edge
    in Ext_Memoize.create ~label:"Surface.pointer" create

  let layers =
    List.map (fun lvl ->
      let aux lvl () =
        match (CImage.get_active ()) with
        | None -> assert false (* does not happen. *)
        | Some img -> let edge = CImage.edge img `SMALL in   
          List.map2 (fun chr rgb ->
            chr, square ~kind:(`RGB rgb) edge
          ) (CAnnot.char_list lvl) (CLevel.colors lvl)
      in lvl, Ext_Memoize.create ~label:"Surface.layers" (aux lvl)
    ) CLevel.flags

  let get_from_char = function
    | '*' -> joker ()
    | '.' -> cursor ()
    | chr -> let lvl = GUI_levels.current () in
      List.assoc chr (List.assoc lvl layers ()) 
end


let white_background ?(sync = true) () =
  let t = GUI_Drawing.cairo () in
  Cairo.set_source_rgba t 1.0 1.0 1.0 1.0;
  let w = float (GUI_Drawing.width ()) 
  and h = float (GUI_Drawing.height ()) in
  Cairo.rectangle t 0.0 0.0 ~w ~h;
  Cairo.fill t;
  Cairo.stroke t;
  if sync then GUI_Drawing.synchronize ()


let tiles ?(sync = true) () =
  Option.iter (fun img ->
    let pixmap = GUI_Drawing.pixmap ()
    and xini = CImage.origin img `X
    and yini = CImage.origin img `Y
    and edge = CImage.edge img `SMALL in
    CImage.iter_tiles (fun ~r ~c tile ->
      pixmap#put_pixbuf
        ~x:(xini + c * edge)
        ~y:(yini + r * edge)
        ~width:edge ~height:edge tile
    ) img `SMALL;
    if sync then GUI_Drawing.synchronize ()
  ) (CImage.get_active ())


let tile ?(sync = false) ~r ~c () =
  Option.iter (fun img ->
    Option.iter (fun tile ->
      (GUI_Drawing.pixmap ())#put_pixbuf
        ~x:(CImage.x ~c img `SMALL)
        ~y:(CImage.y ~r img `SMALL) tile;
      if sync then GUI_Drawing.synchronize ()
    ) (CImage.tile r c img `SMALL)
  ) (CImage.get_active ())


(* FIXME Unsafe function - not for use outside! *)
let surface ?(sync = false) ~r ~c surface =
  Option.iter (fun img ->
    let t = GUI_Drawing.cairo () in
    let x = CImage.x ~c img `SMALL 
    and y = CImage.y ~r img `SMALL in
    Cairo.set_source_surface t surface (float x) (float y);
    Cairo.paint t;
    if sync then GUI_Drawing.synchronize ()
  ) (CImage.get_active ())


let annot ?(sync = false) ~r ~c () =
  Option.iter (fun img ->
    let typ = GUI_Layers.get_active ()
    and tbl = CImage.annotations img
    and lvl = GUI_levels.current () in
    let draw = match typ with
      | '*' -> not (CTable.is_empty tbl lvl ~r ~c) (* Catches any annotation. *)
      | chr -> CTable.mem tbl lvl r c (`CHR chr) in
    if draw then begin
      surface ~r ~c (Surface.get_from_char typ);
      if sync then GUI_Drawing.synchronize ()
    end
  ) (CImage.get_active ())


let cursor ?(sync = false) () =
  Option.iter (fun img ->
    let r, c = CImage.cursor_pos img in
    tile ~r ~c ();
    surface ~r ~c (Surface.get_from_char '.');
    if sync then GUI_Drawing.synchronize ()
  ) (CImage.get_active ())


let active_layer ?(sync = true) () =
  Option.iter (fun img ->
    CTable.iter (fun ~r ~c _ ->
      tile ~r ~c ();
      annot ~r ~c ()
    ) (CImage.annotations img) (GUI_levels.current ());
    cursor ();
(*     let r, c = CImage.cursor_pos img in
    Img_UI_update.set_coordinates r c; *)
    if sync then GUI_Drawing.synchronize ()
  ) (CImage.get_active ())
