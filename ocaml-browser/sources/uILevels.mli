(* CastANet - uI_Levels.mli *)

(** UI auxiliary module dealing with annotation levels. *)

module type PARAMS = sig
  val init_level : CLevel.t
  val packing : GObj.widget -> unit
end

module type S = sig
  val current : unit -> CLevel.t
  (** Returns the active annotation level. *)
  
  val set_current : CLevel.t -> unit
  (** Changes the active annotation level. *)
  
  val radios : (CLevel.t * GButton.radio_button) list 
  (** Radio buttons corresponding to the different annotation types. *)

  val set_callback : (CLevel.t -> GButton.radio_button -> unit) -> unit
  (** Applies a callback function to all radio buttons. *)
end

module Make : PARAMS -> S
(** Generator. *)
