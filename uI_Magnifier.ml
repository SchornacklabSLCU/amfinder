(* CastANet - uI_Magnifier.ml *)

module type PARAMS = sig
  val rows : int
  val columns : int
  val tile_edge : int
  val packing : GObj.widget -> unit
end

module type S = sig
  val tiles : GMisc.image array array
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
    and color = if top = 1 && left = 1 then "red" else "gray60" in
    event#misc#modify_bg [`NORMAL, `NAME color];
    let pixmap = GDraw.pixmap ~width:P.tile_edge ~height:P.tile_edge () in
    GMisc.pixmap pixmap ~packing:event#add ()

  let tiles = Array.(init P.rows (fun t -> init P.columns (tile_image t)))
end
