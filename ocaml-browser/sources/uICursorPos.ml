(* CastANet - uI_CursorPos.ml *)

open Printf

module type PARAMS = sig
  val packing : top:int -> GObj.widget -> unit
end

module type S = sig
  val toolbar : GButton.toolbar
  val row : GMisc.label
  val column : GMisc.label
  val set : r:int -> c:int -> unit
end

let pango typ =
  let chr = match typ with
    | `ROW -> 'R' 
    | `COL -> 'C'
  in sprintf "<small><tt><b>%c:</b> %03d</tt></small>" chr

module Make (P : PARAMS) : S = struct
  let toolbar = GButton.toolbar
    ~orientation:`VERTICAL
    ~style:`ICONS
    ~width:78 ~height:75
    ~packing:(P.packing ~top:0) ()

  let packing = toolbar#insert

  let _ =
    UIHelper.separator packing;
    UIHelper.label packing "<small>Coordinates</small>"

  let row = UIHelper.label ~vspace:false packing (pango `ROW 0)
  let column = UIHelper.label ~vspace:false packing (pango `COL 0)
    
  let set ~r ~c =
    row#set_label (pango `ROW r);
    column#set_label (pango `COL c)
end
