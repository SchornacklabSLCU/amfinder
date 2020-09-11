(* CastANet - uI_CursorPos.ml *)

module type PARAMS = sig
  val packing : top:int -> GObj.widget -> unit
end

module type S = sig
  val toolbar : GButton.toolbar
  val row : GMisc.label
  val column : GMisc.label
end

module type LABEL = sig
  val toolbar : GButton.toolbar
  val label_1 : GMisc.label
  val label_2 : GMisc.label
end

module Make (P : PARAMS) : S = struct
  let make_toolbar_and_labels ~top ~title ~vsp1 ~vsp2 ~lbl1 ~lbl2 =
    let module M = struct
      let toolbar = GButton.toolbar
        ~orientation:`VERTICAL
        ~style:`ICONS
        ~width:78 ~height:80
        ~packing:(P.packing ~top) ()
      let packing = toolbar#insert
      let _ = UI_Helper.separator packing; UI_Helper.label packing title
      let label_1 = UI_Helper.label ~vspace:vsp1 packing lbl1
      let label_2 = UI_Helper.label ~vspace:vsp2 packing lbl2
    end in (module M : LABEL)

    let lbl = make_toolbar_and_labels
      ~top:0 ~title:"Coordinates" 
      ~vsp1:false ~vsp2:false
      ~lbl1:"<tt><b>R:</b> 000</tt>"
      ~lbl2:"<tt><b>C:</b> 000</tt>" 
    include (val lbl : LABEL)
    let row = label_1
    let column = label_2
end
