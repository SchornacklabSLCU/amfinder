(* CastANet - uI_Helper.ml *)

val separator : (GButton.tool_item_o -> unit) -> unit

val morespace : (GButton.tool_item_o -> unit) -> unit

val label : ?vspace:bool -> (GButton.tool_item_o -> unit) -> string -> GMisc.label
