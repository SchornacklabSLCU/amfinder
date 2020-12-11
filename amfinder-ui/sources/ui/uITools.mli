(* The Automated Mycorrhiza Finder version 1.0 - ui/uITools.mli *)

(** Toolbox *)

module type PARAMS = sig
    val packing : GObj.widget -> unit
    val border_width : int
end

module type S = sig
    val toolbar : GButton.toolbar
    val erase : GButton.tool_button
    val snapshot : GButton.tool_button
end

module Make : PARAMS -> S
(** Generator. *)
