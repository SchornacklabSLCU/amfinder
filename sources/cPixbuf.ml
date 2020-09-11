(* CastANet - cPixbuf.ml *)

let crop ~src_x ~src_y ~edge:e pix =
  let dest = GdkPixbuf.create ~width:e ~height:e () in
  GdkPixbuf.copy_area ~dest ~src_x ~src_y pix;
  dest
    
let resize ?(interp = `NEAREST) ~edge:e pix =
  let open GdkPixbuf in
  let scale_x = float e /. (float (get_width pix))
  and scale_y = float e /. (float (get_height pix)) in
  let dest = create ~width:e ~height:e () in
  scale ~dest ~scale_x ~scale_y ~interp pix;
  dest
