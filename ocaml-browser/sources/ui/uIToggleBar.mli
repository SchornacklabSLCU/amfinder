(* CastANet - uI_ToggleBar.mli *)

(** UI auxiliary module dealing with annotation toggle buttons. *)

module type PARAMS = sig
  val packing : GObj.widget -> unit
  
  val remove : GObj.widget -> unit
  
  val current : unit -> AmfLevel.t
  
  val set_current : AmfLevel.t -> unit
  
  val radios : (AmfLevel.t * GButton.radio_button) list
end


module type S = sig
    val is_active : char -> bool option
    (** Indicate whether the given annotation is active at the current level. *)

    val iter_all : (AmfLevel.t -> char -> GButton.toggle_button -> GMisc.image -> unit) -> unit
    (** Iterate over all toggle buttons. *)

    val iter_current : (char -> GButton.toggle_button -> GMisc.image -> unit) -> unit
    (** Iterate over toggle buttons at the current level. *)
end


module Make : PARAMS -> S
(** Generator. *)
