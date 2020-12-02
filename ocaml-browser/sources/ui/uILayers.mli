(* CastANet - uI_Layers.mli *)

module type PARAMS = sig
  val packing : GObj.widget -> unit
  val remove : GObj.widget -> unit
  val current : unit -> AmfLevel.level
  val radios : (AmfLevel.level * GButton.radio_button) list
end

module type S = sig
  val current : unit -> char
  (** Indicates which layer is currently active. *)

  val set_label : char -> int -> unit
  (** Updates the counter of the given annotation. *)

  val set_callback : 
    (char -> 
      GButton.radio_tool_button -> GMisc.label -> GMisc.image -> unit) -> unit
  (** Sets a callback function to call when a button is toggled. The callback
    * function will be applied to all tool buttons. *)
end

module Make : PARAMS -> S
(** Generator. *)
