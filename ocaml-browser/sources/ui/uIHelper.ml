(* CastANet - uI_Helper.ml *)

open Printf

let separator packing = ignore (GButton.separator_tool_item ~packing ())

let morespace packing =
  let item = GButton.tool_item ~expand:false ~packing () in
  ignore (GPack.vbox ~height:5 ~packing:item#add ())

let label ?(vspace = true) packing markup =
  let item = GButton.tool_item ~packing () in
  let markup = sprintf "%s" markup in
  let label = GMisc.label ~markup ~justify:`CENTER ~packing:item#add () in
  if vspace then morespace packing;
  label
