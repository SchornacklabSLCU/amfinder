(* The Automated Mycorrhiza Finder version 1.0 - uI_Levels.mli *)

(** UI auxiliary module dealing with annotation levels. *)

module type PARAMS = sig
  val init_level : AmfLevel.level
  val packing : GObj.widget -> unit
end

module type S = sig
  val current : unit -> AmfLevel.level
  (** Returns the active annotation level. *)
  
  val set_current : AmfLevel.level -> unit
  (** Changes the active annotation level. *)
  
  val radios : (AmfLevel.level * GButton.radio_button) list 
  (** Radio buttons corresponding to the different annotation types. *)

  val set_callback : (AmfLevel.level -> GButton.radio_button -> unit) -> unit
  (** Applies a callback function to all radio buttons. *)
end

module Make : PARAMS -> S
(** Generator. *)
