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
  (** Indicates whether the given annotation is active at the current level. *)

  val set_status : (AmfLevel.t * AmfAnnot.annot) list -> unit
  (** Updates all toggle buttons. *)

  val is_locked : unit -> bool
  (** Indicates whether a toggle is locked and callbacks should not apply. *)
end


module Make : PARAMS -> S
(** Generator. *)
