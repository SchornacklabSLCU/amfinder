(* CastANet - uI_CursorPos.ml *)

open Printf



module type PARAMS = sig
    val packing : #GButton.tool_item_o -> unit
end



module type S = sig
    val row : GMisc.label
    val column : GMisc.label
    val update_coordinates : r:int -> c:int -> unit
end



let pango typ =
    let chr = match typ with
        | `ROW -> 'R' 
        | `COL -> 'C'
    in sprintf "<small><tt><b>%c:</b> %03d</tt></small>" chr



module Make (P : PARAMS) : S = struct

    let _ = UIHelper.separator P.packing
    let _ = UIHelper.label P.packing "<b><small>Coordinates</small></b>"

    let row = UIHelper.label ~vspace:false P.packing (pango `ROW 0)
    let column = UIHelper.label ~vspace:false P.packing (pango `COL 0)

    let update_coordinates ~r ~c =
        row#set_label (pango `ROW r);
        column#set_label (pango `COL c)

    let _ = UIHelper.morespace P.packing; UIHelper.morespace P.packing; UIHelper.morespace P.packing

end
