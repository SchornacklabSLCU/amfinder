(* CastANet - uI_ToggleBar.mli *)

(** UI auxiliary module dealing with annotation toggle buttons. *)

module type PARAMS = sig
  val packing : GObj.widget -> unit
  
  val remove : GObj.widget -> unit
  
  val current : unit -> CLevel.t
  
  val set_current : CLevel.t -> unit
  
  val radios : (CLevel.t * GButton.radio_button) list
end


module type TOGGLE_BAR = sig
  val is_active : char -> bool option
  (** Indicates whether the given annotation is active at the current level. *)

  val set_status : (CLevel.t * CMask.tile) list -> unit
  (** Updates all toggle buttons. *)

  val is_locked : unit -> bool
  (** Indicates whether a toggle is locked and callbacks should not apply. *)
end


module Make : PARAMS -> TOGGLE_BAR
(** Generator. *)
