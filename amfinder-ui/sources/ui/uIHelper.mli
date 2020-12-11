(* The Automated Mycorrhiza Finder version 1.0 - ui/uiHelper.mli *)

(** Helper functions for custom toolbars. *)

val separator : (GButton.tool_item_o -> unit) -> unit
(** Adds a separator (and some extra space). *)

val morespace : (GButton.tool_item_o -> unit) -> unit
(** Adds more space. *)

val label : ?vspace:bool -> (GButton.tool_item_o -> unit) -> string -> GMisc.label
(** Adds a Gtklabel. *)

val pango_small : string -> string
(** Pango small text *)
