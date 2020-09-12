(* CastANet - uI_Palette.mli *)

(** GUI auxiliary module. Loads color palettes. *)

module type PARAMS = sig
  val packing : GObj.widget -> unit
end

module type S = sig
  val ids : unit -> string list
  (** Returns the list of available palette identifiers. *)
  
  val colors : id:string -> string array option
  (** Returns the colors associated with the given palette identifier. *)
  
  val current : unit -> string
  (** Returns the current palette identifier. *)
  
  val set_current : id:string -> unit
  (** Sets the current palette identifier. *)
  
  val toolbar : GButton.toolbar
  (** Main container. *)

  val palette : GButton.tool_button
  (** Displays a small utility window to select a palette. *)
end

module Make : PARAMS -> S
(** Generator. *)
