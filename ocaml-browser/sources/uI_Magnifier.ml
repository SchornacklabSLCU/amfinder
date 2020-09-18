(* CastANet - uI_Magnifier.ml *)

open CExt

module type PARAMS = sig
  val rows : int
  val columns : int
  val tile_edge : int
  val packing : GObj.widget -> unit
end

module type S = sig
  val tiles : GMisc.image array array
  val set_pixbuf : r:int -> c:int -> GdkPixbuf.pixbuf -> unit
end

module Make (P : PARAMS) : S = struct
  let table = GPack.table
    ~rows:P.rows
    ~columns:P.columns
    ~packing:P.packing ()

  let tile_image top left =
    let event = GBin.event_box
      ~width:(P.tile_edge + 2)
      ~height:(P.tile_edge + 2) 
      ~packing:(table#attach ~top ~left) ()
    (* The centre has a red frame to grab users attention. *)
    and color = if top = 1 && left = 1 then "red" else "grey40" in
    event#misc#modify_bg [`NORMAL, `NAME color];
    let pixmap = GDraw.pixmap
      ~width:P.tile_edge
      ~height:P.tile_edge ()
    in GMisc.pixmap pixmap ~packing:event#add ()

  let tiles = Ext_Matrix.init P.rows P.columns tile_image
  
  let set_pixbuf ~r ~c buf =
    try
      assert (r >= 0 && r < P.rows);
      assert (c >= 0 && c < P.columns);
      tiles.(r).(c)#set_pixbuf buf
    with Assert_failure _ -> CLog.error "UI_Magnifier.Make.set_pixbuf was \
      given incorrect values (r = %d, c = %d)" r c
end
