(* CastANet - uI_Levels.mli *)

(** UI auxiliary module dealing with annotation levels. *)

module type PARAMS = sig
  val init_level : AmfLevel.t
  val packing : GObj.widget -> unit
end

module type S = sig
  val current : unit -> AmfLevel.t
  (** Returns the active annotation level. *)
  
  val set_current : AmfLevel.t -> unit
  (** Changes the active annotation level. *)
  
  val radios : (AmfLevel.t * GButton.radio_button) list 
  (** Radio buttons corresponding to the different annotation types. *)

  val set_callback : (AmfLevel.t -> GButton.radio_button -> unit) -> unit
  (** Applies a callback function to all radio buttons. *)
end

module Make : PARAMS -> S
(** Generator. *)
